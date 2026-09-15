class ComplianceTranscriptLine {
  const ComplianceTranscriptLine({required this.text, this.start, this.end});

  final String text;
  final Duration? start;
  final Duration? end;
}

class ComplianceVideoTranscript {
  const ComplianceVideoTranscript._(this.lines);

  final List<ComplianceTranscriptLine> lines;

  static const _timestamp = r'\d+:\d{2}(?::\d{2})?(?:[.,]\d{1,3})?';
  static final _timingPattern = RegExp(
    '^\\s*[\\[(]?($_timestamp)[\\])]?\\s*'
    '(?:(?:-->|[-–—])\\s*[\\[(]?($_timestamp)[\\])]?)?\\s*(.*)\$',
  );

  factory ComplianceVideoTranscript.parse(String? value) {
    final text = (value ?? '')
        .replaceAll(RegExp(r'<br\b[^>]*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</(?:p|div|li)>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('\r\n', '\n')
        .replaceAll('\r', '\n')
        .trim();
    final sourceLines = text.split('\n');
    final parsed = <ComplianceTranscriptLine>[];
    var content = <String>[];
    Duration? start;
    Duration? end;

    void addTimedLine() {
      if (content.isNotEmpty) {
        parsed.add(ComplianceTranscriptLine(text: content.join('\n'), start: start, end: end));
      }
      content = <String>[];
    }

    for (var index = 0; index < sourceLines.length; index++) {
      final line = sourceLines[index].trim();
      if (line.isEmpty || line.startsWith('WEBVTT')) {
        continue;
      }
      // SRT cue numbers are metadata, not transcript content.
      if (RegExp(r'^\d+$').hasMatch(line) &&
          index + 1 < sourceLines.length &&
          _timingPattern.hasMatch(sourceLines[index + 1])) {
        continue;
      }

      final timing = _timingPattern.firstMatch(line);
      final lineStart = timing == null ? null : _parseTimestamp(timing.group(1)!);
      if (timing != null && lineStart != null) {
        addTimedLine();
        start = lineStart;
        end = timing.group(2) == null ? null : _parseTimestamp(timing.group(2)!);
        final lineText = timing.group(3)!.trim();
        if (lineText.isNotEmpty) {
          content.add(lineText);
        }
      } else if (start != null) {
        content.add(line);
      } else {
        parsed.add(ComplianceTranscriptLine(text: line));
      }
    }
    addTimedLine();

    return ComplianceVideoTranscript._(
      List<ComplianceTranscriptLine>.unmodifiable([
        for (var index = 0; index < parsed.length; index++)
          ComplianceTranscriptLine(
            text: parsed[index].text,
            start: parsed[index].start,
            end:
                parsed[index].end ??
                (parsed[index].start != null && index + 1 < parsed.length
                    ? parsed[index + 1].start
                    : null),
          ),
      ]),
    );
  }

  int? activeLineAt(Duration position) {
    for (var index = lines.length - 1; index >= 0; index--) {
      final line = lines[index];
      final start = line.start;
      if (start != null && position >= start && (line.end == null || position < line.end!)) {
        return index;
      }
    }
    return null;
  }

  static Duration? _parseTimestamp(String value) {
    final parts = value.replaceAll(',', '.').split(':');
    final seconds = double.tryParse(parts.last);
    final minutes = int.tryParse(parts[parts.length - 2]);
    final hours = parts.length == 3 ? int.tryParse(parts.first) : 0;
    if (seconds == null ||
        minutes == null ||
        hours == null ||
        seconds >= 60 ||
        (parts.length == 3 && minutes >= 60)) {
      return null;
    }
    return Duration(hours: hours, minutes: minutes, milliseconds: (seconds * 1000).round());
  }
}
