import 'package:flutter/material.dart';

import '../providers/kaizengram_chat_controller.dart';
import 'chat_mention_text.dart';

class ChatMentionTextEditingController extends TextEditingController {
  ChatMentionTextEditingController({
    required List<KaizengramChatUser> users,
    super.text,
  }) : _users = users;

  List<KaizengramChatUser> _users;

  set users(List<KaizengramChatUser> value) {
    _users = value;
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final resolvedStyle = style ?? const TextStyle();
    return TextSpan(
      style: resolvedStyle,
      children: buildChatMentionSpans(
        text: text,
        users: _users,
        defaultStyle: resolvedStyle,
      ),
    );
  }
}
