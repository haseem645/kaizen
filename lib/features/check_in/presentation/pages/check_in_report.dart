import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/datasources/audit_remote_data_source.dart';
import '../../data/repositories/audit_repository_impl.dart';
import '../../domain/usecases/get_audit_overview_usecase.dart';
import '../../domain/usecases/get_quarterly_audit_usecase.dart';
import '../providers/check_in_controller.dart';
import 'single_check_in_report_category_details.dart';

class CheckInReportScreen extends StatelessWidget {
  const CheckInReportScreen({
    super.key,
    required this.profileJobId,
    this.initialYear,
    this.initialQuarter,
  });
  final String profileJobId;
  final int? initialYear;
  final int? initialQuarter;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuditRemoteDataSource>(
          create: (_) => createAuditRemoteDataSource(),
        ),
        ProxyProvider<AuditRemoteDataSource, AuditRepositoryImpl>(
          update: (_, remoteDataSource, __) =>
              createAuditRepository(remoteDataSource),
        ),
        ProxyProvider<AuditRepositoryImpl, GetAuditOverviewUseCase>(
          update: (_, repository, __) =>
              createGetAuditOverviewUseCase(repository),
        ),
        ProxyProvider<AuditRepositoryImpl, GetQuarterlyAuditUseCase>(
          update: (_, repository, __) =>
              createGetQuarterlyAuditUseCase(repository),
        ),
        ChangeNotifierProvider<CheckInController>(
          create: (context) => CheckInController(
            context.read<GetAuditOverviewUseCase>(),
            null,
            null,
            context.read<GetQuarterlyAuditUseCase>(),
            null,
            null,
            null,
            context.read<AuditRepositoryImpl>(),
          ),
        ),
      ],
      child: SingleCheckInReportCategoryDetailsScreen(
        profileJobId: profileJobId,
        quarter: initialQuarter,
        year: initialYear,
      ),
    );
  }
}
