import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/managers/app_manager.dart';
import '../../../../routes/app_router.dart';
import '../../../seat_profile/data/datasources/seat_profile_remote_data_source.dart';
import '../../../seat_profile/data/repositories/seat_profile_repository_impl.dart';
import '../../../seat_profile/domain/usecases/get_seat_profiles_usecase.dart';
import '../../data/datasources/training_library_remote_data_source.dart';
import '../../data/repositories/training_library_repository_impl.dart';
import '../../domain/usecases/get_training_library_modules_usecase.dart';
import '../controllers/training_library_controller.dart';
import '../widgets/training_library_content.dart';
import '../widgets/training_library_department_selection_sheet.dart';
import '../widgets/training_library_seat_selection_sheet.dart';
import 'training_library_detail_screen.dart';

class TrainingLibraryScreen extends StatelessWidget {
  const TrainingLibraryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<TrainingLibraryRemoteDataSource>(
          create: (_) => createTrainingLibraryRemoteDataSource(),
        ),
        ProxyProvider<TrainingLibraryRemoteDataSource, TrainingLibraryRepositoryImpl>(
          update: (_, remoteDataSource, __) => createTrainingLibraryRepository(remoteDataSource),
        ),
        ProxyProvider<TrainingLibraryRepositoryImpl, GetTrainingLibraryModulesUseCase>(
          update: (_, repository, __) => createGetTrainingLibraryModulesUseCase(repository),
        ),
        Provider<SeatProfileRemoteDataSource>(create: (_) => createSeatProfileRemoteDataSource()),
        ProxyProvider<SeatProfileRemoteDataSource, SeatProfileRepositoryImpl>(
          update: (_, remoteDataSource, __) => SeatProfileRepositoryImpl(remoteDataSource),
        ),
        ProxyProvider<SeatProfileRepositoryImpl, GetSeatProfilesUseCase>(
          update: (_, repository, __) => GetSeatProfilesUseCase(repository),
        ),
        ChangeNotifierProvider<TrainingLibraryController>(
          create: (context) => TrainingLibraryController(
            context.read<GetTrainingLibraryModulesUseCase>(),
            getSeatProfilesUseCase: context.read<GetSeatProfilesUseCase>(),
            canCreateTraining: () => AppManager.instance.currentUserCanOpenTrainingModuleCreateFlow,
          )..initialize(),
        ),
      ],
      child: const _TrainingLibraryScreenView(),
    );
  }
}

class _TrainingLibraryScreenView extends StatelessWidget {
  const _TrainingLibraryScreenView();

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<TrainingLibraryController>();
    return ListenableBuilder(
      listenable: AppManager.instance,
      builder: (context, _) => TrainingLibraryContent(
        controller: controller,
        onOpenDetail: (module, view) => Navigator.of(context).push<bool>(
          MaterialPageRoute<bool>(
            builder: (_) => TrainingLibraryDetailScreen(module: module, view: view),
          ),
        ),
        onSelectDepartment: () =>
            showTrainingLibraryDepartmentSelectionSheet(context, controller: controller),
        onSelectSeat: () => showTrainingLibrarySeatSelectionSheet(context, controller: controller),
        onCreate: () => AppRouter.pushNamed(context, AppRouter.seatProfileTrainingSetup),
      ),
    );
  }
}
