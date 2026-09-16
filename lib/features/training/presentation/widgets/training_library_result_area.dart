import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../domain/entities/training_library_module.dart';
import '../controllers/training_library_controller.dart';
import 'training_library_module_card.dart';
import 'training_library_status_state.dart';

class TrainingLibraryResultArea extends StatelessWidget {
  const TrainingLibraryResultArea({
    super.key,
    required this.controller,
    required this.items,
    required this.scrollController,
    required this.onModuleTap,
    this.onModuleActions,
  });

  final TrainingLibraryController controller;
  final List<TrainingLibraryModule> items;
  final ScrollController scrollController;
  final ValueChanged<TrainingLibraryModule> onModuleTap;
  final ValueChanged<TrainingLibraryModule>? onModuleActions;

  VoidCallback? _actionsFor(TrainingLibraryModule module) =>
      onModuleActions != null && controller.canShowModuleActions(module)
      ? () => onModuleActions!(module)
      : null;

  @override
  Widget build(BuildContext context) {
    if (controller.isInlineLoading) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 48),
          Center(child: FastCircularProgressIndicator(width: 24, height: 24)),
        ],
      );
    }

    if (controller.errorMessage != null && controller.items.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          TrainingLibraryStatusState(
            message: controller.errorMessage!,
            actionLabel: AppStrings.trainingLibraryRetry,
            onActionTap: controller.initialize,
          ),
        ],
      );
    }

    if (items.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          TrainingLibraryStatusState(message: AppStrings.trainingLibraryNoModulesFound),
        ],
      );
    }

    return switch (controller.viewMode) {
      TrainingLibraryViewMode.grid => _TrainingLibraryGrid(
        items: items,
        scrollController: scrollController,
        onModuleTap: onModuleTap,
        actionsFor: _actionsFor,
      ),
      TrainingLibraryViewMode.list => _TrainingLibraryList(
        items: items,
        scrollController: scrollController,
        onModuleTap: onModuleTap,
        actionsFor: _actionsFor,
      ),
    };
  }
}

class _TrainingLibraryGrid extends StatelessWidget {
  const _TrainingLibraryGrid({
    required this.items,
    required this.scrollController,
    required this.onModuleTap,
    required this.actionsFor,
  });

  final List<TrainingLibraryModule> items;
  final ScrollController scrollController;
  final ValueChanged<TrainingLibraryModule> onModuleTap;
  final VoidCallback? Function(TrainingLibraryModule module) actionsFor;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 16.0;
        final crossAxisCount = constraints.maxWidth >= 1020
            ? 3
            : (constraints.maxWidth >= 620 ? 2 : 1);
        final cardWidth = (constraints.maxWidth - spacing * (crossAxisCount - 1)) / crossAxisCount;
        final textScaleExtra =
            (MediaQuery.textScalerOf(context).scale(16) - 16).clamp(0.0, double.infinity) * 6;
        final cardHeight = (cardWidth / 1.9).clamp(176.0, 280.0) + textScaleExtra;

        return GridView.builder(
          controller: scrollController,
          padding: const EdgeInsets.only(bottom: 16),
          physics: const AlwaysScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            mainAxisExtent: cardHeight,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return TrainingLibraryModuleCard(
              module: items[index],
              onTap: () => onModuleTap(items[index]),
              onLongPress: actionsFor(items[index]),
            );
          },
        );
      },
    );
  }
}

class _TrainingLibraryList extends StatelessWidget {
  const _TrainingLibraryList({
    required this.items,
    required this.scrollController,
    required this.onModuleTap,
    required this.actionsFor,
  });

  final List<TrainingLibraryModule> items;
  final ScrollController scrollController;
  final ValueChanged<TrainingLibraryModule> onModuleTap;
  final VoidCallback? Function(TrainingLibraryModule module) actionsFor;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 16),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return TrainingLibraryModuleCard(
          module: items[index],
          onTap: () => onModuleTap(items[index]),
          onLongPress: actionsFor(items[index]),
        );
      },
    );
  }
}
