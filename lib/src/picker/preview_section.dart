import 'dart:io';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class SelectedPreview extends StatelessWidget {
  const SelectedPreview({
    super.key,
    required this.height,
    required this.selected,
    required this.aspectRatio,
    required this.videoController,
    required this.isVideoPlaying,
    required this.onToggleVideo,
  });

  final double height;
  final AssetEntity? selected;
  final double aspectRatio;
  final VideoPlayerController? videoController;
  final bool isVideoPlaying;
  final Future<void> Function() onToggleVideo;

  @override
  Widget build(BuildContext context) {
    if (selected == null) {
      return SizedBox(
        height: height,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    final bool isVideo = selected!.type == AssetType.video;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (isVideo && videoController != null)
                _VideoPreview(controller: videoController!)
              else
                _ImagePreview(entity: selected!),
              if (isVideo)
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      IconButton(
                        icon: Icon(
                          isVideoPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle,
                          color: Colors.white,
                          size: 36,
                        ),
                        onPressed: onToggleVideo,
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.videocam, color: Colors.white),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VideoPreview extends StatelessWidget {
  const _VideoPreview({required this.controller});

  final VideoPlayerController controller;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return VideoPlayer(controller);
  }
}

class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.entity});

  final AssetEntity entity;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<File?>(
      future: entity.file,
      builder: (BuildContext context, AsyncSnapshot<File?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        final File? file = snapshot.data;
        if (file == null || !file.existsSync()) {
          return const Center(
            child: Icon(
              Icons.image_not_supported,
              color: Colors.white54,
              size: 48,
            ),
          );
        }
        return Image.file(file, fit: BoxFit.contain, gaplessPlayback: true);
      },
    );
  }
}
