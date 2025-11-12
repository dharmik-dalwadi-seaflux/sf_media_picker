import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

import 'album_dropdown.dart';
import 'asset_grid.dart';
import 'constants.dart';
import 'models/asset_entity_mapper.dart';
import 'models/sf_media_asset.dart';
import 'preview_section.dart';

/// Displays an Instagram-inspired media picker for images and videos.
///
/// The widget is UI-only (no Scaffold) so it can be embedded inside any layout.
/// Consumers receive the currently selected asset via [onAssetSelected].
class SFMediaPicker extends StatefulWidget {
  const SFMediaPicker({
    super.key,
    this.onAssetSelected,
    this.selectedAsset,
    this.previewHeightFactor = kDefaultPreviewHeightFactor,
    this.gridCrossAxisCount = kDefaultCrossAxisCount,
  }) : assert(
         previewHeightFactor > 0 && previewHeightFactor <= 1,
         'previewHeightFactor must be between 0 and 1',
       ),
       assert(gridCrossAxisCount > 0, 'gridCrossAxisCount must be positive');

  /// Callback fired when an asset is selected.
  final AssetSelectionCallback? onAssetSelected;

  /// Initially selected asset.
  final SfMediaAsset? selectedAsset;

  /// Fraction of screen height used by the preview area.
  final double previewHeightFactor;

  /// Number of columns in the media grid.
  final int gridCrossAxisCount;

  @override
  State<SFMediaPicker> createState() => _SFMediaPickerState();
}

class _SFMediaPickerState extends State<SFMediaPicker>
    with WidgetsBindingObserver {
  final List<AssetEntity> _assets = <AssetEntity>[];
  final ScrollController _scrollController = ScrollController();
  late FilterOptionGroup _filterOptions;
  Future<void>? _currentLoad;

  bool _isLoading = false;
  bool _hasMoreToLoad = true;
  int _currentPage = 0;

  List<AssetPathEntity> _albums = <AssetPathEntity>[];
  AssetPathEntity? _activeAlbum;
  AssetEntity? _selectedEntity;
  String? _pendingSelectedAssetId;
  SfMediaAsset? _initialSelectedAsset;
  VideoPlayerController? _videoController;
  bool _isVideoPlaying = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _filterOptions = _createBaseFilterOptions();
    _initialSelectedAsset = widget.selectedAsset;
    _pendingSelectedAssetId = widget.selectedAsset?.id;
    _requestAndLoad();
    PhotoManager.addChangeCallback(_onGalleryChanged);
    PhotoManager.startChangeNotify();
  }

  @override
  void didUpdateWidget(covariant SFMediaPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedAsset?.id != oldWidget.selectedAsset?.id) {
      _initialSelectedAsset = widget.selectedAsset;
      _pendingSelectedAssetId = widget.selectedAsset?.id;
      if (_pendingSelectedAssetId == null) {
        _selectedEntity = null;
      } else {
        _loadInitialSelectionIfPossible();
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PhotoManager.removeChangeCallback(_onGalleryChanged);
    PhotoManager.stopChangeNotify();
    _videoController?.removeListener(_onVideoControllerUpdated);
    _videoController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAll();
    }
  }

  FilterOptionGroup _createBaseFilterOptions() {
    return FilterOptionGroup()
      ..setOption(AssetType.image, const FilterOption(needTitle: true))
      ..setOption(AssetType.video, const FilterOption(needTitle: true))
      ..addOrderOption(
        const OrderOption(type: OrderOptionType.createDate, asc: false),
      );
  }

  Future<void> _requestAndLoad() async {
    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();
    if (!mounted) return;
    if (permission.isAuth) {
      await _loadInitialSelectionIfPossible();
      await _loadAlbums();
      await _loadNextPage(reset: true);
    } else {
      await PhotoManager.openSetting();
    }
  }

  Future<void> _loadInitialSelectionIfPossible() async {
    final SfMediaAsset? asset = _initialSelectedAsset;
    final String? assetId = _pendingSelectedAssetId;
    if (asset == null || assetId == null) return;
    try {
      final AssetEntity? entity = await resolveAssetEntity(asset);
      if (!mounted || entity == null) return;
      if (entity.id != assetId) return;
      _selectedEntity = entity;
      _pendingSelectedAssetId = entity.id;
      await _prepareVideoIfNeeded(_selectedEntity);
      if (!mounted) return;
      setState(() {});
    } catch (_) {
      // Ignore resolution failures; the asset might have been deleted.
    }
  }

  Future<void> _refreshAll() async {
    if (!mounted) return;
    if (_currentLoad != null) {
      await _currentLoad;
    }
    _currentPage = 0;
    _hasMoreToLoad = true;
    _assets.clear();
    _initialSelectedAsset = widget.selectedAsset;
    _pendingSelectedAssetId = widget.selectedAsset?.id;
    _selectedEntity = null;
    setState(() {});
    await _loadInitialSelectionIfPossible();
    await _loadAlbums();
    await _loadNextPage(reset: true);
  }

  void _onGalleryChanged(MethodCall _) {
    _refreshAll();
  }

  Future<void> _loadAlbums() async {
    _filterOptions = _filterOptions.updateDateToNow();
    final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: _filterOptions,
      onlyAll: false,
    );

    if (!mounted) return;

    AssetPathEntity? nextActive;
    if (_activeAlbum != null) {
      nextActive = paths.firstWhere(
        (AssetPathEntity album) => album.id == _activeAlbum!.id,
        orElse: () => paths.isNotEmpty ? paths.first : _activeAlbum!,
      );
    }

    nextActive ??= _resolveFallbackAlbum(paths);

    setState(() {
      _albums = paths;
      _activeAlbum = nextActive;
    });
  }

  AssetPathEntity? _resolveFallbackAlbum(List<AssetPathEntity> albums) {
    if (albums.isEmpty) return null;
    try {
      return albums.firstWhere((AssetPathEntity album) => album.isAll);
    } on StateError {
      return albums.first;
    }
  }

  Future<void> _loadNextPage({bool reset = false}) async {
    if (_isLoading) {
      if (reset && _currentLoad != null) {
        await _currentLoad;
      } else {
        return;
      }
    }
    if (!_hasMoreToLoad && !reset) return;
    final AssetPathEntity? album = _activeAlbum;
    if (album == null) {
      setState(() {
        _isLoading = false;
        _hasMoreToLoad = false;
      });
      return;
    }
    setState(() => _isLoading = true);

    Future<void> loadFuture() async {
      final List<AssetEntity> page = await album.getAssetListPaged(
        page: _currentPage,
        size: kPageSize,
      );

      if (reset && page.isNotEmpty) {
        AssetEntity? nextSelected = _selectedEntity;
        final String? desiredId = _pendingSelectedAssetId;
        if (desiredId != null) {
          nextSelected = page.firstWhere(
            (AssetEntity entity) => entity.id == desiredId,
            orElse: () => nextSelected ?? page.first,
          );
        }

        final AssetEntity resolvedSelection =
            nextSelected ?? page.first;

        if (_selectedEntity?.id != resolvedSelection.id) {
          _selectedEntity = resolvedSelection;
          _pendingSelectedAssetId = resolvedSelection.id;
          await _prepareVideoIfNeeded(_selectedEntity);
        } else if (_selectedEntity != null) {
          await _prepareVideoIfNeeded(_selectedEntity);
        }
      }

      if (!mounted) return;
      setState(() {
        _assets.addAll(page);
        _isLoading = false;
        _hasMoreToLoad = page.length == kPageSize;
        if (_hasMoreToLoad) _currentPage += 1;
      });
    }

    final Future<void> future = loadFuture().catchError((Object error, _) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasMoreToLoad = false;
      });
    });
    _currentLoad = future;
    await future;
    if (identical(_currentLoad, future)) {
      _currentLoad = null;
    }
  }

  Future<void> _prepareVideoIfNeeded(AssetEntity? entity) async {
    _videoController?.removeListener(_onVideoControllerUpdated);
    await _videoController?.dispose();
    _videoController = null;
    _isVideoPlaying = false;
    if (entity == null || entity.type != AssetType.video) return;

    final File? file = await entity.file;
    if (file == null) return;

    final VideoPlayerController controller = VideoPlayerController.file(file);
    await controller.initialize();
    await controller.setLooping(true);
    await controller.setVolume(0);
    controller.addListener(_onVideoControllerUpdated);
    await controller.play();
    if (!mounted) return;
    setState(() {
      _videoController = controller;
      _isVideoPlaying = controller.value.isPlaying;
    });
  }

  void _onSelect(AssetEntity entity) {
    setState(() {
      _selectedEntity = entity;
      _pendingSelectedAssetId = entity.id;
    });
    widget.onAssetSelected?.call(entity.toSfMediaAsset());
    unawaited(_prepareVideoIfNeeded(entity));
  }

  void _onAlbumChanged(AssetPathEntity? album) {
    if (album == null || album.id == _activeAlbum?.id) return;
    setState(() {
      _activeAlbum = album;
      _currentPage = 0;
      _hasMoreToLoad = true;
      _assets.clear();
      _selectedEntity = null;
      _pendingSelectedAssetId = null;
    });
    unawaited(_loadNextPage(reset: true));
  }

  void _onVideoControllerUpdated() {
    final VideoPlayerController? controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    final bool playing = controller.value.isPlaying;
    if (playing != _isVideoPlaying && mounted) {
      setState(() {
        _isVideoPlaying = playing;
      });
    }
  }

  Future<void> _toggleVideoPlayback() async {
    final VideoPlayerController? controller = _videoController;
    if (controller == null || !controller.value.isInitialized) return;
    if (controller.value.isPlaying) {
      await controller.pause();
    } else {
      await controller.play();
    }
    if (!mounted) return;
    setState(() {
      _isVideoPlaying = controller.value.isPlaying;
    });
  }

  double _calculatePreviewAspectRatio(AssetEntity entity) {
    if (entity.type == AssetType.video &&
        _videoController != null &&
        _videoController!.value.isInitialized) {
      final double ratio = _videoController!.value.aspectRatio;
      if (ratio > 0) return ratio;
    }
    final double width = entity.width.toDouble();
    final double height = entity.height.toDouble();
    if (width <= 0 || height <= 0) {
      return 1;
    }
    return width / height;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final String minutes = twoDigits(duration.inMinutes.remainder(60));
    final String seconds = twoDigits(duration.inSeconds.remainder(60));
    final int hours = duration.inHours;
    if (hours > 0) {
      return '${twoDigits(hours)}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final AssetEntity? selected = _selectedEntity;
    final double previewHeight =
        MediaQuery.of(context).size.height * widget.previewHeightFactor;

    return Column(
      children: <Widget>[
        SelectedPreview(
          height: previewHeight,
          selected: selected,
          aspectRatio: selected != null
              ? _calculatePreviewAspectRatio(selected)
              : 1,
          videoController: _videoController,
          isVideoPlaying: _isVideoPlaying,
          onToggleVideo: _toggleVideoPlayback,
        ),
        AlbumDropdown(
          albums: _albums,
          activeAlbum: _activeAlbum,
          onChanged: _onAlbumChanged,
        ),
        Expanded(
          child: AssetGrid(
            assets: _assets,
            scrollController: _scrollController,
            onAssetTap: _onSelect,
            onScrollNearEnd: () => _loadNextPage(),
            isLoading: _isLoading,
            selectedAssetId: selected?.id,
            formatDuration: _formatDuration,
            crossAxisCount: widget.gridCrossAxisCount,
          ),
        ),
      ],
    );
  }
}
