// 音乐生成请求模型
class MusicGenerationRequest {
  final String prompt;
  final String? style;
  final int? duration;
  final String? lyrics;
  final bool instrumental;
  final MultimodalInput? multimodal;

  MusicGenerationRequest({
    required this.prompt,
    this.style,
    this.duration,
    this.lyrics,
    this.instrumental = false,
    this.multimodal,
  });

  Map<String, dynamic> toJson() {
    return {
      'prompt': prompt,
      if (style != null) 'style': style,
      if (duration != null) 'duration': duration,
      if (lyrics != null) 'lyrics': lyrics,
      'instrumental': instrumental,
      if (multimodal != null) 'multimodal': multimodal!.toJson(),
    };
  }
}

// 多模态输入模型
class MultimodalInput {
  final String? imageBase64;
  final String? videoBase64;
  final String? audioBase64;
  final String? imageUrl;
  final String? audioUrl;

  MultimodalInput({
    this.imageBase64,
    this.videoBase64,
    this.audioBase64,
    this.imageUrl,
    this.audioUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      if (imageBase64 != null) 'image': imageBase64,
      if (videoBase64 != null) 'video': videoBase64,
      if (audioBase64 != null) 'audio': audioBase64,
      if (imageUrl != null) 'image_url': imageUrl,
      if (audioUrl != null) 'audio_url': audioUrl,
    };
  }
}

// 音乐生成响应模型
class MusicGenerationResponse {
  final String id;
  final String status;
  final int? progress;
  final String? audioUrl;
  final String? coverUrl;
  final String? title;
  final String? error;
  final DateTime createdAt;

  MusicGenerationResponse({
    required this.id,
    required this.status,
    this.progress,
    this.audioUrl,
    this.coverUrl,
    this.title,
    this.error,
    required this.createdAt,
  });

  factory MusicGenerationResponse.fromJson(Map<String, dynamic> json) {
    return MusicGenerationResponse(
      id: json['id'] ?? '',
      status: json['status'] ?? 'pending',
      progress: json['progress'],
      audioUrl: json['audio_url'],
      coverUrl: json['cover_url'],
      title: json['title'],
      error: json['error'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }

  bool get isCompleted => status == 'completed';
  bool get isFailed => status == 'failed';
  bool get isGenerating => status == 'generating' || status == 'pending';
}

// 音乐作品模型
class MusicTrack {
  final String id;
  final String title;
  final String? artist;
  final String? coverUrl;
  final String audioUrl;
  final int duration;
  final String? style;
  final String? prompt;
  final DateTime createdAt;
  final bool isFavorite;

  MusicTrack({
    required this.id,
    required this.title,
    this.artist,
    this.coverUrl,
    required this.audioUrl,
    required this.duration,
    this.style,
    this.prompt,
    required this.createdAt,
    this.isFavorite = false,
  });

  factory MusicTrack.fromJson(Map<String, dynamic> json) {
    return MusicTrack(
      id: json['id'] ?? '',
      title: json['title'] ?? '未命名作品',
      artist: json['artist'],
      coverUrl: json['cover_url'],
      audioUrl: json['audio_url'] ?? '',
      duration: json['duration'] ?? 0,
      style: json['style'],
      prompt: json['prompt'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      isFavorite: json['is_favorite'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'cover_url': coverUrl,
      'audio_url': audioUrl,
      'duration': duration,
      'style': style,
      'prompt': prompt,
      'created_at': createdAt.toIso8601String(),
      'is_favorite': isFavorite,
    };
  }

  String get durationText {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// 音乐风格模型
class MusicStyle {
  final String id;
  final String name;
  final String icon;
  final String? description;
  final List<String>? tags;

  MusicStyle({
    required this.id,
    required this.name,
    required this.icon,
    this.description,
    this.tags,
  });

  factory MusicStyle.fromJson(Map<String, dynamic> json) {
    return MusicStyle(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      icon: json['icon'] ?? '🎵',
      description: json['description'],
      tags: json['tags'] != null ? List<String>.from(json['tags']) : null,
    );
  }
}

// 聊天消息模型
class ChatMessage {
  final String id;
  final bool isUser;
  final String message;
  final DateTime timestamp;
  final bool isGenerating;
  final MusicTrack? generatedTrack;
  final List<ChatAttachment>? attachments;

  ChatMessage({
    String? id,
    required this.isUser,
    required this.message,
    required this.timestamp,
    this.isGenerating = false,
    this.generatedTrack,
    this.attachments,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  ChatMessage copyWith({
    bool? isGenerating,
    MusicTrack? generatedTrack,
  }) {
    return ChatMessage(
      id: id,
      isUser: isUser,
      message: message,
      timestamp: timestamp,
      isGenerating: isGenerating ?? this.isGenerating,
      generatedTrack: generatedTrack ?? this.generatedTrack,
      attachments: attachments,
    );
  }
}

// 聊天附件模型
class ChatAttachment {
  final String type; // 'image', 'video', 'audio'
  final String? filePath;
  final String? url;
  final String? base64Data;

  ChatAttachment({
    required this.type,
    this.filePath,
    this.url,
    this.base64Data,
  });
}

// 用户模型
class User {
  final String id;
  final String? nickname;
  final String? avatarUrl;
  final int trackCount;
  final int favoriteCount;
  final DateTime createdAt;

  User({
    required this.id,
    this.nickname,
    this.avatarUrl,
    this.trackCount = 0,
    this.favoriteCount = 0,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      nickname: json['nickname'],
      avatarUrl: json['avatar_url'],
      trackCount: json['track_count'] ?? 0,
      favoriteCount: json['favorite_count'] ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
    );
  }
}
