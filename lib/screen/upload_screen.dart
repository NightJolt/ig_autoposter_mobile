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

  void _findReel() async {
    String videoUrl =
        await getVideoUrl("https://www.instagram.com/p/C7yTbG5MnwY");
    String localVideoPath = await downloadVideo(videoUrl);
    String convertedVideoPath = await convertVideo(localVideoPath);
    String uploadedUrl = await uploadLocalVideo(convertedVideoPath);
    await uploadReel(uploadedUrl);

    print(uploadedUrl);

    _videoController = VideoPlayerController.file(File(convertedVideoPath));
    await _videoController!.initialize();

    setState(() {});

    _videoController!.play();
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
