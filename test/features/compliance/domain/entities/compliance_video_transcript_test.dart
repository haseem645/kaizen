// ignore_for_file: depend_on_referenced_packages

import 'package:sparrowkaizen/features/compliance/domain/entities/compliance_video_transcript.dart';
import 'package:test/test.dart';

void main() {
  test('keeps plain and HTML line breaks without inventing timestamps', () {
    final transcript = ComplianceVideoTranscript.parse(
      '<p>First &amp; second<br>Next line</p><div>Last line</div>',
    );

    expect(transcript.lines.map((line) => line.text), ['First & second', 'Next line', 'Last line']);
    expect(transcript.lines.every((line) => line.start == null), isTrue);
    expect(transcript.activeLineAt(const Duration(seconds: 10)), isNull);
  });

  test('selects the matching timestamp after playback, seeks, and replay', () {
    final transcript = ComplianceVideoTranscript.parse(
      '[00:02] Introduction\n[00:05] Main point\n[00:09] Summary',
    );

    expect(transcript.lines.map((line) => line.text), ['Introduction', 'Main point', 'Summary']);
    expect(transcript.activeLineAt(Duration.zero), isNull);
    expect(transcript.activeLineAt(const Duration(seconds: 2)), 0);
    expect(transcript.activeLineAt(const Duration(milliseconds: 4999)), 0);
    expect(transcript.activeLineAt(const Duration(seconds: 5)), 1);
    expect(transcript.activeLineAt(const Duration(seconds: 12)), 2);
    expect(transcript.activeLineAt(const Duration(seconds: 3)), 0);
    expect(transcript.activeLineAt(Duration.zero), isNull);
  });

  test('reads HTML timestamps and multiline cue text', () {
    final transcript = ComplianceVideoTranscript.parse(
      '<p><strong>[00:00]</strong> First line<br>Continued line</p>'
      '<p>[00:04] Next section</p>',
    );

    expect(transcript.lines.length, 2);
    expect(transcript.lines.first.text, 'First line\nContinued line');
    expect(transcript.lines.first.end, const Duration(seconds: 4));
    expect(transcript.activeLineAt(const Duration(seconds: 4)), 1);
  });

  test('reads SRT ranges and clears highlighting in gaps and at the end', () {
    final transcript = ComplianceVideoTranscript.parse(
      '1\r\n00:00:01,250 --> 00:00:02,750\r\nFirst line\r\n'
      'Continued line\r\n\r\n2\r\n00:00:04,000 --> 00:00:06,000\r\nLast line',
    );

    expect(transcript.lines.length, 2);
    expect(transcript.lines.first.text, 'First line\nContinued line');
    expect(transcript.activeLineAt(const Duration(milliseconds: 1249)), isNull);
    expect(transcript.activeLineAt(const Duration(milliseconds: 1250)), 0);
    expect(transcript.activeLineAt(const Duration(milliseconds: 2750)), isNull);
    expect(transcript.activeLineAt(const Duration(seconds: 4)), 1);
    expect(transcript.activeLineAt(const Duration(seconds: 6)), isNull);
  });

  test('reads WebVTT timestamps including hours and milliseconds', () {
    final transcript = ComplianceVideoTranscript.parse(
      'WEBVTT\n\n01:02:03.500 --> 01:02:08.000\nA later section',
    );

    expect(transcript.lines.single.text, 'A later section');
    expect(
      transcript.lines.single.start,
      const Duration(hours: 1, minutes: 2, seconds: 3, milliseconds: 500),
    );
    expect(transcript.activeLineAt(const Duration(hours: 1, minutes: 2, seconds: 4)), 0);
  });

  test('reads unbracketed timestamps and inline ranges', () {
    final transcript = ComplianceVideoTranscript.parse(
      '00:00 Opening\n[00:03 - 00:05] A short point\n00:07 Closing',
    );

    expect(transcript.lines.map((line) => line.text), ['Opening', 'A short point', 'Closing']);
    expect(transcript.activeLineAt(const Duration(seconds: 3)), 1);
    expect(transcript.activeLineAt(const Duration(seconds: 5)), isNull);
    expect(transcript.activeLineAt(const Duration(seconds: 7)), 2);
  });

  test('preserves malformed timestamps as readable text', () {
    final transcript = ComplianceVideoTranscript.parse('[00:99] Invalid time\nPlain text');

    expect(transcript.lines.first.text, '[00:99] Invalid time');
    expect(transcript.activeLineAt(const Duration(minutes: 2)), isNull);
  });

  test('empty transcripts have no rows or active line', () {
    for (final value in [null, '', '  \n ', '<p><br></p>']) {
      final transcript = ComplianceVideoTranscript.parse(value);
      expect(transcript.lines, isEmpty);
      expect(transcript.activeLineAt(Duration.zero), isNull);
    }
  });
}
