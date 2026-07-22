import '../../domain/entities/audit_description_audit.dart';
import '../../domain/entities/audit_details.dart';
import '../../domain/entities/audit_evaluation_chart.dart';
import '../../domain/entities/audit_list.dart';
import '../../domain/entities/audit_main_list.dart';
import '../../domain/entities/audit_profile.dart';
import '../../domain/entities/performance_report.dart';
import '../../domain/entities/quarterly_audit.dart';
import '../../domain/entities/seat_description_audit_report_comments.dart';
import '../../domain/entities/seat_description_final_audit_report.dart';
import '../../domain/entities/seat_description_training.dart';
import '../../domain/entities/single_audit_report_category_details.dart';
import '../../domain/repositories/audit_repository.dart';
import '../datasources/audit_remote_data_source.dart';

class AuditRepositoryImpl implements AuditRepository {
  const AuditRepositoryImpl(this._remoteDataSource);

  final AuditRemoteDataSource _remoteDataSource;

  @override
  Future<AuditMainList> getAuditMainList({
    required int page,
    required int pageSize,
    required int year,
    required int quarter,
  }) {
    return _remoteDataSource.getAuditMainList(
      page: page,
      pageSize: pageSize,
      year: year,
      quarter: quarter,
    );
  }

  @override
  Future<AuditMainList> getAuditTeamMembers({
    required int page,
    required int pageSize,
    int? year,
    int? quarter,
  }) {
    return _remoteDataSource.getAuditTeamMembers(
      page: page,
      pageSize: pageSize,
      year: year,
      quarter: quarter,
    );
  }

  @override
  Future<AuditMainList> getMyAudits({
    required int page,
    required int pageSize,
    int? year,
    int? quarter,
  }) {
    return _remoteDataSource.getMyAudits(
      page: page,
      pageSize: pageSize,
      year: year,
      quarter: quarter,
    );
  }

  @override
  Future<dynamic> getMyPerformanceSnapshot({
    required int page,
    required int pageSize,
  }) {
    return _remoteDataSource.getMyPerformanceSnapshot(
      page: page,
      pageSize: pageSize,
    );
  }

  @override
  Future<dynamic> getPerformanceSnapshot({
    required int page,
    required int pageSize,
  }) {
    return _remoteDataSource.getPerformanceSnapshot(
      page: page,
      pageSize: pageSize,
    );
  }

  Future<List<String>> getSubordinateJobTitles() {
    return _remoteDataSource.getSubordinateJobTitles();
  }

  @override
  Future<PerformanceReport> getPerformanceReportOverview({
    required AuditProfile profile,
    int? year,
    int? quarter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _remoteDataSource.getPerformanceReportOverview(
      profile: profile,
      year: year,
      quarter: quarter,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<Map<String, String>> getPerformanceReportRemarks({
    required AuditProfile profile,
    int? year,
    int? quarter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _remoteDataSource.getPerformanceReportRemarks(
      profile: profile,
      year: year,
      quarter: quarter,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<List<CertifiedReportOption>> getCertifiedReports({
    required AuditProfile profile,
    int? year,
    int? quarter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return _remoteDataSource.getCertifiedReports(
      profile: profile,
      year: year,
      quarter: quarter,
      startDate: startDate,
      endDate: endDate,
    );
  }

  @override
  Future<CertifiedReportDetail> getCertifiedReportDetail({
    required String certifiedReportUuid,
    required AuditProfile fallbackProfile,
  }) {
    return _remoteDataSource.getCertifiedReportDetail(
      certifiedReportUuid: certifiedReportUuid,
      fallbackProfile: fallbackProfile,
    );
  }

  @override
  Future<String> getCertifiedReportPdfUrl({
    required String certifiedReportUuid,
  }) {
    return _remoteDataSource.getCertifiedReportPdfUrl(
      certifiedReportUuid: certifiedReportUuid,
    );
  }

  @override
  Future<String?> certifyPerformanceReport({
    required String profileJobId,
    required Map<String, dynamic> payload,
  }) {
    return _remoteDataSource.certifyPerformanceReport(
      profileJobId: profileJobId,
      payload: payload,
    );
  }

  @override
  Future<AuditDetails> getAuditDetails({
    required String profileJobId,
    required int year,
    required int quarter,
  }) {
    return _remoteDataSource.getAuditDetails(
      profileJobId: profileJobId,
      year: year,
      quarter: quarter,
    );
  }

  @override
  Future<List<AuditEvaluationChart>> getAuditEvaluationChart({
    required String profileJobId,
  }) {
    return _remoteDataSource.getAuditEvaluationChart(
      profileJobId: profileJobId,
    );
  }

  @override
  Future<List<AuditList>> getAuditReport({
    required int quarter,
    required int year,
    required String profileJobId,
  }) {
    return _remoteDataSource.getAuditReport(
      quarter: quarter,
      year: year,
      profileJobId: profileJobId,
    );
  }

  @override
  Future<List<SingleAuditReportCategoryDetails>> getAuditReportCategoryDetails({
    required String categoryId,
    required int quarter,
    required int year,
  }) {
    return _remoteDataSource.getAuditReportCategoryDetails(
      categoryId: categoryId,
      quarter: quarter,
      year: year,
    );
  }

  @override
  Future<SeatDescriptionFinalAuditReport> getSeatDescriptionFinalAuditReport({
    required String flowFirstId,
    String? profileUuid,
    required String descriptionId,
    int? quarter,
    int? year,
    String? timeRange,
  }) {
    return _remoteDataSource.getSeatDescriptionFinalAuditReport(
      flowFirstId: flowFirstId,
      profileUuid: profileUuid,
      descriptionId: descriptionId,
      quarter: quarter,
      year: year,
      timeRange: timeRange,
    );
  }

  @override
  Future<SeatDescriptionAuditReportComments>
  getSeatDescriptionAuditReportComments({
    required String flowFirstId,
    String? profileUuid,
    required String descriptionId,
    int? quarter,
    int? year,
    String? timeRange,
  }) {
    return _remoteDataSource.getSeatDescriptionAuditReportComments(
      flowFirstId: flowFirstId,
      profileUuid: profileUuid,
      descriptionId: descriptionId,
      quarter: quarter,
      year: year,
      timeRange: timeRange,
    );
  }

  @override
  Future<List<SeatDescriptionFinalAuditProfile>>
  getSeatDescriptionAuditReportProfiles({
    required String flowFirstId,
    String? profileUuid,
    required String descriptionId,
    int? quarter,
    int? year,
    String? timeRange,
  }) {
    return _remoteDataSource.getSeatDescriptionAuditReportProfiles(
      flowFirstId: flowFirstId,
      profileUuid: profileUuid,
      descriptionId: descriptionId,
      quarter: quarter,
      year: year,
      timeRange: timeRange,
    );
  }

  @override
  Future<List<SeatDescriptionTrainingModule>>
  getSeatDescriptionTrainingModules({required String descriptionId}) {
    return _remoteDataSource.getSeatDescriptionTrainingModules(
      descriptionId: descriptionId,
    );
  }

  @override
  Future<SeatDescriptionTrainingModuleDetail>
  getSeatDescriptionTrainingModuleDetail({required String moduleId}) {
    return _remoteDataSource.getSeatDescriptionTrainingModuleDetail(
      moduleId: moduleId,
    );
  }

  @override
  Future<SeatDescriptionTrainingDocument>
  getSeatDescriptionTrainingModuleDocument({required String moduleId}) {
    return _remoteDataSource.getSeatDescriptionTrainingModuleDocument(
      moduleId: moduleId,
    );
  }

  @override
  Future<QuarterlyAudit> getQuarterlyAudit({
    required String quarterlyAuditId,
    required String date,
  }) {
    return _remoteDataSource.getQuarterlyAudit(
      quarterlyAuditId: quarterlyAuditId,
      date: date,
    );
  }

  @override
  Future<AuditDescriptionAudit> getAuditDescriptionAudit({
    required String quarterlyAuditId,
    required String descriptionId,
    required String date,
  }) {
    return _remoteDataSource.getAuditDescriptionAudit(
      quarterlyAuditId: quarterlyAuditId,
      descriptionId: descriptionId,
      date: date,
    );
  }

  @override
  Future<AuditDescriptionAudit> submitDescriptionAudit({
    required String descriptionId,
    required Map<String, int> audit,
  }) {
    return _remoteDataSource.submitDescriptionAudit(
      descriptionId: descriptionId,
      audit: audit,
    );
  }

  @override
  Future<String> generateAuditDescriptionMediaUploadUrl({
    required String fileName,
  }) {
    return _remoteDataSource.generateAuditDescriptionMediaUploadUrl(
      fileName: fileName,
    );
  }

  @override
  Future<void> uploadAuditDescriptionMediaFile({
    required String uploadUrl,
    required String fileName,
    required List<int> fileBytes,
    required String contentType,
  }) {
    return _remoteDataSource.uploadAuditDescriptionMediaFile(
      uploadUrl: uploadUrl,
      fileName: fileName,
      fileBytes: fileBytes,
      contentType: contentType,
    );
  }

  @override
  Future<void> createAuditDescriptionMedia({
    required String descriptionId,
    required String comment,
    String? mediaUrl,
    String? mediaType,
  }) {
    return _remoteDataSource.createAuditDescriptionMedia(
      descriptionId: descriptionId,
      comment: comment,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
    );
  }

  @override
  Future<void> createAuditDescriptionComment({
    required String descriptionId,
    required String comment,
  }) {
    return _remoteDataSource.createAuditDescriptionComment(
      descriptionId: descriptionId,
      comment: comment,
    );
  }

  @override
  Future<String> uploadPerformanceReportSignatureImage({
    required String fileName,
    required List<int> fileBytes,
    required String contentType,
  }) {
    return _remoteDataSource.uploadPerformanceReportSignatureImage(
      fileName: fileName,
      fileBytes: fileBytes,
      contentType: contentType,
    );
  }

  @override
  Future<void> markFavoriteSubordinate({required String profileJobId}) {
    return _remoteDataSource.markFavoriteSubordinate(
      profileJobId: profileJobId,
    );
  }

  @override
  Future<void> markUnfavoriteSubordinate({required String profileJobId}) {
    return _remoteDataSource.markUnfavoriteSubordinate(
      profileJobId: profileJobId,
    );
  }
}
