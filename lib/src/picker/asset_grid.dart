import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import 'constants.dart';
import 'entity_thumbnail.dart';

class AssetGrid extends StatelessWidget {
  const AssetGrid({
    super.key,
    required this.assets,
    required this.scrollController,
    required this.onAssetTap,
    required this.onScrollNearEnd,
    required this.isLoading,
    required this.selectedAssetId,
    required this.formatDuration,
    required this.crossAxisCount,
  });

  final List<AssetEntity> assets;
  final ScrollController scrollController;
  final ValueChanged<AssetEntity> onAssetTap;
  final VoidCallback onScrollNearEnd;
  final bool isLoading;
  final String? selectedAssetId;
  final String Function(Duration) formatDuration;
  final int crossAxisCount;

  @override
  Widget build(BuildContext context) {
    if (assets.isEmpty && isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    return NotificationListener<ScrollNotification>(
      onNotification: (ScrollNotification notification) {
        if (notification.metrics.pixels >=
            notification.metrics.maxScrollExtent - kScrollLoadThreshold) {
          onScrollNearEnd();
        }
        return false;
      },
      child: GridView.builder(
        controller: scrollController,
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
          childAspectRatio: 1,
        ),
        itemCount: assets.length,
        itemBuilder: (BuildContext context, int index) {
          final AssetEntity entity = assets[index];
          return GestureDetector(
            key: ValueKey<String>('grid_${entity.id}'),
            onTap: () => onAssetTap(entity),
            child: Stack(
              fit: StackFit.expand,
              children: <Widget>[
                EntityThumbnail(
                  key: ValueKey<String>('thumb_${entity.id}'),
                  entity: entity,
                ),
                if (entity.type == AssetType.video)
                  Positioned(
                    right: 4,
                    bottom: 4,
                    child: Row(
                      children: <Widget>[
                        const Icon(
                          Icons.videocam,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          formatDuration(entity.videoDuration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            shadows: <Shadow>[
                              Shadow(color: Colors.black54, blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                if (selectedAssetId == entity.id)
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: kSelectionBorderColor,
                        width: 2,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
