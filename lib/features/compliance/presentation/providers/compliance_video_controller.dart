import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/compliance_video_transcript.dart';

class ComplianceVideoController extends ChangeNotifier {
  ComplianceVideoController(String? transcript)
    : _transcript = ComplianceVideoTranscript.parse(transcript);

  final ComplianceVideoTranscript _transcript;
  int? _activeTranscriptIndex;
  Future<bool> Function(Duration)? _seekHandler;
  Completer<Future<bool> Function(Duration)?>? _seekHandlerReady;
  int? _seekingTranscriptIndex;
  String? _seekError;
  bool _isCcEnabled = false;
  bool _isDisposed = false;

  List<ComplianceTranscriptLine> get transcriptLines => _transcript.lines;
  int? get activeTranscriptIndex => _activeTranscriptIndex;
  int? get seekingTranscriptIndex => _seekingTranscriptIndex;
  bool get isSeeking => _seekingTranscriptIndex != null;
  String? get seekError => _seekError;
  bool get isCcEnabled => _isCcEnabled;
  ComplianceTranscriptLine? get activeTranscriptLine {
    final index = _activeTranscriptIndex;
    return index == null ? null : _transcript.lines[index];
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

  void toggleCc() {
    if (_isDisposed) return;
    _isCcEnabled = !_isCcEnabled;
    notifyListeners();
  }

  void setSeekHandler(Future<bool> Function(Duration)? handler) {
    if (_isDisposed) return;
    _seekHandler = handler;
    final pending = _seekHandlerReady;
    if (handler != null && pending != null && !pending.isCompleted) {
      pending.complete(handler);
    }
  }

  void clearSeekError() {
    if (_isDisposed || _seekError == null) return;
    _seekError = null;
    notifyListeners();
  }

  Future<Future<bool> Function(Duration)?> _waitForSeekHandler() async {
    if (_seekHandler != null) return _seekHandler;
    final pending = _seekHandlerReady ??= Completer<Future<bool> Function(Duration)?>();
    try {
      return await pending.future.timeout(const Duration(seconds: 10), onTimeout: () => null);
    } finally {
      if (identical(_seekHandlerReady, pending)) _seekHandlerReady = null;
    }
  }

  Future<bool> seekToTranscriptLine(int index) async {
    if (_isDisposed || isSeeking || index < 0 || index >= transcriptLines.length) {
      return false;
    }
    final position = transcriptLines[index].start;
    if (position == null) return false;

    _seekingTranscriptIndex = index;
    _seekError = null;
    notifyListeners();
    var didSeek = false;
    try {
      final handler = await _waitForSeekHandler();
      if (_isDisposed || handler == null) return false;
      didSeek = await handler(position);
      didSeek = didSeek && !_isDisposed && handler == _seekHandler;
      return didSeek;
    } catch (_) {
      return false;
    } finally {
      if (!_isDisposed) {
        _seekingTranscriptIndex = null;
        if (!didSeek) _seekError = AppStrings.trainingTranscriptSeekFailed;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _seekHandler = null;
    final pending = _seekHandlerReady;
    if (pending != null && !pending.isCompleted) pending.complete(null);
    _seekHandlerReady = null;
    super.dispose();
  }
}
