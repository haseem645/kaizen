import 'package:flutter/foundation.dart';

class OperationCancelledException implements Exception {
  const OperationCancelledException([this.message = 'Operation cancelled.']);

  final String message;

  @override
  String toString() => message;
}

class OperationCancellationToken {
  bool _isCancelled = false;
  final List<VoidCallback> _listeners = <VoidCallback>[];

  bool get isCancelled => _isCancelled;

  void cancel() {
    if (_isCancelled) {
      return;
    }

    _isCancelled = true;
    final listeners = List<VoidCallback>.from(_listeners, growable: false);
    _listeners.clear();
    for (final listener in listeners) {
      listener();
    }
  }

  VoidCallback addListener(VoidCallback listener) {
    if (_isCancelled) {
      listener();
      return () {};
    }

    _listeners.add(listener);
    return () {
      _listeners.remove(listener);
    };
  }
}
