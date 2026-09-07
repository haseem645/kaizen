import '../entities/audit_description_audit.dart';
import '../repositories/audit_repository.dart';

class SubmitDescriptionAuditUseCase {
  SubmitDescriptionAuditUseCase(this._repository, {this.beforeSubmit});

  final AuditRepository _repository;
  final void Function()? beforeSubmit;
  final Map<String, Future<void>> _pendingSubmissions = {};

  Future<AuditDescriptionAudit> call({
    required String descriptionId,
    required Map<String, int> audit,
  }) {
    final counts = Map<String, int>.unmodifiable(audit);
    final previous = _pendingSubmissions[descriptionId] ?? Future<void>.value();
    final submission = previous.then((_) {
      beforeSubmit?.call();
      return _repository.submitDescriptionAudit(
        descriptionId: descriptionId,
        audit: counts,
      );
    });

    // Keep writes to one description ordered, even if an earlier write fails.
    final completion = submission.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {},
    );
    _pendingSubmissions[descriptionId] = completion;
    return submission.whenComplete(() {
      if (identical(_pendingSubmissions[descriptionId], completion)) {
        _pendingSubmissions.remove(descriptionId);
      }
    });
  }
}
