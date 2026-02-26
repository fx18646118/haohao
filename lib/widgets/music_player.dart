import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/music_models.dart';
import '../services/music_player_service.dart';
import '../utils/theme.dart';

// 迷你播放器组件
class MiniPlayer extends StatelessWidget {
  final MusicPlayerService playerService;
  final VoidCallback? onExpand;

  const MiniPlayer({
    super.key,
    required this.playerService,
    this.onExpand,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: playerService,
      builder: (context, child) {
        final track = playerService.currentTrack;
        if (track == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: onExpand,
          child: Container(
            height: 64,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                // 封面
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    image: track.coverUrl != null
                        ? DecorationImage(
                            image: NetworkImage(track.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: track.coverUrl == null
                      ? const Icon(Icons.music_note, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                // 歌曲信息
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artist ?? 'AI生成',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // 播放控制
                IconButton(
                  icon: Icon(
                    playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                  ),
                  onPressed: () => playerService.togglePlay(track),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next, color: Colors.white),
                  onPressed: () {
                    // 下一首
                  },
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// 完整播放器组件
class FullPlayer extends StatelessWidget {
  final MusicPlayerService playerService;
  final VoidCallback? onMinimize;

  const FullPlayer({
    super.key,
    required this.playerService,
    this.onMinimize,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: playerService,
      builder: (context, child) {
        final track = playerService.currentTrack;
        if (track == null) return const SizedBox.shrink();

        return Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.darkGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // 顶部栏
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down),
                        onPressed: onMinimize,
                      ),
                      const Expanded(
                        child: Text(
                          '正在播放',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.more_vert),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // 封面
                Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                    image: track.coverUrl != null
                        ? DecorationImage(
                            image: NetworkImage(track.coverUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    gradient: track.coverUrl == null ? AppTheme.primaryGradient : null,
                  ),
                  child: track.coverUrl == null
                      ? const Icon(Icons.music_note, size: 80, color: Colors.white)
                      : null,
                ),
                const Spacer(),
                // 歌曲信息
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Text(
                        track.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        track.artist ?? 'AI生成',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // 进度条
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      Slider(
                        value: playerService.progress.clamp(0.0, 1.0),
                        onChanged: (value) {
                          final position = Duration(
                            milliseconds: (value * playerService.duration.inMilliseconds).toInt(),
                          );
                          playerService.seekTo(position);
                        },
                        activeColor: AppTheme.primaryColor,
                        inactiveColor: Colors.grey.shade800,
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(playerService.position),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                          Text(
                            track.durationText,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // 播放控制
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(
                        playerService.isLooping ? Icons.repeat_one : Icons.repeat,
                        color: playerService.isLooping ? AppTheme.primaryColor : null,
                      ),
                      onPressed: playerService.toggleLoop,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.skip_previous, size: 40),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () => playerService.togglePlay(track),
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: const BoxDecoration(
                          gradient: AppTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          playerService.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.skip_next, size: 40),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.playlist_add),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}

// 音乐卡片组件
class MusicCard extends StatelessWidget {
  final MusicTrack track;
  final bool isPlaying;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onMore;

  const MusicCard({
    super.key,
    required this.track,
    this.isPlaying = false,
    this.onTap,
    this.onPlay,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 封面
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6C5DD3), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                      image: track.coverUrl != null
                          ? DecorationImage(
                              image: NetworkImage(track.coverUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: track.coverUrl == null
                        ? Center(
                            child: Icon(
                              Icons.music_note,
                              size: 48,
                              color: Colors.white.withOpacity(0.5),
                            ),
                          )
                        : null,
                  ),
                  // 播放按钮
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(16),
                        ),
                        onTap: onPlay,
                        child: Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // 时长标签
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        track.durationText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 信息
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      track.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      track.style ?? 'AI生成',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
