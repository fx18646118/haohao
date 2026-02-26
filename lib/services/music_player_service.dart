import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import '../models/music_models.dart';

// 播放器状态
enum PlayerState {
  idle,
  loading,
  playing,
  paused,
  completed,
  error,
}

// 音乐播放器服务
class MusicPlayerService extends ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  PlayerState _state = PlayerState.idle;
  MusicTrack? _currentTrack;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  double _volume = 1.0;
  bool _isLooping = false;
  
  // Getters
  PlayerState get state => _state;
  MusicTrack? get currentTrack => _currentTrack;
  Duration get duration => _duration;
  Duration get position => _position;
  double get volume => _volume;
  bool get isLooping => _isLooping;
  bool get isPlaying => _state == PlayerState.playing;
  bool get isLoading => _state == PlayerState.loading;
  
  // 进度百分比
  double get progress {
    if (_duration.inMilliseconds == 0) return 0;
    return _position.inMilliseconds / _duration.inMilliseconds;
  }
  
  // 构造函数
  MusicPlayerService() {
    _initAudioPlayer();
  }
  
  void _initAudioPlayer() {
    // 监听播放器状态
    _audioPlayer.onPlayerStateChanged.listen((state) {
      switch (state) {
        case PlayerState.playing:
          _state = PlayerState.playing;
          break;
        case PlayerState.paused:
          _state = PlayerState.paused;
          break;
        case PlayerState.completed:
          _state = PlayerState.completed;
          _position = Duration.zero;
          if (_isLooping && _currentTrack != null) {
            play(_currentTrack!);
          }
          break;
        default:
          break;
      }
      notifyListeners();
    });
    
    // 监听播放时长
    _audioPlayer.onDurationChanged.listen((Duration duration) {
      _duration = duration;
      notifyListeners();
    });
    
    // 监听播放位置
    _audioPlayer.onPositionChanged.listen((Duration position) {
      _position = position;
      notifyListeners();
    });
    
    // 监听错误
    _audioPlayer.onPlayerComplete.listen((_) {
      _state = PlayerState.completed;
      notifyListeners();
    });
  }
  
  // 播放音乐
  Future<void> play(MusicTrack track) async {
    try {
      if (_currentTrack?.id != track.id) {
        // 播放新曲目
        _state = PlayerState.loading;
        _currentTrack = track;
        _position = Duration.zero;
        notifyListeners();
        
        await _audioPlayer.stop();
        await _audioPlayer.play(UrlSource(track.audioUrl));
      } else {
        // 恢复播放当前曲目
        if (_state == PlayerState.paused) {
          await _audioPlayer.resume();
        } else if (_state == PlayerState.completed) {
          await _audioPlayer.seek(Duration.zero);
          await _audioPlayer.resume();
        }
      }
    } catch (e) {
      _state = PlayerState.error;
      notifyListeners();
    }
  }
  
  // 暂停播放
  Future<void> pause() async {
    await _audioPlayer.pause();
    _state = PlayerState.paused;
    notifyListeners();
  }
  
  // 停止播放
  Future<void> stop() async {
    await _audioPlayer.stop();
    _state = PlayerState.idle;
    _position = Duration.zero;
    notifyListeners();
  }
  
  // 跳转到指定位置
  Future<void> seekTo(Duration position) async {
    await _audioPlayer.seek(position);
    _position = position;
    notifyListeners();
  }
  
  // 设置音量
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    await _audioPlayer.setVolume(_volume);
    notifyListeners();
  }
  
  // 切换循环模式
  void toggleLoop() {
    _isLooping = !_isLooping;
    notifyListeners();
  }
  
  // 播放/暂停切换
  Future<void> togglePlay(MusicTrack track) async {
    if (_currentTrack?.id == track.id && isPlaying) {
      await pause();
    } else {
      await play(track);
    }
  }
  
  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }
}
