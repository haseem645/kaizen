import 'package:flutter/foundation.dart';

import '../../domain/entities/compliance_track_item_detail.dart';
import '../../domain/usecases/get_compliance_track_item_detail_usecase.dart';

class ComplianceTrainingController extends ChangeNotifier {
  ComplianceTrainingController(this._getComplianceTrackItemDetailUseCase);

  final GetComplianceTrackItemDetailUseCase _getComplianceTrackItemDetailUseCase;

  bool _isLoading = true;
  ComplianceTrackItemDetail? _detail;

  bool get isLoading => _isLoading;
  ComplianceTrackItemDetail? get detail => _detail;

  Future<void> initialize({
    required String trackAssignmentUuid,
    required String itemUuid,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      _detail = await _getComplianceTrackItemDetailUseCase.call(
        trackAssignmentUuid: trackAssignmentUuid,
        itemUuid: itemUuid,
      );
    } catch (_) {
      _detail = null;
    }

    _isLoading = false;
    notifyListeners();
  }
}
