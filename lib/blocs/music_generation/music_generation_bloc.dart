import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/music_models.dart';
import '../../services/api_service.dart';

// 音乐生成事件
abstract class MusicGenerationEvent {}

class StartMusicGeneration extends MusicGenerationEvent {
  final MusicGenerationRequest request;
  
  StartMusicGeneration(this.request);
}

class CheckGenerationStatus extends MusicGenerationEvent {
  final String taskId;
  
  CheckGenerationStatus(this.taskId);
}

class CancelGeneration extends MusicGenerationEvent {
  final String taskId;
  
  CancelGeneration(this.taskId);
}

// 音乐生成状态
abstract class MusicGenerationState {}

class MusicGenerationInitial extends MusicGenerationState {}

class MusicGenerationLoading extends MusicGenerationState {
  final String? message;
  final int? progress;
  
  MusicGenerationLoading({this.message, this.progress});
}

class MusicGenerationSuccess extends MusicGenerationState {
  final MusicTrack track;
  
  MusicGenerationSuccess(this.track);
}

class MusicGenerationError extends MusicGenerationState {
  final String message;
  
  MusicGenerationError(this.message);
}

// 音乐生成 BLoC
class MusicGenerationBloc extends Bloc<MusicGenerationEvent, MusicGenerationState> {
  final ApiService _apiService;
  
  MusicGenerationBloc({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService(),
        super(MusicGenerationInitial()) {
    on<StartMusicGeneration>(_onStartGeneration);
    on<CheckGenerationStatus>(_onCheckStatus);
    on<CancelGeneration>(_onCancelGeneration);
  }
  
  Future<void> _onStartGeneration(
    StartMusicGeneration event,
    Emitter<MusicGenerationState> emit,
  ) async {
    emit(MusicGenerationLoading(message: '正在提交创作请求...'));
    
    try {
      // 提交生成请求
      final response = await _apiService.generateMusic(event.request);
      
      if (response.isFailed) {
        emit(MusicGenerationError(response.error ?? '生成失败'));
        return;
      }
      
      // 开始轮询状态
      await _pollGenerationStatus(response.id, emit);
    } catch (e) {
      emit(MusicGenerationError('创作请求失败: $e'));
    }
  }
  
  Future<void> _pollGenerationStatus(
    String taskId,
    Emitter<MusicGenerationState> emit,
  ) async {
    const maxRetries = 60; // 最多轮询60次（约5分钟）
    const pollInterval = Duration(seconds: 5);
    
    for (int i = 0; i < maxRetries; i++) {
      try {
        final status = await _apiService.getGenerationStatus(taskId);
        
        if (status.isCompleted) {
          // 生成完成
          final track = MusicTrack(
            id: status.id,
            title: status.title ?? 'AI生成作品',
            audioUrl: status.audioUrl ?? '',
            coverUrl: status.coverUrl,
            duration: 120, // 默认时长
            style: 'AI生成',
            prompt: '',
            createdAt: DateTime.now(),
          );
          emit(MusicGenerationSuccess(track));
          return;
        } else if (status.isFailed) {
          emit(MusicGenerationError(status.error ?? '生成失败'));
          return;
        } else {
          // 仍在生成中
          emit(MusicGenerationLoading(
            message: _getProgressMessage(status.progress),
            progress: status.progress,
          ));
        }
        
        // 等待后再次查询
        await Future.delayed(pollInterval);
      } catch (e) {
        // 查询失败，继续尝试
        emit(MusicGenerationLoading(
          message: '正在创作中，请稍候...',
          progress: null,
        ));
        await Future.delayed(pollInterval);
      }
    }
    
    // 超时
    emit(MusicGenerationError('生成超时，请稍后到作品库查看'));
  }
  
  String _getProgressMessage(int? progress) {
    if (progress == null) return '正在创作中，请稍候...';
    
    if (progress < 20) return '正在分析创作需求...';
    if (progress < 40) return '正在生成歌词...';
    if (progress < 60) return '正在作曲编曲...';
    if (progress < 80) return '正在合成音频...';
    if (progress < 100) return '正在后期处理...';
    return '即将完成...';
  }
  
  Future<void> _onCheckStatus(
    CheckGenerationStatus event,
    Emitter<MusicGenerationState> emit,
  ) async {
    try {
      final status = await _apiService.getGenerationStatus(event.taskId);
      
      if (status.isCompleted) {
        final track = MusicTrack(
          id: status.id,
          title: status.title ?? 'AI生成作品',
          audioUrl: status.audioUrl ?? '',
          coverUrl: status.coverUrl,
          duration: 120,
          style: 'AI生成',
          prompt: '',
          createdAt: DateTime.now(),
        );
        emit(MusicGenerationSuccess(track));
      } else if (status.isFailed) {
        emit(MusicGenerationError(status.error ?? '生成失败'));
      } else {
        emit(MusicGenerationLoading(
          message: _getProgressMessage(status.progress),
          progress: status.progress,
        ));
      }
    } catch (e) {
      emit(MusicGenerationError('查询状态失败: $e'));
    }
  }
  
  Future<void> _onCancelGeneration(
    CancelGeneration event,
    Emitter<MusicGenerationState> emit,
  ) async {
    try {
      await _apiService.cancelGeneration(event.taskId);
      emit(MusicGenerationInitial());
    } catch (e) {
      // 取消失败，忽略错误
    }
  }
}
