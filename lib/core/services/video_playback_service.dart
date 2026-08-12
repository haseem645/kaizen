import 'dart:async';
import 'dart:io';

import 'package:cached_video_player_plus/cached_video_player_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:video_player/video_player.dart';

import '../utils/custom_functions.dart';
import '../utils/webm_playback_helper.dart';

class VideoPlaybackService {
  VideoPlaybackService._();

  static const Duration defaultCacheMaxAge = Duration(days: 30);
  static const String _customCacheNamespace = 'kaizen-video';
  static const String _packageCacheStoragePrefix =
      'cached_video_player_plus_caching_time_of_';
  static final Map<String, Future<void>> _warmUpJobs = <String, Future<void>>{};

  static Future<void> warmUp(
    String? videoUrl, {
    Map<String, String> headers = const <String, String>{},
    Duration cacheMaxAge = defaultCacheMaxAge,
  }) async {
    final resolvedUrl = CustomFunctions.resolveNetworkUrl(videoUrl);
    if (resolvedUrl == null || _requiresAppleWebmTranscode(resolvedUrl)) {
      return;
    }

    await _warmUpResolvedUri(
      Uri.parse(resolvedUrl),
      headers: headers,
      cacheMaxAge: cacheMaxAge,
    );
  }

  static Future<VideoPlayerController?> createInitializedController(
    String? videoUrl, {
    String? localFilePath,
    Map<String, String> headers = const <String, String>{},
    Duration cacheMaxAge = defaultCacheMaxAge,
    VideoPlayerOptions? videoPlayerOptions,
    VideoViewType viewType = VideoViewType.textureView,
  }) async {
    final resolvedLocalFilePath = localFilePath?.trim();
    if (resolvedLocalFilePath != null && resolvedLocalFilePath.isNotEmpty) {
      final localFile = File(resolvedLocalFilePath);
      if (await localFile.exists()) {
        final localController = VideoPlayerController.file(
          localFile,
          videoPlayerOptions: videoPlayerOptions,
          viewType: viewType,
        );

        try {
          await localController.initialize();
          return localController;
        } catch (error) {
          await localController.dispose();
          debugPrint(
            'Local video initialization failed for $resolvedLocalFilePath: $error',
          );
        }
      }
    }

    final resolvedUrl = CustomFunctions.resolveNetworkUrl(videoUrl);
    if (resolvedUrl == null) {
      return null;
    }

    if (_requiresAppleWebmTranscode(resolvedUrl)) {
      return _createControllerFromResolvedSource(
        videoUrl,
        headers: headers,
        videoPlayerOptions: videoPlayerOptions,
        viewType: viewType,
      );
    }

    final videoUri = Uri.parse(resolvedUrl);
    final cacheKey = _cacheKeyFor(videoUri);
    unawaited(
      _warmUpResolvedUri(videoUri, headers: headers, cacheMaxAge: cacheMaxAge),
    );

    final cachedFile = await _getValidCachedFile(
      cacheKey: cacheKey,
      cacheMaxAge: cacheMaxAge,
    );
    if (cachedFile != null) {
      final cachedController = VideoPlayerController.file(
        cachedFile,
        videoPlayerOptions: videoPlayerOptions,
        viewType: viewType,
      );

      try {
        await cachedController.initialize();
        return cachedController;
      } catch (error) {
        await cachedController.dispose();
        debugPrint(
          'Cached video initialization failed for $resolvedUrl: $error',
        );
        await _removeCachedFileByKey(cacheKey);
      }
    }

    final controller = VideoPlayerController.networkUrl(
      videoUri,
      httpHeaders: headers,
      videoPlayerOptions: videoPlayerOptions,
      viewType: viewType,
    );
    await controller.initialize();
    return controller;
  }

  static Future<VideoPlayerController?> _createControllerFromResolvedSource(
    String? videoUrl, {
    required Map<String, String> headers,
    VideoPlayerOptions? videoPlayerOptions,
    required VideoViewType viewType,
  }) async {
    final source = await WebmPlaybackHelper.resolvePlayableSource(
      videoUrl,
      headers: headers,
    );
    if (source == null) {
      return null;
    }

    final controller = source.isFile
        ? VideoPlayerController.file(
            File(source.path),
            videoPlayerOptions: videoPlayerOptions,
            viewType: viewType,
          )
        : VideoPlayerController.networkUrl(
            Uri.parse(source.path),
            httpHeaders: headers,
            videoPlayerOptions: videoPlayerOptions,
            viewType: viewType,
          );
    await controller.initialize();
    return controller;
  }

  static Future<void> _warmUpResolvedUri(
    Uri videoUri, {
    required Map<String, String> headers,
    required Duration cacheMaxAge,
  }) async {
    final cacheKey = _cacheKeyFor(videoUri);
    final existingJob = _warmUpJobs[cacheKey];
    if (existingJob != null) {
      await existingJob;
      return;
    }

    late final Future<void> job;
    job =
        () async {
          try {
            await CachedVideoPlayerPlus.preCacheVideo(
              videoUri,
              downloadHeaders: headers,
              invalidateCacheIfOlderThan: cacheMaxAge,
              cacheKey: cacheKey,
            );
          } catch (error) {
            debugPrint('Video cache warm-up failed for $videoUri: $error');
          }
        }().whenComplete(() {
          if (identical(_warmUpJobs[cacheKey], job)) {
            _warmUpJobs.remove(cacheKey);
          }
        });

    _warmUpJobs[cacheKey] = job;
    await job;
  }

  static Future<File?> _getValidCachedFile({
    required String cacheKey,
    required Duration cacheMaxAge,
  }) async {
    final storageKey = _storageKeyFor(cacheKey);
    final fileInfo = await CachedVideoPlayerPlus.cacheManager.getFileFromCache(
      storageKey,
    );
    if (fileInfo == null) {
      return null;
    }

    final cachedAtMillis = await CachedVideoPlayerPlus.metadataStorage.read(
      storageKey,
    );
    var isCacheExpired = cachedAtMillis == null;
    if (cachedAtMillis != null) {
      final cachedDate = DateTime.fromMillisecondsSinceEpoch(cachedAtMillis);
      isCacheExpired =
          DateTime.timestamp().difference(cachedDate) > cacheMaxAge;
    }

    final file = fileInfo.file;
    final fileExists = await file.exists();
    final isEmptyFile = fileExists ? await file.length() == 0 : true;
    if (isCacheExpired || isEmptyFile) {
      await _removeCachedFileByKey(cacheKey);
      return null;
    }

    return file;
  }

  static Future<void> _removeCachedFileByKey(String cacheKey) async {
    final storageKey = _storageKeyFor(cacheKey);
    await Future.wait<void>([
      CachedVideoPlayerPlus.cacheManager.removeFile(storageKey),
      CachedVideoPlayerPlus.metadataStorage.remove(storageKey),
    ]);
  }

  static String _cacheKeyFor(Uri videoUri) {
    final normalizedUri = videoUri.replace(fragment: '');
    return '$_customCacheNamespace::$normalizedUri';
  }

  static String _storageKeyFor(String cacheKey) {
    return '$_packageCacheStoragePrefix$cacheKey';
  }

  static bool _requiresAppleWebmTranscode(String resolvedUrl) {
    return CustomFunctions.isApplePlatform() &&
        CustomFunctions.isWebmVideoUrl(resolvedUrl);
  }
}
