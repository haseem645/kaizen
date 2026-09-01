import 'package:flutter/material.dart';

class _KaizengramViewNotifier extends ChangeNotifier {
  void trigger() {
    notifyListeners();
  }
}

mixin KaizengramNotifierState<T extends StatefulWidget> on State<T> {
  final _KaizengramViewNotifier _viewNotifier = _KaizengramViewNotifier();

  @protected
  void notifyView() {
    if (!mounted) {
      return;
    }

    _viewNotifier.trigger();
  }

  @protected
  void updateView([VoidCallback? mutation]) {
    mutation?.call();
    notifyView();
  }

  @protected
  Widget buildWithNotifier(Widget Function(BuildContext context) builder) {
    return ListenableBuilder(
      listenable: _viewNotifier,
      builder: (context, _) => builder(context),
    );
  }

  @override
  @mustCallSuper
  void dispose() {
    _viewNotifier.dispose();
    super.dispose();
  }
}
