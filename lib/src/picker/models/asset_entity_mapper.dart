import 'package:photo_manager/photo_manager.dart';

import 'sf_media_asset.dart';

SfMediaAssetType _toSfMediaAssetType(AssetType type) {
  switch (type) {
    case AssetType.image:
      return SfMediaAssetType.image;
    case AssetType.video:
      return SfMediaAssetType.video;
    case AssetType.audio:
      return SfMediaAssetType.audio;
    case AssetType.other:
      return SfMediaAssetType.other;
  }
}

extension AssetEntityMapper on AssetEntity {
  SfMediaAsset toSfMediaAsset() {
    return SfMediaAsset(
      id: id,
      type: _toSfMediaAssetType(type),
      width: width,
      height: height,
      duration: type == AssetType.video ? videoDuration : Duration.zero,
      title: title,
      createDateTime: createDateTime,
      modifiedDateTime: modifiedDateTime,
    );
  }
}

Future<AssetEntity?> resolveAssetEntity(SfMediaAsset asset) {
  return AssetEntity.fromId(asset.id);
}
