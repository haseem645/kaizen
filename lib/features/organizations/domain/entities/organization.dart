class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.website,
    required this.contactNo,
    required this.address,
    required this.createdAt,
    required this.type,
    required this.logoUrl,
  });

  final String id;
  final String name;
  final String? website;
  final String? contactNo;
  final String? address;
  final String createdAt;
  final String type;
  final String? logoUrl;
}
