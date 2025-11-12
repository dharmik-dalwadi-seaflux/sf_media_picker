import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'constants.dart';

class EntityThumbnail extends StatefulWidget {
  const EntityThumbnail({super.key, required this.entity});

  final AssetEntity entity;

  @override
  State<EntityThumbnail> createState() => _EntityThumbnailState();
}

class _EntityThumbnailState extends State<EntityThumbnail> {
  late Future<Uint8List?> _thumbnailFuture;

  @override
  void initState() {
    super.initState();
    _thumbnailFuture = widget.entity.thumbnailDataWithSize(kThumbnailSize);
  }

  @override
  void didUpdateWidget(covariant EntityThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.entity.id != oldWidget.entity.id) {
      _thumbnailFuture = widget.entity.thumbnailDataWithSize(kThumbnailSize);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: _thumbnailFuture,
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (!snapshot.hasData) {
          return const ColoredBox(color: Colors.black12);
        }
        return Image.memory(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}
