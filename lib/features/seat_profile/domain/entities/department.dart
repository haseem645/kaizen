class Department {
  const Department({
    required this.id,
    required this.name,
    this.colorHex,
    this.fromSandbox,
    this.driveId,
  });

  final String id;
  final String name;
  final String? colorHex;
  final Object? fromSandbox;
  final String? driveId;
}
