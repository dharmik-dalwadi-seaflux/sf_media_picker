import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:sf_media_picker/sf_media_picker.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(useMaterial3: false),
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  AssetEntity? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Media Picker Demo'),
        actions: <Widget>[
          if (_selected != null)
            TextButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Selected: ${_selected!.type.name} • ${_selected!.title ?? ''}',
                    ),
                  ),
                );
              },
              child: const Text(
                'Done',
                style: TextStyle(
                  color: Color(0xFFFFC107),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
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
