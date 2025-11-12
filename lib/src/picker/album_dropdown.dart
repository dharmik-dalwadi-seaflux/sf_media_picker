import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class AlbumDropdown extends StatelessWidget {
  const AlbumDropdown({
    super.key,
    required this.albums,
    required this.activeAlbum,
    required this.onChanged,
  });

  final List<AssetPathEntity> albums;
  final AssetPathEntity? activeAlbum;
  final ValueChanged<AssetPathEntity?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (albums.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<AssetPathEntity>(
          value: activeAlbum,
          dropdownColor: Colors.grey.shade900,
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white,
          isExpanded: true,
          onChanged: onChanged,
          items: albums
              .map(
                (AssetPathEntity album) => DropdownMenuItem<AssetPathEntity>(
                  value: album,
                  child: Text(
                    album.name,
                    style: const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
