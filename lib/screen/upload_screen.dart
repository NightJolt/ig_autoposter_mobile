import 'dart:io';

import 'package:autoposter_mobile/service.dart';
import 'package:flutter/material.dart';

import 'package:video_player/video_player.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final TextEditingController _textController = TextEditingController();
  VideoPlayerController? _videoController;
  String statusText = '';
  Color statusColor = Colors.black;

  void _updateStatusColor(bool success) {
    setState(() {
      statusColor = success ? Colors.green.shade900 : Colors.red.shade900;
    });
  }

  void _updateStatusText(String text) {
    setState(() {
      statusText = text;
    });
  }

  void _findReel() async {
    _updateStatusColor(true);

    setState(() {
      _updateStatusText('Finding reel...');
    });
    String videoUrl = await getVideoUrl(_textController.text);

    if (videoUrl.isEmpty) {
      _updateStatusColor(false);
      return;
    }
    setState(() {
      _updateStatusText('Downloading video...');
    });
    String localVideoPath = await downloadVideo(videoUrl);

    if (localVideoPath.isEmpty) {
      _updateStatusColor(false);
      return;
    }
    setState(() {
      _updateStatusText('Converting video...');
    });
    String convertedVideoPath = await convertVideo(localVideoPath);

    if (convertedVideoPath.isEmpty) {
      _updateStatusColor(false);
      return;
    }

    _videoController = VideoPlayerController.file(File(convertedVideoPath));
    await _videoController!.initialize();

    setState(() {});

    _videoController!.setLooping(true);
    _videoController!.play();

    setState(() {
      _updateStatusText('Uploading video...');
    });
    String uploadedUrl = await uploadLocalVideo(convertedVideoPath);

    if (uploadedUrl.isEmpty) {
      _updateStatusColor(false);
      return;
    }
    setState(() {
      _updateStatusText('Publishing reel...');
    });
    bool success = await uploadReel(uploadedUrl);

    if (success) {
      setState(() {
        _updateStatusText('Reel published!');
      });

      _textController.clear();
    } else {
      _updateStatusColor(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Screen'),
      ),
      body: Column(
        children: [
          TextField(
            controller: _textController,
          ),
          TextButton(
            onPressed: _findReel,
            child: const Text('Upload'),
          ),
          const SizedBox(height: 16.0),
          Text(
            statusText,
            style: TextStyle(color: statusColor),
          ),
          const SizedBox(height: 16.0),
          _videoController != null && _videoController!.value.isInitialized
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64.0),
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                )
              : Container(),
        ],
      ),
    );
  }
}
