import '../../../compliance/data/datasources/compliance_remote_data_source.dart';
import '../../../compliance/domain/entities/compliance_document.dart';
import '../../../compliance/domain/entities/compliance_overview.dart';
import '../../../compliance/domain/entities/learning_module_detail_track.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../presentation/providers/kaizengram_controller.dart';

class KaizengramRemoteDataSource {
  KaizengramRemoteDataSource({
    ComplianceRemoteDataSource? complianceRemoteDataSource,
  }) : _complianceRemoteDataSource =
           complianceRemoteDataSource ?? ComplianceRemoteDataSource();

  final ComplianceRemoteDataSource _complianceRemoteDataSource;

  Future<List<KaizengramFeedItem>> fetchKaizenFeed({
    bool forceRefresh = false,
  }) async {
    final results = await Future.wait<dynamic>(<Future<dynamic>>[
      _complianceRemoteDataSource.getComplianceOverview(
        forceRefresh: forceRefresh,
      ),
      _complianceRemoteDataSource.getComplianceDocuments(
        forceRefresh: forceRefresh,
      ),
    ]);

    final overview = results[0] as ComplianceOverview;
    final documents = results[1] as List<ComplianceDocument>;

    final feed = <KaizengramFeedItem>[
      ...overview.learningTracks
          .where((track) => !track.isBreakPoint)
          .map(_feedFromLearningTrack),
      ...documents.map(_feedFromDocument),
    ];

    return List<KaizengramFeedItem>.unmodifiable(feed);
  }

  KaizengramFeedItem _feedFromLearningTrack(LearningTrackModuleDetail track) {
    final videoUrl = _normalizedUrl(track.videoUrl);
    final thumbnailUrl =
        _normalizedUrl(track.videoThumbnailLink) ??
        _normalizedUrl(track.thumbnailLink);
    final dueBy = _buildDueByLabel(track.deadline);
    final deadlineDate = _buildDeadlineDate(track.deadline);
    final schedule = _formatSchedule(track.schedule);

    return KaizengramFeedItem(
      id: track.uuid?.trim().isNotEmpty == true
          ? track.uuid!.trim()
          : (track.trainingModuleItemId?.trim().isNotEmpty == true
                ? track.trainingModuleItemId!.trim()
                : track.displayName),
      type: KaizengramFeedType.learningCompliance,
      title: _displayText(track.displayName, fallback: 'Learning Compliance'),
      description: track.displayStatus,
      status: track.displayStatus,
      seatProfile: _displayText(track.displayJob, fallback: 'No Job'),
      rawDeadline: _normalizedText(track.deadline),
      dueBy: dueBy,
      deadlineDate: deadlineDate,
      schedule: schedule,
      trackAssignmentUuid: _normalizedText(track.uuid),
      documentPreviewUrl: null,
      feedImageUrl: thumbnailUrl,
      feedVideoUrl: videoUrl,
      subtitle: 'Learning Compliance',
      timestampLabel: track.displayCreatedAt,
    );
  }

  KaizengramFeedItem _feedFromDocument(ComplianceDocument document) {
    final descriptionParts = <String>[
      document.category.trim(),
      document.status.trim(),
    ].where((value) => value.isNotEmpty).toList(growable: false);
    final latestDocumentUrl = _normalizedUrl(document.latestDocumentUrl);
    final thumbnailUrl = _normalizedUrl(document.latestDocumentThumbnailUrl);
    final isVideo = _isVideoUrl(latestDocumentUrl);

    return KaizengramFeedItem(
      id: document.id,
      type: KaizengramFeedType.documentCompliance,
      title: _displayText(document.title, fallback: 'Document Compliance'),
      description: descriptionParts.join(' • '),
      status: _documentStatusLabel(document),
      seatProfile: document.seatProfiles.isEmpty
          ? 'All Jobs'
          : document.seatProfiles.join(', '),
      rawDeadline: null,
      dueBy: null,
      deadlineDate: null,
      schedule: null,
      trackAssignmentUuid: null,
      documentPreviewUrl: latestDocumentUrl ?? thumbnailUrl,
      feedImageUrl: isVideo ? thumbnailUrl : (thumbnailUrl ?? latestDocumentUrl),
      feedVideoUrl: isVideo ? latestDocumentUrl : null,
      subtitle: 'Document Compliance',
      timestampLabel: document.updatedAt.trim().isEmpty
          ? 'Recent'
          : document.updatedAt.trim(),
    );
  }

  String _documentStatusLabel(ComplianceDocument document) {
    final rawStatus = CustomFunctions.normalizedStatus(document.rawStatus ?? document.status);
    if (rawStatus == 'compliant') {
      return 'Compliant';
    }

    if (rawStatus == 'pending submission') {
      return 'Pending Submission';
    }

    if (CustomFunctions.isNoLongerNeededStatus(rawStatus)) {
      return 'No Longer Required';
    }

    if (rawStatus == 'rejected') {
      return 'Rejected';
    }

    return document.status;
  }

  String? _normalizedUrl(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  String? _normalizedText(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  String _displayText(String? value, {required String fallback}) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty || _looksLikeIdentifier(trimmed)) {
      return fallback;
    }

    return trimmed;
  }

  bool _looksLikeIdentifier(String value) {
    final compact = value.trim();
    if (compact.isEmpty || compact.contains(' ')) {
      return false;
    }

    final uuidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (uuidPattern.hasMatch(compact)) {
      return true;
    }

    final identifierPattern = RegExp(r'^[A-Za-z0-9_-]{10,}$');
    return identifierPattern.hasMatch(compact);
  }

  bool _isVideoUrl(String? value) {
    if (value == null || value.isEmpty) {
      return false;
    }

    final uri = Uri.tryParse(value);
    final path = (uri?.path ?? value).toLowerCase();
    return path.endsWith('.mp4') ||
        path.endsWith('.mov') ||
        path.endsWith('.m4v') ||
        path.endsWith('.webm') ||
        path.endsWith('.h264');
  }

  String _buildDueByLabel(String? deadline) {
    final daysLeft = CustomFunctions.formatDeadlineInDays(deadline);
    if (daysLeft == 'No deadline') {
      return 'No deadline';
    }

    return daysLeft;
  }

  String _buildDeadlineDate(String? deadline) {
    final formattedDate = CustomFunctions.formatDate(deadline);
    if (formattedDate == 'No date') {
      return 'No deadline';
    }

    return formattedDate;
  }

  String _formatSchedule(String? value) {
    final resolved = _displayText(value, fallback: 'No schedule');
    return CustomFunctions.displayStatus(resolved) ?? resolved;
  }
}
