import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

typedef AssetSelectionCallback = ValueChanged<AssetEntity>;

const double kDefaultPreviewHeightFactor = 0.35;
const int kDefaultCrossAxisCount = 4;
const double kScrollLoadThreshold = 300;
const int kPageSize = 80;
const Color kSelectionBorderColor = Color(0xFFFFC107);
const ThumbnailSize kThumbnailSize = ThumbnailSize(300, 300);
