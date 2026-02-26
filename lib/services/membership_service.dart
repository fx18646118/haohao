// 会员服务 - 处理登录、会员、支付相关API

import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/membership_models.dart';
import 'local_storage_service.dart';

/// API 配置
class MembershipApiConfig {
  // 会员系统API基础URL
  static const String baseUrl = 'https://api.tunee.ai/v1';
  
  // 请求超时配置
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 30);
}

/// 会员服务类
class MembershipService {
  final http.Client _client = http.Client();
  String? _authToken;

  // 单例模式
  static final MembershipService _instance = MembershipService._internal();
  factory MembershipService() => _instance;
  MembershipService._internal();

  /// 获取当前token
  String? get authToken => _authToken;

  /// 设置token
  void setAuthToken(String token) {
    _authToken = token;
    LocalStorageService.setAuthToken(token);
  }

  /// 清除token
  void clearAuthToken() {
    _authToken = null;
    LocalStorageService.clearAuthToken();
  }

  /// 从本地存储加载token
  Future<void> loadAuthToken() async {
    _authToken = await LocalStorageService.getAuthToken();
  }

  /// 通用请求头
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ============ 登录/认证 API ============

  /// 发送手机验证码
  /// 
  /// [phone] 手机号
  Future<VerificationCode> sendPhoneCode(String phone) async {
    final response = await _post('/auth/phone/send-code', body: {
      'phone': phone,
    });
    return VerificationCode.fromJson(response);
  }

  /// 手机号验证码登录
  /// 
  /// [phone] 手机号
  /// [code] 验证码
  /// [sessionId] 会话ID（从sendPhoneCode获取）
  Future<LoginResponse> loginWithPhone(String phone, String code, String sessionId) async {
    final response = await _post('/auth/phone/login', body: {
      'phone': phone,
      'code': code,
      'session_id': sessionId,
    });
    
    final loginResponse = LoginResponse.fromJson(response);
    setAuthToken(loginResponse.token);
    return loginResponse;
  }

  /// 微信登录
  /// 
  /// [code] 微信授权码
  Future<LoginResponse> loginWithWechat(String code) async {
    final response = await _post('/auth/wechat/login', body: {
      'code': code,
    });
    
    final loginResponse = LoginResponse.fromJson(response);
    setAuthToken(loginResponse.token);
    return loginResponse;
  }

  /// 获取微信登录URL（用于网页授权）
  String getWechatAuthUrl(String redirectUri, {String? state}) {
    final params = {
      'appid': 'YOUR_WECHAT_APPID',
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': 'snsapi_userinfo',
      if (state != null) 'state': state,
    };
    
    final uri = Uri.parse('https://open.weixin.qq.com/connect/oauth2/authorize')
        .replace(queryParameters: params);
    
    return uri.toString();
  }

  /// 退出登录
  Future<void> logout() async {
    try {
      await _post('/auth/logout');
    } catch (e) {
      // 忽略错误
    } finally {
      clearAuthToken();
    }
  }

  /// 刷新Token
  Future<String?> refreshToken() async {
    try {
      final response = await _post('/auth/refresh');
      final newToken = response['token'] as String?;
      if (newToken != null) {
        setAuthToken(newToken);
      }
      return newToken;
    } catch (e) {
      return null;
    }
  }

  // ============ 用户信息 API ============

  /// 获取当前用户信息
  Future<UserProfile?> getCurrentUser() async {
    try {
      final response = await _get('/user/profile');
      return UserProfile.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  /// 更新用户信息
  Future<UserProfile> updateUserProfile({
    String? nickname,
    String? avatarUrl,
  }) async {
    final body = <String, dynamic>{};
    if (nickname != null) body['nickname'] = nickname;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    
    final response = await _post('/user/profile', body: body);
    return UserProfile.fromJson(response);
  }

  /// 检查生成次数
  Future<Map<String, dynamic>> checkGenerationQuota() async {
    return await _get('/user/quota');
  }

  /// 使用一次生成次数
  Future<bool> consumeGenerationQuota() async {
    try {
      final response = await _post('/user/quota/consume');
      return response['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // ============ 会员套餐 API ============

  /// 获取会员套餐列表
  Future<List<MembershipPlan>> getMembershipPlans() async {
    final response = await _get('/membership/plans');
    
    if (response is List) {
      return response.map((json) => MembershipPlan.fromJson(json)).toList();
    }
    
    // 返回默认套餐
    return _getDefaultPlans();
  }

  /// 获取默认套餐（当API不可用时）
  List<MembershipPlan> _getDefaultPlans() {
    return [
      MembershipPlan(
        id: 'basic_monthly',
        name: '基础会员',
        description: '适合轻度使用者',
        price: 19.9,
        originalPrice: 29.9,
        durationDays: 30,
        generationQuota: 50,
        level: MembershipLevel.basic,
        features: [
          '每日10次生成额度',
          '标准音质下载',
          '基础风格选择',
          '7天作品保存',
        ],
      ),
      MembershipPlan(
        id: 'premium_monthly',
        name: '高级会员',
        description: '最受欢迎',
        price: 49.9,
        originalPrice: 79.9,
        durationDays: 30,
        generationQuota: 200,
        level: MembershipLevel.premium,
        isPopular: true,
        features: [
          '每日50次生成额度',
          '高清音质下载',
          '全部风格选择',
          '30天作品保存',
          '优先生成队列',
          '商业使用授权',
        ],
      ),
      MembershipPlan(
        id: 'vip_yearly',
        name: 'VIP会员',
        description: '超值年卡',
        price: 399.0,
        originalPrice: 599.0,
        durationDays: 365,
        generationQuota: 9999,
        level: MembershipLevel.vip,
        isNew: true,
        features: [
          '无限生成额度',
          '无损音质下载',
          '全部风格选择',
          '永久作品保存',
          'VIP专属队列',
          '商业使用授权',
          '专属客服支持',
          '新功能优先体验',
        ],
      ),
    ];
  }

  // ============ 支付 API ============

  /// 创建支付订单
  /// 
  /// [planId] 套餐ID
  /// [paymentMethod] 支付方式: 'wechat', 'alipay'
  Future<PaymentOrder> createOrder(String planId, String paymentMethod) async {
    final response = await _post('/payment/create', body: {
      'plan_id': planId,
      'payment_method': paymentMethod,
    });
    return PaymentOrder.fromJson(response);
  }

  /// 获取微信支付参数
  /// 
  /// [orderId] 订单ID
  Future<Map<String, dynamic>> getWechatPayParams(String orderId) async {
    return await _post('/payment/wechat/prepay', body: {
      'order_id': orderId,
    });
  }

  /// 获取支付宝支付参数
  /// 
  /// [orderId] 订单ID
  Future<Map<String, dynamic>> getAlipayParams(String orderId) async {
    return await _post('/payment/alipay/prepay', body: {
      'order_id': orderId,
    });
  }

  /// 查询订单状态
  /// 
  /// [orderId] 订单ID
  Future<PaymentOrder> getOrderStatus(String orderId) async {
    final response = await _get('/payment/order/$orderId');
    return PaymentOrder.fromJson(response);
  }

  /// 取消订单
  /// 
  /// [orderId] 订单ID
  Future<void> cancelOrder(String orderId) async {
    await _post('/payment/order/$orderId/cancel');
  }

  // ============ HTTP 请求方法 ============

  Future<dynamic> _get(String endpoint) async {
    final uri = Uri.parse('${MembershipApiConfig.baseUrl}$endpoint');
    
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(MembershipApiConfig.receiveTimeout);
    
    return _handleResponse(response);
  }

  Future<dynamic> _post(String endpoint, {Map<String, dynamic>? body}) async {
    final uri = Uri.parse('${MembershipApiConfig.baseUrl}$endpoint');
    
    final response = await _client
        .post(
          uri,
          headers: _headers,
          body: body != null ? jsonEncode(body) : null,
        )
        .timeout(MembershipApiConfig.receiveTimeout);
    
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    } else if (statusCode == 401) {
      // Token过期，尝试刷新
      throw MembershipApiException('登录已过期，请重新登录', code: 'UNAUTHORIZED');
    } else if (statusCode == 403) {
      throw MembershipApiException('权限不足', code: 'FORBIDDEN');
    } else if (statusCode == 429) {
      throw MembershipApiException('请求过于频繁，请稍后重试', code: 'RATE_LIMIT');
    } else if (statusCode >= 500) {
      throw MembershipApiException('服务器错误，请稍后重试', code: 'SERVER_ERROR');
    } else {
      try {
        final errorData = jsonDecode(body);
        final message = errorData['message'] ?? errorData['error'] ?? '请求失败';
        final code = errorData['code'] ?? 'UNKNOWN_ERROR';
        throw MembershipApiException(message, code: code);
      } catch (e) {
        if (e is MembershipApiException) rethrow;
        throw MembershipApiException('请求失败: $body', code: 'UNKNOWN_ERROR');
      }
    }
  }

  /// 关闭客户端
  void dispose() {
    _client.close();
  }
}

/// 会员API异常
class MembershipApiException implements Exception {
  final String message;
  final String code;

  MembershipApiException(this.message, {this.code = 'UNKNOWN_ERROR'});

  @override
  String toString() => 'MembershipApiException: $message (Code: $code)';
}
