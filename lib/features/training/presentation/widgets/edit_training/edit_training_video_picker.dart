part of 'package:sparrowkaizen/features/training/presentation/pages/edit_training_screen.dart';

class _TrainingVideoPickerSelection {
  const _TrainingVideoPickerSelection.camera()
    : asset = null,
      usesCamera = true,
      usesSystemGalleryPicker = false;

  const _TrainingVideoPickerSelection.systemGallery()
    : asset = null,
      usesCamera = false,
      usesSystemGalleryPicker = true;

  const _TrainingVideoPickerSelection.asset(AssetEntity selectedAsset)
    : asset = selectedAsset,
      usesCamera = false,
      usesSystemGalleryPicker = false;

  final AssetEntity? asset;
  final bool usesCamera;
  final bool usesSystemGalleryPicker;
}

class _PickedTrainingVideo {
  const _PickedTrainingVideo({
    required this.file,
    required this.isSavedDirectlyToGallery,
  });

  final File file;
  final bool isSavedDirectlyToGallery;
}

class _TrainingVideoGalleryPickerStateController extends ChangeNotifier {
  PermissionState? permissionState;
  AssetPathEntity? videoAlbum;
  final List<AssetEntity> videos = <AssetEntity>[];
  bool isLoadingInitial = true;
  bool isLoadingMore = false;
  bool hasMore = true;
  String? errorMessage;

  bool get hasGalleryAccess => permissionState?.hasAccess ?? false;

  void showInitialLoader() {
    isLoadingInitial = true;
    errorMessage = null;
    notifyListeners();
  }

  void showPermissionDenied(PermissionState nextPermissionState) {
    permissionState = nextPermissionState;
    videoAlbum = null;
    videos.clear();
    hasMore = false;
    isLoadingInitial = false;
    isLoadingMore = false;
    errorMessage = null;
    notifyListeners();
  }

  void showInitialVideos({
    required PermissionState nextPermissionState,
    required AssetPathEntity? nextVideoAlbum,
    required List<AssetEntity> nextVideos,
    required int pageSize,
  }) {
    permissionState = nextPermissionState;
    videoAlbum = nextVideoAlbum;
    videos
      ..clear()
      ..addAll(nextVideos);
    hasMore = nextVideos.length == pageSize;
    isLoadingInitial = false;
    isLoadingMore = false;
    errorMessage = null;
    notifyListeners();
  }

  void showInitialError(String message) {
    isLoadingInitial = false;
    isLoadingMore = false;
    hasMore = false;
    errorMessage = message;
    notifyListeners();
  }

  void startLoadingMore() {
    isLoadingMore = true;
    errorMessage = null;
    notifyListeners();
  }

  void appendVideos(List<AssetEntity> nextVideos, int pageSize) {
    videos.addAll(nextVideos);
    hasMore = nextVideos.length == pageSize;
    isLoadingMore = false;
    notifyListeners();
  }

  void showLoadMoreError(String message) {
    isLoadingMore = false;
    errorMessage = message;
    notifyListeners();
  }
}

class _TrainingVideoGalleryPickerSheet extends StatefulWidget {
  const _TrainingVideoGalleryPickerSheet();

  @override
  State<_TrainingVideoGalleryPickerSheet> createState() =>
      _TrainingVideoGalleryPickerSheetState();
}

class _TrainingVideoGalleryPickerSheetState
    extends State<_TrainingVideoGalleryPickerSheet>
    with WidgetsBindingObserver {
  static const int _pageSize = 24;

  final ScrollController _scrollController = ScrollController();
  final _TrainingVideoGalleryPickerStateController _galleryState =
      _TrainingVideoGalleryPickerStateController();

  bool get _isGalleryAccessLimited =>
      _galleryState.permissionState == PermissionState.limited;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_handleScroll);
    _loadInitialVideos();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    _galleryState.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadInitialVideos(showLoader: false);
    }
  }

  void _handleScroll() {
    if (!_scrollController.hasClients ||
        _galleryState.isLoadingInitial ||
        _galleryState.isLoadingMore ||
        !_galleryState.hasMore ||
        _galleryState.videoAlbum == null) {
      return;
    }

    if (_scrollController.position.extentAfter < 280) {
      _loadMoreVideos();
    }
  }

  Future<void> _loadInitialVideos({bool showLoader = true}) async {
    if (showLoader && mounted) {
      _galleryState.showInitialLoader();
    }

    try {
      final permissionState = await PhotoManager.requestPermissionExtend(
        requestOption: const PermissionRequestOption(
          androidPermission: AndroidPermission(
            type: RequestType.video,
            mediaLocation: false,
          ),
        ),
      );
      if (!mounted) {
        return;
      }

      if (!permissionState.hasAccess) {
        _galleryState.showPermissionDenied(permissionState);
        return;
      }

      final albums = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.video,
      );
      if (!mounted) {
        return;
      }

      final videoAlbum = albums.isNotEmpty ? albums.first : null;
      final videos = videoAlbum == null
          ? <AssetEntity>[]
          : await videoAlbum.getAssetListPaged(
              page: 0,
              size: _pageSize,
              type: RequestType.video,
            );
      if (!mounted) {
        return;
      }

      _galleryState.showInitialVideos(
        nextPermissionState: permissionState,
        nextVideoAlbum: videoAlbum,
        nextVideos: videos,
        pageSize: _pageSize,
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      _galleryState.showInitialError(AppStrings.pickVideoError);
    }
  }

  Future<void> _loadMoreVideos() async {
    final videoAlbum = _galleryState.videoAlbum;
    if (videoAlbum == null ||
        _galleryState.isLoadingInitial ||
        _galleryState.isLoadingMore ||
        !_galleryState.hasMore) {
      return;
    }

    _galleryState.startLoadingMore();

    try {
      final nextPage = _galleryState.videos.length ~/ _pageSize;
      final nextVideos = await videoAlbum.getAssetListPaged(
        page: nextPage,
        size: _pageSize,
        type: RequestType.video,
      );
      if (!mounted) {
        return;
      }

      _galleryState.appendVideos(nextVideos, _pageSize);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _galleryState.showLoadMoreError(AppStrings.pickVideoError);
    }
  }

  Future<void> _presentLimitedVideoAccessPicker() async {
    try {
      await PhotoManager.presentLimited(type: RequestType.video);
      if (!mounted) {
        return;
      }

      await _loadInitialVideos(showLoader: false);
    } catch (_) {
      if (!mounted) {
        return;
      }

      _galleryState.showLoadMoreError(AppStrings.pickVideoError);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _galleryState,
      builder: (context, _) {
        return FractionallySizedBox(
          heightFactor: 0.82,
          child: SafeArea(
            top: false,
            bottom: false,
            child: Container(
              decoration: const BoxDecoration(
                color: AppColors.surfaceDark3,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.fieldBorder.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppTextView.body1(
                              AppStrings.trainingSelectVideoSource,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                            SizedBox(height: 8),
                            AppTextView.body2(
                              AppStrings.trainingSelectVideoSourceHint,
                              color: AppColors.textSecondary,
                              height: 1.45,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      AppOverlayCloseButton(
                        onTap: () => Navigator.of(context).maybePop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const AppTextView.body3(
                    AppStrings.trainingRecentVideos,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: GridView.builder(
                            controller: _scrollController,
                            physics: const BouncingScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  mainAxisExtent: 118,
                                ),
                            itemCount:
                                _galleryState.videos.length +
                                1 +
                                (_isGalleryAccessLimited ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == 0) {
                                return _TrainingVideoCameraTile(
                                  onTap: () => Navigator.of(context).pop(
                                    const _TrainingVideoPickerSelection.camera(),
                                  ),
                                );
                              }

                              if (_isGalleryAccessLimited && index == 1) {
                                return _TrainingVideoManageAccessTile(
                                  onTap: _presentLimitedVideoAccessPicker,
                                );
                              }

                              final assetIndex =
                                  index - (_isGalleryAccessLimited ? 2 : 1);
                              final asset = _galleryState.videos[assetIndex];
                              return _TrainingVideoGalleryTile(
                                asset: asset,
                                onTap: () => Navigator.of(context).pop(
                                  _TrainingVideoPickerSelection.asset(asset),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TrainingVideoSystemPickerSheet extends StatelessWidget {
  const _TrainingVideoSystemPickerSheet();

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      heightFactor: 0.46,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.surfaceDark3,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.fieldBorder.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTextView.body1(
                          AppStrings.trainingSelectVideoSource,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        SizedBox(height: 8),
                        AppTextView.body2(
                          AppStrings.trainingSelectVideoSourceHint,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  AppOverlayCloseButton(
                    onTap: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              _TrainingVideoSystemPickerOptionTile(
                icon: Icons.videocam_rounded,
                title: AppStrings.trainingRecordVideo,
                subtitle: AppStrings.trainingRecordVideoHint,
                accentColor: AppColors.secondaryColor,
                onTap: () => Navigator.of(
                  context,
                ).pop(const _TrainingVideoPickerSelection.camera()),
              ),
              const SizedBox(height: 12),
              _TrainingVideoSystemPickerOptionTile(
                icon: Icons.video_library_outlined,
                title: AppStrings.trainingUploadVideo,
                subtitle: AppStrings.trainingUploadVideoHint,
                onTap: () => Navigator.of(
                  context,
                ).pop(const _TrainingVideoPickerSelection.systemGallery()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
