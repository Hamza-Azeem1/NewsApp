import 'package:flutter/material.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../models/news_video.dart';

class YoutubePlayerScreen extends StatefulWidget {
  final NewsVideo video;

  const YoutubePlayerScreen({super.key, required this.video});

  @override
  State<YoutubePlayerScreen> createState() => _YoutubePlayerScreenState();
}

class _YoutubePlayerScreenState extends State<YoutubePlayerScreen> {
  late YoutubePlayerController _controller;
  String? _videoId;

  @override
  void initState() {
    super.initState();
    _videoId = _extractVideoId(widget.video.videoUrl);

    if (_videoId != null) {
      _controller = YoutubePlayerController.fromVideoId(
        videoId: _videoId!,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          mute: false,
          playsInline: true,
        ),
      );
    }
  }

  @override
  void dispose() {
    if (_videoId != null) {
      _controller.close();
    }
    super.dispose();
  }

  String? _extractVideoId(String url) {
    final lower = url.toLowerCase();

    if (!lower.contains('youtube.com') && !lower.contains('youtu.be')) {
      return null;
    }

    // youtu.be/<id>
    final shortMatch = RegExp(r'youtu\.be/([^?&/]+)').firstMatch(url);
    if (shortMatch != null) {
      return shortMatch.group(1);
    }

    // youtube.com/watch?v=<id>
    final longMatch = RegExp(r'v=([^?&/]+)').firstMatch(url);
    if (longMatch != null) {
      return longMatch.group(1);
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (_videoId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.video.title)),
        body: const Center(child: Text('Invalid YouTube URL')),
      );
    }

    return YoutubePlayerScaffold(
      controller: _controller,
      builder: (context, player) {
        return Scaffold(
          appBar: AppBar(title: Text(widget.video.title)),
          body: Column(
            children: [
              AspectRatio(aspectRatio: 16 / 9, child: player),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    widget.video.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}