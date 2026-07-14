import 'package:flutter/material.dart';

import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/seat_description_training.dart';
import '../../domain/repositories/audit_repository.dart';

class AuditViewTrainingController extends ChangeNotifier {
  AuditViewTrainingController(this._auditRepository);

  final AuditRepository _auditRepository;

  bool _isLoading = false;
  bool _isDocumentLoading = false;
  String? _errorMessage;
  String? _documentErrorMessage;
  List<SeatDescriptionTrainingModule> _modules =
      const <SeatDescriptionTrainingModule>[];
  SeatDescriptionTrainingModuleDetail? _selectedModuleDetail;
  SeatDescriptionTrainingDocument? _selectedModuleDocument;
  String _selectedModuleId = '';

  bool get isLoading => _isLoading;
  bool get isDocumentLoading => _isDocumentLoading;
  String? get errorMessage => _errorMessage;
  String? get documentErrorMessage => _documentErrorMessage;
  List<SeatDescriptionTrainingModule> get modules => _modules;
  String get selectedModuleId => _selectedModuleId;
  SeatDescriptionTrainingModuleDetail? get selectedModuleDetail =>
      _selectedModuleDetail;
  SeatDescriptionTrainingDocument? get selectedModuleDocument =>
      _selectedModuleDocument;

  String get selectedModuleTitle {
    final detailTitle = _selectedModuleDetail?.title.trim();
    if (detailTitle != null && detailTitle.isNotEmpty) {
      return detailTitle;
    }

    for (final module in _modules) {
      if (module.uuid == _selectedModuleId) {
        return module.title;
      }
    }

    return '';
  }

  Future<void> initialize({required String descriptionId}) async {
    final resolvedDescriptionId = descriptionId.trim();
    if (resolvedDescriptionId.isEmpty) {
      _errorMessage = AppStrings.loginSomethingWentWrong;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _documentErrorMessage = null;
    _modules = const <SeatDescriptionTrainingModule>[];
    _selectedModuleId = '';
    _selectedModuleDetail = null;
    _selectedModuleDocument = null;
    notifyListeners();

    try {
      final modules = await _auditRepository.getSeatDescriptionTrainingModules(
        descriptionId: resolvedDescriptionId,
      );
      _modules = modules;

      if (modules.isEmpty) {
        _isLoading = false;
        notifyListeners();
        return;
      }

      _selectedModuleId = modules.first.uuid;
      notifyListeners();
      await _loadSelectedModuleDetail();
    } catch (error) {
      _errorMessage = error.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectModule(String moduleId) async {
    final resolvedModuleId = moduleId.trim();
    if (resolvedModuleId.isEmpty) {
      return;
    }

    if (_selectedModuleId == resolvedModuleId &&
        _selectedModuleDetail != null &&
        _errorMessage == null) {
      return;
    }

    _selectedModuleId = resolvedModuleId;
    _selectedModuleDetail = null;
    _selectedModuleDocument = null;
    _documentErrorMessage = null;
    await _loadSelectedModuleDetail();
  }

  Future<void> loadDocumentForSelectedModule() async {
    if (_selectedModuleId.isEmpty ||
        _selectedModuleDocument != null ||
        _isDocumentLoading) {
      return;
    }

    _isDocumentLoading = true;
    _documentErrorMessage = null;
    notifyListeners();

    try {
      _selectedModuleDocument = await _auditRepository
          .getSeatDescriptionTrainingModuleDocument(
            moduleId: _selectedModuleId,
          );
    } catch (error) {
      _documentErrorMessage = error.toString();
    }

    _isDocumentLoading = false;
    notifyListeners();
  }

  Future<void> _loadSelectedModuleDetail() async {
    if (_selectedModuleId.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedModuleDetail = await _auditRepository
          .getSeatDescriptionTrainingModuleDetail(moduleId: _selectedModuleId);
    } catch (error) {
      _errorMessage = error.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
