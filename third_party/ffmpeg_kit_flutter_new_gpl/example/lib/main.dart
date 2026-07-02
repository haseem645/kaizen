import 'dart:io';

import 'package:ffmpeg_kit_flutter_new_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/log.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/session.dart';
import 'package:ffmpeg_kit_flutter_new_gpl/statistics.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'FFmpeg example'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String logString = 'Logs will be here.';
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;

  VideoPlayerController? _videoPlayerController2;
  ChewieController? _chewieController2;

  @override
  void initState() {
    super.initState();
    initializePlayer();
    checkFFmpegFilters();
  }

  @override
  void dispose() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _videoPlayerController2?.dispose();
    _chewieController2?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                (_chewieController != null && _chewieController2 == null)
                    ? AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Chewie(controller: _chewieController!),
                    )
                    : (_chewieController2 != null)
                    ? AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Chewie(controller: _chewieController2!),
                    )
                    : const SizedBox(),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Wrap(
                    direction: Axis.horizontal,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          mergeVideo();
                        },
                        child: const Text('合并'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          chongdieVideo();
                        },
                        child: const Text('重叠'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          corpVideo();
                        },
                        child: const Text('部分重叠'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          addTextToVideo();
                        },
                        child: const Text('添加文字'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          addImageToVideo();
                        },
                        child: const Text('添加图片'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          addAudioToVideo();
                        },
                        child: const Text('添加音频'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          addLutToVideo();
                        },
                        child: const Text('添加lut'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          test();
                        },
                        child: const Text('测试'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: executeFFmpegCommand,
      //   child: const Icon(Icons.rocket),
      // ),
    );
  }

  Future<void> initializePlayer() async {
    final videoPath = await getPath();
    debugPrint('Video path: $videoPath');

    try {
      _videoPlayerController = VideoPlayerController.file(File(videoPath));
      await _videoPlayerController!.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: true,
        looping: false,
        aspectRatio: 9 / 16,
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Text(
              'Error: $errorMessage',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );

      setState(() {});
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  Future<String> getPath() async {
    final tempDir = await getDirectory();
    final sampleVideoRoot = await rootBundle.load('assets/input.mp4');
    final sampleVideoFile = File('${tempDir.path}/input.mp4');
    await sampleVideoFile.writeAsBytes(sampleVideoRoot.buffer.asUint8List());
    debugPrint('sampleVideoFile: ${sampleVideoFile.path}');
    return sampleVideoFile.path;
  }

  void executeFFmpegCommand() async {
    logString = '';
    final tempDir = await getDirectory();
    final sampleVideoRoot = await rootBundle.load('assets/input.mp4');
    final sampleVideoFile = File('${tempDir.path}/input.mp4');
    final outputFile = File('${tempDir.path}/output.mp4');
    await sampleVideoFile.writeAsBytes(sampleVideoRoot.buffer.asUint8List());
    if (outputFile.existsSync()) await outputFile.delete();

    /// Execute FFmpeg command
    await FFmpegKit.executeAsync(
      '-i '
      '${sampleVideoFile.path} -c:v mpeg4 -preset ultrafast '
      '${tempDir.path}/output.mp4',
      (Session session) async {
        debugPrint('session: ${await session.getOutput()}');
      },
      (Log log) {
        logString += log.getMessage();
        debugPrint('log: ${log.getMessage()}');
      },
      (Statistics statistics) {
        debugPrint('statistics: ${statistics.getSize()}');
      },
    );
    setState(() {});
  }

  void mergeVideo() async {
    try {
      final tempDir = await getDirectory();
      final sampleVideoRoot = await rootBundle.load('assets/sample_video.mp4');
      final sampleVideoRoot2 = await rootBundle.load('assets/oceans.mp4');
      final sampleVideoFile = File('${tempDir.path}/sample_video.mp4');
      final sampleVideoFile2 = File('${tempDir.path}/oceans.mp4');
      final outputFile = File('${tempDir.path}/output.mp4');

      await sampleVideoFile.writeAsBytes(sampleVideoRoot.buffer.asUint8List());
      await sampleVideoFile2.writeAsBytes(
        sampleVideoRoot2.buffer.asUint8List(),
      );

      await FFmpegKit.executeAsync(
        '-y -i ${sampleVideoFile.path} -i ${sampleVideoFile2.path} '
        '-filter_complex "[0:v]scale=960:400,setsar=1,fps=25[v0];[1:v]scale=960:400,setsar=1,fps=25[v1];'
        '[v0][0:a][v1][1:a]concat=n=2:v=1:a=1[outv][outa]" '
        '-map "[outv]" -map "[outa]" '
        '-c:v mpeg4 '
        '-q:v 2 '
        '-r 25 ' // 设置输出帧率为25fps
        '-vsync 1 ' // 使用视频同步模式1
        '-c:a aac '
        '-b:a 128k '
        '-movflags +faststart '
        '${outputFile.path}',
        (Session session) async {
          debugPrint('session: ${await session.getOutput()}');
          initializePlayer2(outputFile.path);
        },
        (Log log) {
          logString += log.getMessage();
          debugPrint('log: ${log.getMessage()}');
        },
        (Statistics statistics) {
          debugPrint('statistics: ${statistics.getSize()}');
        },
      );
    } catch (e) {
      debugPrint('Error merging video: $e');
    }
  }

  void chongdieVideo() async {
    try {
      final tempDir = await getDirectory();
      final sampleVideoRoot = await rootBundle.load('assets/sample_video.mp4');
      final sampleVideoRoot2 = await rootBundle.load('assets/oceans.mp4');
      final sampleVideoFile = File('${tempDir.path}/sample_video.mp4');
      final sampleVideoFile2 = File('${tempDir.path}/oceans.mp4');
      final outputFile = File('${tempDir.path}/output.mp4');

      await sampleVideoFile.writeAsBytes(sampleVideoRoot.buffer.asUint8List());
      await sampleVideoFile2.writeAsBytes(
        sampleVideoRoot2.buffer.asUint8List(),
      );

      debugPrint('开始处理视频...');
      debugPrint('视频1路径: ${sampleVideoFile.path}');
      debugPrint('视频2路径: ${sampleVideoFile2.path}');
      debugPrint('输出路径: ${outputFile.path}');

      await FFmpegKit.executeAsync(
        '-y -i ${sampleVideoFile.path} -i ${sampleVideoFile2.path} '
        '-filter_complex "[0:v]scale=960:400,setsar=1,fps=25[base];'
        '[1:v]scale=960:400,setsar=1,fps=25,format=rgba,colorchannelmixer=aa=0.5[overlay];'
        '[base][overlay]overlay=0:0:format=auto,format=yuv420p[outv];'
        '[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=2[outa]" '
        '-map "[outv]" -map "[outa]" '
        '-c:v mpeg4 '
        '-q:v 2 '
        '-r 25 '
        '-vsync 1 '
        '-c:a aac '
        '-b:a 128k '
        '-movflags +faststart '
        '${outputFile.path}',
        (Session session) async {
          final returnCode = await session.getReturnCode();
          final output = await session.getOutput();
          debugPrint('FFmpeg处理完成，返回码: $returnCode');
          debugPrint('FFmpeg输出: $output');

          if (returnCode?.isValueSuccess() ?? false) {
            debugPrint('视频处理成功');
            if (await outputFile.exists()) {
              debugPrint('输出文件存在，大小: ${await outputFile.length()} bytes');
              initializePlayer2(outputFile.path);
            } else {
              debugPrint('输出文件不存在');
            }
          } else {
            debugPrint('视频处理失败');
          }
        },
        (Log log) {
          debugPrint('FFmpeg日志: ${log.getMessage()}');
        },
        (Statistics statistics) {
          debugPrint('FFmpeg统计: ${statistics.getTime()}');
        },
      );
    } catch (e) {
      debugPrint('发生错误: $e');
    }
  }

  void corpVideo() async {
    try {
      final tempDir = await getDirectory();
      final sampleVideoRoot = await rootBundle.load('assets/sample_video.mp4');
      final sampleVideoRoot2 = await rootBundle.load('assets/oceans.mp4');
      final sampleVideoFile = File('${tempDir.path}/sample_video.mp4');
      final sampleVideoFile2 = File('${tempDir.path}/oceans.mp4');
      final outputFile = File('${tempDir.path}/output.mp4');

      await sampleVideoFile.writeAsBytes(sampleVideoRoot.buffer.asUint8List());
      await sampleVideoFile2.writeAsBytes(
        sampleVideoRoot2.buffer.asUint8List(),
      );

      debugPrint('开始处理视频...');
      debugPrint('视频1路径: ${sampleVideoFile.path}');
      debugPrint('视频2路径: ${sampleVideoFile2.path}');
      debugPrint('输出路径: ${outputFile.path}');

      await FFmpegKit.executeAsync(
        '-y -i ${sampleVideoFile.path} -i ${sampleVideoFile2.path} '
        '-filter_complex "[1:v]scale=960:400,setsar=1,fps=25[base];'
        '[0:v]scale=480:200,setsar=1,fps=25,format=rgba,colorchannelmixer=aa=0.7[overlay];'
        '[base][overlay]overlay=W-w-10:H-h-10:format=auto,format=yuv420p[outv];'
        '[0:a][1:a]amix=inputs=2:duration=first:dropout_transition=2[outa]" '
        '-map "[outv]" -map "[outa]" '
        '-c:v mpeg4 '
        '-q:v 2 '
        '-r 25 '
        '-vsync 1 '
        '-c:a aac '
        '-b:a 128k '
        '-movflags +faststart '
        '${outputFile.path}',
        (Session session) async {
          final returnCode = await session.getReturnCode();
          final output = await session.getOutput();
          debugPrint('FFmpeg处理完成，返回码: $returnCode');
          debugPrint('FFmpeg输出: $output');

          if (returnCode?.isValueSuccess() ?? false) {
            debugPrint('视频处理成功');
            if (await outputFile.exists()) {
              debugPrint('输出文件存在，大小: ${await outputFile.length()} bytes');
              initializePlayer2(outputFile.path);
            } else {
              debugPrint('输出文件不存在');
            }
          } else {
            debugPrint('视频处理失败');
          }
        },
        (Log log) {
          debugPrint('FFmpeg日志: ${log.getMessage()}');
        },
        (Statistics statistics) {
          debugPrint('FFmpeg统计: ${statistics.getTime()}');
        },
      );
    } catch (e) {
      debugPrint('发生错误: $e');
    }
  }

  void addTextToVideo() async {
    try {
      final tempDir = await getDirectory();
      final sampleVideoRoot = await rootBundle.load('assets/sample_video.mp4');
      final sampleVideoFile = File('${tempDir.path}/sample_video.mp4');
      final outputFile = File('${tempDir.path}/output.mp4');

      await sampleVideoFile.writeAsBytes(sampleVideoRoot.buffer.asUint8List());

      final fontData = await rootBundle.load('fonts/ali_puhuiti_heavy.otf');
      final fontFile = File('${tempDir.path}/NotoSans-Regular.ttf');
      await fontFile.writeAsBytes(fontData.buffer.asUint8List());
      debugPrint('开始处理视频...');
      debugPrint('视频路径: ${sampleVideoFile.path}');
      debugPrint('输出路径: ${outputFile.path}');

      await FFmpegKit.executeAsync(
        '-y -i ${sampleVideoFile.path} '
        '-vf "drawtext=fontfile=${fontFile.path}:text=\'Hello World\':fontcolor=white:fontsize=24:box=1:boxcolor=black@0.5:boxborderw=5:'
        'x=(w-text_w)/2:y=h-(h-text_h)*mod(t/5\\,1):enable=\'between(t,0,30)\','
        'drawtext=fontfile=${fontFile.path}:text=\'Moving Text\':fontcolor=yellow:fontsize=30:box=1:boxcolor=red@0.3:boxborderw=5:'
        'x=(w-text_w)*mod(t/3\\,1):y=(h-text_h)/2:enable=\'between(t,0,30)\'" '
        '-c:v libx264 '
        '-q:v 2 '
        '-r 25 '
        '-vsync 1 '
        '-c:a copy '
        '-movflags +faststart '
        '${outputFile.path}',
        (Session session) async {
          final returnCode = await session.getReturnCode();
          final output = await session.getOutput();
          debugPrint('FFmpeg处理完成，返回码: $returnCode');
          debugPrint('FFmpeg输出: $output');

          if (returnCode?.isValueSuccess() ?? false) {
            debugPrint('视频处理成功');
            if (await outputFile.exists()) {
              debugPrint('输出文件存在，大小: ${await outputFile.length()} bytes');
              initializePlayer2(outputFile.path);
            } else {
              debugPrint('输出文件不存在');
            }
          } else {
            debugPrint('视频处理失败');
          }
        },
        (Log log) {
          debugPrint('FFmpeg日志: ${log.getMessage()}');
        },
        (Statistics statistics) {
          debugPrint('FFmpeg统计: ${statistics.getTime()}');
        },
      );
    } catch (e) {
      debugPrint('发生错误: $e');
    }
  }

  void addImageToVideo() async {
    try {
      final tempDir = await getDirectory();
      final sampleVideoRoot = await rootBundle.load('assets/sample_video.mp4');
      final imageRoot = await rootBundle.load('assets/gift.png');
      final sampleVideoFile = File('${tempDir.path}/sample_video.mp4');
      final imageFile = File('${tempDir.path}/gift.png');
      final outputFile = File('${tempDir.path}/output.mp4');

      await sampleVideoFile.writeAsBytes(sampleVideoRoot.buffer.asUint8List());
      await imageFile.writeAsBytes(imageRoot.buffer.asUint8List());

      debugPrint('开始处理视频...');
      debugPrint('视频路径: ${sampleVideoFile.path}');
      debugPrint('图片路径: ${imageFile.path}');
      debugPrint('输出路径: ${outputFile.path}');

      await FFmpegKit.executeAsync(
        '-y -i ${sampleVideoFile.path} -i ${imageFile.path} '
        '-filter_complex "[1:v]scale=100:100,setsar=1[img];'
        '[0:v][img]overlay='
        'x=\'if(gte(t,0), if(gte(t,10), if(gte(t,20), if(gte(t,30), '
        '10, W-w-10), W-w-10), 10+(W-w-20)*t/10), 10)\':'
        'y=\'if(gte(t,0), if(gte(t,10), if(gte(t,20), if(gte(t,30), '
        '10+(H-h-20)*(t-30)/10, H-h-10), 10+(H-h-20)*(t-20)/10), 10), 10)\':'
        'format=auto,format=yuv420p[outv]" '
        '-map "[outv]" -map 0:a '
        '-c:v mpeg4 '
        '-q:v 2 '
        '-r 25 '
        '-vsync 1 '
        '-c:a copy '
        '-movflags +faststart '
        '${outputFile.path}',
        (Session session) async {
          final returnCode = await session.getReturnCode();
          final output = await session.getOutput();
          debugPrint('FFmpeg处理完成，返回码: $returnCode');
          debugPrint('FFmpeg输出: $output');

          if (returnCode?.isValueSuccess() ?? false) {
            debugPrint('视频处理成功');
            if (await outputFile.exists()) {
              debugPrint('输出文件存在，大小: ${await outputFile.length()} bytes');
              initializePlayer2(outputFile.path);
            } else {
              debugPrint('输出文件不存在');
            }
          } else {
            debugPrint('视频处理失败');
          }
        },
        (Log log) {
          debugPrint('FFmpeg日志: ${log.getMessage()}');
        },
        (Statistics statistics) {
          debugPrint('FFmpeg统计: ${statistics.getTime()}');
        },
      );
    } catch (e) {
      debugPrint('发生错误: $e');
    }
  }

  void addAudioToVideo() async {
    try {
      final tempDir = await getDirectory();
      final sampleVideoRoot = await rootBundle.load('assets/sample_video.mp4');
      final audioRoot = await rootBundle.load('assets/demo.wav');
      final sampleVideoFile = File('${tempDir.path}/sample_video.mp4');
      final audioFile = File('${tempDir.path}/demo.wav');
      final outputFile = File('${tempDir.path}/output.mp4');

      await sampleVideoFile.writeAsBytes(sampleVideoRoot.buffer.asUint8List());
      await audioFile.writeAsBytes(audioRoot.buffer.asUint8List());

      debugPrint('开始处理视频...');
      debugPrint('视频路径: ${sampleVideoFile.path}');
      debugPrint('音频路径: ${audioFile.path}');
      debugPrint('输出路径: ${outputFile.path}');

      await FFmpegKit.executeAsync(
        '-y -i ${sampleVideoFile.path} -i ${audioFile.path} '
        '-filter_complex "[0:v]setpts=PTS-STARTPTS[v]" '
        '-map "[v]" -map 1:a '
        '-c:v mpeg4 '
        '-q:v 2 '
        '-r 25 '
        '-vsync 1 '
        '-c:a aac '
        '-b:a 128k '
        '-shortest '
        '-movflags +faststart '
        '${outputFile.path}',
        (Session session) async {
          final returnCode = await session.getReturnCode();
          final output = await session.getOutput();
          debugPrint('FFmpeg处理完成，返回码: $returnCode');
          debugPrint('FFmpeg输出: $output');

          if (returnCode?.isValueSuccess() ?? false) {
            debugPrint('视频处理成功');
            if (await outputFile.exists()) {
              debugPrint('输出文件存在，大小: ${await outputFile.length()} bytes');
              initializePlayer2(outputFile.path);
            } else {
              debugPrint('输出文件不存在');
            }
          } else {
            debugPrint('视频处理失败');
          }
        },
        (Log log) {
          debugPrint('FFmpeg日志: ${log.getMessage()}');
        },
        (Statistics statistics) {
          debugPrint('FFmpeg统计: ${statistics.getTime()}');
        },
      );
    } catch (e) {
      debugPrint('发生错误: $e');
    }
  }

  void addLutToVideo() async {
    try {
      final tempDir = await getDirectory();
      final sampleVideoRoot = await rootBundle.load('assets/input.mp4');
      final lutRoot = await rootBundle.load('assets/color_grade.cube');
      final sampleVideoFile = File('${tempDir.path}/input.mp4');
      final lutFile = File('${tempDir.path}/color_grade.cube');
      final outputFile = File('${tempDir.path}/output.mp4');

      await sampleVideoFile.writeAsBytes(sampleVideoRoot.buffer.asUint8List());
      await lutFile.writeAsBytes(lutRoot.buffer.asUint8List());

      debugPrint('开始处理视频...');
      debugPrint('视频路径: ${sampleVideoFile.path}');
      debugPrint('lut路径: ${lutFile.path}');
      debugPrint('输出路径: ${outputFile.path}');

      await FFmpegKit.executeAsync(
        '-y -i ${sampleVideoFile.path} '
        // '-filter_complex "[0:v]split[a][b];[a]lut3d=file=${lutFile.path}[lut];[b][lut]blend=all_mode=normal:all_opacity=0.7[out]" '
        // '-filter_complex "[0:v]split[a][b];[a]lut3d=${lutFile.path}[lut];[b][lut]blend=all_mode=normal:all_opacity=0.7;" '
        // '-filter_complex "[0:v]split=outputs=2[a][b];[a]lut3d=file=${lutFile.path}[lut];[b][lut]blend=all_mode=normal:all_opacity=0.7;" '
        '-filter_complex "split[a][b];[a]lut3d=${lutFile.path}[lut];[b][lut]blend=all_mode=normal:all_opacity=0.7;" '
        // '-vf "lut3d=file=${lutFile.path}," ' // 移除interp参数
        '-c:v libx264 '
        // '-q:v 2 '
        // '-c:a copy '
        // '-movflags +faststart '
        '${outputFile.path}',
        (Session session) async {
          final returnCode = await session.getReturnCode();
          final output = await session.getOutput();
          debugPrint('FFmpeg处理完成，返回码: $returnCode');
          debugPrint('FFmpeg输出: $output');

          if (returnCode?.isValueSuccess() ?? false) {
            debugPrint('视频处理成功');
            if (await outputFile.exists()) {
              debugPrint('输出文件存在，大小: ${await outputFile.length()} bytes');
              initializePlayer2(outputFile.path);
            } else {
              debugPrint('输出文件不存在');
            }
          } else {
            debugPrint('视频处理失败');
          }
        },
        (Log log) {
          debugPrint('FFmpeg日志: ${log.getMessage()}');
        },
        (Statistics statistics) {
          debugPrint('FFmpeg统计: ${statistics.getTime()}');
        },
      );
    } catch (e) {
      debugPrint('发生错误: $e');
    }
  }

  void test() async {
    try {
      final tempDir = await getDirectory();
      final inputRoot = await rootBundle.load('assets/input.mp4');
      final inputFile = File('${tempDir.path}/input.mp4');
      final video1 = await rootBundle.load('assets/1.mp4');
      final video2 = await rootBundle.load('assets/2.mp4');
      final video3 = await rootBundle.load('assets/3.mp4');
      final video4 = await rootBundle.load('assets/4.mp4');
      final video5 = await rootBundle.load('assets/5.mp4');
      final videoFile1 = File('${tempDir.path}/1.mp4');
      final videoFile2 = File('${tempDir.path}/2.mp4');
      final videoFile3 = File('${tempDir.path}/3.mp4');
      final videoFile4 = File('${tempDir.path}/4.mp4');
      final videoFile5 = File('${tempDir.path}/5.mp4');

      final outputFile = File('${tempDir.path}/output.mp4');

      await inputFile.writeAsBytes(inputRoot.buffer.asUint8List());
      await videoFile1.writeAsBytes(video1.buffer.asUint8List());
      await videoFile2.writeAsBytes(video2.buffer.asUint8List());
      await videoFile3.writeAsBytes(video3.buffer.asUint8List());
      await videoFile4.writeAsBytes(video4.buffer.asUint8List());
      await videoFile5.writeAsBytes(video5.buffer.asUint8List());

      await FFmpegKit.executeAsync(
        '-y -hide_banner -i ${inputFile.path} '
        '-i ${videoFile1.path} '
        '-i ${videoFile2.path} '
        '-i ${videoFile3.path} '
        '-i ${videoFile4.path} '
        '-i ${videoFile5.path} '
        '-filter_complex "[1:v]rotate=a=\'t*PI/180*31\',scale=1080:1920[v1];'
        '[2:v]rotate=a=\'t*PI/180*43\',scale=1080:1920[v2];'
        '[3:v]rotate=a=\'t*PI/180*47\',scale=1080:1920[v3];'
        '[4:v]rotate=a=\'t*PI/180*23\',scale=1080:1920[v4];'
        '[5:v]rotate=a=\'t*PI/180*13\',scale=1080:1920[v5];'
        '[0:v][v1]blend=all_mode=normal:all_opacity=0.8[out1];'
        '[out1][v2]blend=all_mode=normal:all_opacity=0.8[out2];'
        '[out2][v3]blend=all_mode=normal:all_opacity=0.8[out3];'
        '[out3][v4]blend=all_mode=normal:all_opacity=0.8[out4];'
        '[out4][v5]blend=all_mode=normal:all_opacity=0.8[out]" '
        '-r 30 '
        '-map "[out]" '
        '-an '
        '-c:v libx264 '
        '${outputFile.path}',
        (Session session) async {
          final returnCode = await session.getReturnCode();
          final output = await session.getOutput();
          debugPrint('FFmpeg处理完成，返回码: $returnCode');
          debugPrint('FFmpeg输出: $output');

          if (returnCode?.isValueSuccess() ?? false) {
            debugPrint('视频处理成功');
            if (await outputFile.exists()) {
              debugPrint('输出文件存在，大小: ${await outputFile.length()} bytes');
              initializePlayer2(outputFile.path);
            } else {
              debugPrint('输出文件不存在');
            }
          } else {
            debugPrint('视频处理失败');
          }
        },
        (Log log) {
          debugPrint('FFmpeg日志: ${log.getMessage()}');
        },
        (Statistics statistics) {
          debugPrint('FFmpeg统计: ${statistics.getTime()}');
        },
      );
    } catch (e) {
      debugPrint('发生错误: $e');
    }
  }

  Future<void> initializePlayer2(String videoPath) async {
    debugPrint('Video path: $videoPath');
    _videoPlayerController2 = VideoPlayerController.file(File(videoPath));
    await _videoPlayerController2!.initialize();

    _chewieController2 = ChewieController(
      videoPlayerController: _videoPlayerController2!,
      autoPlay: true,
      aspectRatio: 9 / 16,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            'Error: $errorMessage',
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
    setState(() {});
  }

  Future<Directory> getDirectory() async {
    if (Platform.isAndroid) {
      final tempDir = await getExternalStorageDirectory();
      return tempDir ?? await getTemporaryDirectory();
    } else {
      return await getTemporaryDirectory();
    }
  }

  void checkFFmpegFilters() async {
    await FFmpegKit.executeAsync(
      '-buildconf',
      (Session session) async {
        final output = await session.getOutput();
        debugPrint('FFmpeg支持的过滤器: $output');
      },
      (Log log) {
        // debugPrint('FFmpeg日志: ${log.getMessage()}');
      },
      (Statistics statistics) {
        debugPrint('FFmpeg统计: ${statistics.getTime()}');
      },
    );
  }
}
