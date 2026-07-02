import 'package:flutter/material.dart';

import '../../data/datasources/seat_profile_remote_data_source.dart';
import '../../data/repositories/seat_profile_repository_impl.dart';
import '../../domain/entities/seat_profile_detail.dart';
import '../../domain/usecases/get_seat_profiles_usecase.dart';

class SeatProfileDetailController extends ChangeNotifier {
  SeatProfileDetailController(this._getSeatProfilesUseCase);

  final GetSeatProfilesUseCase _getSeatProfilesUseCase;

  bool _isLoading = false;
  String? _errorMessage;
  SeatProfileDetail? _detail;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  SeatProfileDetail? get detail => _detail;

  Future<void> initialize(String seatId) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _detail = await _getSeatProfilesUseCase.getSeatProfileDetail(seatId);
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}

SeatProfileRepositoryImpl createSeatProfileDetailRepository(
  SeatProfileRemoteDataSource remoteDataSource,
) {
  return SeatProfileRepositoryImpl(remoteDataSource);
}

GetSeatProfilesUseCase createGetSeatProfileDetailUseCase(
  SeatProfileRepositoryImpl repository,
) {
  return GetSeatProfilesUseCase(repository);
}
