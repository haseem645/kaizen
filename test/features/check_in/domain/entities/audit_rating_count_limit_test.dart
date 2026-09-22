// ignore_for_file: depend_on_referenced_packages

import 'package:sparrowkaizen/features/check_in/domain/entities/audit_description_audit.dart';
import 'package:test/test.dart';

void main() {
  group('rating count limit', () {
    test('allows a rating to start at zero', () {
      expect(AuditRating.canIncrementCount(0), isTrue);
    });

    test('allows the final increment from 98 to 99', () {
      expect(AuditRating.canIncrementCount(98), isTrue);
    });

    test('stops incrementing at 99', () {
      expect(AuditRating.canIncrementCount(99), isFalse);
    });

    test('also blocks existing counts above the limit', () {
      expect(AuditRating.canIncrementCount(100), isFalse);
    });

    test('applies the limit separately to each rating', () {
      const counts = <AuditRating, int>{
        AuditRating.great: 99,
        AuditRating.almostThere: 98,
        AuditRating.needsImprovement: 98,
      };

      expect(
        counts.map(
          (rating, count) =>
              MapEntry(rating, AuditRating.canIncrementCount(count)),
        ),
        <AuditRating, bool>{
          AuditRating.great: false,
          AuditRating.almostThere: true,
          AuditRating.needsImprovement: true,
        },
      );
    });
  });
}
