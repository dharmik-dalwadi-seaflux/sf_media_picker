# SF Media Picker

A polished, Instagram-inspired media picker for Flutter. Let your users browse albums, preview photos or looping videos, and choose the perfect asset without leaving your custom UI. Built entirely in Dart with zero platform code.

## Features

- 🎨 Modern, high-contrast UI that feels right at home on iOS and Android
- 📸 Unified picker for photos and videos with looping autoplay preview
- 📁 Album switching with instant refresh when the device library changes
- ♾️ Infinite scrolling grid with lazy paging
- 🔌 Reusable widget – no Scaffold/AppBar so you own the surrounding UI
- 🧩 Configurable preview height and grid density
- ⚡ Pure Dart UI that works alongside existing `photo_manager`/`video_player` setups

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  sf_media_picker: ^0.1.0
```

Or install from a local path:

```yaml
dependencies:
  sf_media_picker:
    path: ../path/to/sf_media_picker
```

Then run:

```bash
flutter pub get
```

## Platform Setup

Since this package depends on `photo_manager` and `video_player`, you'll need to configure permissions in your app (not in this package). Follow the platform setup instructions for those plugins:

### iOS

Add the following to your app's `ios/Runner/Info.plist`:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to your photo library to select images and videos.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>This app needs access to save photos to your library.</string>
```

### Android

Add the following permissions to your app's `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
```

For Android 13+ (API level 33+), you may also need:

```xml
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
```

> **Note**: This package itself doesn't require any native configuration. All platform-specific setup is handled by the underlying `photo_manager` and `video_player` plugins that your app depends on.

## Usage

### Basic Example

The `SFMediaPicker` is a reusable widget that can be embedded anywhere in your app. It doesn't include a Scaffold or AppBar, giving you full control over the UI layout.

```dart
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sf_media_picker/sf_media_picker.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _MediaPickerScreen(),
    );
  }
}

class _MediaPickerScreen extends StatefulWidget {
  @override
  State<_MediaPickerScreen> createState() => _MediaPickerScreenState();
}

class _MediaPickerScreenState extends State<_MediaPickerScreen> {
  AssetEntity? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Select Media'),
        actions: <Widget>[
          if (_selected != null)
            TextButton(
              onPressed: () {
                // Handle selected media
                print('Selected: ${_selected!.id}');
              },
              child: const Text(
                'Done',
                style: TextStyle(color: Colors.amber),
              ),
            ),
        ],
      ),
      body: SFMediaPicker(
        selectedAsset: _selected,
        onAssetSelected: (AssetEntity asset) {
          setState(() {
            _selected = asset;
          });
        },
      ),
    );
  }
}
```

### Widget Properties

| Property | Type | Default | Description |
| --- | --- | --- | --- |
| `selectedAsset` | `AssetEntity?` | `null` | Asset to highlight when the picker loads. |
| `onAssetSelected` | `ValueChanged<AssetEntity>?` | `null` | Callback fired whenever the selection changes. |
| `previewHeightFactor` | `double` | `0.35` | Portion of available height dedicated to the preview. Must be between `0` and `1`. |
| `gridCrossAxisCount` | `int` | `4` | Number of columns in the asset grid. |

### Customisation

Tweak layout density or the preview size to better match your design language:

```dart
SFMediaPicker(
  previewHeightFactor: 0.45,
  gridCrossAxisCount: 3,
  onAssetSelected: (asset) => debugPrint('Selected: ${asset.id}'),
)
```

### Working with Selected Media

```dart
// Get the file
File? file = await assetEntity.file;

// Get image bytes
Uint8List? imageBytes = await assetEntity.originBytes;

// Get thumbnail
Uint8List? thumbnail = await assetEntity.thumbnailDataWithSize(
  const ThumbnailSize(300, 300),
);

// Check media type
if (assetEntity.type == AssetType.image) {
  // Handle image
} else if (assetEntity.type == AssetType.video) {
  // Handle video
}
```

## Example

Check out the [example](example) directory for a complete working example.

## Dependencies

This package depends on:
- [photo_manager](https://pub.dev/packages/photo_manager) - For accessing device media
- [video_player](https://pub.dev/packages/video_player) - For video playback

## Package Structure

This is a pure Dart/Flutter package with no native code. It's lightweight and only contains:
- `lib/sf_media_picker.dart` - Single entry-point export
- `lib/src/` - Widget implementation and private helpers
- `example/` - Example app demonstrating usage

No platform-specific folders (Android, iOS, macOS, Web, Windows, Linux) are included in the package itself, making it lightweight and easy to integrate.

The `SFMediaPicker` widget is a reusable component that can be embedded anywhere in your app. It doesn't include a Scaffold or AppBar, giving you complete control over the UI layout, navigation, and styling.

## License

Released under the MIT License. See [LICENSE](LICENSE) for details.

## Contributing

Issues and pull requests are welcome! Please file bugs or feature requests via the [issue tracker](https://github.com/yourusername/sf_media_picker/issues).
