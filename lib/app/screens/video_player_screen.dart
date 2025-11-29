import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../models/news_video.dart';

class VideoPlayerScreen extends StatefulWidget {
  final NewsVideo video;

  const VideoPlayerScreen({super.key, required this.video});

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late VideoPlayerController _controller;
  bool _initialized = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.video.videoUrl),
    )
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _initialized = true;
        });
        _controller.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() {
          _hasError = true;
        });
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    if (!_initialized) return;
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
      } else {
        _controller.play();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_hasError) {
      body = const Center(
        child: Text('Could not load video'),
      );
    } else if (!_initialized) {
      body = const Center(
        child: CircularProgressIndicator(),
      );
    } else {
      body = Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: VideoPlayer(_controller),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.video.title),
      ),
      body: body,
      floatingActionButton: _initialized && !_hasError
          ? FloatingActionButton(
              onPressed: _togglePlay,
              child: Icon(
                _controller.value.isPlaying
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
              ),
            )
          : null,
    );
  }
}
