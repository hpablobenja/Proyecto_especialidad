// lib/presentation/widgets/local_video_player_widget.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class LocalVideoPlayerWidget extends StatefulWidget {
  final String filePath;
  final Duration initialPosition;
  final Function(Duration) onPositionChanged;
  final Function(bool) onPlayingChanged;
  final VoidCallback onEnded;

  const LocalVideoPlayerWidget({
    super.key,
    required this.filePath,
    required this.initialPosition,
    required this.onPositionChanged,
    required this.onPlayingChanged,
    required this.onEnded,
  });

  @override
  State<LocalVideoPlayerWidget> createState() => _LocalVideoPlayerWidgetState();
}

class _LocalVideoPlayerWidgetState extends State<LocalVideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isReady = false;
  bool _wasPlaying = false;
  Duration _lastPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _controller = VideoPlayerController.file(File(widget.filePath));
    try {
      await _controller.initialize();
      if (!mounted) return;

      if (widget.initialPosition > Duration.zero) {
        await _controller.seekTo(widget.initialPosition);
      }

      _controller.addListener(_onVideoControllerUpdate);
      setState(() {
        _isReady = true;
      });
      _controller.play();
    } catch (e) {
      debugPrint('Error initializing local video player: $e');
    }
  }

  void _onVideoControllerUpdate() {
    if (!_isReady || !mounted) return;

    final isPlaying = _controller.value.isPlaying;
    if (isPlaying != _wasPlaying) {
      _wasPlaying = isPlaying;
      widget.onPlayingChanged(isPlaying);
    }

    final pos = _controller.value.position;
    if ((pos - _lastPosition).abs() >= const Duration(milliseconds: 500)) {
      _lastPosition = pos;
      widget.onPositionChanged(pos);
    }

    final duration = _controller.value.duration;
    if (duration > Duration.zero && pos >= duration) {
      widget.onEnded();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoControllerUpdate);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return AspectRatio(
      aspectRatio:
          _controller.value.aspectRatio > 0
              ? _controller.value.aspectRatio
              : 16 / 9,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          VideoPlayer(_controller),
          _ControlsOverlay(controller: _controller),
          VideoProgressIndicator(
            _controller,
            allowScrubbing: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            colors: VideoProgressColors(
              playedColor: Theme.of(context).colorScheme.primary,
              bufferedColor: Colors.white24,
              backgroundColor: Colors.black26,
            ),
          ),
        ],
      ),
    );
  }
}

class _ControlsOverlay extends StatelessWidget {
  final VideoPlayerController controller;

  const _ControlsOverlay({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      reverseDuration: const Duration(milliseconds: 200),
      child:
          controller.value.isPlaying
              ? const SizedBox.shrink()
              : Container(
                color: Colors.black26,
                child: const Center(
                  child: Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 64.0,
                    semanticLabel: 'Play',
                  ),
                ),
              ),
    );
  }
}
