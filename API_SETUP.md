# Tunee App API 配置指南

## 快速开始

### 1. 获取 API 密钥

目前支持以下 AI 音乐生成服务：

#### Option A: Suno API (推荐)
1. 访问 https://www.suno.ai
2. 注册账号并获取 API 密钥
3. 将密钥填入配置

#### Option B: 其他音乐生成服务
- Mureka AI
- Udio
- 其他兼容 API

### 2. 配置 API 密钥

编辑文件：`lib/services/api_service.dart`

```dart
class ApiConfig {
  // 主 API 配置
  static const String baseUrl = 'https://api.suno.ai/v1';  // 替换为你的API地址
  static const String apiKey = 'YOUR_API_KEY_HERE';        // 替换为你的API密钥
  
  // 备用 API 配置（可选）
  static const String backupBaseUrl = 'https://api.backup.com/v1';
  static const String backupApiKey = 'YOUR_BACKUP_API_KEY';
}
```

### 3. 接口适配

如果你的 API 接口格式不同，需要修改 `ApiService` 类中的方法：

#### 生成音乐接口
```dart
Future<MusicGenerationResponse> generateMusic(MusicGenerationRequest request) async {
  // 根据你的 API 调整请求格式
  final body = {
    'prompt': request.prompt,
    'style': request.style,
    'duration': request.duration,
    // ... 其他参数
  };
  
  final data = await post('/music/generate', body: body);
  return MusicGenerationResponse.fromJson(data);
}
```

#### 查询状态接口
```dart
Future<MusicGenerationResponse> getGenerationStatus(String taskId) async {
  final data = await get('/music/status', queryParams: {'id': taskId});
  return MusicGenerationResponse.fromJson(data);
}
```

### 4. 响应格式适配

如果你的 API 响应格式不同，修改 `MusicGenerationResponse.fromJson`：

```dart
factory MusicGenerationResponse.fromJson(Map<String, dynamic> json) {
  return MusicGenerationResponse(
    id: json['id'] ?? '',                    // 调整字段名
    status: json['status'] ?? 'pending',     // 调整字段名
    progress: json['progress'],              // 调整字段名
    audioUrl: json['audio_url'],             // 调整字段名
    coverUrl: json['cover_url'],             // 调整字段名
    title: json['title'],
    error: json['error'],
    createdAt: DateTime.now(),
  );
}
```

## 模拟模式（开发测试）

如果没有 API 密钥，可以启用模拟模式：

```dart
class ApiService {
  bool _mockMode = true;  // 启用模拟模式
  
  Future<MusicGenerationResponse> generateMusic(MusicGenerationRequest request) async {
    if (_mockMode) {
      // 模拟延迟
      await Future.delayed(const Duration(seconds: 2));
      
      // 返回模拟数据
      return MusicGenerationResponse(
        id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
        status: 'completed',
        audioUrl: 'https://example.com/mock-audio.mp3',
        title: '模拟生成作品',
        createdAt: DateTime.now(),
      );
    }
    
    // 真实 API 调用...
  }
}
```

## 本地数据模式

App 支持完全离线模式，所有数据存储在本地：

```dart
// 作品自动保存到本地
LocalStorageService.saveTrack(track);

// 从本地读取作品
final tracks = LocalStorageService.getAllTracks();
```

## 常见问题

### Q: 如何测试 API 是否正常工作？

```bash
# 使用 curl 测试
curl -X POST https://api.yourservice.com/v1/music/generate \
  -H "Authorization: Bearer YOUR_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"prompt": "happy pop song", "style": "pop"}'
```

### Q: 支持哪些音乐风格？

在 `ApiService._getDefaultStyles()` 中配置：

```dart
List<MusicStyle> _getDefaultStyles() {
  return [
    MusicStyle(id: 'pop', name: '流行', icon: '🎵'),
    MusicStyle(id: 'rock', name: '摇滚', icon: '🎸'),
    // 添加更多风格...
  ];
}
```

### Q: 如何添加新的 API 提供商？

1. 在 `ApiConfig` 中添加新配置
2. 创建新的 `ApiService` 子类或修改现有类
3. 实现必要的接口方法
4. 在 `main.dart` 中切换服务

## 安全提示

⚠️ **不要将 API 密钥提交到代码仓库！**

建议使用环境变量或配置文件：

```dart
// 从环境变量读取
static String get apiKey => const String.fromEnvironment('TUNEE_API_KEY');
```

运行时使用：
```bash
flutter run --dart-define=TUNEE_API_KEY=your_api_key_here
```
