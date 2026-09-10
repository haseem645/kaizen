import 'package:flutter/foundation.dart';

/// Shares the selected tab between the training pager and bottom navigation.
class TrainingTabNavigationController extends ChangeNotifier {
  static const int tabCount = 4;

  int _selectedIndex = 0;
  bool _isDisposed = false;

  int get selectedIndex => _selectedIndex;

  void selectTab(int index) {
    if (_isDisposed || index < 0 || index >= tabCount) {
      return;
    }
    _selectedIndex = index;
    // A tap on the current tab must also settle an interrupted swipe.
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}
