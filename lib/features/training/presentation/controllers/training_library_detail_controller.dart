import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/training_library_module.dart';
import '../../domain/usecases/get_training_library_modules_usecase.dart';

class TrainingLibraryDetailController extends ChangeNotifier {
  TrainingLibraryDetailController({
    required TrainingLibraryModule initialModule,
    required GetTrainingLibraryModulesUseCase getTrainingLibraryModules,
    required String view,
  }) : _module = initialModule,
       _getTrainingLibraryModules = getTrainingLibraryModules,
       _view = view.trim().isEmpty ? 'list' : view.trim();

  static const int _pageSize = 25;

  final GetTrainingLibraryModulesUseCase _getTrainingLibraryModules;
  final String _view;

  TrainingLibraryModule _module;
  bool _isRefreshing = false;
  String? _errorMessage;

  TrainingLibraryModule get module => _module;
  bool get isRefreshing => _isRefreshing;
  String? get errorMessage => _errorMessage;

  Future<bool> refreshModule() async {
    final descriptionId = _module.id.trim();
    if (_isRefreshing || descriptionId.isEmpty) {
      return false;
    }

    _isRefreshing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final refreshedModule = await _findModuleByDescriptionId(descriptionId);
      if (refreshedModule == null) {
        _errorMessage = AppStrings.loginSomethingWentWrong;
        return false;
      }

      _module = refreshedModule;
      return true;
    } catch (error) {
      final resolvedMessage = error.toString().trim();
      _errorMessage = resolvedMessage.isEmpty
          ? AppStrings.loginSomethingWentWrong
          : resolvedMessage;
      return false;
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<TrainingLibraryModule?> _findModuleByDescriptionId(
    String descriptionId,
  ) async {
    var page = 1;
    var hasNextPage = true;

    while (hasNextPage) {
      final response = await _getTrainingLibraryModules(
        view: _view,
        page: page,
        pageSize: _pageSize,
        searchType: 'category',
        searchText: '',
      );

      for (final module in response.items) {
        if (module.id.trim() == descriptionId) {
          return module;
        }
      }

      hasNextPage = response.hasNextPage;
      page += 1;
    }

    return null;
  }
}
