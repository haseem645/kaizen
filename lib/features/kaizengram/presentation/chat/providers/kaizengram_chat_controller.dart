import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../chat_strings.dart';

////
class KaizengramChatController extends ChangeNotifier {
  KaizengramChatController() {
    _currentUser = const KaizengramChatUser(
      name: KaizengramChatStrings.userYouName,
      email: KaizengramChatStrings.userYouEmail,
    );
    _users = <KaizengramChatUser>[
      _currentUser,
      const KaizengramChatUser(
        name: KaizengramChatStrings.userOliviaName,
        email: KaizengramChatStrings.userOliviaEmail,
      ),
      const KaizengramChatUser(
        name: KaizengramChatStrings.userMarcusName,
        email: KaizengramChatStrings.userMarcusEmail,
      ),
      const KaizengramChatUser(
        name: KaizengramChatStrings.userNinaName,
        email: KaizengramChatStrings.userNinaEmail,
      ),
      const KaizengramChatUser(
        name: KaizengramChatStrings.userChrisName,
        email: KaizengramChatStrings.userChrisEmail,
      ),
      const KaizengramChatUser(
        name: KaizengramChatStrings.userBotName,
        email: KaizengramChatStrings.userBotEmail,
      ),
    ];
    _channels = <String>[
      KaizengramChatStrings.channelGeneral,
      KaizengramChatStrings.channelAnnouncements,
      KaizengramChatStrings.channelWins,
    ];
    _channelMemberEmailsByChannel = <String, List<String>>{
      KaizengramChatStrings.channelGeneral: <String>[
        KaizengramChatStrings.userYouEmail,
        KaizengramChatStrings.userOliviaEmail,
        KaizengramChatStrings.userMarcusEmail,
        KaizengramChatStrings.userNinaEmail,
        KaizengramChatStrings.userChrisEmail,
      ],
      KaizengramChatStrings.channelAnnouncements: <String>[
        KaizengramChatStrings.userYouEmail,
        KaizengramChatStrings.userOliviaEmail,
        KaizengramChatStrings.userBotEmail,
      ],
      KaizengramChatStrings.channelWins: <String>[
        KaizengramChatStrings.userYouEmail,
        KaizengramChatStrings.userNinaEmail,
        KaizengramChatStrings.userChrisEmail,
      ],
    };
    _directMessageEmails = <String>[KaizengramChatStrings.userOliviaEmail];
    _messagesByConversation = <String, List<KaizengramChatMessage>>{
      _channelConversationKey(KaizengramChatStrings.channelGeneral): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'general-1',
          sender: _userByEmail(KaizengramChatStrings.userOliviaEmail),
          message: KaizengramChatStrings.generalMessageOne,
        ),
        KaizengramChatMessage(
          id: 'general-2',
          sender: _userByEmail(KaizengramChatStrings.userMarcusEmail),
          message: KaizengramChatStrings.generalMessageTwo,
        ),
        KaizengramChatMessage(
          id: 'general-3',
          sender: _userByEmail(KaizengramChatStrings.userNinaEmail),
          message: KaizengramChatStrings.generalMessageThree,
        ),
        KaizengramChatMessage(
          id: 'general-4',
          sender: _userByEmail(KaizengramChatStrings.userChrisEmail),
          message: KaizengramChatStrings.generalMessageFour,
        ),
        KaizengramChatMessage(
          id: 'general-5',
          sender: _userByEmail(KaizengramChatStrings.userYouEmail),
          message: KaizengramChatStrings.generalMessageFive,
        ),
        KaizengramChatMessage(
          id: 'general-6',
          sender: _userByEmail(KaizengramChatStrings.userOliviaEmail),
          message: KaizengramChatStrings.generalMessageSix,
        ),
        KaizengramChatMessage(
          id: 'general-7',
          sender: _userByEmail(KaizengramChatStrings.userMarcusEmail),
          message: KaizengramChatStrings.generalMessageSeven,
        ),
        KaizengramChatMessage(
          id: 'general-8',
          sender: _userByEmail(KaizengramChatStrings.userYouEmail),
          message: KaizengramChatStrings.generalMessageEight,
        ),
      ],
      _channelConversationKey(KaizengramChatStrings.channelAnnouncements): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'announcements-1',
          sender: _userByEmail(KaizengramChatStrings.userBotEmail),
          message: KaizengramChatStrings.announcementsMessage,
        ),
      ],
      _channelConversationKey(KaizengramChatStrings.channelWins): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'wins-1',
          sender: _userByEmail(KaizengramChatStrings.userNinaEmail),
          message: KaizengramChatStrings.winsMessage,
        ),
      ],
      _directConversationKey(KaizengramChatStrings.userOliviaEmail): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'dm-olivia-1',
          sender: _userByEmail(KaizengramChatStrings.userOliviaEmail),
          message: KaizengramChatStrings.directMessageOlivia,
        ),
      ],
      _directConversationKey(KaizengramChatStrings.userMarcusEmail): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'dm-marcus-1',
          sender: _userByEmail(KaizengramChatStrings.userMarcusEmail),
          message: KaizengramChatStrings.directMessageMarcus,
        ),
      ],
      _directConversationKey(KaizengramChatStrings.userNinaEmail): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'dm-nina-1',
          sender: _userByEmail(KaizengramChatStrings.userNinaEmail),
          message: KaizengramChatStrings.directMessageNina,
        ),
      ],
    };
  }

  static const int maxMessageMediaCount = 3;

  late final List<KaizengramChatUser> _users;
  final ImagePicker _imagePicker = ImagePicker();
  late final KaizengramChatUser _currentUser;
  late final List<String> _channels;
  late final Map<String, List<String>> _channelMemberEmailsByChannel;
  late final List<String> _directMessageEmails;
  late final Map<String, List<KaizengramChatMessage>> _messagesByConversation;
  KaizengramChatConversationTarget? _selectedConversation;
  String _draftMessage = '';
  List<KaizengramChatMediaAttachment> _draftAttachments = <KaizengramChatMediaAttachment>[];
  bool _isPickingDraftMedia = false;
  int _messageVersion = 0;
  KaizengramChatMessage? _replyingTo;

  List<KaizengramChatUser> get users => List<KaizengramChatUser>.unmodifiable(_users);
  List<String> get channels => List<String>.unmodifiable(_channels);
  List<KaizengramChatUser> get currentChannelUsers {
    final channelName = activeChannelName;
    if (channelName == null) {
      return const <KaizengramChatUser>[];
    }

    final channelMemberEmails = _channelMemberEmailsByChannel[channelName] ?? const <String>[];
    return List<KaizengramChatUser>.unmodifiable(
      channelMemberEmails.map(_userByEmail).toList(growable: false),
    );
  }

  List<KaizengramChatUser> get directMessageUsers => List<KaizengramChatUser>.unmodifiable(
    _directMessageEmails.map(_userByEmail).toList(growable: false),
  );
  List<KaizengramChatUser> get directMessageCandidates => List<KaizengramChatUser>.unmodifiable(
    _users
        .where(_canStartDirectMessageWith)
        .where((user) => !_directMessageEmails.contains(user.email))
        .toList(growable: false),
  );
  String get draftMessage => _draftMessage;
  List<KaizengramChatMediaAttachment> get draftAttachments =>
      List<KaizengramChatMediaAttachment>.unmodifiable(_draftAttachments);
  bool get isPickingDraftMedia => _isPickingDraftMedia;
  int get messageVersion => _messageVersion;
  bool get hasDraftMedia => _draftAttachments.isNotEmpty;
  bool get canAddMoreDraftMedia => _draftAttachments.length < maxMessageMediaCount;
  bool get canSendMessage => _draftMessage.trim().isNotEmpty || hasDraftMedia;
  KaizengramChatUser get currentUser => _currentUser;
  KaizengramChatMessage? get replyingTo => _replyingTo;
  bool get hasSelectedConversation => _selectedConversation != null;
  KaizengramChatConversationType? get currentConversationType => _selectedConversation?.type;
  bool get isCurrentConversationChannel =>
      currentConversationType == KaizengramChatConversationType.channel;
  bool get canDeleteCurrentChannel => isCurrentConversationChannel && _channels.length > 1;
  String? get activeChannelName =>
      _selectedConversation?.type == KaizengramChatConversationType.channel
      ? _selectedConversation!.id
      : null;
  KaizengramChatUser? get activeDirectMessageUser =>
      _selectedConversation?.type == KaizengramChatConversationType.directMessage
      ? _userByEmail(_selectedConversation!.id)
      : null;
  String get currentConversationTitle {
    final channelName = activeChannelName;
    if (channelName != null) {
      return channelName;
    }

    return activeDirectMessageUser?.name ?? '';
  }

  String get currentConversationLabel {
    switch (currentConversationType) {
      case KaizengramChatConversationType.channel:
        return KaizengramChatStrings.channelLabel;
      case KaizengramChatConversationType.directMessage:
        return KaizengramChatStrings.directMessageLabel;
      case null:
        return KaizengramChatStrings.conversationLabel;
    }
  }

  List<KaizengramChatMessage> get messages => List<KaizengramChatMessage>.unmodifiable(
    _messagesByConversation[_selectedConversation?.key] ?? const <KaizengramChatMessage>[],
  );

  bool isOwnMessage(KaizengramChatMessage message) {
    return message.sender.email == _currentUser.email;
  }

  bool isChannelSelected(String channelName) {
    final selectedConversation = _selectedConversation;
    return selectedConversation?.type == KaizengramChatConversationType.channel &&
        selectedConversation?.id == channelName;
  }

  bool isDirectMessageSelected(String email) {
    final selectedConversation = _selectedConversation;
    return selectedConversation?.type == KaizengramChatConversationType.directMessage &&
        selectedConversation?.id == email;
  }

  List<KaizengramChatUser> mentionSuggestions(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    if (normalizedQuery.isEmpty) {
      return List<KaizengramChatUser>.unmodifiable(_users);
    }

    return List<KaizengramChatUser>.unmodifiable(
      _users.where((user) {
        final lowerName = user.name.toLowerCase();
        final lowerEmail = user.email.toLowerCase();
        return lowerName.contains(normalizedQuery) || lowerEmail.contains(normalizedQuery);
      }),
    );
  }

  void updateDraftMessage(String value) {
    if (_draftMessage == value) {
      return;
    }

    _draftMessage = value;
    notifyListeners();
  }

  Future<KaizengramChatDraftMediaPickResult> pickDraftMedia() async {
    if (isPickingDraftMedia) {
      return KaizengramChatDraftMediaPickResult.cancelled;
    }

    final availableSlots = maxMessageMediaCount - _draftAttachments.length;
    if (availableSlots <= 0) {
      return KaizengramChatDraftMediaPickResult.limitReached;
    }

    _isPickingDraftMedia = true;
    notifyListeners();

    try {
      final List<XFile> pickedMedia;
      if (availableSlots == 1) {
        final pickedSingleMedia = await _imagePicker.pickMedia(imageQuality: 85);
        pickedMedia = pickedSingleMedia == null ? <XFile>[] : <XFile>[pickedSingleMedia];
      } else {
        pickedMedia = await _imagePicker.pickMultipleMedia(imageQuality: 85, limit: availableSlots);
      }
      if (pickedMedia.isEmpty) {
        return KaizengramChatDraftMediaPickResult.cancelled;
      }

      final existingPaths = _draftAttachments.map((attachment) => attachment.path).toSet();
      final nextAttachments = pickedMedia
          .map((file) => KaizengramChatMediaAttachment.fromPath(file.path))
          .where(
            (attachment) => attachment.path.isNotEmpty && !existingPaths.contains(attachment.path),
          )
          .take(availableSlots)
          .toList(growable: false);
      if (nextAttachments.isEmpty) {
        return KaizengramChatDraftMediaPickResult.cancelled;
      }

      _draftAttachments = <KaizengramChatMediaAttachment>[..._draftAttachments, ...nextAttachments];
      notifyListeners();
      return KaizengramChatDraftMediaPickResult.selected;
    } catch (_) {
      return KaizengramChatDraftMediaPickResult.failed;
    } finally {
      _isPickingDraftMedia = false;
      notifyListeners();
    }
  }

  void removeDraftMedia(String mediaPath) {
    final normalizedPath = mediaPath.trim();
    if (normalizedPath.isEmpty) {
      return;
    }

    final nextAttachments = _draftAttachments
        .where((attachment) => attachment.path != normalizedPath)
        .toList(growable: false);
    if (nextAttachments.length == _draftAttachments.length) {
      return;
    }

    _draftAttachments = nextAttachments;
    notifyListeners();
  }

  void selectChannel(String channelName) {
    if (!_channels.contains(channelName)) {
      return;
    }

    _selectConversation(KaizengramChatConversationTarget.channel(channelName));
  }

  void openDirectMessage(String userEmail) {
    final normalizedEmail = userEmail.trim().toLowerCase();
    if (!_canStartDirectMessageWithEmail(normalizedEmail)) {
      return;
    }

    if (!_directMessageEmails.contains(normalizedEmail)) {
      _directMessageEmails.add(normalizedEmail);
      _messagesByConversation.putIfAbsent(
        _directConversationKey(normalizedEmail),
        () => <KaizengramChatMessage>[],
      );
    }

    _selectConversation(KaizengramChatConversationTarget.directMessage(normalizedEmail));
  }

  String? validateChannelName(String rawName) {
    final channelName = _normalizedChannelName(rawName);
    if (channelName.isEmpty) {
      return KaizengramChatStrings.emptyChannelNameError;
    }
    if (_channels.contains(channelName)) {
      return KaizengramChatStrings.duplicateChannelNameError;
    }

    return null;
  }

  String? validateUserEmail(String rawEmail) {
    final email = rawEmail.trim().toLowerCase();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return KaizengramChatStrings.invalidEmailError;
    }
    if (_users.any((user) => user.email.toLowerCase() == email)) {
      return KaizengramChatStrings.duplicateUserError;
    }

    return null;
  }

  String? validateUserEmailForCurrentChannel(String rawEmail) {
    final email = rawEmail.trim().toLowerCase();
    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    if (!emailRegex.hasMatch(email)) {
      return KaizengramChatStrings.invalidEmailError;
    }

    final channelName = activeChannelName;
    if (channelName == null) {
      return KaizengramChatStrings.noActiveChannelError;
    }

    final channelMemberEmails = _channelMemberEmailsByChannel[channelName] ?? const <String>[];
    if (channelMemberEmails.contains(email)) {
      return KaizengramChatStrings.duplicateChannelUserError;
    }

    return null;
  }

  String createChannel(String rawName) {
    final validationMessage = validateChannelName(rawName);
    if (validationMessage != null) {
      return '';
    }

    final channelName = _normalizedChannelName(rawName);
    _channels.add(channelName);
    _channelMemberEmailsByChannel[channelName] = <String>[_currentUser.email];
    _messagesByConversation[_channelConversationKey(channelName)] = <KaizengramChatMessage>[
      KaizengramChatMessage(
        id: '$channelName-1',
        sender: _userByEmail(KaizengramChatStrings.userBotEmail),
        message: KaizengramChatStrings.createdChannelMessage(channelName),
      ),
    ];
    notifyListeners();
    return channelName;
  }

  bool deleteCurrentChannel() {
    final channelName = activeChannelName;
    if (channelName == null) {
      return false;
    }

    return deleteChannel(channelName);
  }

  bool deleteChannel(String channelName) {
    if (_channels.length <= 1 || !_channels.contains(channelName)) {
      return false;
    }

    final deletedChannel = channelName;
    _channels.remove(deletedChannel);
    _channelMemberEmailsByChannel.remove(deletedChannel);
    _messagesByConversation.remove(_channelConversationKey(deletedChannel));

    if (isChannelSelected(deletedChannel)) {
      _selectedConversation = null;
      _clearDraftState();
    }

    _messageVersion++;
    notifyListeners();
    return true;
  }

  void startReply(KaizengramChatMessage message) {
    _replyingTo = message;
    notifyListeners();
  }

  void cancelReply() {
    if (_replyingTo == null) {
      return;
    }

    _replyingTo = null;
    notifyListeners();
  }

  bool sendMessage() {
    final conversationKey = _selectedConversation?.key;
    final trimmedMessage = _draftMessage.trim();
    final attachments = List<KaizengramChatMediaAttachment>.unmodifiable(_draftAttachments);
    if (conversationKey == null || (trimmedMessage.isEmpty && attachments.isEmpty)) {
      return false;
    }

    final conversationMessages = _messagesByConversation.putIfAbsent(
      conversationKey,
      () => <KaizengramChatMessage>[],
    );
    conversationMessages.add(
      KaizengramChatMessage(
        id: '$conversationKey-${DateTime.now().microsecondsSinceEpoch}',
        sender: _currentUser,
        message: trimmedMessage,
        attachments: attachments,
        replyTo: _replyingTo == null
            ? null
            : KaizengramChatReplyPreview(
                messageId: _replyingTo!.id,
                senderName: _replyingTo!.sender.name,
                message: _replyingTo!.previewText,
              ),
      ),
    );
    _clearDraftState();
    _messageVersion++;
    notifyListeners();
    return true;
  }

  String addUserToCurrentChannel(String rawEmail) {
    final validationMessage = validateUserEmailForCurrentChannel(rawEmail);
    if (validationMessage != null) {
      return '';
    }

    final channelName = activeChannelName;
    if (channelName == null) {
      return '';
    }

    final email = rawEmail.trim().toLowerCase();
    if (!_users.any((user) => user.email == email)) {
      final localPart = email.split('@').first;
      final user = KaizengramChatUser(name: _displayNameFromEmail(localPart), email: email);
      _users.add(user);
    }

    final channelMemberEmails = _channelMemberEmailsByChannel.putIfAbsent(
      channelName,
      () => <String>[_currentUser.email],
    );
    channelMemberEmails.insert(0, email);
    notifyListeners();
    return email;
  }

  bool removeUserFromCurrentChannel(KaizengramChatUser user) {
    final channelName = activeChannelName;
    if (channelName == null || user.email == _currentUser.email) {
      return false;
    }

    final channelMemberEmails = _channelMemberEmailsByChannel[channelName];
    if (channelMemberEmails == null) {
      return false;
    }

    final didRemove = channelMemberEmails.remove(user.email);
    if (didRemove) {
      notifyListeners();
    }
    return didRemove;
  }

  KaizengramChatUser _userByEmail(String email) {
    return _users.firstWhere((user) => user.email == email);
  }

  bool _canStartDirectMessageWith(KaizengramChatUser user) {
    return _canStartDirectMessageWithEmail(user.email);
  }

  bool _canStartDirectMessageWithEmail(String email) {
    return email != _currentUser.email &&
        email != KaizengramChatStrings.userBotEmail &&
        _users.any((user) => user.email == email);
  }

  void _selectConversation(KaizengramChatConversationTarget target) {
    if (_selectedConversation == target) {
      return;
    }

    _selectedConversation = target;
    _clearDraftState();
    _messageVersion++;
    notifyListeners();
  }

  void _clearDraftState() {
    _draftMessage = '';
    _draftAttachments = <KaizengramChatMediaAttachment>[];
    _replyingTo = null;
  }

  String _normalizedChannelName(String rawName) {
    final normalized = rawName
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-{2,}'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return normalized;
  }

  String _displayNameFromEmail(String localPart) {
    return localPart
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => '${part.substring(0, 1).toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _channelConversationKey(String channelName) {
    return 'channel:$channelName';
  }

  String _directConversationKey(String email) {
    return 'direct:$email';
  }
}

enum KaizengramChatConversationType { channel, directMessage }

class KaizengramChatConversationTarget {
  const KaizengramChatConversationTarget._({required this.type, required this.id});

  const KaizengramChatConversationTarget.channel(String channelName)
    : this._(type: KaizengramChatConversationType.channel, id: channelName);

  const KaizengramChatConversationTarget.directMessage(String email)
    : this._(type: KaizengramChatConversationType.directMessage, id: email);

  final KaizengramChatConversationType type;
  final String id;

  String get key {
    switch (type) {
      case KaizengramChatConversationType.channel:
        return 'channel:$id';
      case KaizengramChatConversationType.directMessage:
        return 'direct:$id';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is KaizengramChatConversationTarget && other.type == type && other.id == id;
  }

  @override
  int get hashCode => Object.hash(type, id);
}

class KaizengramChatUser {
  const KaizengramChatUser({required this.name, required this.email});

  final String name;
  final String email;
}

enum KaizengramChatMediaType { image, video }

class KaizengramChatMediaAttachment {
  const KaizengramChatMediaAttachment({required this.path, required this.type});

  factory KaizengramChatMediaAttachment.fromPath(String rawPath) {
    final normalizedPath = rawPath.trim();
    return KaizengramChatMediaAttachment(
      path: normalizedPath,
      type: _isKaizengramChatVideoPath(normalizedPath)
          ? KaizengramChatMediaType.video
          : KaizengramChatMediaType.image,
    );
  }

  final String path;
  final KaizengramChatMediaType type;

  bool get isImage => type == KaizengramChatMediaType.image;
  bool get isVideo => type == KaizengramChatMediaType.video;
}

class KaizengramChatMessage {
  const KaizengramChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    this.attachments = const <KaizengramChatMediaAttachment>[],
    this.replyTo,
  });

  final String id;
  final KaizengramChatUser sender;
  final String message;
  final List<KaizengramChatMediaAttachment> attachments;
  final KaizengramChatReplyPreview? replyTo;

  bool get hasText => message.trim().isNotEmpty;
  bool get hasMedia => attachments.isNotEmpty;
  bool get hasImage => attachments.any((attachment) => attachment.isImage);
  bool get hasVideo => attachments.any((attachment) => attachment.isVideo);
  String get previewText => hasText
      ? message
      : attachments.length > 1
      ? KaizengramChatStrings.mediaMessageLabel
      : hasVideo
      ? KaizengramChatStrings.videoMessageLabel
      : KaizengramChatStrings.photoMessageLabel;
}

class KaizengramChatReplyPreview {
  const KaizengramChatReplyPreview({
    required this.messageId,
    required this.senderName,
    required this.message,
  });

  final String messageId;
  final String senderName;
  final String message;
}

enum KaizengramChatDraftMediaPickResult { selected, cancelled, failed, limitReached }

bool _isKaizengramChatVideoPath(String path) {
  final normalizedPath = path.trim().toLowerCase();
  return normalizedPath.endsWith('.mp4') ||
      normalizedPath.endsWith('.mov') ||
      normalizedPath.endsWith('.m4v') ||
      normalizedPath.endsWith('.avi') ||
      normalizedPath.endsWith('.webm') ||
      normalizedPath.endsWith('.mkv') ||
      normalizedPath.endsWith('.3gp');
}
