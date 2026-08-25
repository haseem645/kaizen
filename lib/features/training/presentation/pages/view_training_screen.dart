import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';
import '../../../check_in/data/datasources/audit_remote_data_source.dart';
import '../../../check_in/data/repositories/audit_repository_impl.dart';
import '../../../compliance/presentation/widgets/compliance_video_player.dart';
import '../../domain/entities/seat_description_training.dart';
import '../../domain/entities/seat_description_training_route.dart';
import '../controllers/training_module_controller.dart';

class ViewTrainingScreen extends StatelessWidget {
  const ViewTrainingScreen({super.key, required this.trainingRoute});

  final SeatDescriptionTrainingRoute trainingRoute;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuditRemoteDataSource>(create: (_) => AuditRemoteDataSource()),
        ProxyProvider<AuditRemoteDataSource, AuditRepositoryImpl>(
          update: (_, remoteDataSource, __) => AuditRepositoryImpl(remoteDataSource),
        ),
        ChangeNotifierProvider<TrainingModuleController>(
          create: (context) =>
              TrainingModuleController(context.read<AuditRepositoryImpl>())..initialize(
                jobId: trainingRoute.job,
                descriptionId: trainingRoute.description,
                initialModuleId: trainingRoute.initialModuleId,
              ),
        ),
      ],
      child: const _ViewTrainingScreenView(),
    );
  }
}

class _ViewTrainingScreenView extends StatefulWidget {
  const _ViewTrainingScreenView();

  @override
  State<_ViewTrainingScreenView> createState() => _ViewTrainingScreenViewState();
}

class _ViewTrainingScreenViewState extends State<_ViewTrainingScreenView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  var _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (_tabController.indexIsChanging || _selectedTabIndex == _tabController.index) {
      return;
    }

    final controller = context.read<TrainingModuleController>();

    setState(() {
      _selectedTabIndex = _tabController.index;
    });

    if (_selectedTabIndex == 1) {
      controller.loadDocumentForSelectedModule();
      return;
    }

    if (_selectedTabIndex == 2) {
      controller.loadQuestionsForSelectedModule();
      return;
    }

    if (_selectedTabIndex == 3) {
      controller.loadAssignmentForSelectedModule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingModuleController>();

    return Scaffold(
      backgroundColor: AppColors.mainBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(padding: const EdgeInsets.fromLTRB(16, 2, 16, 0), child: _buildHeader(context)),
            const SizedBox(height: 18),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _buildBody(controller),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.of(context).pop(),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: SvgPicture.asset(
                  '${AppStrings.imagePath}back.svg',
                  height: 24,
                  width: 24,
                  colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                ),
              ),
            ),
          ),
          const AppTextView.body(
            AppStrings.seatProfileTrainings,
            color: AppColors.secondaryColor,
            fontSize: 20,
            fontWeight: FontWeight.w500,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(TrainingModuleController controller) {
    if (controller.isLoading && controller.modules.isEmpty) {
      return Center(child: FastCircularProgressIndicator());
    }

    if (controller.errorMessage != null && controller.modules.isEmpty) {
      return _CenteredMessage(message: controller.errorMessage!);
    }

    if (controller.modules.isEmpty) {
      return const _CenteredMessage(message: AppStrings.trainingNoModulesAvailable);
    }

    return ListView(
      children: [
        if (controller.modules.length > 1) ...[
          _ModuleSelector(
            modules: controller.modules,
            selectedModuleId: controller.selectedModuleId,
            onModuleSelected: (moduleId) async {
              if (moduleId == controller.selectedModuleId) {
                await _syncSelectedTabData(controller);
                return;
              }

              await controller.selectModule(moduleId);
              if (!mounted) {
                return;
              }
              await _syncSelectedTabData(controller);
            },
          ),
          const SizedBox(height: 18),
        ],
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (controller.selectedModuleTitle.isNotEmpty) ...[
                AppTextView.body1(
                  controller.selectedModuleTitle,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
                const SizedBox(height: 14),
              ],
              _TrainingTabs(controller: _tabController),
              const SizedBox(height: 18),
              _buildTabContent(controller),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabContent(TrainingModuleController controller) {
    if (controller.isLoading && controller.selectedModuleDetail == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(child: FastCircularProgressIndicator()),
      );
    }

    if (controller.errorMessage != null && controller.selectedModuleDetail == null) {
      return _ContentMessage(message: controller.errorMessage!);
    }

    if (_selectedTabIndex == 0) {
      return _VideoTabContent(detail: controller.selectedModuleDetail);
    }

    if (_selectedTabIndex == 1) {
      return _SopTabContent(
        isLoading: controller.isDocumentLoading,
        errorMessage: controller.documentErrorMessage,
        document: controller.selectedModuleDocument,
      );
    }

    if (_selectedTabIndex == 2) {
      return _QuizTabContent(
        isLoading: controller.isQuestionsLoading,
        errorMessage: controller.questionsErrorMessage,
        questions: controller.selectedModuleQuestions,
      );
    }

    return _AssignmentTabContent(
      isLoading: controller.isAssignmentLoading,
      errorMessage: controller.assignmentErrorMessage,
      assignment: controller.selectedModuleAssignment,
    );
  }

  Future<void> _syncSelectedTabData(TrainingModuleController controller) async {
    if (_selectedTabIndex == 1) {
      await controller.loadDocumentForSelectedModule();
      return;
    }

    if (_selectedTabIndex == 2) {
      await controller.loadQuestionsForSelectedModule();
      return;
    }

    if (_selectedTabIndex == 3) {
      await controller.loadAssignmentForSelectedModule();
    }
  }
}

class _TrainingTabs extends StatelessWidget {
  const _TrainingTabs({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: controller,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelPadding: EdgeInsets.zero,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorColor: AppColors.secondaryColor,
      labelColor: AppColors.secondaryColor,
      unselectedLabelColor: AppColors.textSecondary,
      dividerColor: AppColors.fieldBorder.withValues(alpha: 0.22),
      tabs: const <Widget>[
        _TrainingTabLabel(label: AppStrings.trainingVideoTab),
        _TrainingTabLabel(label: AppStrings.trainingSopTab),
        _TrainingTabLabel(label: AppStrings.trainingQuizTab),
        _TrainingTabLabel(label: AppStrings.trainingAssignmentTab),
      ],
    );
  }
}

class _TrainingTabLabel extends StatelessWidget {
  const _TrainingTabLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 22),
      child: Tab(
        child: Padding(
          padding: const EdgeInsets.only(left: 22, right: 14),
          child: AppTextView.body2(label, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _ModuleSelector extends StatelessWidget {
  const _ModuleSelector({
    required this.modules,
    required this.selectedModuleId,
    required this.onModuleSelected,
  });

  final List<SeatDescriptionTrainingModule> modules;
  final String selectedModuleId;
  final Future<void> Function(String moduleId) onModuleSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: modules.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final module = modules[index];
          return _ModuleCard(
            module: module,
            isSelected: module.uuid == selectedModuleId,
            onTap: () => onModuleSelected(module.uuid),
          );
        },
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({required this.module, required this.isSelected, required this.onTap});

  final SeatDescriptionTrainingModule module;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final resolvedThumbnail = CustomFunctions.resolveImageUrl(module.thumbnailLink);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 228,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark.withValues(alpha: 0.84),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? AppColors.secondaryColor.withValues(alpha: 0.55)
                : AppColors.fieldBorder.withValues(alpha: 0.22),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 76,
                height: 76,
                child: resolvedThumbnail == null
                    ? const _ModuleThumbnailPlaceholder()
                    : CachedNetworkImage(
                        imageUrl: resolvedThumbnail,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const _ModuleThumbnailPlaceholder(),
                        errorWidget: (_, _, _) => const _ModuleThumbnailPlaceholder(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AppTextView.body2(
                module.title,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModuleThumbnailPlaceholder extends StatelessWidget {
  const _ModuleThumbnailPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      '${AppStrings.imagePath}fallback.png',
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) {
        return Container(
          color: AppColors.mainBg,
          alignment: Alignment.center,
          child: const Icon(
            Icons.play_circle_outline_rounded,
            color: AppColors.textSecondary,
            size: 24,
          ),
        );
      },
    );
  }
}

class _VideoTabContent extends StatelessWidget {
  const _VideoTabContent({required this.detail});

  final SeatDescriptionTrainingModuleDetail? detail;

  @override
  Widget build(BuildContext context) {
    final video = detail?.trainingVideo;
    final videoUrl = video?.url?.trim();
    final summary = detail?.description?.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (videoUrl != null && videoUrl.isNotEmpty)
          ComplianceVideoPlayer(
            videoUrl: videoUrl,
            title: detail?.title ?? '',
            thumbnailLink: detail?.previewThumbnailLink,
            fillBounds: true,
          )
        else
          const _ContentMessage(message: AppStrings.trainingNoVideoAvailable),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.mainBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.18)),
          ),
          child: AppTextView.body3(
            summary != null && summary.isNotEmpty
                ? CustomFunctions.stripHtmlTags(summary)
                : AppStrings.trainingNoSummaryAvailable,
            color: AppColors.textPrimary,
            height: 1.65,
          ),
        ),
      ],
    );
  }
}

class _SopTabContent extends StatelessWidget {
  const _SopTabContent({
    required this.isLoading,
    required this.errorMessage,
    required this.document,
  });

  final bool isLoading;
  final String? errorMessage;
  final SeatDescriptionTrainingDocument? document;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 36),
        child: Center(child: FastCircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return _ContentMessage(message: errorMessage!);
    }

    final html = document?.text?.trim();
    if (html == null || html.isEmpty) {
      return const _ContentMessage(message: AppStrings.trainingNoSopAvailable);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.18)),
      ),
      child: Html(
        data: html,
        shrinkWrap: true,
        style: {
          'body': Style(
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
            color: AppColors.textPrimary,
            fontSize: FontSize(13),
            fontWeight: FontWeight.w400,
            lineHeight: const LineHeight(1.65),
          ),
          'p': Style(margin: Margins.only(bottom: 12), lineHeight: const LineHeight(1.65)),
          'ul': Style(margin: Margins.only(bottom: 12)),
          'ol': Style(margin: Margins.only(bottom: 12)),
          'li': Style(margin: Margins.only(bottom: 6)),
          'h1': _headingStyle(20),
          'h2': _headingStyle(18),
          'h3': _headingStyle(16),
          'h4': _headingStyle(15),
          'h5': _headingStyle(14),
          'h6': _headingStyle(14),
          'a': Style(color: AppColors.secondaryColor),
        },
      ),
    );
  }

  Style _headingStyle(double fontSize) => Style(
    margin: Margins.only(bottom: 10),
    color: AppColors.textPrimary,
    fontSize: FontSize(fontSize),
    fontWeight: FontWeight.w700,
    lineHeight: const LineHeight(1.35),
  );
}

class _QuizTabContent extends StatelessWidget {
  const _QuizTabContent({
    required this.isLoading,
    required this.errorMessage,
    required this.questions,
  });

  final bool isLoading;
  final String? errorMessage;
  final List<SeatDescriptionTrainingQuestion> questions;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(child: FastCircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return _ContentMessage(message: errorMessage!);
    }

    if (questions.isEmpty) {
      return const _ContentMessage(message: AppStrings.trainingNoQuizQuestionsAvailable);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var index = 0; index < questions.length; index++) ...[
          _QuizQuestionCard(number: index + 1, question: questions[index]),
          if (index != questions.length - 1) const SizedBox(height: 14),
        ],
      ],
    );
  }
}

class _AssignmentTabContent extends StatelessWidget {
  const _AssignmentTabContent({
    required this.isLoading,
    required this.errorMessage,
    required this.assignment,
  });

  final bool isLoading;
  final String? errorMessage;
  final SeatDescriptionTrainingAssignment? assignment;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 36),
        child: Center(child: FastCircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return _ContentMessage(message: errorMessage!);
    }

    final title = assignment?.title?.trim();
    final instructions = assignment?.instructions?.trim();
    final hasTitle = title != null && title.isNotEmpty;
    final hasInstructions = instructions != null && instructions.isNotEmpty;
    if (!hasTitle && !hasInstructions) {
      return const _ContentMessage(message: AppStrings.trainingNoAssignmentAvailable);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasTitle) ...[
          const AppTextView.body3(
            AppStrings.trainingLessonTitle,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.mainBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.18)),
            ),
            child: AppTextView.body2(
              title,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
        ],
        if (hasTitle && hasInstructions) const SizedBox(height: 18),
        if (hasInstructions) ...[
          const AppTextView.body3(
            AppStrings.trainingAssignmentDescriptionLabel,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.mainBg,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.18)),
            ),
            child: Html(
              data: instructions,
              shrinkWrap: true,
              style: {
                'body': Style(
                  margin: Margins.zero,
                  padding: HtmlPaddings.zero,
                  color: AppColors.textPrimary,
                  fontSize: FontSize(13),
                  fontWeight: FontWeight.w400,
                  lineHeight: const LineHeight(1.65),
                ),
                'p': Style(margin: Margins.only(bottom: 12), lineHeight: const LineHeight(1.65)),
                'ul': Style(margin: Margins.only(bottom: 12)),
                'ol': Style(margin: Margins.only(bottom: 12)),
                'li': Style(margin: Margins.only(bottom: 6)),
                'h1': _htmlHeadingStyle(20),
                'h2': _htmlHeadingStyle(18),
                'h3': _htmlHeadingStyle(16),
                'h4': _htmlHeadingStyle(15),
                'h5': _htmlHeadingStyle(14),
                'h6': _htmlHeadingStyle(14),
                'a': Style(color: AppColors.secondaryColor),
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _QuizQuestionCard extends StatelessWidget {
  const _QuizQuestionCard({required this.number, required this.question});

  final int number;
  final SeatDescriptionTrainingQuestion question;

  @override
  Widget build(BuildContext context) {
    final resolvedImageUrl = CustomFunctions.resolveImageUrl(question.imageUrl);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextView.body3(
            '$number. ${question.question}',
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            height: 1.45,
          ),
          if (resolvedImageUrl != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: resolvedImageUrl,
                height: 160,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          if (question.options.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (var index = 0; index < question.options.length; index++) ...[
              _QuizOptionTile(
                text: question.options[index].text,
                isSelected: question.selectedOptionUuid == question.options[index].uuid,
              ),
              if (index != question.options.length - 1) const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class _QuizOptionTile extends StatelessWidget {
  const _QuizOptionTile({required this.text, required this.isSelected});

  final String text;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 14,
          height: 14,
          margin: const EdgeInsets.only(top: 3, right: 8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? AppColors.secondaryColor : AppColors.textSecondary,
              width: 1.4,
            ),
          ),
          child: isSelected
              ? Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.secondaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                )
              : null,
        ),
        Expanded(
          child: AppTextView.body3(
            text,
            color: isSelected ? AppColors.secondaryColor : AppColors.textPrimary,
            height: 1.4,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

Style _htmlHeadingStyle(double fontSize) => Style(
  margin: Margins.only(bottom: 10),
  color: AppColors.textPrimary,
  fontSize: FontSize(fontSize),
  fontWeight: FontWeight.w700,
  lineHeight: const LineHeight(1.35),
);

class _ContentMessage extends StatelessWidget {
  const _ContentMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: AppColors.mainBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.fieldBorder.withValues(alpha: 0.18)),
      ),
      child: AppTextView.body3(
        message,
        color: AppColors.textSecondary,
        textAlign: TextAlign.center,
        height: 1.55,
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppTextView.body(message, color: AppColors.textSecondary, textAlign: TextAlign.center),
    );
  }
}
