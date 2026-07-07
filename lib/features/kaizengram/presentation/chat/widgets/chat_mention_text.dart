import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';
import '../providers/kaizengram_chat_controller.dart';

class ChatMentionText extends StatelessWidget {
  const ChatMentionText({
    super.key,
    required this.text,
    required this.users,
    required this.defaultStyle,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String text;
  final List<KaizengramChatUser> users;
  final TextStyle defaultStyle;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: maxLines,
      overflow: overflow ?? TextOverflow.clip,
      textAlign: textAlign ?? TextAlign.start,
      text: TextSpan(
        style: defaultStyle,
        children: buildChatMentionSpans(
          text: text,
          users: users,
          defaultStyle: defaultStyle,
        ),
      ),
    );
  }
}

List<InlineSpan> buildChatMentionSpans({
  required String text,
  required List<KaizengramChatUser> users,
  required TextStyle defaultStyle,
}) {
  if (text.isEmpty) {
    return <InlineSpan>[TextSpan(text: text, style: defaultStyle)];
  }

  final spans = <InlineSpan>[];
  final sortedNames =
      users
          .map((user) => user.name.trim())
          .where((name) => name.isNotEmpty)
          .toSet()
          .toList(growable: false)
        ..sort((a, b) => b.length.compareTo(a.length));
  final lowerText = text.toLowerCase();
  var cursor = 0;
  var plainBuffer = StringBuffer();

  while (cursor < text.length) {
    String? mentionLabel;
    if (text[cursor] == '@') {
      for (final name in sortedNames) {
        final token = '@$name';
        final lowerToken = token.toLowerCase();
        if (lowerText.startsWith(lowerToken, cursor) &&
            _hasMentionBoundary(text, cursor + token.length)) {
          mentionLabel = text.substring(cursor, cursor + token.length);
          break;
        }
      }
    }

    if (mentionLabel != null) {
      if (plainBuffer.isNotEmpty) {
        spans.add(TextSpan(text: plainBuffer.toString(), style: defaultStyle));
        plainBuffer = StringBuffer();
      }
      spans.add(
        TextSpan(
          text: mentionLabel,
          style: defaultStyle.copyWith(
            color: AppColors.blue,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
      cursor += mentionLabel.length;
      continue;
    }

    plainBuffer.write(text[cursor]);
    cursor++;
  }

  if (plainBuffer.isNotEmpty || spans.isEmpty) {
    spans.add(TextSpan(text: plainBuffer.toString(), style: defaultStyle));
  }

  return spans;
}

bool _hasMentionBoundary(String text, int index) {
  if (index >= text.length) {
    return true;
  }

  const boundaryCharacters = <String>{
    ' ',
    '\n',
    '\t',
    '.',
    ',',
    '!',
    '?',
    ':',
    ';',
    ')',
    ']',
  };

  return boundaryCharacters.contains(text[index]);
}
