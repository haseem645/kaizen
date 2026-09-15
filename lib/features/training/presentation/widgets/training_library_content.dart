import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/navigation/app_menu_type.dart';
import '../../../../core/widgets/drawer_main_screen.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../domain/entities/training_library_module.dart';
import '../controllers/training_library_controller.dart';
import 'training_library_create_action.dart';
import 'training_library_result_area.dart';
import 'training_library_search_bar.dart';

class TrainingLibraryContent extends StatelessWidget {
  const TrainingLibraryContent({
    super.key,
    required this.controller,
    required this.onOpenDetail,
    required this.onSelectSeat,
    required this.onCreate,
  });

  final TrainingLibraryController controller;
  final Future<bool?> Function(TrainingLibraryModule module, String view) onOpenDetail;
  final VoidCallback onSelectSeat;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return DrawerMainScreen(
      title: AppStrings.trainingLibraryTitle,
      selectedMenu: AppMenuType.library,
      centerTitle: true,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: controller.isShowingFullscreenLoading
                  ? Center(child: FastCircularProgressIndicator(width: 24, height: 24))
                  : _TrainingLibraryFiltersAndResults(
                      controller: controller,
                      onModuleTap: (module) =>
                          controller.openLibraryDetail(module, openDetail: onOpenDetail),
                      onSelectSeat: onSelectSeat,
                    ),
            ),
            if (!controller.isShowingFullscreenLoading && controller.canCreateTraining)
              TrainingLibraryCreateAction(onTap: () => controller.openCreateFlow(onOpen: onCreate)),
          ],
        ),
      ),
    );
  }
}

class _TrainingLibraryFiltersAndResults extends StatelessWidget {
  const _TrainingLibraryFiltersAndResults({
    required this.controller,
    required this.onModuleTap,
    required this.onSelectSeat,
  });

  final TrainingLibraryController controller;
  final ValueChanged<TrainingLibraryModule> onModuleTap;
  final VoidCallback onSelectSeat;

  @override
  Widget build(BuildContext context) {
    final items = controller.visibleItems;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TrainingLibrarySearchBar(controller: controller, onSelectSeat: onSelectSeat),
          const SizedBox(height: 24),
          Expanded(
            child: RefreshIndicator.noSpinner(
              onRefresh: controller.refresh,
              child: TrainingLibraryResultArea(
                controller: controller,
                items: items,
                scrollController: controller.scrollController,
                onModuleTap: onModuleTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
