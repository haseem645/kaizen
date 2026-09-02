import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:sound_stream/sound_stream.dart';
import 'package:vad/vad.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/socket_manager.dart';
import '../../../../core/preference/app_preference.dart';
import '../../../../core/utils/auth_controller.dart';
import '../../../../core/utils/custom_functions.dart';

class KaizenGptController extends ChangeNotifier {
  static const Duration _speechPause = Duration(milliseconds: 2200);
  static const Duration _assistantPlaybackIdleWindow = Duration(
    milliseconds: 1200,
  );
  static const Duration _assistantPostAudioGuardWindow = Duration(
    milliseconds: 500,
  );
  static const Duration _assistantStaleActivityWindow = Duration(
    milliseconds: 1500,
  );
  static const Duration _assistantTurnIdleSpeechWindow = Duration(
    milliseconds: 800,
  );
  static const Duration _audioIdleTimeout = Duration(seconds: 25);
  static const int _audioSampleRate = 16000;
  static const int _defaultAssistantPlaybackSampleRate = 24000;
  static const int _vadFrameSamples = 512;
  static const int _vadChunkFramesToEmit = 10;
  static const int _maxBufferedVadChunks = 4;
  static const double _vadPositiveSpeechThreshold = 0.5;
  static const double _vadNegativeSpeechThreshold = 0.35;
  static const int _vadMinSpeechFrames = 7;
  static const int _vadRedemptionFrames = 24;
  static const int _vadPreSpeechPadFrames = 6;
  static const int _vadEndSpeechPadFrames = 8;
  static const Duration _assistantSocketTokenRefreshLeadTime = Duration(
    seconds: 45,
  );

  final List<KaizenGptMessage> _messages = <KaizenGptMessage>[];
  final TextEditingController _promptController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final SocketManager _socketManager = SocketManager.instance;
  final PlayerStream _player = PlayerStream();
  final VadHandler _vadHandler = VadHandler.create(
    isDebug: false,
    onLog: _vadLog,
  );

  StreamSubscription<SocketEventMessage>? _socketEventsSubscription;
  StreamSubscription<Object>? _socketErrorsSubscription;
  StreamSubscription<SoundStreamStatus>? _playerStatusSubscription;
  StreamSubscription<void>? _vadRealSpeechStartSubscription;
  StreamSubscription<List<double>>? _vadSpeechEndSubscription;
  StreamSubscription<void>? _vadMisfireSubscription;
  StreamSubscription<String>? _vadErrorSubscription;
  StreamSubscription<({List<double> samples, bool isFinal})>?
  _vadChunkSubscription;

  bool _isMicMuted = true;
  bool _isSpeakerMuted = true;
  bool _isListening = false;
  bool _isSocketConnected = false;
  bool _isConnectingSocket = false;
  bool _isPlayerInitialized = false;
  bool _isVadInitialized = false;
  bool _isVadListening = false;
  bool _isPlayerStarted = false;
  bool _isMicToggleInProgress = false;
  bool _isSpeakerToggleInProgress = false;
  bool _hasConfiguredPlaybackForCurrentResponse = false;
  bool _isStreamingUserAudio = false;
  bool _hasSentSttStart = false;
  bool _hasSentSttEndForCurrentUtterance = false;
  bool _hasSentInterruptForCurrentResponse = false;
  bool _isIgnoringInterruptedAssistantResponse = false;
  bool _acceptAssistantAudioChunks = false;
  bool _isResponding = false;
  bool _isAssistantTurnActive = false;
  bool _isResettingForNewUserTurn = false;
  bool _isStartingUserTurn = false;
  bool? _lastAppliedSpeakerRoute;
  DateTime? _assistantPlaybackStartedAt;
  DateTime? _assistantPlaybackExpectedUntilAt;
  DateTime? _lastAssistantAudioChunkAt;
  DateTime? _lastAssistantActivityAt;
  DateTime? _assistantResponseCompletedAt;
  DateTime? _lastAudioActivityAt;
  int _assistantPlaybackSampleRate = _defaultAssistantPlaybackSampleRate;
  int? _assistantResponseSampleRateHint;
  String? _socketErrorMessage;
  String? _activeConversationId;
  String _liveUserTranscript = '';
  int? _currentUserTurnMessageIndex;
  final List<Uint8List> _bufferedVadChunks = <Uint8List>[];
  Future<void>? _assistantSocketConnectFuture;
  Future<void> _assistantAudioChunkQueue = Future<void>.value();
  Timer? _silenceTimer;
  Timer? _assistantPlaybackIdleTimer;
  Timer? _audioIdleTimer;
  int _assistantAudioQueueGeneration = 0;

  void _log(String message) {
    debugPrint('[KaizenGptController] $message');
  }

  static void _vadLog(String message) {
    debugPrint('[KaizenGptVAD] $message');
  }

  List<KaizenGptMessage> get messages =>
      List<KaizenGptMessage>.unmodifiable(_messages);
  TextEditingController get promptController => _promptController;
  ScrollController get scrollController => _scrollController;
  bool get isMicMuted => _isMicMuted;
  bool get isSpeakerMuted => _isSpeakerMuted;
  bool get isListening => _isListening;
  bool get isSocketConnected => _isSocketConnected;
  bool get isConnectingSocket => _isConnectingSocket;
  bool get isResponding => _isResponding;
  bool get isMicToggleInProgress => _isMicToggleInProgress;
  bool get isSpeakerToggleInProgress => _isSpeakerToggleInProgress;
  String? get socketErrorMessage => _socketErrorMessage;
  bool get showSpeechTranscript => _messages.isNotEmpty || !_isMicMuted;
  String get latestTranscriptPairText {
    final latestUserMessage = _latestMessageText(isUser: true);
    final latestAssistantMessage = _latestMessageText(isUser: false);
    final pendingTranscript = _pendingUserTranscriptForDisplay;

    if (pendingTranscript != null) {
      if (latestAssistantMessage != null) {
        return 'AI: $latestAssistantMessage\n\nYou: $pendingTranscript';
      }

      return 'You: $pendingTranscript';
    }

    if (latestUserMessage != null && latestAssistantMessage != null) {
      return 'You: $latestUserMessage\n\nAI: $latestAssistantMessage';
    }

    if (latestAssistantMessage != null) {
      return 'AI: $latestAssistantMessage';
    }

    if (latestUserMessage != null) {
      return 'You: $latestUserMessage';
    }

    return '';
  }

  String get transcriptText {
    final lines = <String>[
      ..._messages.map(
        (message) =>
            message.isUser ? 'You: ${message.text}' : 'AI: ${message.text}',
      ),
    ];

    final pendingTranscript = _pendingUserTranscriptForDisplay;

    if (pendingTranscript != null) {
      lines.add('You: $pendingTranscript');
    }

    return lines.join('\n\n').trim();
  }

  String? get _pendingUserTranscriptForDisplay {
    final pendingTranscript = _liveUserTranscript.trim();
    final shouldShowPendingTranscript =
        pendingTranscript.isNotEmpty &&
        (_messages.isEmpty ||
            !_messages.last.isUser ||
            _messages.last.text.trim() != pendingTranscript);

    return shouldShowPendingTranscript ? pendingTranscript : null;
  }

  String? _latestMessageText({required bool isUser}) {
    for (var index = _messages.length - 1; index >= 0; index--) {
      final message = _messages[index];
      final normalizedText = message.text.trim();
      if (message.isUser == isUser && normalizedText.isNotEmpty) {
        return normalizedText;
      }
    }

    return null;
  }

  Future<void> initializeAssistantSocket() async {
    _log('initializeAssistantSocket called');
    _socketEventsSubscription ??= _socketManager.events.listen(
      _handleSocketEvent,
    );
    _socketErrorsSubscription ??= _socketManager.errors.listen(
      _handleSocketError,
    );

    await _initializeAudioStreams();

    await _connectAssistantSocketIfNeeded();
  }

  Future<void> _connectAssistantSocketIfNeeded() async {
    if (_isSocketConnected && _socketManager.assistantSocket != null) {
      return;
    }

    final existingConnectFuture = _assistantSocketConnectFuture;
    if (existingConnectFuture != null) {
      await existingConnectFuture;
      return;
    }

    final connectFuture = _openAssistantSocket();
    _assistantSocketConnectFuture = connectFuture;

    try {
      await connectFuture;
    } finally {
      if (identical(_assistantSocketConnectFuture, connectFuture)) {
        _assistantSocketConnectFuture = null;
      }
    }
  }

  Future<void> _openAssistantSocket() async {
    final authToken = await _resolveAssistantSocketToken();
    if (authToken.isEmpty) {
      _log('_connectAssistantSocketIfNeeded aborted: missing auth token');
      _socketErrorMessage = 'Missing auth token.';
      notifyListeners();
      return;
    }

    _isConnectingSocket = true;
    _socketErrorMessage = null;
    notifyListeners();

    try {
      await _socketManager.connectAssistantSocket(token: authToken);
      _isSocketConnected = true;
      _log('Assistant socket connected successfully');
    } catch (error) {
      _isSocketConnected = false;
      _socketErrorMessage = '$error';
      _log('Assistant socket connection failed in controller: $error');
    } finally {
      _isConnectingSocket = false;
      notifyListeners();
    }
  }

  Future<String> _resolveAssistantSocketToken() async {
    final authToken = AppPreference.getAuthToken().trim();
    if (authToken.isEmpty) {
      return '';
    }

    if (!_shouldRefreshAssistantSocketToken(authToken)) {
      return authToken;
    }

    _log('Refreshing assistant socket token before websocket connect');
    try {
      return await AuthController.requestRefreshToken();
    } catch (error) {
      _socketErrorMessage = '$error';
      _log('Assistant socket token refresh failed: $error');
      return AppPreference.getAuthToken().trim();
    }
  }

  bool _shouldRefreshAssistantSocketToken(String token) {
    final expiration = _jwtExpiry(token);
    if (expiration == null) {
      return false;
    }

    final refreshAt = expiration.subtract(_assistantSocketTokenRefreshLeadTime);
    return !DateTime.now().isBefore(refreshAt);
  }

  DateTime? _jwtExpiry(String token) {
    final parts = token.split('.');
    if (parts.length != 3) {
      return null;
    }

    try {
      final payload = utf8.decode(
        base64Url.decode(base64Url.normalize(parts[1])),
      );
      final decoded = jsonDecode(payload);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final expValue = decoded['exp'];
      if (expValue is int) {
        return DateTime.fromMillisecondsSinceEpoch(expValue * 1000);
      }
      if (expValue is num) {
        return DateTime.fromMillisecondsSinceEpoch(expValue.toInt() * 1000);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _initializeAudioStreams() async {
    if (_isVadInitialized && _isPlayerInitialized) {
      _log('_initializeAudioStreams skipped: already initialized');
      return;
    }

    _log('Initializing audio streams');
    if (!_isVadInitialized) {
      await _initializeVad();
    }

    if (!_isPlayerInitialized) {
      await _player.initialize(
        sampleRate: _assistantPlaybackSampleRate,
        showLogs: false,
      );
      await _player.usePhoneSpeaker(!_isSpeakerMuted);
      _lastAppliedSpeakerRoute = !_isSpeakerMuted;
      _playerStatusSubscription ??= _player.status.listen((status) {
        _log('Player status changed: $status');
        if (status == SoundStreamStatus.Playing) {
          _isPlayerStarted = true;
          return;
        }

        if (status == SoundStreamStatus.Stopped ||
            status == SoundStreamStatus.Unset) {
          _isPlayerStarted = false;
          _assistantPlaybackStartedAt = null;
          _assistantPlaybackExpectedUntilAt = null;
          if (!_isResponding) {
            _assistantPlaybackIdleTimer?.cancel();
            _acceptAssistantAudioChunks = false;
            _scheduleAudioIdleShutdownIfNeeded();
            notifyListeners();
          }
        }
      });
      _isPlayerInitialized = true;
    }

    _log('Audio streams initialized');
  }

  @override
  void dispose() {
    _log('dispose called');
    _silenceTimer?.cancel();
    _assistantPlaybackIdleTimer?.cancel();
    _audioIdleTimer?.cancel();
    unawaited(_socketEventsSubscription?.cancel());
    unawaited(_socketErrorsSubscription?.cancel());
    unawaited(_playerStatusSubscription?.cancel());
    unawaited(_vadRealSpeechStartSubscription?.cancel());
    unawaited(_vadSpeechEndSubscription?.cancel());
    unawaited(_vadMisfireSubscription?.cancel());
    unawaited(_vadErrorSubscription?.cancel());
    unawaited(_vadChunkSubscription?.cancel());
    unawaited(_shutdownAudio());
    unawaited(_vadHandler.dispose());
    unawaited(_socketManager.disconnectAssistantSocket());
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _shutdownAudio() async {
    await _stopVadListening();

    try {
      await _player.stop();
    } catch (_) {
      _log('Player stop during dispose failed but was ignored');
    }

    _player.dispose();
  }

  Future<void> _initializeVad() async {
    if (_isVadInitialized) {
      return;
    }

    _log('Initializing VAD handler');
    _vadRealSpeechStartSubscription ??= _vadHandler.onRealSpeechStart.listen((
      _,
    ) {
      unawaited(_handleVadRealSpeechStart());
    });
    _vadSpeechEndSubscription ??= _vadHandler.onSpeechEnd.listen((_) {
      unawaited(_handleVadSpeechEnd());
    });
    _vadMisfireSubscription ??= _vadHandler.onVADMisfire.listen((_) {
      _log('VAD misfire ignored');
      _resetSpeechCandidate();
    });
    _vadErrorSubscription ??= _vadHandler.onError.listen((error) {
      _socketErrorMessage = error;
      _log('VAD error: $error');
      notifyListeners();
    });
    _vadChunkSubscription ??= _vadHandler.onEmitChunk.listen((chunkData) {
      _handleVadChunkEmission(chunkData);
    });

    _isVadInitialized = true;
    _log('VAD handler initialized');
  }

  Future<void> _startVadListening() async {
    if (_isVadListening) {
      return;
    }

    await _initializeVad();
    _log('Starting VAD microphone stream');
    await _vadHandler.startListening(
      frameSamples: _vadFrameSamples,
      model: 'v5',
      positiveSpeechThreshold: _vadPositiveSpeechThreshold,
      negativeSpeechThreshold: _vadNegativeSpeechThreshold,
      minSpeechFrames: _vadMinSpeechFrames,
      redemptionFrames: _vadRedemptionFrames,
      preSpeechPadFrames: _vadPreSpeechPadFrames,
      endSpeechPadFrames: _vadEndSpeechPadFrames,
      numFramesToEmit: _vadChunkFramesToEmit,
      submitUserSpeechOnPause: false,
      recordConfig: RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: _audioSampleRate,
        bitRate: 16,
        numChannels: 1,
        echoCancel: true,
        autoGain: true,
        noiseSuppress: true,
        androidConfig: const AndroidRecordConfig(
          speakerphone: true,
          audioSource: AndroidAudioSource.voiceCommunication,
          audioManagerMode: AudioManagerMode.modeInCommunication,
        ),
        iosConfig: IosRecordConfig(
          categoryOptions: const <IosAudioCategoryOption>[
            IosAudioCategoryOption.defaultToSpeaker,
            IosAudioCategoryOption.allowBluetooth,
            IosAudioCategoryOption.allowBluetoothA2DP,
          ],
        ),
      ),
    );
    _isVadListening = true;
    _log('VAD microphone stream started');
  }

  Future<void> _stopVadListening() async {
    if (!_isVadListening) {
      return;
    }

    try {
      await _vadHandler.stopListening();
      _log('VAD microphone stream stopped');
    } catch (error) {
      _log('VAD stop failed but was ignored: $error');
    } finally {
      _isVadListening = false;
    }
  }

  Future<void> toggleMic(BuildContext context) async {
    _log('toggleMic called. isMicMuted=$_isMicMuted');

    if (_isMicToggleInProgress) {
      _log('toggleMic ignored: toggle already in progress');
      return;
    }

    _isMicToggleInProgress = true;
    notifyListeners();

    try {
      if (_isMicMuted) {
        _isMicMuted = false;
        _isListening = false;
        notifyListeners();
        await _startMicrophoneCapture(context);
        return;
      }

      _isListening = false;
      _isMicMuted = true;
      notifyListeners();
      await _stopMicrophoneCapture(sendSttEnd: true, muteMic: true);
    } finally {
      _isMicToggleInProgress = false;
      notifyListeners();
    }
  }

  Future<void> _startMicrophoneCapture(BuildContext context) async {
    _log('_startMicrophoneCapture called');

    try {
      await _initializeAudioStreams();
      _clearStaleAssistantTurnState();
      if (_isAssistantBusyForUserTurn &&
          !_isResponding &&
          !_isAssistantTurnActive) {
        _log('Clearing assistant tail state before starting microphone capture');
        _finishAssistantTurn(resetInterruptState: true, stopPlayback: false);
      }
      _isListening = false;
      _log('Mic capture starting. speakerMuted=$_isSpeakerMuted');
      await _startVadListening();
      _markAudioActivity();
      notifyListeners();
    } catch (error) {
      _isMicMuted = true;
      _isListening = false;
      _socketErrorMessage = '$error';
      _log('Failed to start microphone capture: $error');
      notifyListeners();

      if (context.mounted) {
        CustomFunctions.showCustomAlert(
          context,
          AppStrings.kaizenGptSpeechPermissionTitle,
          AppStrings.kaizenGptSpeechPermissionMessage,
        );
      }
    }
  }

  Future<void> _stopMicrophoneCapture({
    required bool sendSttEnd,
    required bool muteMic,
    bool keepVadActive = false,
  }) async {
    _log(
      '_stopMicrophoneCapture called. sendSttEnd=$sendSttEnd, muteMic=$muteMic, keepVadActive=$keepVadActive',
    );

    _silenceTimer?.cancel();

    if (sendSttEnd && _isStreamingUserAudio) {
      await _sendSttEndEvent();
    }

    _hasSentSttStart = false;

    _isStreamingUserAudio = false;
    _isListening = false;
    _resetSpeechCandidate();

    if (muteMic) {
      if (!keepVadActive) {
        await _stopVadListening();
      }
      _commitLiveUserTranscript();
      _isMicMuted = true;
    }
    _scheduleAudioIdleShutdownIfNeeded();
    notifyListeners();
  }

  Future<void> toggleSpeaker() async {
    if (_isSpeakerToggleInProgress) {
      _log('toggleSpeaker ignored: toggle already in progress');
      return;
    }

    _isSpeakerToggleInProgress = true;
    _isSpeakerMuted = !_isSpeakerMuted;
    _log('toggleSpeaker called. isSpeakerMuted=$_isSpeakerMuted');
    notifyListeners();

    try {
      if (_isSpeakerMuted) {
        await _stopPlayer();
      } else if (_acceptAssistantAudioChunks ||
          _isResponding ||
          _isAssistantTurnActive) {
        await _applySpeakerRoute();
        await _ensurePlayerStarted();
        _markAudioActivity();
      } else if (!_isSpeakerMuted) {
        _markAudioActivity();
      }
      _scheduleAudioIdleShutdownIfNeeded();
    } finally {
      _isSpeakerToggleInProgress = false;
      notifyListeners();
    }
  }

  Future<void> _stopPlayer() async {
    if (!_isPlayerInitialized || !_isPlayerStarted) {
      return;
    }

    try {
      await _player.stop();
      _isPlayerStarted = false;
      _assistantPlaybackStartedAt = null;
      _assistantPlaybackExpectedUntilAt = null;
      _log('Player stopped');
    } catch (error) {
      _log('Player stop failed but was ignored: $error');
    }
  }

  void _invalidateAssistantAudioQueue() {
    _assistantAudioQueueGeneration++;
  }

  Future<void> _applySpeakerRoute() async {
    if (!_isPlayerInitialized) {
      return;
    }

    if (_lastAppliedSpeakerRoute == true) {
      return;
    }

    await _player.usePhoneSpeaker(true);
    _lastAppliedSpeakerRoute = true;
    _log('Speaker route applied. usePhoneSpeaker=true');
  }

  Future<void> _ensurePlayerStarted() async {
    if (_isSpeakerMuted) {
      _log('_ensurePlayerStarted skipped: speaker muted');
      return;
    }

    await _initializeAudioStreams();
    if (_isPlayerStarted) {
      return;
    }

    await _applySpeakerRoute();
    await _player.start();
    await _applySpeakerRoute();
    _isPlayerStarted = true;
    _assistantPlaybackStartedAt ??= DateTime.now();
    _log('Player started');
  }

  Future<void> _configureAssistantPlaybackSampleRateIfNeeded(
    int? sampleRate,
  ) async {
    if (sampleRate == null || sampleRate <= 0) {
      return;
    }

    if (_assistantPlaybackSampleRate == sampleRate && _isPlayerInitialized) {
      return;
    }

    final wasPlaying = _isPlayerStarted;
    if (wasPlaying) {
      await _stopPlayer();
    }

    _assistantPlaybackSampleRate = sampleRate;
    if (_isPlayerInitialized) {
      await _player.initialize(
        sampleRate: _assistantPlaybackSampleRate,
        showLogs: false,
      );
      _lastAppliedSpeakerRoute = null;
      await _applySpeakerRoute();
    }

    _assistantPlaybackStartedAt = null;
    _assistantPlaybackExpectedUntilAt = null;
    _log(
      'Assistant playback sample rate configured to $_assistantPlaybackSampleRate Hz',
    );
  }

  Future<void> _handleVadRealSpeechStart() async {
    if (_isMicMuted) {
      return;
    }

    _log('VAD confirmed real speech start');
    _markAudioActivity();
    _clearStaleAssistantTurnState();

    if (_isStreamingUserAudio) {
      _hasSentSttEndForCurrentUtterance = false;
      _restartSilenceTimer();
      return;
    }

    if (_isAssistantTurnActive) {
      final useAssistantEchoGate = _shouldUseAssistantEchoGate;
      _log(
        useAssistantEchoGate
            ? 'VAD speech start during assistant turn; interrupting before stt_start'
            : 'VAD speech start after idle assistant turn; interrupting before stt_start',
      );
      await _restartUserTurnAfterInterrupt(
        discardAssistantResponse: useAssistantEchoGate,
        initialAudioChunks: _consumeBufferedVadChunks(),
      );
      return;
    }

    if (_isAssistantBusyForUserTurn) {
      if (!_isResponding && !_isAssistantTurnActive) {
        _log(
          'VAD speech start detected during assistant tail window; reclaiming mic for next utterance',
        );
        _finishAssistantTurn(resetInterruptState: true, stopPlayback: true);
        await _beginFreshUserTurn(
          initialAudioChunks: _consumeBufferedVadChunks(),
        );
        return;
      }

      _log(
        'VAD speech start ignored because assistant is still busy. responding=$_isResponding, acceptChunks=$_acceptAssistantAudioChunks, playerStarted=$_isPlayerStarted',
      );
      return;
    }

    await _beginFreshUserTurn(initialAudioChunks: _consumeBufferedVadChunks());
  }

  Future<void> _handleVadSpeechEnd() async {
    if (!_isStreamingUserAudio) {
      return;
    }

    _log(
      'VAD detected speech end; starting grace window before sending stt_end',
    );
    _markAudioActivity();
    _restartSilenceTimer();
  }

  Future<void> _beginFreshUserTurn({
    String? seedTranscript,
    bool afterInterrupt = false,
    List<Uint8List>? initialAudioChunks,
  }) async {
    if (_isMicMuted ||
        _isStreamingUserAudio ||
        _isStartingUserTurn ||
        (_isResettingForNewUserTurn && !afterInterrupt)) {
      return;
    }

    if (_isAssistantTurnActive && !afterInterrupt) {
      _log('_beginFreshUserTurn blocked: assistant turn is active');
      return;
    }

    _isStartingUserTurn = true;
    try {
      _invalidateAssistantAudioQueue();
      if (!_isResponding || afterInterrupt) {
        _assistantPlaybackIdleTimer?.cancel();
        _acceptAssistantAudioChunks = false;
        if (_isPlayerStarted) {
          await _stopPlayer();
        }
      }

      _log('_beginFreshUserTurn starting live user turn');
      _liveUserTranscript = seedTranscript?.trim() ?? '';
      _currentUserTurnMessageIndex = null;
      _hasSentSttStart = false;
      _hasSentSttEndForCurrentUtterance = false;
      _hasSentInterruptForCurrentResponse = false;
      _isIgnoringInterruptedAssistantResponse = false;
      _isStreamingUserAudio = true;
      _isListening = true;
      _isAssistantTurnActive = false;
      _assistantPlaybackStartedAt = null;
      _assistantPlaybackExpectedUntilAt = null;
      _markAudioActivity();

      if (!_isSocketConnected || _socketManager.assistantSocket == null) {
        _log(
          '_beginFreshUserTurn proceeding without ready socket; reconnecting in background',
        );
        unawaited(_connectAssistantSocketIfNeeded());
      }

      _sendSttStartEvent();
      if (_hasSentSttStart) {
        _sendBufferedUserAudioChunks(initialAudioChunks);
        _sendBufferedUserAudioChunks(_consumeBufferedVadChunks());
        _restartSilenceTimer();
      } else {
        _bufferVadChunks(initialAudioChunks);
      }
      notifyListeners();
    } finally {
      _isStartingUserTurn = false;
    }
  }

  Future<void> _restartUserTurnAfterInterrupt({
    String? seedTranscript,
    bool discardAssistantResponse = true,
    List<Uint8List>? initialAudioChunks,
  }) async {
    if (_isMicMuted || _isResettingForNewUserTurn) {
      return;
    }

    _isResettingForNewUserTurn = true;
    _log('Restarting user turn after interrupt');

    try {
      _silenceTimer?.cancel();
      _interruptAssistant(discardAssistantResponse: discardAssistantResponse);

      await _beginFreshUserTurn(
        seedTranscript: seedTranscript,
        afterInterrupt: true,
        initialAudioChunks: initialAudioChunks,
      );
      if ((seedTranscript?.trim().isNotEmpty ?? false)) {
        _restartSilenceTimer();
      }
    } finally {
      _isResettingForNewUserTurn = false;
    }
  }

  void _interruptAssistant({bool discardAssistantResponse = true}) {
    if (_hasSentInterruptForCurrentResponse) {
      return;
    }

    _invalidateAssistantAudioQueue();
    _hasSentInterruptForCurrentResponse = true;
    _isIgnoringInterruptedAssistantResponse = true;
    _isResponding = false;
    _isAssistantTurnActive = false;
    _acceptAssistantAudioChunks = false;
    _hasSentSttStart = false;
    _resetSpeechCandidate();
    if (discardAssistantResponse) {
      _clearActiveAssistantResponse();
    }
    _log('Active assistant response cleared for interrupt');
    notifyListeners();
    unawaited(_stopPlayer());

    if (!_isSocketConnected || _socketManager.assistantSocket == null) {
      _log('_interruptAssistant skipped socket send: socket not connected');
      return;
    }

    try {
      _socketManager.sendAssistantMessage(const <String, dynamic>{
        'type': 'interrupt',
      });
      _log('interrupt event sent');
    } catch (error) {
      _log('interrupt event failed but was ignored: $error');
    }
  }

  void _clearActiveAssistantResponse() {
    final conversationId = _activeConversationId?.trim();
    if (conversationId != null && conversationId.isNotEmpty) {
      _messages.removeWhere(
        (message) =>
            !message.isUser && message.conversationId == conversationId,
      );
    } else if (_messages.isNotEmpty && !_messages.last.isUser) {
      _messages.removeLast();
    }

    _activeConversationId = null;
  }

  void _markAssistantTurnStarted() {
    _isAssistantTurnActive = true;
    _assistantResponseCompletedAt = null;
    _assistantPlaybackStartedAt ??= DateTime.now();
  }

  void _resetSpeechCandidate() {
    _bufferedVadChunks.clear();
  }

  void _sendBufferedUserAudioChunks(List<Uint8List>? chunks) {
    if (chunks == null || chunks.isEmpty) {
      return;
    }

    for (final chunk in chunks) {
      _sendUserAudioChunk(chunk);
    }
  }

  void _sendUserAudioChunk(Uint8List chunk) {
    if (_socketManager.assistantSocket == null || !_isSocketConnected) {
      _bufferVadChunk(chunk);
      if (!_isMicMuted) {
        unawaited(_connectAssistantSocketIfNeeded());
      }
      return;
    }

    try {
      _socketManager.sendAssistantMessage(chunk);
    } catch (error) {
      _bufferVadChunk(chunk);
      _socketErrorMessage = '$error';
      _log('Failed to send microphone chunk to socket: $error');
      _handleAssistantSocketInterruption(
        'audio chunk send failure',
        reconnectIfMicActive: true,
      );
      notifyListeners();
    }
  }

  void _handleAssistantSocketInterruption(
    String reason, {
    required bool reconnectIfMicActive,
  }) {
    _log('Assistant socket interrupted: $reason');
    _isSocketConnected = false;
    _isConnectingSocket = false;
    if (_isStreamingUserAudio) {
      _hasSentSttStart = false;
      _hasSentSttEndForCurrentUtterance = false;
    }
    if (reconnectIfMicActive && !_isMicMuted) {
      unawaited(_connectAssistantSocketIfNeeded());
    }
  }

  void _handleVadChunkEmission(
    ({List<double> samples, bool isFinal}) chunkData,
  ) {
    if (_isMicMuted || chunkData.samples.isEmpty) {
      return;
    }

    _markAudioActivity();

    final audioChunk = _pcm16ChunkFromVadSamples(chunkData.samples);
    if (audioChunk.isEmpty) {
      return;
    }

    _clearStaleAssistantTurnState();
    if (_isStreamingUserAudio && _hasSentSttStart) {
      _sendUserAudioChunk(audioChunk);
      return;
    }

    _bufferVadChunk(audioChunk);
  }

  void _bufferVadChunk(Uint8List chunk) {
    _bufferedVadChunks.add(Uint8List.fromList(chunk));
    if (_bufferedVadChunks.length > _maxBufferedVadChunks) {
      _bufferedVadChunks.removeAt(0);
    }
  }

  void _bufferVadChunks(List<Uint8List>? chunks) {
    if (chunks == null || chunks.isEmpty) {
      return;
    }

    for (final chunk in chunks) {
      _bufferVadChunk(chunk);
    }
  }

  List<Uint8List> _consumeBufferedVadChunks() {
    final chunks = List<Uint8List>.from(_bufferedVadChunks);
    _bufferedVadChunks.clear();
    return chunks;
  }

  Uint8List _pcm16ChunkFromVadSamples(List<double> samples) {
    if (samples.isEmpty) {
      return Uint8List(0);
    }

    final int16Samples = Int16List(samples.length);
    for (var index = 0; index < samples.length; index++) {
      final clampedSample = samples[index].clamp(-1.0, 1.0).toDouble();
      final scaledSample = clampedSample < 0
          ? (clampedSample * 32768).round()
          : (clampedSample * 32767).round();
      int16Samples[index] = scaledSample.clamp(-32768, 32767).toInt();
    }
    return int16Samples.buffer.asUint8List();
  }

  void _commitLiveUserTranscript() {
    final transcript = _liveUserTranscript;
    if (transcript.trim().isEmpty) {
      _log('_commitLiveUserTranscript skipped: empty transcript');
      return;
    }

    final currentIndex = _currentUserTurnMessageIndex;
    if (currentIndex != null &&
        currentIndex >= 0 &&
        currentIndex < _messages.length &&
        _messages[currentIndex].isUser) {
      _messages[currentIndex] = KaizenGptMessage(
        text: transcript,
        isUser: true,
      );
      _liveUserTranscript = '';
      _log('Updated current user transcript message');
      notifyListeners();
      return;
    }

    _messages.add(KaizenGptMessage(text: transcript, isUser: true));
    _currentUserTurnMessageIndex = _messages.length - 1;
    _liveUserTranscript = '';
    _log('Committed live user transcript to chat history');
    notifyListeners();
  }

  void _restartSilenceTimer() {
    _silenceTimer?.cancel();
    _log('Silence timer restarted for ${_speechPause.inSeconds}s');
    _silenceTimer = Timer(_speechPause, () async {
      _log('Silence timer fired');
      if (_hasSentSttEndForCurrentUtterance) {
        _log('Silence timer ignored: stt_end already sent');
        return;
      }

      await _stopMicrophoneCapture(
        sendSttEnd: true,
        muteMic: false,
        keepVadActive: true,
      );
    });
  }

  void scrollToBottom() {}

  void _handleSocketEvent(SocketEventMessage event) {
    _log(
      'Socket event received: ${event.event}, dataType=${event.data.runtimeType}',
    );

    final eventName = _normalizeAssistantType(event.event);
    switch (eventName) {
      case 'assistant_connect':
        _isSocketConnected = true;
        _isConnectingSocket = false;
        _socketErrorMessage = null;
        if (_isStreamingUserAudio && !_hasSentSttStart) {
          _log(
            'assistant_connect received while user turn is active; sending pending stt_start',
          );
          _sendSttStartEvent();
          if (_hasSentSttStart) {
            _sendBufferedUserAudioChunks(_consumeBufferedVadChunks());
          }
        }
        notifyListeners();
        return;
      case 'assistant_disconnect':
        _handleAssistantSocketInterruption(
          'assistant_disconnect event',
          reconnectIfMicActive: true,
        );
        _finishAssistantTurn(resetInterruptState: true, stopPlayback: true);
        notifyListeners();
        return;
      case 'assistant_message':
        _handleAssistantMessage(event.data);
        return;
      case 'transcript':
        _handleTranscriptPayload(event.data);
        return;
      case 'voice_ready':
      case 'ai_speaking':
      case 'text_chunk':
      case 'ai_done':
      case 'error':
        _handleAssistantMessage(
          _assistantPayloadFromSocketEvent(eventName, event.data),
        );
        return;
      default:
        _log('Unhandled socket event ignored: ${event.event}');
        return;
    }
  }

  void _handleSocketError(Object error) {
    _log('Socket error received: $error');
    _handleAssistantSocketInterruption(
      'socket error: $error',
      reconnectIfMicActive: true,
    );
    _finishAssistantTurn(resetInterruptState: true, stopPlayback: true);
    _socketErrorMessage = '$error';
    notifyListeners();
  }

  Map<String, dynamic> _assistantPayloadFromSocketEvent(
    String type,
    dynamic data,
  ) {
    if (data is Map) {
      return <String, dynamic>{...data, 'type': type};
    }

    return <String, dynamic>{'type': type, 'data': data};
  }

  void _handleAssistantMessage(dynamic rawData) {
    if (_isEmptyAssistantMessage(rawData)) {
      return;
    }

    _log('Raw assistant message received. type=${rawData.runtimeType}');

    if (rawData is Uint8List) {
      _enqueueAssistantAudioChunk(rawData);
      return;
    }

    if (rawData is List<int>) {
      _enqueueAssistantAudioChunk(Uint8List.fromList(rawData));
      return;
    }

    final payload = _normalizeAssistantPayload(rawData);
    _log('Normalized assistant payload: $payload');
    if (payload is String) {
      final type = _normalizeAssistantType(payload);
      if (_isAssistantControlType(type)) {
        _log('Assistant control string received. type="$type"');
        _handleAssistantMessage(<String, dynamic>{'type': type});
        return;
      }
    }

    if (payload is! Map) {
      if (_isStreamingUserAudio) {
        _log(
          'Assistant non-map message ignored because user audio is currently streaming',
        );
        return;
      }
      _log('Assistant payload is not a map and not audio. Ignoring');
      return;
    }

    final type = _normalizeAssistantType(payload['type']?.toString() ?? '');
    _log('Assistant payload type="$type"');

    switch (type) {
      case 'transcript':
        _handleTranscriptPayload(payload);
        return;
      case 'voice_ready':
        if (_isIgnoringInterruptedAssistantResponse) {
          _log('voice_ready ignored because current response was interrupted');
          return;
        }
        _assistantResponseSampleRateHint = _extractAssistantAudioSampleRate(
          payload,
        );
        _log('voice_ready received');
        _assistantPlaybackIdleTimer?.cancel();
        _hasSentInterruptForCurrentResponse = false;
        _acceptAssistantAudioChunks = true;
        _hasConfiguredPlaybackForCurrentResponse = false;
        _lastAssistantActivityAt = DateTime.now();
        _markAssistantTurnStarted();
        _markAudioActivity();
        if (!_isSpeakerMuted) {
          unawaited(_ensurePlayerStarted());
          unawaited(_applySpeakerRoute());
        }
        return;
      case 'ai_speaking':
        _assistantPlaybackIdleTimer?.cancel();
        _commitLiveUserTranscript();
        _activeConversationId = payload['conversation_id']?.toString().trim();
        _assistantResponseSampleRateHint =
            _extractAssistantAudioSampleRate(payload) ??
            _assistantResponseSampleRateHint;
        _isIgnoringInterruptedAssistantResponse = false;
        _hasSentInterruptForCurrentResponse = false;
        _isResponding = true;
        _acceptAssistantAudioChunks = true;
        _hasConfiguredPlaybackForCurrentResponse = false;
        _lastAssistantActivityAt = DateTime.now();
        _markAssistantTurnStarted();
        _markAudioActivity();
        if (!_isSpeakerMuted) {
          unawaited(_applySpeakerRoute());
        }
        _log('ai_speaking received. conversationId=$_activeConversationId');
        notifyListeners();
        return;
      case 'text_chunk':
        if (_isIgnoringInterruptedAssistantResponse) {
          _log('text_chunk ignored because current response was interrupted');
          return;
        }
        final chunk = payload['chunk']?.toString() ?? '';
        final conversationId = payload['conversation_id']?.toString().trim();
        final completedAt = _assistantResponseCompletedAt;
        final isLateChunkAfterDone =
            completedAt != null &&
            DateTime.now().difference(completedAt) <
                _assistantStaleActivityWindow;
        if (!isLateChunkAfterDone) {
          _acceptAssistantAudioChunks = true;
          _lastAssistantActivityAt = DateTime.now();
          _markAssistantTurnStarted();
          _markAudioActivity();
        }
        _appendAssistantChunk(
          chunk: chunk,
          conversationId: conversationId,
          markResponding: !isLateChunkAfterDone,
        );
        return;
      case 'ai_done':
        if (_isIgnoringInterruptedAssistantResponse) {
          _log(
            'ai_done ignored because interrupted response is being discarded',
          );
          return;
        }
        _commitLiveUserTranscript();
        _activeConversationId = payload['conversation_id']?.toString().trim();
        _markAudioActivity();
        _completeAssistantResponse();
        _log('ai_done received. conversationId=$_activeConversationId');
        notifyListeners();
        return;
      case 'error':
        _socketErrorMessage =
            payload['error']?.toString().trim() ??
            'Assistant socket returned an unknown error.';
        _finishAssistantTurn(resetInterruptState: true, stopPlayback: true);
        _log('Socket error payload received: $_socketErrorMessage');
        notifyListeners();
        return;
      default:
        if (_isStreamingUserAudio) {
          _log(
            'Assistant payload ignored because user audio is currently streaming',
          );
          return;
        }
        _log('Unhandled assistant payload type="$type"');
        return;
    }
  }

  void _enqueueAssistantAudioChunk(Uint8List chunk) {
    final generation = _assistantAudioQueueGeneration;
    _assistantAudioChunkQueue = _assistantAudioChunkQueue
        .then((_) async {
          if (generation != _assistantAudioQueueGeneration) {
            _log(
              'Assistant audio chunk dropped because playback queue was reset',
            );
            return;
          }

          await _handleAssistantAudioChunk(chunk, generation: generation);
        })
        .catchError((Object error, StackTrace stackTrace) {
          _log('Assistant audio queue failure ignored: $error');
        });
  }

  Future<void> _handleAssistantAudioChunk(
    Uint8List chunk, {
    required int generation,
  }) async {
    _log('Assistant audio chunk received. bytes=${chunk.length}');
    if (generation != _assistantAudioQueueGeneration) {
      _log('Assistant audio chunk ignored because playback queue was reset');
      return;
    }

    if (_isStreamingUserAudio) {
      _log(
        'Assistant audio chunk ignored because user audio is currently streaming',
      );
      return;
    }

    if (_isIgnoringInterruptedAssistantResponse) {
      _log(
        'Assistant audio chunk ignored because current response was interrupted',
      );
      return;
    }

    _assistantPlaybackIdleTimer?.cancel();
    _acceptAssistantAudioChunks = true;
    final now = DateTime.now();
    _lastAssistantAudioChunkAt = now;
    _lastAssistantActivityAt = now;
    _markAudioActivity();
    if (_assistantResponseCompletedAt == null) {
      _markAssistantTurnStarted();
    }

    try {
      final normalizedChunk = await _normalizeAssistantAudioChunk(chunk);
      if (normalizedChunk.isEmpty) {
        _log('Assistant audio chunk skipped after normalization');
        return;
      }

      if (generation != _assistantAudioQueueGeneration) {
        _log(
          'Assistant audio chunk dropped after normalization because playback queue was reset',
        );
        return;
      }

      if (_isSpeakerMuted) {
        _log('Assistant audio chunk skipped because speaker output is muted');
        return;
      }

      await _ensurePlayerStarted();
      await _player.writeChunk(normalizedChunk);
      _extendAssistantPlaybackEstimate(normalizedChunk.length);
      if (_assistantResponseCompletedAt != null) {
        _restartAssistantPlaybackIdleTimer();
      }
      _log(
        _isSpeakerMuted
            ? 'Assistant audio chunk queued muted for playback timing'
            : 'Assistant audio chunk queued for playback',
      );
    } catch (error) {
      _socketErrorMessage = '$error';
      _log('Assistant audio chunk playback failed: $error');
      notifyListeners();
    }
  }

  Future<Uint8List> _normalizeAssistantAudioChunk(Uint8List chunk) async {
    final parsedChunk = _parseAssistantAudioChunk(chunk);
    if (!_hasConfiguredPlaybackForCurrentResponse) {
      final playbackSampleRate =
          parsedChunk.sampleRate ?? _assistantResponseSampleRateHint;
      await _configureAssistantPlaybackSampleRateIfNeeded(playbackSampleRate);
      _hasConfiguredPlaybackForCurrentResponse = true;
    }
    return parsedChunk.bytes;
  }

  ({Uint8List bytes, int? sampleRate}) _parseAssistantAudioChunk(
    Uint8List chunk,
  ) {
    if (chunk.lengthInBytes < 12) {
      return (bytes: chunk, sampleRate: null);
    }

    final riffHeader = ascii.decode(chunk.sublist(0, 4), allowInvalid: true);
    final waveHeader = ascii.decode(chunk.sublist(8, 12), allowInvalid: true);
    if (riffHeader != 'RIFF' || waveHeader != 'WAVE') {
      return (bytes: chunk, sampleRate: null);
    }

    final byteData = ByteData.sublistView(chunk);
    var offset = 12;
    int? sampleRate;
    int? channelCount;
    int? bitsPerSample;
    int? dataOffset;

    while (offset + 8 <= chunk.lengthInBytes) {
      final chunkId = ascii.decode(
        chunk.sublist(offset, offset + 4),
        allowInvalid: true,
      );
      final chunkSize = byteData.getUint32(offset + 4, Endian.little);
      final nextOffset = offset + 8 + chunkSize + (chunkSize.isOdd ? 1 : 0);
      if (nextOffset > chunk.lengthInBytes) {
        break;
      }

      if (chunkId == 'fmt ' && chunkSize >= 16) {
        channelCount = byteData.getUint16(offset + 10, Endian.little);
        sampleRate = byteData.getUint32(offset + 12, Endian.little);
        bitsPerSample = byteData.getUint16(offset + 22, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = offset + 8;
        break;
      }

      offset = nextOffset;
    }

    if (sampleRate != null) {
      _log(
        'Assistant WAV header detected. sampleRate=$sampleRate, channels=$channelCount, bitsPerSample=$bitsPerSample',
      );
    }

    if (channelCount != null && channelCount != 1) {
      _log(
        'Assistant audio is not mono (channels=$channelCount). Playback may be distorted.',
      );
    }

    if (bitsPerSample != null && bitsPerSample != 16) {
      _log(
        'Assistant audio is not PCM16 (bitsPerSample=$bitsPerSample). Playback may be distorted.',
      );
    }

    if (dataOffset == null || dataOffset >= chunk.lengthInBytes) {
      return (bytes: chunk, sampleRate: sampleRate);
    }

    return (
      bytes: Uint8List.sublistView(chunk, dataOffset),
      sampleRate: sampleRate,
    );
  }

  int? _extractAssistantAudioSampleRate(Map payload) {
    final directKeys = <dynamic>[
      payload['sample_rate'],
      payload['sampleRate'],
      payload['audio_sample_rate'],
      payload['audioSampleRate'],
    ];

    for (final value in directKeys) {
      final sampleRate = _parseIntValue(value);
      if (sampleRate != null && sampleRate > 0) {
        _log('Assistant audio sample rate hint received: $sampleRate Hz');
        return sampleRate;
      }
    }

    final audioPayload = payload['audio'];
    if (audioPayload is Map) {
      return _extractAssistantAudioSampleRate(
        Map<String, dynamic>.from(audioPayload),
      );
    }

    return null;
  }

  int? _parseIntValue(dynamic value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    if (value is String) {
      return int.tryParse(value.trim());
    }
    return null;
  }

  void _handleTranscriptPayload(dynamic rawData) {
    final payload = rawData is Map
        ? rawData
        : _normalizeAssistantPayload(rawData);
    if (payload is! Map) {
      _log('Transcript payload ignored because it is not a map');
      return;
    }

    final transcriptValue = payload['transcript']?.toString();
    final textValue = payload['text']?.toString();
    final chunkValue = payload['chunk']?.toString();
    final transcript = transcriptValue ?? textValue;
    final normalizedTranscript = transcript ?? '';
    final normalizedChunk = chunkValue ?? '';

    if (normalizedTranscript.trim().isEmpty && normalizedChunk.trim().isEmpty) {
      _log('Transcript payload ignored because transcript was empty');
      return;
    }

    final isFinal =
        payload['is_final'] == true ||
        payload['isFinal'] == true ||
        payload['final'] == true;

    if (normalizedTranscript.trim().isNotEmpty) {
      _liveUserTranscript = normalizedTranscript;
    } else {
      _liveUserTranscript = normalizedChunk;
    }
    _markAudioActivity();
    if (_isStreamingUserAudio) {
      _hasSentSttEndForCurrentUtterance = false;
      _restartSilenceTimer();
    }
    _log('Transcript updated. text="$_liveUserTranscript", isFinal=$isFinal');
    _commitLiveUserTranscript();
  }

  bool _isEmptyAssistantMessage(dynamic rawData) {
    if (rawData == null) {
      _log('Assistant message ignored because payload was null');
      return true;
    }

    if (rawData is String && rawData.trim().isEmpty) {
      return true;
    }

    if (rawData is Uint8List && rawData.isEmpty) {
      _log('Assistant audio chunk ignored because payload was empty');
      return true;
    }

    if (rawData is List<int> && rawData.isEmpty) {
      _log('Assistant audio list ignored because payload was empty');
      return true;
    }

    return false;
  }

  void _finishAssistantTurn({
    required bool resetInterruptState,
    required bool stopPlayback,
  }) {
    _invalidateAssistantAudioQueue();
    _assistantPlaybackIdleTimer?.cancel();
    _isResponding = false;
    _isAssistantTurnActive = false;
    _acceptAssistantAudioChunks = false;
    _hasConfiguredPlaybackForCurrentResponse = false;
    if (!_isStreamingUserAudio) {
      _resetSpeechCandidate();
    }
    _assistantPlaybackStartedAt = null;
    _assistantPlaybackExpectedUntilAt = null;
    _lastAssistantAudioChunkAt = null;
    _lastAssistantActivityAt = null;
    _assistantResponseCompletedAt = null;
    _assistantResponseSampleRateHint = null;

    if (resetInterruptState) {
      _hasSentInterruptForCurrentResponse = false;
      _isIgnoringInterruptedAssistantResponse = false;
    }

    if (stopPlayback && _isPlayerStarted) {
      unawaited(_stopPlayer());
    }
    _scheduleAudioIdleShutdownIfNeeded();
  }

  void _completeAssistantResponse() {
    _assistantPlaybackIdleTimer?.cancel();
    _isResponding = false;
    _isAssistantTurnActive = false;
    _acceptAssistantAudioChunks = false;
    _hasConfiguredPlaybackForCurrentResponse = false;
    _assistantPlaybackStartedAt = null;
    _assistantPlaybackExpectedUntilAt = null;
    final now = DateTime.now();
    _lastAssistantActivityAt = now;
    _assistantResponseCompletedAt = now;
    _assistantResponseSampleRateHint = null;
    _hasSentInterruptForCurrentResponse = false;
    _isIgnoringInterruptedAssistantResponse = false;
    _scheduleAudioIdleShutdownIfNeeded();
  }

  dynamic _normalizeAssistantPayload(dynamic rawData) {
    if (rawData is String) {
      final trimmed = rawData.trim();
      if (trimmed.isEmpty) {
        return trimmed;
      }

      try {
        return jsonDecode(trimmed);
      } catch (_) {
        return trimmed;
      }
    }

    return rawData;
  }

  String _normalizeAssistantType(String rawType) {
    final normalized = rawType.trim().toLowerCase();
    switch (normalized) {
      case 'done':
      case 'ai_complete':
      case 'ai_completed':
      case 'assistant_done':
      case 'response_done':
      case 'response.done':
        return 'ai_done';
      case 'speaking':
      case 'assistant_speaking':
        return 'ai_speaking';
      case 'chunk':
      case 'assistant_text_chunk':
        return 'text_chunk';
      default:
        return normalized;
    }
  }

  bool _isAssistantControlType(String type) {
    return type == 'transcript' ||
        type == 'voice_ready' ||
        type == 'ai_speaking' ||
        type == 'text_chunk' ||
        type == 'ai_done' ||
        type == 'error';
  }

  void _appendAssistantChunk({
    required String chunk,
    required String? conversationId,
    bool markResponding = true,
  }) {
    if (chunk.isEmpty) {
      _log('_appendAssistantChunk ignored empty chunk');
      return;
    }

    final normalizedConversationId = conversationId?.trim();
    if (normalizedConversationId != null &&
        normalizedConversationId.isNotEmpty) {
      _activeConversationId = normalizedConversationId;
    }

    _log(
      '_appendAssistantChunk called. chunk="$chunk", activeConversationId=$_activeConversationId',
    );

    if (_messages.isNotEmpty &&
        !_messages.last.isUser &&
        _messages.last.conversationId == _activeConversationId) {
      final current = _messages.removeLast();
      _messages.add(
        KaizenGptMessage(
          text: '${current.text}$chunk',
          isUser: false,
          conversationId: _activeConversationId,
        ),
      );
      _log('Concatenated assistant text chunk onto existing message');
    } else {
      _messages.add(
        KaizenGptMessage(
          text: chunk,
          isUser: false,
          conversationId: _activeConversationId,
        ),
      );
      _log('Added new assistant text message');
    }

    if (markResponding) {
      _isResponding = true;
    }
    notifyListeners();
  }

  bool get _isAssistantBusyForUserTurn {
    if (_isAssistantTurnActive || _isResponding) {
      return true;
    }

    if (!_acceptAssistantAudioChunks) {
      return false;
    }

    final completedAt = _assistantResponseCompletedAt;
    if (completedAt == null) {
      final lastActivityAt = _lastAssistantActivityAt;
      if (lastActivityAt == null) {
        return false;
      }

      return DateTime.now().difference(lastActivityAt) <
          _assistantStaleActivityWindow;
    }

    final now = DateTime.now();
    final lastAudioAt = _lastAssistantAudioChunkAt;
    if (lastAudioAt != null &&
        now.difference(lastAudioAt) < _assistantPostAudioGuardWindow) {
      return true;
    }

    if (now.difference(completedAt) < _assistantPostAudioGuardWindow) {
      return true;
    }

    return false;
  }

  bool get _shouldUseAssistantEchoGate {
    if (!_isAssistantTurnActive) {
      return false;
    }

    if (_isSpeakerMuted) {
      return false;
    }

    final now = DateTime.now();
    final expectedPlaybackUntil = _assistantPlaybackExpectedUntilAt;
    if (expectedPlaybackUntil != null &&
        now.difference(expectedPlaybackUntil) <
            _assistantPostAudioGuardWindow) {
      return true;
    }

    final lastAudioAt = _lastAssistantAudioChunkAt;
    if (lastAudioAt != null &&
        now.difference(lastAudioAt) < _assistantTurnIdleSpeechWindow) {
      return true;
    }

    final lastActivityAt = _lastAssistantActivityAt;
    if (lastActivityAt != null &&
        now.difference(lastActivityAt) < _assistantTurnIdleSpeechWindow) {
      return true;
    }

    return false;
  }

  void _extendAssistantPlaybackEstimate(int byteLength) {
    if (byteLength <= 0) {
      return;
    }

    final sampleCount = byteLength / 2;
    final durationMs = (sampleCount / _assistantPlaybackSampleRate * 1000)
        .ceil();
    if (durationMs <= 0) {
      return;
    }

    final now = DateTime.now();
    final currentExpectedUntil = _assistantPlaybackExpectedUntilAt;
    final startsAt =
        currentExpectedUntil != null && currentExpectedUntil.isAfter(now)
        ? currentExpectedUntil
        : now;
    _assistantPlaybackExpectedUntilAt = startsAt.add(
      Duration(milliseconds: durationMs),
    );
  }

  bool get _hasStaleAssistantPlaybackState {
    if (!_acceptAssistantAudioChunks ||
        _isResponding ||
        _isAssistantTurnActive) {
      return false;
    }

    return !_isAssistantBusyForUserTurn;
  }

  void _clearStaleAssistantTurnState() {
    if (!_hasStaleAssistantPlaybackState) {
      return;
    }

    _invalidateAssistantAudioQueue();
    _assistantPlaybackIdleTimer?.cancel();
    _acceptAssistantAudioChunks = false;
    _isAssistantTurnActive = false;
    _assistantPlaybackStartedAt = null;
    _assistantPlaybackExpectedUntilAt = null;
    _lastAssistantAudioChunkAt = null;
    _lastAssistantActivityAt = null;
    _assistantResponseCompletedAt = null;
    if (_isPlayerStarted) {
      unawaited(_stopPlayer());
    }
    _log('Cleared stale assistant playback state');
    _scheduleAudioIdleShutdownIfNeeded();
  }

  void _restartAssistantPlaybackIdleTimer() {
    _assistantPlaybackIdleTimer?.cancel();
    _assistantPlaybackIdleTimer = Timer(_assistantPlaybackIdleWindow, () async {
      _acceptAssistantAudioChunks = false;
      _isAssistantTurnActive = false;
      _assistantPlaybackExpectedUntilAt = null;
      _lastAssistantAudioChunkAt = null;
      _lastAssistantActivityAt = null;
      _assistantResponseCompletedAt = null;
      if (_isPlayerStarted) {
        await _stopPlayer();
      }
      _scheduleAudioIdleShutdownIfNeeded();
      notifyListeners();
    });
  }

  void _cancelAudioIdleTimer() {
    _audioIdleTimer?.cancel();
  }

  bool get _hasEnabledAudioOutputOrInput {
    return !_isMicMuted || !_isSpeakerMuted;
  }

  void _markAudioActivity() {
    _lastAudioActivityAt = DateTime.now();
    _scheduleAudioIdleShutdownIfNeeded();
  }

  void _scheduleAudioIdleShutdownIfNeeded() {
    _cancelAudioIdleTimer();

    if (!_hasEnabledAudioOutputOrInput ||
        _isMicToggleInProgress ||
        _isSpeakerToggleInProgress) {
      return;
    }

    final lastActivityAt = _lastAudioActivityAt ?? DateTime.now();
    final elapsed = DateTime.now().difference(lastActivityAt);
    final remaining = _audioIdleTimeout - elapsed;
    final delay = remaining.isNegative ? Duration.zero : remaining;

    _audioIdleTimer = Timer(delay, () async {
      if (!_hasEnabledAudioOutputOrInput ||
          _isMicToggleInProgress ||
          _isSpeakerToggleInProgress) {
        return;
      }

      final lastSeenActivityAt = _lastAudioActivityAt ?? DateTime.now();
      final idleFor = DateTime.now().difference(lastSeenActivityAt);
      if (idleFor < _audioIdleTimeout) {
        _scheduleAudioIdleShutdownIfNeeded();
        return;
      }

      _log('Mic and speaker were idle for 20 seconds; muting them');
      await _shutdownIdleAudioAfterInactivity();
    });
  }

  Future<void> _shutdownIdleAudioAfterInactivity() async {
    if (!_hasEnabledAudioOutputOrInput ||
        _isMicToggleInProgress ||
        _isSpeakerToggleInProgress) {
      return;
    }

    if (!_isMicMuted) {
      await _stopMicrophoneCapture(
        sendSttEnd: false,
        muteMic: true,
        keepVadActive: false,
      );
    }

    if (!_isSpeakerMuted) {
      _isSpeakerMuted = true;
      await _stopPlayer();
    }

    _cancelAudioIdleTimer();
    notifyListeners();
  }

  void _sendSttStartEvent() {
    if (_hasSentSttStart) {
      _log('_sendSttStartEvent skipped: already sent for current user turn');
      return;
    }

    if (!_isSocketConnected || _socketManager.assistantSocket == null) {
      _log('_sendSttStartEvent skipped: socket not connected');
      return;
    }

    try {
      _socketManager.sendAssistantMessage(const <String, dynamic>{
        'type': 'stt_start',
      });
      _hasSentSttStart = true;
      _log('stt_start event sent');
    } catch (error) {
      _log('stt_start event failed but was ignored: $error');
    }
  }

  Future<bool> _sendSttEndEvent() async {
    if (_hasSentSttEndForCurrentUtterance) {
      _log('_sendSttEndEvent skipped: already sent for current user turn');
      return true;
    }

    if (!_hasSentSttStart) {
      if (_isStreamingUserAudio) {
        _log(
          '_sendSttEndEvent attempting to restore stt_start on current socket before stt_end',
        );
        await _connectAssistantSocketIfNeeded();
        _sendSttStartEvent();
        if (_hasSentSttStart) {
          _sendBufferedUserAudioChunks(_consumeBufferedVadChunks());
        }
      }
    }

    if (!_hasSentSttStart) {
      _log(
        '_sendSttEndEvent skipped: stt_start was not sent for current user turn',
      );
      return false;
    }

    if (!_isSocketConnected || _socketManager.assistantSocket == null) {
      _log('_sendSttEndEvent reconnecting before stt_end');
      await _connectAssistantSocketIfNeeded();
    }

    if (!_isSocketConnected || _socketManager.assistantSocket == null) {
      _log('_sendSttEndEvent skipped: socket still not connected');
      return false;
    }

    try {
      _socketManager.sendAssistantMessage(const <String, dynamic>{
        'type': 'stt_end',
      });
      _hasSentSttEndForCurrentUtterance = true;
      _hasSentSttStart = false;
      _log('stt_end event sent');
      return true;
    } catch (error) {
      _log('stt_end event failed but was ignored: $error');
      return false;
    }
  }
}

class KaizenGptMessage {
  const KaizenGptMessage({
    required this.text,
    required this.isUser,
    this.conversationId,
  });

  final String text;
  final bool isUser;
  final String? conversationId;
}
