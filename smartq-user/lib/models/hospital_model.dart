class HospitalModel {
  final String id;
  final String name;
  final String? city;
  final int departmentCount;

  HospitalModel({
    required this.id,
    required this.name,
    this.city,
    required this.departmentCount,
  });

  factory HospitalModel.fromJson(Map<String, dynamic> json) {
    return HospitalModel(
      id: json["_id"]?.toString() ?? "",
      name: json["name"]?.toString() ?? "",
      city: json["city"]?.toString(),
      departmentCount: json["departmentCount"] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "_id": id,
      "name": name,
      "city": city,
      "departmentCount": departmentCount,
    };
  }
}