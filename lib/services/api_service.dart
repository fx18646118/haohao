import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/music_models.dart';

// API 配置
class ApiConfig {
  // 主 API 配置 - 可以根据需要切换不同的音乐生成服务
  static const String baseUrl = 'https://api.tunee.ai/v1';  // 示例URL
  static const String apiKey = 'YOUR_API_KEY_HERE';
  
  // 备用 API 配置
  static const String backupBaseUrl = 'https://api.suno.ai/v1';
  static const String backupApiKey = 'YOUR_BACKUP_API_KEY';
  
  // 请求超时配置
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  static const Duration sendTimeout = Duration(seconds: 30);
}

// API 异常类
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, {this.statusCode});
  
  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

// API 服务类
class ApiService {
  final http.Client _client = http.Client();
  
  // 通用请求头
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer ${ApiConfig.apiKey}',
    'Accept': 'application/json',
  };
  
  // GET 请求
  Future<dynamic> get(String endpoint, {Map<String, String>? queryParams}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint').replace(
        queryParameters: queryParams,
      );
      
      final response = await _client.get(
        uri,
        headers: _headers,
      ).timeout(ApiConfig.receiveTimeout);
      
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException('网络连接失败，请检查网络设置');
    } on TimeoutException catch (e) {
      throw ApiException('请求超时，请稍后重试');
    } catch (e) {
      throw ApiException('请求失败: $e');
    }
  }
  
  // POST 请求
  Future<dynamic> post(String endpoint, {Map<String, dynamic>? body}) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}$endpoint');
      
      final response = await _client.post(
        uri,
        headers: _headers,
        body: body != null ? jsonEncode(body) : null,
      ).timeout(ApiConfig.receiveTimeout);
      
      return _handleResponse(response);
    } on SocketException catch (e) {
      throw ApiException('网络连接失败，请检查网络设置');
    } on TimeoutException catch (e) {
      throw ApiException('请求超时，请稍后重试');
    } catch (e) {
      throw ApiException('请求失败: $e');
    }
  }
  
  // 处理响应
  dynamic _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;
    
    if (statusCode >= 200 && statusCode < 300) {
      if (body.isEmpty) return null;
      return jsonDecode(body);
    } else if (statusCode == 401) {
      throw ApiException('API 密钥无效或已过期', statusCode: statusCode);
    } else if (statusCode == 429) {
      throw ApiException('请求过于频繁，请稍后重试', statusCode: statusCode);
    } else if (statusCode >= 500) {
      throw ApiException('服务器错误，请稍后重试', statusCode: statusCode);
    } else {
      try {
        final errorData = jsonDecode(body);
        final errorMessage = errorData['error']?['message'] ?? errorData['message'] ?? '未知错误';
        throw ApiException(errorMessage, statusCode: statusCode);
      } catch (e) {
        throw ApiException('请求失败: $body', statusCode: statusCode);
      }
    }
  }
  
  // ============ 音乐生成 API ============
  
  /// 生成音乐
  /// 
  /// [request] 音乐生成请求参数
  /// 返回生成任务ID
  Future<MusicGenerationResponse> generateMusic(MusicGenerationRequest request) async {
    final data = await post('/music/generate', body: request.toJson());
    return MusicGenerationResponse.fromJson(data);
  }
  
  /// 查询生成状态
  /// 
  /// [taskId] 生成任务ID
  Future<MusicGenerationResponse> getGenerationStatus(String taskId) async {
    final data = await get('/music/status', queryParams: {'id': taskId});
    return MusicGenerationResponse.fromJson(data);
  }
  
  /// 取消生成任务
  Future<void> cancelGeneration(String taskId) async {
    await post('/music/cancel', body: {'id': taskId});
  }
  
  // ============ 作品管理 API ============
  
  /// 获取作品列表
  Future<List<MusicTrack>> getTracks({int page = 1, int limit = 20}) async {
    final data = await get('/tracks', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
    
    if (data is List) {
      return data.map((json) => MusicTrack.fromJson(json)).toList();
    }
    return [];
  }
  
  /// 获取作品详情
  Future<MusicTrack?> getTrack(String trackId) async {
    try {
      final data = await get('/tracks/$trackId');
      return MusicTrack.fromJson(data);
    } catch (e) {
      return null;
    }
  }
  
  /// 删除作品
  Future<void> deleteTrack(String trackId) async {
    await post('/tracks/$trackId/delete');
  }
  
  /// 更新作品信息
  Future<MusicTrack> updateTrack(String trackId, {String? title, bool? isFavorite}) async {
    final body = <String, dynamic>{};
    if (title != null) body['title'] = title;
    if (isFavorite != null) body['is_favorite'] = isFavorite;
    
    final data = await post('/tracks/$trackId/update', body: body);
    return MusicTrack.fromJson(data);
  }
  
  // ============ 风格/发现 API ============
  
  /// 获取音乐风格列表
  Future<List<MusicStyle>> getStyles() async {
    final data = await get('/styles');
    
    if (data is List) {
      return data.map((json) => MusicStyle.fromJson(json)).toList();
    }
    
    // 返回默认风格列表
    return _getDefaultStyles();
  }
  
  /// 获取推荐作品
  Future<List<MusicTrack>> getRecommendedTracks({int limit = 10}) async {
    final data = await get('/tracks/recommended', queryParams: {
      'limit': limit.toString(),
    });
    
    if (data is List) {
      return data.map((json) => MusicTrack.fromJson(json)).toList();
    }
    return [];
  }
  
  /// 获取热门作品
  Future<List<MusicTrack>> getPopularTracks({int limit = 10}) async {
    final data = await get('/tracks/popular', queryParams: {
      'limit': limit.toString(),
    });
    
    if (data is List) {
      return data.map((json) => MusicTrack.fromJson(json)).toList();
    }
    return [];
  }
  
  // ============ 文件上传 API ============
  
  /// 上传图片
  Future<String> uploadImage(File file) async {
    return _uploadFile(file, 'image');
  }
  
  /// 上传音频
  Future<String> uploadAudio(File file) async {
    return _uploadFile(file, 'audio');
  }
  
  /// 上传视频
  Future<String> uploadVideo(File file) async {
    return _uploadFile(file, 'video');
  }
  
  /// 通用文件上传
  Future<String> _uploadFile(File file, String type) async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/upload');
      
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_headers);
      
      // 确定 MIME 类型
      String? mimeType;
      switch (type) {
        case 'image':
          mimeType = 'image/jpeg';
          break;
        case 'audio':
          mimeType = 'audio/mpeg';
          break;
        case 'video':
          mimeType = 'video/mp4';
          break;
      }
      
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        file.path,
        contentType: mimeType != null ? MediaType.parse(mimeType) : null,
      ));
      
      request.fields['type'] = type;
      
      final streamedResponse = await request.send().timeout(ApiConfig.sendTimeout);
      final response = await http.Response.fromStream(streamedResponse);
      
      final data = _handleResponse(response);
      return data['url'] ?? '';
    } catch (e) {
      throw ApiException('文件上传失败: $e');
    }
  }
  
  // ============ 用户 API ============
  
  /// 获取用户信息
  Future<User?> getUserInfo() async {
    try {
      final data = await get('/user');
      return User.fromJson(data);
    } catch (e) {
      return null;
    }
  }
  
  /// 获取用户统计
  Future<Map<String, dynamic>?> getUserStats() async {
    try {
      return await get('/user/stats');
    } catch (e) {
      return null;
    }
  }
  
  // ============ 辅助方法 ============
  
  /// 获取默认风格列表
  List<MusicStyle> _getDefaultStyles() {
    return [
      MusicStyle(id: 'pop', name: '流行', icon: '🎵', description: '现代流行音乐风格'),
      MusicStyle(id: 'rock', name: '摇滚', icon: '🎸', description: '激情摇滚风格'),
      MusicStyle(id: 'electronic', name: '电子', icon: '🎹', description: '电子音乐风格'),
      MusicStyle(id: 'classical', name: '古典', icon: '🎼', description: '古典音乐风格'),
      MusicStyle(id: 'jazz', name: '爵士', icon: '🎷', description: '爵士音乐风格'),
      MusicStyle(id: 'hiphop', name: '说唱', icon: '🎤', description: '嘻哈说唱风格'),
      MusicStyle(id: 'folk', name: '民谣', icon: '🪕', description: '民谣风格'),
      MusicStyle(id: 'rnb', name: 'R&B', icon: '💿', description: '节奏布鲁斯风格'),
    ];
  }
  
  /// 关闭客户端
  void dispose() {
    _client.close();
  }
}
