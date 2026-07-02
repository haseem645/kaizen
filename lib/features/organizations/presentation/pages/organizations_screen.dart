import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/managers/app_manager.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';

class OrganizationsScreen extends StatelessWidget {
  const OrganizationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appManager = context.watch<AppManager>();
    final organizations = appManager.visibleOrganizations;

    return Scaffold(
      backgroundColor: AppColors.mainBg,
      appBar: AppBar(
        backgroundColor: AppColors.mainBg,
        foregroundColor: AppColors.textPrimary,
        title: AppTextView.title1(
          AppStrings.organizationsTitle,
          color: AppColors.secondaryColor,
          fontSize: 24,
          fontWeight: FontWeight.w500,
        ),
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextView.body2(
                AppStrings.organizationsSandboxNote,
                color: AppColors.textSecondary,
                textAlign: TextAlign.left,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: appManager.isLoadingOrganizations && organizations.isEmpty
                    ? Center(child: FastCircularProgressIndicator())
                    : organizations.isEmpty
                    ? Center(
                        child: AppTextView.body(
                          AppStrings.organizationsNoItemsFound,
                          color: AppColors.textSecondary,
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.separated(
                        itemCount: organizations.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final organization = organizations[index];
                          final isLoading = appManager.activatingOrganizationId == organization.id;

                          return InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: appManager.isSettingActiveOrganization
                                ? null
                                : () =>
                                      _handleOrganizationTap(context, appManager, organization.id),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceDark,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: AppTextView.body2(
                                      organization.name,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (isLoading)
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: FastCircularProgressIndicator(),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleOrganizationTap(
    BuildContext context,
    AppManager appManager,
    String organizationId,
  ) async {
    final isSuccess = await appManager.setActiveOrganization(organizationId);
    if (isSuccess || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: AppTextView.body2(AppStrings.loginSomethingWentWrong)));
  }
}
