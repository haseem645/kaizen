import 'paygrade.dart';

class PaygradePage {
  const PaygradePage({required this.items, required this.hasNextPage});

  final List<Paygrade> items;
  final bool hasNextPage;
}
