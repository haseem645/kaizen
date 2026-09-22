import 'package:flutter/foundation.dart';

import '../../domain/entities/compliance_video_transcript.dart';

class ComplianceVideoController extends ChangeNotifier {
  ComplianceVideoController(String? transcript)
    : _transcript = ComplianceVideoTranscript.parse(transcript);

  final ComplianceVideoTranscript _transcript;
  int? _activeTranscriptIndex;

  List<ComplianceTranscriptLine> get transcriptLines => _transcript.lines;
  int? get activeTranscriptIndex => _activeTranscriptIndex;

  void updatePlaybackPosition(Duration position) {
    final index = _transcript.activeLineAt(position);
    if (index == _activeTranscriptIndex) {
      return;
    }
    _activeTranscriptIndex = index;
    notifyListeners();
  }
}
