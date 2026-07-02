import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/return_code.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'custom_functions.dart';

class ResolvedVideoPlaybackSource {
  const ResolvedVideoPlaybackSource._({
    required this.path,
    required this.isFile,
  });

  const ResolvedVideoPlaybackSource.network(String url)
    : this._(path: url, isFile: false);

  const ResolvedVideoPlaybackSource.file(String path)
    : this._(path: path, isFile: true);

  final String path;
  final bool isFile;
}

class WebmPlaybackHelper {
  static final Map<String, Future<String?>> _transcodeJobs =
      <String, Future<String?>>{};

  static Future<ResolvedVideoPlaybackSource?> resolvePlayableSource(
    String? mediaUrl, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    final resolvedUrl = CustomFunctions.resolveNetworkUrl(mediaUrl);
    if (resolvedUrl == null) {
      return null;
    }

    if (!CustomFunctions.isApplePlatform() ||
        !CustomFunctions.isWebmVideoUrl(resolvedUrl)) {
      return ResolvedVideoPlaybackSource.network(resolvedUrl);
    }

    final cacheKey = '$resolvedUrl::${headers.hashCode}';
    final localPath = await _transcodeJobs.putIfAbsent(
      cacheKey,
      () => _downloadAndTranscodeWebm(resolvedUrl, headers: headers),
    );

    if (localPath == null) {
      return null;
    }

    return ResolvedVideoPlaybackSource.file(localPath);
  }

  static Future<String?> _downloadAndTranscodeWebm(
    String videoUrl, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    final tempDirectory = await getTemporaryDirectory();
    final cacheDirectory = Directory('${tempDirectory.path}/webm_cache');
    if (!await cacheDirectory.exists()) {
      await cacheDirectory.create(recursive: true);
    }

    final sanitizedId = videoUrl.hashCode.abs().toString();
    final inputFile = File('${cacheDirectory.path}/$sanitizedId.webm');
    final outputFile = File('${cacheDirectory.path}/$sanitizedId.mp4');

    if (await outputFile.exists() && await outputFile.length() > 0) {
      return outputFile.path;
    }

    if (!await inputFile.exists() || await inputFile.length() == 0) {
      final response = await http.get(Uri.parse(videoUrl), headers: headers);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      await inputFile.writeAsBytes(response.bodyBytes, flush: true);
    }

    final escapedInputPath = inputFile.path.replaceAll("'", r"'\''");
    final escapedOutputPath = outputFile.path.replaceAll("'", r"'\''");
    final session = await FFmpegKit.execute(
      "-y -i '$escapedInputPath' -c:v libx264 -pix_fmt yuv420p "
      "-c:a aac -movflags +faststart '$escapedOutputPath'",
    );
    final returnCode = await session.getReturnCode();
    if (!ReturnCode.isSuccess(returnCode)) {
      return null;
    }

    if (!await outputFile.exists() || await outputFile.length() == 0) {
      return null;
    }

    return outputFile.path;
  }
}
