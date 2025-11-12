import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class SelectedPreview extends StatelessWidget {
  const SelectedPreview({
    super.key,
    required this.height,
    required this.selected,
    required this.imageFile,
    required this.isImageLoading,
    required this.aspectRatio,
    required this.videoController,
    required this.isVideoPlaying,
    required this.onToggleVideo,
  });

  final double height;
  final AssetEntity? selected;
  final File? imageFile;
  final bool isImageLoading;
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
          child: Icon(Icons.photo, color: Colors.white54, size: 48),
        ),
      );
    }

    final AssetEntity entity = selected!;
    final bool isVideo = entity.type == AssetType.video;
    return SizedBox(
      height: height,
      width: double.infinity,
      child: Center(
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeInOut,
            transitionBuilder: (Widget child, Animation<double> animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Stack(
              key: ValueKey<String>(
                'preview_${entity.id}_${isVideo ? 'video' : 'image'}',
              ),
              fit: StackFit.expand,
              children: <Widget>[
                if (isVideo && videoController != null)
                  _VideoPreview(controller: videoController!)
                else
                  _ImagePreview(entity: entity, file: imageFile),
                if (!isVideo && isImageLoading)
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: Colors.black26),
                    ),
                  ),
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
  const _ImagePreview({required this.entity, required this.file});

  final AssetEntity entity;
  final File? file;

  @override
  Widget build(BuildContext context) {
    if (file != null && file!.existsSync()) {
      return Image.file(file!, fit: BoxFit.contain, gaplessPlayback: true);
    }

    return FutureBuilder<Uint8List?>(
      future: entity.thumbnailDataWithSize(const ThumbnailSize(600, 600)),
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (!snapshot.hasData) {
          return const ColoredBox(color: Colors.black26);
        }
        final Uint8List bytes = snapshot.data!;
        return Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true);
      },
    );
  }
}
