import 'compliance_document.dart';
import 'learning_module_detail_track.dart';

class ComplianceOverview {
  const ComplianceOverview({required this.learningTracks, required this.documents});

  final List<LearningTrackModuleDetail> learningTracks;
  final List<ComplianceDocument> documents;
}
