import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../domain/entities/checkpoint_entity.dart';
import '../../core/services/video_download_service.dart';
import '../../data/models/downloaded_video_hive.dart';
import '../providers/video_tracking_provider.dart';
import 'checkpoint_dialog.dart';
import 'local_video_player_widget.dart';

/// Widget que envuelve el reproductor de video y maneja el tracking
class VideoTrackingWidget extends ConsumerStatefulWidget {
  final String videoId;
  final String userId;
  final String courseId;
  final String moduleId;
  final String lessonId;
  final List<CheckpointEntity> checkpoints;
  final int totalDurationMs;
  final VoidCallback? onLessonCompleted;
  final Function(Duration)? onPositionChanged;

  const VideoTrackingWidget({
    super.key,
    required this.videoId,
    required this.userId,
    required this.courseId,
    required this.moduleId,
    required this.lessonId,
    this.checkpoints = const [],
    this.totalDurationMs = 0,
    this.onLessonCompleted,
    this.onPositionChanged,
  });

  @override
  ConsumerState<VideoTrackingWidget> createState() =>
      _VideoTrackingWidgetState();
}

class _VideoTrackingWidgetState extends ConsumerState<VideoTrackingWidget> {
  YoutubePlayerController? _controller;
  DownloadedVideoHive? _downloadedVideo;
  bool _isOfflineVideo = false;
  bool _isInitialized = false;
  bool _isPlayerReady = false;
  CheckpointEntity? _pendingCheckpoint;
  bool _disposed = false;
  Duration? _pendingSeekPosition;

  @override
  void initState() {
    super.initState();
    _checkVideoSource();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeTracking();
    });
  }

  void _checkVideoSource() {
    final downloaded = VideoDownloadService().getDownloadedVideo(
      widget.videoId,
    );
    if (downloaded != null && downloaded.isCompleted) {
      _downloadedVideo = downloaded;
      _isOfflineVideo = true;
    } else {
      _isOfflineVideo = false;
      _initializePlayer();
    }
  }

  void _initializePlayer() {
    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: false,
        mute: false,
        enableCaption: true,
        hideControls: false,
        controlsVisibleAtStart: true,
      ),
    );

    _controller!.addListener(_handlePlayerState);
  }

  Future<void> _initializeTracking() async {
    if (_disposed) return;

    final trackingNotifier = ref.read(videoTrackingProvider.notifier);

    await trackingNotifier.initializeLesson(
      userId: widget.userId,
      courseId: widget.courseId,
      moduleId: widget.moduleId,
      lessonId: widget.lessonId,
      checkpoints: widget.checkpoints,
      totalDurationMs: widget.totalDurationMs,
    );

    if (_disposed) return;

    // Guardar posición de reanudación para hacer seek cuando el reproductor esté listo
    final state = ref.read(videoTrackingProvider);
    if (state.resumePosition > Duration.zero) {
      _pendingSeekPosition = state.resumePosition;
    }

    if (!mounted) return;

    setState(() {
      _isInitialized = true;
    });
  }

  void _handlePlayerState() {
    if (!_isInitialized || _disposed || _controller == null) return;

    final position = _controller!.value.position;
    final playerState = _controller!.value.playerState;

    // Detectar cuando el reproductor está listo
    if (!_isPlayerReady && _controller!.value.isReady) {
      _isPlayerReady = true;

      // Hacer seek pendiente si existe
      if (_pendingSeekPosition != null &&
          _pendingSeekPosition! > Duration.zero) {
        final seekPos = _pendingSeekPosition!;
        _controller!.seekTo(seekPos);
        _pendingSeekPosition = null;
        debugPrint('Seeked to resume position: ${seekPos.inSeconds}s');
      }
    }

    // Notificar cambio de posición
    _handlePositionUpdate(position);

    // Actualizar estado de reproducción
    final isPlaying = playerState == PlayerState.playing;
    _handlePlayingUpdate(isPlaying);

    // Detectar final del video
    if (playerState == PlayerState.ended) {
      widget.onLessonCompleted?.call();
    }
  }

  void _handlePositionUpdate(Duration position) {
    if (_disposed) return;

    ref.read(videoTrackingProvider.notifier).onPositionChange(position);
    widget.onPositionChanged?.call(position);

    // Actualizar progreso persistente local si es video offline
    if (_isOfflineVideo && _downloadedVideo != null) {
      VideoDownloadService().updateWatchedProgress(
        videoId: widget.videoId,
        watchedSeconds: position.inSeconds,
        totalSeconds: widget.totalDurationMs ~/ 1000,
        pendingSync: true,
      );
    }

    // Detectar checkpoint
    final trackingState = ref.read(videoTrackingProvider);
    if (trackingState.currentTracking != null) {
      final currentSeconds = position.inSeconds;

      for (final checkpoint in widget.checkpoints) {
        final passedCheckpoints =
            trackingState.currentTracking!.checkpointsPassed;
        if (!passedCheckpoints.contains(checkpoint.id) &&
            currentSeconds >= checkpoint.triggerPositionSeconds &&
            _pendingCheckpoint == null) {
          _pendingCheckpoint = checkpoint;
          _controller?.pause();
          _showCheckpointDialog(checkpoint);
          break;
        }
      }
    }
  }

  void _handlePlayingUpdate(bool isPlaying) {
    if (_disposed) return;
    ref.read(videoTrackingProvider.notifier).setPlaying(isPlaying);
  }

  void _showCheckpointDialog(CheckpointEntity checkpoint) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => CheckpointDialog(
            checkpoint: checkpoint,
            onAnswerSelected: (selectedIndex) async {
              final result = await ref
                  .read(videoTrackingProvider.notifier)
                  .validateCheckpoint(
                    checkpointId: checkpoint.id,
                    selectedOptionIndex: selectedIndex,
                  );

              if (!mounted) return;
              if (result.isCorrect) {
                setState(() {
                  _pendingCheckpoint = null;
                });
                Navigator.of(context).pop();
                _controller?.play();
              } else {
                // Incorrecto: mantener el diálogo abierto
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
    );
  }

  @override
  void dispose() {
    _disposed = true;
    if (_controller != null) {
      _controller!.removeListener(_handlePlayerState);
      _controller!.dispose();
    }
    try {
      ref.read(videoTrackingProvider.notifier).dispose();
    } catch (e) {
      // Ignorar error si el provider ya fue eliminado
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isOfflineVideo && _downloadedVideo != null) {
      return LocalVideoPlayerWidget(
        filePath: _downloadedVideo!.localPath,
        initialPosition: _pendingSeekPosition ?? Duration.zero,
        onPositionChanged: _handlePositionUpdate,
        onPlayingChanged: _handlePlayingUpdate,
        onEnded: () {
          widget.onLessonCompleted?.call();
        },
      );
    }

    if (_controller == null) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: Text('Error cargando reproductor')),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller!,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Theme.of(context).colorScheme.primary,
      ),
      builder: (context, player) {
        return AspectRatio(aspectRatio: 16 / 9, child: player);
      },
    );
  }
}
