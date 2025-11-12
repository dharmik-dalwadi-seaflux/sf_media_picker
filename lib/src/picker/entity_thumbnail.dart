import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'constants.dart';

class EntityThumbnail extends StatelessWidget {
  const EntityThumbnail({super.key, required this.entity});

  final AssetEntity entity;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: entity.thumbnailDataWithSize(kThumbnailSize),
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        if (!snapshot.hasData) {
          return const ColoredBox(color: Colors.black12);
        }
        return Image.memory(snapshot.data!, fit: BoxFit.cover);
      },
    );
  }
}
