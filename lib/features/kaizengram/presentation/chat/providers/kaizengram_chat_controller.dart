import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../kaizengram_message_attachment.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';

class KaizengramChatController extends ChangeNotifier {
  KaizengramChatController() {
    _currentUser = const KaizengramChatUser(
      name: AppStrings.userYouName,
      email: AppStrings.userYouEmail,
    );
    _users = <KaizengramChatUser>[
      _currentUser,
      const KaizengramChatUser(
        name: AppStrings.userOliviaName,
        email: AppStrings.userOliviaEmail,
      ),
      const KaizengramChatUser(
        name: AppStrings.userMarcusName,
        email: AppStrings.userMarcusEmail,
      ),
      const KaizengramChatUser(
        name: AppStrings.userNinaName,
        email: AppStrings.userNinaEmail,
      ),
      const KaizengramChatUser(
        name: AppStrings.userChrisName,
        email: AppStrings.userChrisEmail,
      ),
      const KaizengramChatUser(
        name: AppStrings.userAishaName,
        email: AppStrings.userAishaEmail,
      ),
      const KaizengramChatUser(
        name: AppStrings.userDanielName,
        email: AppStrings.userDanielEmail,
      ),
      const KaizengramChatUser(
        name: AppStrings.userFatimaName,
        email: AppStrings.userFatimaEmail,
      ),
      const KaizengramChatUser(
        name: AppStrings.userLiamName,
        email: AppStrings.userLiamEmail,
      ),
      const KaizengramChatUser(
        name: AppStrings.userEmmaName,
        email: AppStrings.userEmmaEmail,
      ),
      const KaizengramChatUser(
        name: AppStrings.userBotName,
        email: AppStrings.userBotEmail,
      ),
    ];
    _channels = <KaizengramChatChannel>[
      const KaizengramChatChannel(
        name: AppStrings.channelGeneral,
        imagePath:
            'https://images.unsplash.com/photo-1521737604893-d14cc237f11d?auto=format&fit=crop&w=400&q=80',
      ),
      const KaizengramChatChannel(
        name: AppStrings.channelAnnouncements,
        imagePath:
            'https://images.unsplash.com/photo-1517048676732-d65bc937f952?auto=format&fit=crop&w=400&q=80',
      ),
      const KaizengramChatChannel(
        name: AppStrings.channelWins,
        imagePath:
            'https://images.unsplash.com/photo-1552664730-d307ca884978?auto=format&fit=crop&w=400&q=80',
      ),
      const KaizengramChatChannel(
        name: AppStrings.channelCoaching,
        imagePath:
            'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=400&q=80',
      ),
      const KaizengramChatChannel(
        name: AppStrings.channelTrainingHub,
        imagePath:
            'https://images.unsplash.com/photo-1504384308090-c894fdcc538d?auto=format&fit=crop&w=400&q=80',
      ),
      const KaizengramChatChannel(
        name: AppStrings.channelQaReview,
        imagePath:
            'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?auto=format&fit=crop&w=400&q=80',
      ),
    ];
    _channelMemberEmailsByChannel = <String, List<String>>{
      AppStrings.channelGeneral: <String>[
        AppStrings.userYouEmail,
        AppStrings.userOliviaEmail,
        AppStrings.userMarcusEmail,
        AppStrings.userNinaEmail,
        AppStrings.userChrisEmail,
      ],
      AppStrings.channelAnnouncements: <String>[
        AppStrings.userYouEmail,
        AppStrings.userOliviaEmail,
        AppStrings.userBotEmail,
      ],
      AppStrings.channelWins: <String>[
        AppStrings.userYouEmail,
        AppStrings.userNinaEmail,
        AppStrings.userChrisEmail,
      ],
      AppStrings.channelCoaching: <String>[
        AppStrings.userYouEmail,
        AppStrings.userOliviaEmail,
        AppStrings.userNinaEmail,
      ],
      AppStrings.channelTrainingHub: <String>[
        AppStrings.userYouEmail,
        AppStrings.userMarcusEmail,
        AppStrings.userChrisEmail,
      ],
      AppStrings.channelQaReview: <String>[
        AppStrings.userYouEmail,
        AppStrings.userOliviaEmail,
        AppStrings.userBotEmail,
      ],
    };
    _directMessageEmails = <String>[AppStrings.userOliviaEmail];
    _messagesByConversation = <String, List<KaizengramChatMessage>>{
      _channelConversationKey(
        AppStrings.channelGeneral,
      ): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'general-1',
          sender: _userByEmail(AppStrings.userOliviaEmail),
          message: AppStrings.generalMessageOne,
        ),
        KaizengramChatMessage(
          id: 'general-2',
          sender: _userByEmail(AppStrings.userMarcusEmail),
          message: AppStrings.generalMessageTwo,
        ),
        KaizengramChatMessage(
          id: 'general-3',
          sender: _userByEmail(AppStrings.userNinaEmail),
          message: AppStrings.generalMessageThree,
        ),
        KaizengramChatMessage(
          id: 'general-4',
          sender: _userByEmail(AppStrings.userChrisEmail),
          message: AppStrings.generalMessageFour,
        ),
        KaizengramChatMessage(
          id: 'general-5',
          sender: _userByEmail(AppStrings.userYouEmail),
          message: AppStrings.generalMessageFive,
        ),
        KaizengramChatMessage(
          id: 'general-6',
          sender: _userByEmail(AppStrings.userOliviaEmail),
          message: AppStrings.generalMessageSix,
        ),
        KaizengramChatMessage(
          id: 'general-7',
          sender: _userByEmail(AppStrings.userMarcusEmail),
          message: AppStrings.generalMessageSeven,
        ),
        KaizengramChatMessage(
          id: 'general-8',
          sender: _userByEmail(AppStrings.userYouEmail),
          message: AppStrings.generalMessageEight,
        ),
      ],
      _channelConversationKey(
        AppStrings.channelAnnouncements,
      ): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'announcements-1',
          sender: _userByEmail(AppStrings.userBotEmail),
          message: AppStrings.announcementsMessage,
        ),
      ],
      _channelConversationKey(AppStrings.channelWins): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'wins-1',
          sender: _userByEmail(AppStrings.userNinaEmail),
          message: AppStrings.winsMessage,
        ),
      ],
      _channelConversationKey(
        AppStrings.channelCoaching,
      ): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'coaching-1',
          sender: _userByEmail(AppStrings.userOliviaEmail),
          message: AppStrings.coachingMessage,
        ),
      ],
      _channelConversationKey(
        AppStrings.channelTrainingHub,
      ): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'training-hub-1',
          sender: _userByEmail(AppStrings.userMarcusEmail),
          message: AppStrings.trainingHubMessage,
        ),
      ],
      _channelConversationKey(
        AppStrings.channelQaReview,
      ): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'qa-review-1',
          sender: _userByEmail(AppStrings.userBotEmail),
          message: AppStrings.qaReviewMessage,
        ),
      ],
      _directConversationKey(
        AppStrings.userOliviaEmail,
      ): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'dm-olivia-1',
          sender: _userByEmail(AppStrings.userOliviaEmail),
          message: AppStrings.directMessageOlivia,
        ),
      ],
      _directConversationKey(
        AppStrings.userMarcusEmail,
      ): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'dm-marcus-1',
          sender: _userByEmail(AppStrings.userMarcusEmail),
          message: AppStrings.directMessageMarcus,
        ),
      ],
      _directConversationKey(AppStrings.userNinaEmail): <KaizengramChatMessage>[
        KaizengramChatMessage(
          id: 'dm-nina-1',
          sender: _userByEmail(AppStrings.userNinaEmail),
          message: AppStrings.directMessageNina,
        ),
      ],
    };
  }

  static const int maxMessageMediaCount = kaizengramMessageAttachmentLimit;

  late final List<KaizengramChatUser> _users;
  final ImagePicker _imagePicker = ImagePicker();
  late final KaizengramChatUser _currentUser;
  late final List<KaizengramChatChannel> _channels;
  late final Map<String, List<String>> _channelMemberEmailsByChannel;
  late final List<String> _directMessageEmails;
  late final Map<String, List<KaizengramChatMessage>> _messagesByConversation;
  KaizengramChatConversationTarget? _selectedConversation;
  String _draftMessage = '';
  List<KaizengramMessageAttachment> _draftAttachments =
      <KaizengramMessageAttachment>[];
  bool _isPickingDraftMedia = false;
  int _messageVersion = 0;
  KaizengramChatMessage? _replyingTo;

  List<KaizengramChatUser> get users =>
      List<KaizengramChatUser>.unmodifiable(_users);
  List<KaizengramChatChannel> get channels =>
      List<KaizengramChatChannel>.unmodifiable(_channels);
  List<KaizengramChatUser> get currentChannelUsers {
    final channelName = activeChannelName;
    if (channelName == null) {
      return const <KaizengramChatUser>[];
    }

    final channelMemberEmails =
        _channelMemberEmailsByChannel[channelName] ?? const <String>[];
    return List<KaizengramChatUser>.unmodifiable(
      channelMemberEmails.map(_userByEmail).toList(growable: false),
    );
  }

  List<KaizengramChatUser> get directMessageUsers =>
      List<KaizengramChatUser>.unmodifiable(
        _directMessageEmails.map(_userByEmail).toList(growable: false),
      );
  List<KaizengramChatUser> get directMessageCandidates =>
      List<KaizengramChatUser>.unmodifiable(
        _users
            .where(_canStartDirectMessageWith)
            .where((user) => !_directMessageEmails.contains(user.email))
            .toList(growable: false),
      );
  Set<String> get currentChannelMemberEmails {
    final channelName = activeChannelName;
    if (channelName == null) {
      return const <String>{};
    }

    final channelMemberEmails =
        _channelMemberEmailsByChannel[channelName] ?? const <String>[];
    return Set<String>.unmodifiable(channelMemberEmails.map(_normalizeEmail));
  }

  List<KaizengramChatUser> get shareDirectMessageTargets {
    final seenEmails = <String>{};
    final orderedUsers = <KaizengramChatUser>[];

    for (final user in directMessageUsers) {
      if (seenEmails.add(user.email)) {
        orderedUsers.add(user);
      }
    }

    for (final user in directMessageCandidates) {
      if (seenEmails.add(user.email)) {
        orderedUsers.add(user);
      }
    }

    return List<KaizengramChatUser>.unmodifiable(orderedUsers);
  }

  String get draftMessage => _draftMessage;
  List<KaizengramMessageAttachment> get draftAttachments =>
      List<KaizengramMessageAttachment>.unmodifiable(_draftAttachments);
  bool get isPickingDraftMedia => _isPickingDraftMedia;
  int get messageVersion => _messageVersion;
  bool get hasDraftMedia => _draftAttachments.isNotEmpty;
  bool get canAddMoreDraftMedia =>
      _draftAttachments.length < maxMessageMediaCount;
  bool get canSendMessage => _draftMessage.trim().isNotEmpty || hasDraftMedia;
  KaizengramChatUser get currentUser => _currentUser;
  KaizengramChatMessage? get replyingTo => _replyingTo;
  bool get hasSelectedConversation => _selectedConversation != null;
  KaizengramChatConversationType? get currentConversationType =>
      _selectedConversation?.type;
  bool get isCurrentConversationChannel =>
      currentConversationType == KaizengramChatConversationType.channel;
  bool get canDeleteCurrentChannel =>
      isCurrentConversationChannel && _channels.length > 1;
  String? get activeChannelName =>
      _selectedConversation?.type == KaizengramChatConversationType.channel
      ? _selectedConversation!.id
      : null;
  KaizengramChatUser? get activeDirectMessageUser =>
      _selectedConversation?.type ==
          KaizengramChatConversationType.directMessage
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
        return AppStrings.channelLabel;
      case KaizengramChatConversationType.directMessage:
        return AppStrings.directMessageLabel;
      case null:
        return AppStrings.conversationLabel;
    }
  }

  List<KaizengramChatMessage> get messages =>
      List<KaizengramChatMessage>.unmodifiable(
        _messagesByConversation[_selectedConversation?.key] ??
            const <KaizengramChatMessage>[],
      );

  bool isOwnMessage(KaizengramChatMessage message) {
    return message.sender.email == _currentUser.email;
  }

  bool isChannelSelected(String channelName) {
    final selectedConversation = _selectedConversation;
    return selectedConversation?.type ==
            KaizengramChatConversationType.channel &&
        selectedConversation?.id == channelName;
  }

  bool isDirectMessageSelected(String email) {
    final selectedConversation = _selectedConversation;
    return selectedConversation?.type ==
            KaizengramChatConversationType.directMessage &&
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
        return lowerName.contains(normalizedQuery) ||
            lowerEmail.contains(normalizedQuery);
      }),
    );
  }

  int channelMemberCount(String channelName) {
    final memberEmails =
        _channelMemberEmailsByChannel[channelName] ?? const <String>[];
    return memberEmails.length;
  }

  List<KaizengramChatUser> directMessageCandidatesForQuery(String query) {
    final normalizedQuery = query.trim().toLowerCase();
    final candidates = directMessageCandidates
        .where((user) => user.matchesQuery(normalizedQuery))
        .toList(growable: false);

    return List<KaizengramChatUser>.unmodifiable(
      _sortedUsersForQuery(candidates, normalizedQuery),
    );
  }

  List<KaizengramChatUser> currentChannelInviteSuggestions(
    String query, {
    Iterable<String> excludedEmails = const <String>[],
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final blockedEmails = <String>{
      ...currentChannelMemberEmails,
      ...excludedEmails.map(_normalizeEmail),
      _currentUser.normalizedEmail,
      AppStrings.userBotEmail,
    };
    final candidates = _users
        .where(
          (user) =>
              !blockedEmails.contains(user.normalizedEmail) &&
              user.matchesQuery(normalizedQuery),
        )
        .toList(growable: false);

    final sortedUsers = _sortedUsersForQuery(candidates, normalizedQuery);
    if (normalizedQuery.isEmpty && sortedUsers.length > 8) {
      return List<KaizengramChatUser>.unmodifiable(
        sortedUsers.take(8).toList(growable: false),
      );
    }

    return List<KaizengramChatUser>.unmodifiable(sortedUsers);
  }

  KaizengramChatUser? currentChannelInviteCandidate(
    String query, {
    Iterable<String> excludedEmails = const <String>[],
  }) {
    final normalizedEmail = _normalizeEmail(query);
    if (normalizedEmail.isEmpty) {
      return null;
    }

    final blockedEmails = <String>{
      ...currentChannelMemberEmails,
      ...excludedEmails.map(_normalizeEmail),
      _currentUser.normalizedEmail,
      AppStrings.userBotEmail,
    };
    if (blockedEmails.contains(normalizedEmail)) {
      return null;
    }

    final matchingUser = _users.cast<KaizengramChatUser?>().firstWhere(
      (user) => user?.normalizedEmail == normalizedEmail,
      orElse: () => null,
    );
    if (matchingUser != null) {
      return matchingUser;
    }

    if (!_isValidEmail(normalizedEmail)) {
      return null;
    }

    return KaizengramChatUser(
      name: _displayNameFromEmail(normalizedEmail.split('@').first),
      email: normalizedEmail,
      isExternal: true,
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
    return pickDraftMediaForSource(
      source: KaizengramMessageAttachmentPickSource.media,
    );
  }

  Future<KaizengramChatDraftMediaPickResult> pickDraftMediaForSource({
    required KaizengramMessageAttachmentPickSource source,
  }) async {
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
      final nextAttachments = await KaizengramMessageAttachmentPicker.pick(
        source: source,
        availableSlots: availableSlots,
        existingPaths: _draftAttachments.map((attachment) => attachment.path),
      );
      if (nextAttachments.isEmpty) {
        return KaizengramChatDraftMediaPickResult.cancelled;
      }

      _draftAttachments = <KaizengramMessageAttachment>[
        ..._draftAttachments,
        ...nextAttachments,
      ];
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

  Future<String?> pickChannelImage() async {
    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    return pickedImage?.path;
  }

  void selectChannel(String channelName) {
    if (!_hasChannelNamed(channelName)) {
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

    _selectConversation(
      KaizengramChatConversationTarget.directMessage(normalizedEmail),
    );
  }

  String? validateChannelName(String rawName) {
    final channelName = _normalizedChannelName(rawName);
    if (channelName.isEmpty) {
      return AppStrings.emptyChannelNameError;
    }
    if (_hasChannelNamed(channelName)) {
      return AppStrings.duplicateChannelNameError;
    }

    return null;
  }

  String? validateUserEmail(String rawEmail) {
    final email = _normalizeEmail(rawEmail);
    if (!_isValidEmail(email)) {
      return AppStrings.invalidEmailError;
    }
    if (_users.any((user) => user.normalizedEmail == email)) {
      return AppStrings.duplicateUserError;
    }

    return null;
  }

  String? validateUserEmailForCurrentChannel(String rawEmail) {
    final email = _normalizeEmail(rawEmail);
    if (!_isValidEmail(email)) {
      return AppStrings.invalidEmailError;
    }

    final channelName = activeChannelName;
    if (channelName == null) {
      return AppStrings.noActiveChannelError;
    }

    final channelMemberEmails =
        _channelMemberEmailsByChannel[channelName] ?? const <String>[];
    if (channelMemberEmails.contains(email)) {
      return AppStrings.duplicateChannelUserError;
    }

    return null;
  }

  String createChannel(String rawName, {String? imagePath}) {
    final validationMessage = validateChannelName(rawName);
    if (validationMessage != null) {
      return '';
    }

    final channelName = _normalizedChannelName(rawName);
    final normalizedImagePath = imagePath?.trim();
    _channels.add(
      KaizengramChatChannel(
        name: channelName,
        imagePath: normalizedImagePath == null || normalizedImagePath.isEmpty
            ? null
            : normalizedImagePath,
      ),
    );
    _channelMemberEmailsByChannel[channelName] = <String>[_currentUser.email];
    _messagesByConversation[_channelConversationKey(
      channelName,
    )] = <KaizengramChatMessage>[
      KaizengramChatMessage(
        id: '$channelName-1',
        sender: _userByEmail(AppStrings.userBotEmail),
        message: AppStrings.createdChannelMessage(channelName),
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
    final deletedIndex = _channels.indexWhere(
      (channel) => channel.name == channelName,
    );
    if (_channels.length <= 1 || deletedIndex == -1) {
      return false;
    }

    final deletedChannel = channelName;
    _channels.removeAt(deletedIndex);
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
    final attachments = List<KaizengramMessageAttachment>.unmodifiable(
      _draftAttachments,
    );
    if (conversationKey == null ||
        (trimmedMessage.isEmpty && attachments.isEmpty)) {
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

  bool sendPresetMessage({
    required KaizengramChatConversationTarget conversation,
    required String message,
    List<KaizengramMessageAttachment> attachments =
        const <KaizengramMessageAttachment>[],
  }) {
    final trimmedMessage = message.trim();
    final normalizedAttachments = attachments
        .where((attachment) => attachment.path.trim().isNotEmpty)
        .take(maxMessageMediaCount)
        .toList(growable: false);
    final resolvedConversation = _ensureConversationExists(conversation);

    if (resolvedConversation == null ||
        (trimmedMessage.isEmpty && normalizedAttachments.isEmpty)) {
      return false;
    }

    final conversationMessages = _messagesByConversation.putIfAbsent(
      resolvedConversation.key,
      () => <KaizengramChatMessage>[],
    );
    conversationMessages.add(
      KaizengramChatMessage(
        id: '${resolvedConversation.key}-${DateTime.now().microsecondsSinceEpoch}',
        sender: _currentUser,
        message: trimmedMessage,
        attachments: normalizedAttachments,
      ),
    );

    _selectedConversation = resolvedConversation;
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

    final email = _normalizeEmail(rawEmail);
    if (!_users.any((user) => user.normalizedEmail == email)) {
      final user = KaizengramChatUser(
        name: _displayNameFromEmail(email.split('@').first),
        email: email,
        isExternal: true,
      );
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

  List<String> addUsersToCurrentChannel(Iterable<String> rawEmails) {
    final addedEmails = <String>[];

    for (final rawEmail in rawEmails) {
      final addedEmail = addUserToCurrentChannel(rawEmail);
      if (addedEmail.isNotEmpty && !addedEmails.contains(addedEmail)) {
        addedEmails.add(addedEmail);
      }
    }

    return List<String>.unmodifiable(addedEmails);
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
    final normalizedEmail = _normalizeEmail(email);
    return _users.firstWhere((user) => user.normalizedEmail == normalizedEmail);
  }

  bool _canStartDirectMessageWith(KaizengramChatUser user) {
    return _canStartDirectMessageWithEmail(user.email);
  }

  bool _canStartDirectMessageWithEmail(String email) {
    return email != _currentUser.email &&
        email != AppStrings.userBotEmail &&
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
    _draftAttachments = <KaizengramMessageAttachment>[];
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
        .map(
          (part) => '${part.substring(0, 1).toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  String _normalizeEmail(String rawEmail) {
    return rawEmail.trim().toLowerCase();
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
  }

  List<KaizengramChatUser> _sortedUsersForQuery(
    List<KaizengramChatUser> users,
    String normalizedQuery,
  ) {
    final sortedUsers = List<KaizengramChatUser>.from(users);
    sortedUsers.sort((left, right) {
      final leftStarts =
          left.name.toLowerCase().startsWith(normalizedQuery) ||
          left.normalizedEmail.startsWith(normalizedQuery);
      final rightStarts =
          right.name.toLowerCase().startsWith(normalizedQuery) ||
          right.normalizedEmail.startsWith(normalizedQuery);
      if (leftStarts != rightStarts) {
        return leftStarts ? -1 : 1;
      }

      return left.name.compareTo(right.name);
    });
    return sortedUsers;
  }

  String _channelConversationKey(String channelName) {
    return 'channel:$channelName';
  }

  String _directConversationKey(String email) {
    return 'direct:$email';
  }

  bool _hasChannelNamed(String channelName) {
    return _channels.any((channel) => channel.name == channelName);
  }

  KaizengramChatConversationTarget? _ensureConversationExists(
    KaizengramChatConversationTarget conversation,
  ) {
    switch (conversation.type) {
      case KaizengramChatConversationType.channel:
        final channelName = conversation.id.trim();
        if (!_hasChannelNamed(channelName)) {
          return null;
        }

        return KaizengramChatConversationTarget.channel(channelName);
      case KaizengramChatConversationType.directMessage:
        final email = conversation.id.trim().toLowerCase();
        if (!_canStartDirectMessageWithEmail(email)) {
          return null;
        }

        if (!_directMessageEmails.contains(email)) {
          _directMessageEmails.add(email);
          _messagesByConversation.putIfAbsent(
            _directConversationKey(email),
            () => <KaizengramChatMessage>[],
          );
        }

        return KaizengramChatConversationTarget.directMessage(email);
    }
  }
}

enum KaizengramChatConversationType { channel, directMessage }

class KaizengramChatConversationTarget {
  const KaizengramChatConversationTarget._({
    required this.type,
    required this.id,
  });

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

    return other is KaizengramChatConversationTarget &&
        other.type == type &&
        other.id == id;
  }

  @override
  int get hashCode => Object.hash(type, id);
}

class KaizengramChatUser {
  const KaizengramChatUser({
    required this.name,
    required this.email,
    this.isExternal = false,
  });

  final String name;
  final String email;
  final bool isExternal;

  String get normalizedEmail => email.trim().toLowerCase();

  bool matchesQuery(String query) {
    if (query.isEmpty) {
      return true;
    }

    final normalizedQuery = query.toLowerCase();
    return name.toLowerCase().contains(normalizedQuery) ||
        normalizedEmail.contains(normalizedQuery);
  }
}

class KaizengramChatChannel {
  const KaizengramChatChannel({required this.name, this.imagePath});

  final String name;
  final String? imagePath;
}

class KaizengramChatMessage {
  const KaizengramChatMessage({
    required this.id,
    required this.sender,
    required this.message,
    this.attachments = const <KaizengramMessageAttachment>[],
    this.replyTo,
  });

  final String id;
  final KaizengramChatUser sender;
  final String message;
  final List<KaizengramMessageAttachment> attachments;
  final KaizengramChatReplyPreview? replyTo;

  bool get hasText => message.trim().isNotEmpty;
  bool get hasMedia => attachments.isNotEmpty;
  bool get hasImage => attachments.any((attachment) => attachment.isImage);
  bool get hasVideo => attachments.any((attachment) => attachment.isVideo);
  bool get hasPdf => attachments.any((attachment) => attachment.isPdf);
  String get previewText => hasText
      ? message
      : attachments.length > 1
      ? AppStrings.mediaMessageLabel
      : hasPdf
      ? AppStrings.documentMessageLabel
      : hasVideo
      ? AppStrings.videoMessageLabel
      : AppStrings.photoMessageLabel;
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

enum KaizengramChatDraftMediaPickResult {
  selected,
  cancelled,
  failed,
  limitReached,
}
