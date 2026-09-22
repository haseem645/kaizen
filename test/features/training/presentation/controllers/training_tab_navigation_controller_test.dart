import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/features/training/presentation/controllers/training_tab_navigation_controller.dart';

void main() {
  late TrainingTabNavigationController navigation;

  setUp(() => navigation = TrainingTabNavigationController());
  tearDown(() => navigation.dispose());

  test('selection is shared for all four tabs', () {
    final selections = <int>[];
    navigation.addListener(() => selections.add(navigation.selectedIndex));
    for (final index in [1, 0, 2, 3]) {
      navigation.selectTab(index);
    }
    expect(selections, [1, 0, 2, 3]);
  });

  test('selecting the same tab notifies the pager to settle an unfinished swipe', () {
    var requests = 0;
    navigation.addListener(() => requests++);
    navigation.selectTab(0);
    navigation.selectTab(0);
    expect(requests, 2);
    expect(navigation.selectedIndex, 0);
  });

  test('invalid indices cannot change the selected tab', () {
    navigation.selectTab(2);
    var requests = 0;
    navigation.addListener(() => requests++);
    navigation.selectTab(-1);
    navigation.selectTab(4);
    expect(navigation.selectedIndex, 2);
    expect(requests, 0);
  });
}
