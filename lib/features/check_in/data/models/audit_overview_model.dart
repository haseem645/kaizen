import '../../domain/entities/audit_overview.dart';
import 'audit_member_model.dart';

class AuditOverviewModel extends AuditOverview {
  const AuditOverviewModel({required List<AuditMemberModel> members})
    : super(members: members);
}
