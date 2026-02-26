import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/music_models.dart';
import '../../services/api_service.dart';

// 聊天事件
abstract class ChatEvent {}

class SendMessage extends ChatEvent {
  final String message;
  final List<ChatAttachment>? attachments;
  
  SendMessage(this.message, {this.attachments});
}

class ReceiveMessage extends ChatEvent {
  final ChatMessage message;
  
  ReceiveMessage(this.message);
}

class UpdateMessage extends ChatEvent {
  final String messageId;
  final bool? isGenerating;
  final MusicTrack? generatedTrack;
  
  UpdateMessage({
    required this.messageId,
    this.isGenerating,
    this.generatedTrack,
  });
}

class ClearChat extends ChatEvent {}

class LoadChatHistory extends ChatEvent {}

// 聊天状态
abstract class ChatState {}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;
  final bool isGenerating;
  
  ChatLoaded(this.messages, {this.isGenerating = false});
}

class ChatError extends ChatState {
  final String message;
  
  ChatError(this.message);
}

// 聊天 BLoC
class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService _apiService;
  final List<ChatMessage> _messages = [];
  
  ChatBloc({ApiService? apiService})
      : _apiService = apiService ?? ApiService(),
        super(ChatInitial()) {
    on<SendMessage>(_onSendMessage);
    on<ReceiveMessage>(_onReceiveMessage);
    on<UpdateMessage>(_onUpdateMessage);
    on<ClearChat>(_onClearChat);
    on<LoadChatHistory>(_onLoadChatHistory);
    
    // 初始化欢迎消息
    _addWelcomeMessage();
  }
  
  void _addWelcomeMessage() {
    _messages.add(ChatMessage(
      isUser: false,
      message: '''你好！我是皓皓同学，你的AI音乐创作助手 🎵

我可以帮你：
• 🎤 根据描述生成完整歌曲
• 🎸 创作特定风格的音乐
• 🎹 为视频/图片配乐
• 📝 写歌词并谱曲

告诉我你想创作什么样的音乐？比如：
"写一首关于夏日海滩的轻快节奏流行歌"''',
      timestamp: DateTime.now(),
    ));
  }
  
  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<ChatState> emit,
  ) async {
    // 添加用户消息
    final userMessage = ChatMessage(
      isUser: true,
      message: event.message,
      timestamp: DateTime.now(),
      attachments: event.attachments,
    );
    _messages.add(userMessage);
    emit(ChatLoaded(List.from(_messages), isGenerating: true));
    
    // 模拟AI思考并回复
    await Future.delayed(const Duration(milliseconds: 800));
    
    // 根据用户输入生成AI回复
    final aiResponse = _generateAIResponse(event.message);
    
    final aiMessage = ChatMessage(
      isUser: false,
      message: aiResponse,
      timestamp: DateTime.now(),
      isGenerating: aiResponse.contains('生成中') || aiResponse.contains('创作'),
    );
    _messages.add(aiMessage);
    
    emit(ChatLoaded(List.from(_messages), isGenerating: aiMessage.isGenerating));
  }
  
  String _generateAIResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();
    
    // 检测是否是音乐生成请求
    if (lowerMessage.contains('歌') || 
        lowerMessage.contains('曲') || 
        lowerMessage.contains('音乐') ||
        lowerMessage.contains('生成') ||
        lowerMessage.contains('创作') ||
        lowerMessage.contains('写')) {
      
      // 提取风格
      String style = '流行';
      if (lowerMessage.contains('摇滚')) style = '摇滚';
      else if (lowerMessage.contains('电子')) style = '电子';
      else if (lowerMessage.contains('古典')) style = '古典';
      else if (lowerMessage.contains('爵士')) style = '爵士';
      else if (lowerMessage.contains('说唱') || lowerMessage.contains('rap')) style = '说唱';
      else if (lowerMessage.contains('民谣')) style = '民谣';
      
      return '''好的！我来为你创作一首$style风格的歌曲。

🎵 正在分析你的需求...
📝 正在生成歌词...
🎸 正在作曲编曲...
🎤 正在合成演唱...

请稍等，创作完成后我会自动播放给你听！''';
    }
    
    // 问候语
    if (lowerMessage.contains('你好') || lowerMessage.contains('嗨') || lowerMessage.contains('hi')) {
      return '你好！准备好创作音乐了吗？告诉我你的想法 💡';
    }
    
    // 帮助请求
    if (lowerMessage.contains('帮助') || lowerMessage.contains('怎么用') || lowerMessage.contains('help')) {
      return '''我可以这样帮你创作音乐：

1️⃣ **直接描述**："写一首关于失恋的伤感情歌"
2️⃣ **指定风格**："生成一段轻快的电子音乐"
3️⃣ **上传素材**：点击下方的 📎 按钮上传图片/视频/音频作为参考
4️⃣ **快捷选择**：使用上方的快捷按钮快速选择风格

试试输入你的创意吧！''';
    }
    
    // 默认回复
    return '''收到！我理解你想创作关于"$userMessage"的音乐。

让我为你生成一首独特的作品，请稍候...

⏱️ 预计需要 1-2 分钟''';
  }
  
  Future<void> _onReceiveMessage(
    ReceiveMessage event,
    Emitter<ChatState> emit,
  ) async {
    _messages.add(event.message);
    emit(ChatLoaded(List.from(_messages)));
  }
  
  Future<void> _onUpdateMessage(
    UpdateMessage event,
    Emitter<ChatState> emit,
  ) async {
    final index = _messages.indexWhere((m) => m.id == event.messageId);
    if (index != -1) {
      _messages[index] = _messages[index].copyWith(
        isGenerating: event.isGenerating,
        generatedTrack: event.generatedTrack,
      );
      emit(ChatLoaded(List.from(_messages), isGenerating: event.isGenerating ?? false));
    }
  }
  
  Future<void> _onClearChat(
    ClearChat event,
    Emitter<ChatState> emit,
  ) async {
    _messages.clear();
    _addWelcomeMessage();
    emit(ChatLoaded(List.from(_messages)));
  }
  
  Future<void> _onLoadChatHistory(
    LoadChatHistory event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    // 这里可以从本地存储加载历史记录
    emit(ChatLoaded(List.from(_messages)));
  }
}
