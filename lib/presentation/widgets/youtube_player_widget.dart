// lib/presentation/widgets/youtube_player_widget.dart

import 'package:flutter/material.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class YouTubePlayerWidget extends StatefulWidget {
  final String videoId;
  final bool autoPlay;
  final VoidCallback? onEnded;
  final ValueChanged<Duration>? onDurationLoaded;

  const YouTubePlayerWidget({
    super.key,
    required this.videoId,
    this.autoPlay = false,
    this.onEnded,
    this.onDurationLoaded,
  });

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget> {
  late final YoutubePlayerController _controller;
  late final bool _isValidId;
  bool _durationEmitted = false;

  @override
  void initState() {
    super.initState();
    _isValidId = RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(widget.videoId);
    if (!_isValidId) return;

    _controller = YoutubePlayerController(
      initialVideoId: widget.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: widget.autoPlay,
        mute: false,
        enableCaption: true,
        hideControls: false,
        controlsVisibleAtStart: true,
      ),
    );

    _controller.addListener(_handlePlayerState);
  }

  void _handlePlayerState() {
    if (!_durationEmitted && _controller.metadata.duration > Duration.zero) {
      _durationEmitted = true;
      widget.onDurationLoaded?.call(_controller.metadata.duration);
    }
    if (_controller.value.playerState == PlayerState.ended) {
      widget.onEnded?.call();
    }
  }

  @override
  void didUpdateWidget(covariant YouTubePlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoId != widget.videoId) {
      _durationEmitted = false;
      _isValidId = RegExp(r'^[A-Za-z0-9_-]{11}$').hasMatch(widget.videoId);
      if (_isValidId) {
        _controller.load(widget.videoId);
      }
    }
  }

  @override
  void dispose() {
    if (_isValidId) {
      _controller.removeListener(_handlePlayerState);
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isValidId) {
      return const AspectRatio(
        aspectRatio: 16 / 9,
        child: Center(child: Text('Video de YouTube no válido.')),
      );
    }

    return YoutubePlayerBuilder(
      player: YoutubePlayer(
        controller: _controller,
        showVideoProgressIndicator: true,
        progressIndicatorColor: Theme.of(context).colorScheme.primary,
      ),
      builder:
          (context, player) => AspectRatio(aspectRatio: 16 / 9, child: player),
    );
  }
}
