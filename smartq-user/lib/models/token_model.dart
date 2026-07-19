class TokenModel {
  final String tokenCode;
  final String patientName;
  final String? patientPhone;
  final String status;

  TokenModel({
    required this.tokenCode,
    required this.patientName,
    this.patientPhone,
    required this.status,
  });

  factory TokenModel.fromJson(Map<String, dynamic> json) {
    return TokenModel(
      tokenCode: json["tokenCode"] ?? "",
      patientName: json["patientName"] ?? "",
      patientPhone: json["patientPhone"],
      status: json["status"] ?? "",
    );
  }
}