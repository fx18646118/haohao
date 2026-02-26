// 会员状态管理 - 使用 ChangeNotifier

import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/membership_models.dart';
import '../services/membership_service.dart';
import '../services/local_storage_service.dart';

/// 会员状态管理类
class MembershipProvider extends ChangeNotifier {
  final MembershipService _membershipService = MembershipService();
  
  // 用户状态
  UserProfile? _user;
  bool _isLoading = false;
  String? _error;
  
  // 套餐列表
  List<MembershipPlan> _plans = [];
  bool _isLoadingPlans = false;
  
  // 当前订单
  PaymentOrder? _currentOrder;
  bool _isProcessingPayment = false;

  // Getters
  UserProfile? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isLoggedIn => _user?.isLoggedIn ?? false;
  bool get isMember => _user?.isMember ?? false;
  bool get canGenerate => _user?.canGenerate ?? false;
  int get remainingGenerations => _user?.remainingGenerations ?? 0;
  MembershipLevel get membershipLevel => _user?.level ?? MembershipLevel.free;
  
  List<MembershipPlan> get plans => _plans;
  bool get isLoadingPlans => _isLoadingPlans;
  
  PaymentOrder? get currentOrder => _currentOrder;
  bool get isProcessingPayment => _isProcessingPayment;

  /// 初始化 - 加载本地存储的用户信息
  Future<void> initialize() async {
    _setLoading(true);
    
    try {
      // 加载token
      await _membershipService.loadAuthToken();
      
      // 如果有token，获取用户信息
      if (_membershipService.authToken != null) {
        await refreshUserProfile();
      }
      
      // 加载套餐列表
      await loadMembershipPlans();
    } catch (e) {
      _setError('初始化失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 刷新用户信息
  Future<void> refreshUserProfile() async {
    try {
      final user = await _membershipService.getCurrentUser();
      if (user != null) {
        _user = user;
        notifyListeners();
      }
    } catch (e) {
      // 如果获取失败，可能是token过期
      _membershipService.clearAuthToken();
    }
  }

  /// 发送手机验证码
  Future<VerificationCode?> sendPhoneCode(String phone) async {
    _setLoading(true);
    _clearError();
    
    try {
      final code = await _membershipService.sendPhoneCode(phone);
      _setLoading(false);
      return code;
    } on MembershipApiException catch (e) {
      _setError(e.message);
      return null;
    } catch (e) {
      _setError('发送验证码失败');
      return null;
    }
  }

  /// 手机号验证码登录
  Future<bool> loginWithPhone(String phone, String code, String sessionId) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _membershipService.loginWithPhone(phone, code, sessionId);
      _user = response.user;
      _setLoading(false);
      notifyListeners();
      return true;
    } on MembershipApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('登录失败');
      return false;
    }
  }

  /// 微信登录
  Future<bool> loginWithWechat(String code) async {
    _setLoading(true);
    _clearError();
    
    try {
      final response = await _membershipService.loginWithWechat(code);
      _user = response.user;
      _setLoading(false);
      notifyListeners();
      return true;
    } on MembershipApiException catch (e) {
      _setError(e.message);
      return false;
    } catch (e) {
      _setError('微信登录失败');
      return false;
    }
  }

  /// 退出登录
  Future<void> logout() async {
    await _membershipService.logout();
    _user = null;
    _currentOrder = null;
    notifyListeners();
  }

  /// 加载会员套餐
  Future<void> loadMembershipPlans() async {
    _isLoadingPlans = true;
    notifyListeners();
    
    try {
      _plans = await _membershipService.getMembershipPlans();
    } catch (e) {
      // 使用默认套餐
      _plans = _getDefaultPlans();
    } finally {
      _isLoadingPlans = false;
      notifyListeners();
    }
  }

  /// 创建支付订单
  Future<PaymentOrder?> createOrder(String planId, String paymentMethod) async {
    _isProcessingPayment = true;
    _clearError();
    notifyListeners();
    
    try {
      final order = await _membershipService.createOrder(planId, paymentMethod);
      _currentOrder = order;
      _isProcessingPayment = false;
      notifyListeners();
      return order;
    } on MembershipApiException catch (e) {
      _setError(e.message);
      _isProcessingPayment = false;
      notifyListeners();
      return null;
    } catch (e) {
      _setError('创建订单失败');
      _isProcessingPayment = false;
      notifyListeners();
      return null;
    }
  }

  /// 获取微信支付参数
  Future<Map<String, dynamic>?> getWechatPayParams() async {
    if (_currentOrder == null) return null;
    
    try {
      return await _membershipService.getWechatPayParams(_currentOrder!.id);
    } catch (e) {
      _setError('获取支付参数失败');
      return null;
    }
  }

  /// 获取支付宝支付参数
  Future<Map<String, dynamic>?> getAlipayParams() async {
    if (_currentOrder == null) return null;
    
    try {
      return await _membershipService.getAlipayParams(_currentOrder!.id);
    } catch (e) {
      _setError('获取支付参数失败');
      return null;
    }
  }

  /// 查询订单状态
  Future<void> checkOrderStatus() async {
    if (_currentOrder == null) return;
    
    try {
      final order = await _membershipService.getOrderStatus(_currentOrder!.id);
      _currentOrder = order;
      
      // 如果支付成功，刷新用户信息
      if (order.isPaid) {
        await refreshUserProfile();
      }
      
      notifyListeners();
    } catch (e) {
      // 忽略错误
    }
  }

  /// 取消订单
  Future<void> cancelOrder() async {
    if (_currentOrder == null) return;
    
    try {
      await _membershipService.cancelOrder(_currentOrder!.id);
      _currentOrder = null;
      notifyListeners();
    } catch (e) {
      // 忽略错误
    }
  }

  /// 检查生成次数
  Future<bool> checkGenerationQuota() async {
    if (!isLoggedIn) return false;
    
    try {
      final result = await _membershipService.checkGenerationQuota();
      final remaining = result['remaining_generations'] as int? ?? 0;
      
      // 更新本地用户信息
      if (_user != null) {
        _user = _user!.copyWith(remainingGenerations: remaining);
        notifyListeners();
      }
      
      return remaining > 0;
    } catch (e) {
      return false;
    }
  }

  /// 消耗一次生成次数
  Future<bool> consumeGeneration() async {
    if (!isLoggedIn) return false;
    
    try {
      final success = await _membershipService.consumeGenerationQuota();
      if (success && _user != null) {
        _user = _user!.copyWith(
          remainingGenerations: _user!.remainingGenerations - 1,
          totalGenerations: _user!.totalGenerations + 1,
        );
        notifyListeners();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  /// 更新用户信息
  Future<bool> updateProfile({String? nickname, String? avatarUrl}) async {
    _setLoading(true);
    
    try {
      final user = await _membershipService.updateUserProfile(
        nickname: nickname,
        avatarUrl: avatarUrl,
      );
      _user = user;
      _setLoading(false);
      return true;
    } catch (e) {
      _setError('更新失败');
      return false;
    }
  }

  /// 清除当前错误
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// 清除当前订单
  void clearCurrentOrder() {
    _currentOrder = null;
    notifyListeners();
  }

  // Private methods
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _error = message;
    _isLoading = false;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  /// 获取默认套餐
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
}
