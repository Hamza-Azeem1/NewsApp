import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';

import '../models/news_video.dart';
import '../screens/video_player_screen.dart';
import '../screens/youtube_player_screen.dart';

class VideoCard extends StatefulWidget {
  final NewsVideo video;

  const VideoCard({super.key, required this.video});

  @override
  State<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends State<VideoCard> {
  YoutubePlayerController? _ytController;
  VideoPlayerController? _videoController;

  bool _isInlinePlaying = false;
  bool _isYoutube = false;
  bool _isRawVideo = false;
  bool _videoInitialized = false;

  @override
  void initState() {
    super.initState();
    final url = widget.video.videoUrl;
    _isYoutube = _isYoutubeUrl(url);
    _isRawVideo = _isRawVideoUrl(url);
  }

  @override
  void dispose() {
    _ytController?.close();
    _videoController?.dispose();
    super.dispose();
  }

  bool _isYoutubeUrl(String url) {
    final u = url.toLowerCase();
    return u.contains('youtube.com') || u.contains('youtu.be');
  }

  bool _isRawVideoUrl(String url) {
    final u = url.toLowerCase();
    return u.endsWith('.mp4') ||
        u.endsWith('.mov') ||
        u.endsWith('.m4v') ||
        u.endsWith('.webm') ||
        u.endsWith('.m3u8');
  }

  String? _extractYoutubeId(String url) {
    final lower = url.toLowerCase();
    if (!lower.contains('youtube.com') && !lower.contains('youtu.be')) {
      return null;
    }
    final shortMatch = RegExp(r'youtu\.be/([^?&/]+)').firstMatch(url);
    if (shortMatch != null) return shortMatch.group(1);
    final longMatch = RegExp(r'v=([^?&/]+)').firstMatch(url);
    if (longMatch != null) return longMatch.group(1);
    return null;
  }

  String _formatDuration(Duration d) {
    two(int n) => n.toString().padLeft(2, '0');
    final m = d.inMinutes.remainder(60);
    final s = d.inSeconds.remainder(60);
    final h = d.inHours;
    if (h > 0) {
      return '${two(h)}:${two(m)}:${two(s)}';
    }
    return '${two(m)}:${two(s)}';
  }

  Future<void> _startInlinePlay() async {
    if (_isInlinePlaying) return;

    final url = widget.video.videoUrl;
    if (_isYoutube) {
      final id = _extractYoutubeId(url);
      if (id == null) {
        _showSnack('Invalid YouTube URL');
        return;
      }
      _ytController = YoutubePlayerController.fromVideoId(
        videoId: id,
        autoPlay: true,
        params: const YoutubePlayerParams(
          showFullscreenButton: true,
          showControls: true,
        ),
      );
      setState(() {
        _isInlinePlaying = true;
      });
    } else if (_isRawVideo) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url))
        ..initialize().then((_) {
          if (!mounted) return;
          _videoController!.addListener(() {
            if (!mounted) return;
            setState(() {});
          });
          setState(() {
            _videoInitialized = true;
            _isInlinePlaying = true;
          });
          _videoController!.play();
        }).catchError((_) {
          _showSnack('Could not load video');
        });
      setState(() {}); // to show loader
    } else {
      _showSnack('Unsupported video URL. Use YouTube or direct .mp4');
    }
  }

  void _toggleNativePlay() {
    if (!_videoInitialized || _videoController == null) return;
    setState(() {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    });
  }

  void _seekRelative(Duration offset) {
    if (!_videoInitialized || _videoController == null) return;
    final current = _videoController!.value.position;
    final target = current + offset;
    final total = _videoController!.value.duration;
    Duration clamped;
    if (target < Duration.zero) {
      clamped = Duration.zero;
    } else if (target > total) {
      clamped = total;
    } else {
      clamped = target;
    }
    _videoController!.seekTo(clamped);
  }

  void _openFullscreen() {
    if (_isYoutube) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => YoutubePlayerScreen(video: widget.video),
        ),
      );
    } else if (_isRawVideo) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => VideoPlayerScreen(video: widget.video),
        ),
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top: thumbnail or inline player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: _buildMediaArea(),
          ),

          // Bottom: text + actions
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First row: VIDEO label + fullscreen button
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'VIDEO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
                        ),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Full screen',
                      icon: const Icon(Icons.fullscreen_rounded, size: 20),
                      onPressed: _openFullscreen,
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // All categories as chips
                if (widget.video.categories.isNotEmpty)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: widget.video.categories.map((cat) {
                      return Chip(
                        label: Text(
                          cat,
                          style: const TextStyle(fontSize: 11),
                        ),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      );
                    }).toList(),
                  ),

                if (widget.video.categories.isNotEmpty) const SizedBox(height: 6),

                // Title
                Text(
                  widget.video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),

                // Description
                if (widget.video.description.isNotEmpty)
                  Text(
                    widget.video.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaArea() {
    // Inline YouTube
    if (_isInlinePlaying && _isYoutube && _ytController != null) {
      return YoutubePlayer(controller: _ytController!);
    }

    // Inline native video with controls
    if (_isInlinePlaying && _isRawVideo && _videoController != null) {
      if (!_videoInitialized) {
        return const Center(child: CircularProgressIndicator());
      }

      final v = _videoController!.value;
      final total = v.duration;
      final current = v.position;

      return Stack(
        children: [
          // Video
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: v.size.width,
                height: v.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),

          // Controls overlay
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding:
                  const EdgeInsets.only(left: 8, right: 8, top: 6, bottom: 6),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  VideoProgressIndicator(
                    _videoController!,
                    allowScrubbing: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        iconSize: 20,
                        onPressed: () =>
                            _seekRelative(const Duration(seconds: -10)),
                        icon: const Icon(
                          Icons.replay_10_rounded,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        iconSize: 26,
                        onPressed: _toggleNativePlay,
                        icon: Icon(
                          v.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                        ),
                      ),
                      IconButton(
                        iconSize: 20,
                        onPressed: () =>
                            _seekRelative(const Duration(seconds: 10)),
                        icon: const Icon(
                          Icons.forward_10_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_formatDuration(current)} / ${_formatDuration(total)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // Default: thumbnail with play overlay
    return GestureDetector(
      onTap: _startInlinePlay,
      child: Stack(
        children: [
          Positioned.fill(
            child: CachedNetworkImage(
              imageUrl: widget.video.thumbnailUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) =>
                  const Center(child: CircularProgressIndicator()),
              errorWidget: (context, url, error) =>
                  const ColoredBox(color: Colors.black26),
            ),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black54,
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xCC000000),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                size: 40,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
