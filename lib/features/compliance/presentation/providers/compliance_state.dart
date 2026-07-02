import '../../domain/entities/compliance_overview.dart';
import '../../domain/entities/compliance_tab_type.dart';

class ComplianceState {
  const ComplianceState({
    this.isLoading = true,
    this.overview,
    this.selectedTab = ComplianceTabType.learningTrack,
  });

  final bool isLoading;
  final ComplianceOverview? overview;
  final ComplianceTabType selectedTab;

  ComplianceState copyWith({
    bool? isLoading,
    ComplianceOverview? overview,
    ComplianceTabType? selectedTab,
    bool clearOverview = false,
  }) {
    return ComplianceState(
      isLoading: isLoading ?? this.isLoading,
      overview: clearOverview ? null : overview ?? this.overview,
      selectedTab: selectedTab ?? this.selectedTab,
    );
  }
}
