class DepartmentModel {
  final String id;
  final String name;
  final String prefix;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.prefix,
  });

  factory DepartmentModel.fromJson(Map<String, dynamic> json) {
    return DepartmentModel(
      id: json["_id"],
      name: json["name"] ?? "",
      prefix: json["prefix"] ?? "",
    );
  }
}