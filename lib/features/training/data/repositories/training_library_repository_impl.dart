import '../../domain/entities/training_library_page.dart';
import '../../domain/repositories/training_library_repository.dart';
import '../datasources/training_library_remote_data_source.dart';

class TrainingLibraryRepositoryImpl implements TrainingLibraryRepository {
  const TrainingLibraryRepositoryImpl(this._remoteDataSource);

  final TrainingLibraryRemoteDataSource _remoteDataSource;

  @override
  Future<TrainingLibraryPage> getTrainingLibraryModules({
    required String view,
    required int page,
    int pageSize = 10,
    String searchType = 'category',
    String searchText = '',
    String? departmentId,
  }) {
    return _remoteDataSource.getTrainingLibraryModules(
      view: view,
      page: page,
      pageSize: pageSize,
      searchType: searchType,
      searchText: searchText,
      departmentId: departmentId,
    );
  }
}

TrainingLibraryRepositoryImpl createTrainingLibraryRepository(
  TrainingLibraryRemoteDataSource remoteDataSource,
) {
  return TrainingLibraryRepositoryImpl(remoteDataSource);
}
