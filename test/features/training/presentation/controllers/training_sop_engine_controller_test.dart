import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/features/training/presentation/controllers/training_sop_editor_controller.dart';
import 'package:sparrowkaizen/features/training/presentation/controllers/training_sop_engine_controller.dart';
// The WebView package's platform test API is already installed transitively.
// ignore: depend_on_referenced_packages
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory temporaryDirectory;
  late _WebViewPlatform platform;
  late TrainingSopEditorController controller;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp('kaizen-sop-test-');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (call) async => temporaryDirectory.path,
    );
    platform = _WebViewPlatform();
    WebViewPlatform.instance = platform;
    controller = TrainingSopEditorController(
      initialHtml: '<p>Native SOP</p>',
      editor: TrainingSopEngineController(),
      onHtmlChanged: (_) => fail('Initialization must not save the document'),
    );
  });

  tearDown(() async {
    controller.dispose();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    await temporaryDirectory.delete(recursive: true);
  });

  test(
    'the first native document is initialized by the SOP engine without a bootstrap editor',
    () async {
      await controller.initialize(editable: false);
      expect(controller.isReady, isTrue);
      expect(controller.errorMessage, isNull);
      expect(platform.controller.commands.map((command) => command['name']), ['init']);
      expect(platform.controller.commands.single['payload'], {
        'content': '<p>Native SOP</p>',
        'editable': false,
      });
      expect(controller.editor.document!.content!.single.content!.single.text, 'Native SOP');
    },
  );

  test('a native init failure ends loading even when no document or ready event arrives', () async {
    platform.controller.failInit = true;
    await controller.initialize().timeout(const Duration(seconds: 2));
    expect(controller.isReady, isFalse);
    expect(controller.errorMessage, AppStrings.trainingSopEditorError);
  });
}

class _WebViewPlatform extends WebViewPlatform {
  late _WebViewController controller;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => controller = _WebViewController(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(PlatformWebViewWidgetCreationParams params) =>
      _WebViewWidget(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => _NavigationDelegate(params);
}

class _WebViewController extends PlatformWebViewController {
  _WebViewController(super.params) : super.implementation();

  final commands = <Map<String, dynamic>>[];
  final _channels = <String, JavaScriptChannelParams>{};
  late _NavigationDelegate _navigation;
  bool _sopInstalled = false;
  bool failInit = false;

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> addJavaScriptChannel(JavaScriptChannelParams params) async {
    _channels[params.name] = params;
  }

  @override
  Future<void> setPlatformNavigationDelegate(PlatformNavigationDelegate handler) async {
    _navigation = handler as _NavigationDelegate;
  }

  @override
  Future<void> loadFile(String absoluteFilePath) async {
    _navigation.onPageFinished(absoluteFilePath);
  }

  @override
  Future<void> runJavaScript(String javaScript) async {
    if (javaScript.contains('Adapter injected successfully')) {
      _send({'type': 'engineGlobalReady'});
    } else if (javaScript.contains('window.TrainingSopDocument=')) {
      _sopInstalled = true;
    } else if (javaScript.startsWith('TiptapEngine.handleCommand(')) {
      final json = javaScript
          .substring("TiptapEngine.handleCommand('".length, javaScript.length - 2)
          .replaceAll(r"\'", "'")
          .replaceAll(r'\\', r'\');
      final command = jsonDecode(json) as Map<String, dynamic>;
      commands.add(command);
      if (command['name'] == 'init') {
        if (!_sopInstalled) throw StateError('Document initialized with the wrong engine');
        if (failInit) throw StateError('Native init failed');
        _send({'type': 'event', 'name': 'schemaReady', 'payload': <String, dynamic>{}});
        _send({'type': 'event', 'name': 'ready', 'payload': <String, dynamic>{}});
        _send({
          'type': 'event',
          'name': 'stateChanged',
          'payload': {
            'editable': (command['payload'] as Map<String, dynamic>)['editable'],
            'doc': {
              'type': 'doc',
              'content': [
                {
                  'type': 'paragraph',
                  'content': [
                    {'type': 'text', 'text': 'Native SOP'},
                  ],
                },
              ],
            },
          },
        });
      }
      _send({'type': 'response', 'id': command['id'], 'success': true});
    }
  }

  void _send(Map<String, dynamic> message) =>
      _channels['TiptapBridge']!.onMessageReceived(JavaScriptMessage(message: jsonEncode(message)));
}

class _WebViewWidget extends PlatformWebViewWidget {
  _WebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}

class _NavigationDelegate extends PlatformNavigationDelegate {
  _NavigationDelegate(super.params) : super.implementation();

  late PageEventCallback onPageFinished;

  @override
  Future<void> setOnPageFinished(PageEventCallback callback) async => onPageFinished = callback;

  @override
  Future<void> setOnPageStarted(PageEventCallback callback) async {}

  @override
  Future<void> setOnProgress(ProgressCallback callback) async {}

  @override
  Future<void> setOnWebResourceError(WebResourceErrorCallback callback) async {}

  @override
  Future<void> setOnNavigationRequest(NavigationRequestCallback callback) async {}
}
