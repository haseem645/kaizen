import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/compliance_video_transcript.dart';

class ComplianceVideoController extends ChangeNotifier {
  ComplianceVideoController(String? transcript)
    : _transcript = ComplianceVideoTranscript.parse(transcript);

  final ComplianceVideoTranscript _transcript;
  int? _activeTranscriptIndex;
  bool _isCcEnabled = false;
  bool _isDisposed = false;
  int? _seekingIndex;
  String? _seekError;
  Future<bool> Function(Duration)? _seekHandler;
  Completer<Future<bool> Function(Duration)?>? _seekHandlerReady;

  List<ComplianceTranscriptLine> get transcriptLines => _transcript.lines;
  int? get activeTranscriptIndex => _activeTranscriptIndex;
  ComplianceTranscriptLine? get activeTranscriptLine =>
      _activeTranscriptIndex == null ? null : transcriptLines[_activeTranscriptIndex!];
  bool get isCcEnabled => _isCcEnabled;
  bool get isSeeking => _seekingIndex != null;
  int? get seekingIndex => _seekingIndex;
  String? get seekError => _seekError;

  void toggleCc() {
    if (_isDisposed) return;
    _isCcEnabled = !_isCcEnabled;
    notifyListeners();
  }

  void setSeekHandler(Future<bool> Function(Duration)? handler) {
    if (_isDisposed) return;
    _seekHandler = handler;
    if (handler != null) {
      _seekHandlerReady?.complete(handler);
      _seekHandlerReady = null;
    }
  }

  void clearSeekError() {
    if (_isDisposed || _seekError == null) return;
    _seekError = null;
    notifyListeners();
  }

  Future<bool> seekToTranscriptLine(int index) async {
    if (_isDisposed || isSeeking || index < 0 || index >= transcriptLines.length) return false;
    final start = transcriptLines[index].start;
    if (start == null) return false;
    _seekingIndex = index;
    _seekError = null;
    notifyListeners();
    try {
      final handler =
          _seekHandler ??
          await (_seekHandlerReady ??= Completer<Future<bool> Function(Duration)?>()).future
              .timeout(const Duration(seconds: 10), onTimeout: () => null);
      if (_isDisposed) return false;
      final succeeded = handler != null && await handler(start);
      if (_isDisposed) return false;
      if (succeeded && identical(handler, _seekHandler)) return true;
      _seekError = AppStrings.trainingTranscriptSeekFailed;
      return false;
    } catch (_) {
      if (!_isDisposed) _seekError = AppStrings.trainingTranscriptSeekFailed;
      return false;
    } finally {
      if (!_isDisposed) {
        _seekingIndex = null;
        notifyListeners();
      }
    }
  }

  void updatePlaybackPosition(Duration position) {
    if (_isDisposed) return;
    final index = _transcript.activeLineAt(position);
    if (index == _activeTranscriptIndex) {
      return;
    }
    _activeTranscriptIndex = index;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _seekHandler = null;
    _seekHandlerReady?.complete(null);
    _seekHandlerReady = null;
    super.dispose();
  }
}
