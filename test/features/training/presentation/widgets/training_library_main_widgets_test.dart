import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sparrowkaizen/core/constants/app_strings.dart';
import 'package:sparrowkaizen/features/seat_profile/domain/repositories/seat_profile_repository.dart';
import 'package:sparrowkaizen/features/seat_profile/domain/usecases/get_seat_profiles_usecase.dart';
import 'package:sparrowkaizen/features/training/domain/entities/training_library_module.dart';
import 'package:sparrowkaizen/features/training/domain/entities/training_library_page.dart';
import 'package:sparrowkaizen/features/training/domain/repositories/training_library_repository.dart';
import 'package:sparrowkaizen/features/training/domain/usecases/get_training_library_modules_usecase.dart';
import 'package:sparrowkaizen/features/training/presentation/controllers/training_library_controller.dart';
import 'package:sparrowkaizen/features/training/presentation/widgets/training_library_department_filter_strip.dart';
import 'package:sparrowkaizen/features/training/presentation/widgets/training_library_module_card.dart';
import 'package:sparrowkaizen/features/training/presentation/widgets/training_library_result_area.dart';
import 'package:sparrowkaizen/features/training/presentation/widgets/training_library_search_bar.dart';

void main() {
  late TrainingLibraryController controller;

  setUp(() async {
    controller = TrainingLibraryController(
      GetTrainingLibraryModulesUseCase(_LibraryRepository()),
      getSeatProfilesUseCase: GetSeatProfilesUseCase(_SeatRepository()),
    );
    await controller.initialize();
  });

  tearDown(() => controller.dispose());

  testWidgets(
    'search keeps its height and both filter buttons open seat selection',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var openedSeats = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListenableBuilder(
                listenable: controller,
                builder: (context, _) => TrainingLibrarySearchBar(
                  controller: controller,
                  onSelectSeat: () => openedSeats++,
                ),
              ),
            ),
          ),
        ),
      );
      final height = tester
          .getSize(find.byType(TrainingLibrarySearchBar))
          .height;
      await tester.tap(find.byIcon(Icons.arrow_drop_down_rounded));
      await tester.tap(find.byIcon(Icons.tune_rounded));
      expect(openedSeats, 2);
      await tester.enterText(find.byType(TextField), 'Seat');
      await tester.pump();
      expect(controller.searchQuery, 'Seat');
      expect(
        tester.getSize(find.byType(TrainingLibrarySearchBar)).height,
        height,
      );
      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      expect(
        tester.getSize(find.byType(TrainingLibrarySearchBar)).height,
        height,
      );
      expect(tester.takeException(), isNull);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'department See All and module cards keep their action callbacks',
    (tester) async {
      var openedDepartments = false;
      TrainingLibraryModule? openedModule;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TrainingLibraryDepartmentFilterStrip(
                  controller: controller,
                  onSeeAll: () => openedDepartments = true,
                ),
                Expanded(
                  child: TrainingLibraryResultArea(
                    controller: controller,
                    items: controller.visibleItems,
                    scrollController: controller.scrollController,
                    onModuleTap: (module) => openedModule = module,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text(AppStrings.seeAllAction));
      expect(openedDepartments, isTrue);
      await tester.tap(find.byType(TrainingLibraryModuleCard));
      expect(openedModule, same(controller.items.single));
      expect(tester.takeException(), isNull);
    },
  );
}

class _SeatRepository extends Fake implements SeatProfileRepository {}

class _LibraryRepository extends Fake implements TrainingLibraryRepository {
  @override
  Future<TrainingLibraryPage> getTrainingLibraryModules({
    required String view,
    required int page,
    int pageSize = 10,
    String searchType = 'category',
    String searchText = '',
    String? departmentId,
  }) async => TrainingLibraryPage(
    items: const [
      TrainingLibraryModule(
        id: 'module',
        title: 'Module',
        description: '',
        department: TrainingLibraryDepartment(
          id: 'department',
          name: 'Department',
        ),
        totalDuration: 60,
        seat: TrainingLibrarySeat(id: 'seat', title: 'Seat'),
        lessons: [],
        thumbnailLink: null,
        category: TrainingLibraryCategory(id: 'category', title: 'Category'),
      ),
    ],
    hasNextPage: false,
  );
}
