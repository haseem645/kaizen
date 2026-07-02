import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/datasources/audit_remote_data_source.dart';
import '../../data/repositories/audit_repository_impl.dart';
import '../../domain/usecases/get_audit_overview_usecase.dart';
import '../../domain/usecases/get_quarterly_audit_usecase.dart';
import '../providers/audit_controller.dart';
import 'single_audit_report_category_details.dart';

class AuditReportScreen extends StatelessWidget {
  const AuditReportScreen({
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
        Provider<AuditRemoteDataSource>(create: (_) => createAuditRemoteDataSource()),
        ProxyProvider<AuditRemoteDataSource, AuditRepositoryImpl>(
          update: (_, remoteDataSource, __) => createAuditRepository(remoteDataSource),
        ),
        ProxyProvider<AuditRepositoryImpl, GetAuditOverviewUseCase>(
          update: (_, repository, __) => createGetAuditOverviewUseCase(repository),
        ),
        ProxyProvider<AuditRepositoryImpl, GetQuarterlyAuditUseCase>(
          update: (_, repository, __) => createGetQuarterlyAuditUseCase(repository),
        ),
        ChangeNotifierProvider<AuditController>(
          create: (context) => AuditController(
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
      child: SingleAuditReportCategoryDetailsScreen(
        profileJobId: profileJobId,
        quarter: initialQuarter,
        year: initialYear,
      ),
    );
  }
}
