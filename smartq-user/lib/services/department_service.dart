import '../models/department_model.dart';
import 'api_service.dart';

class DepartmentService {
  final api = ApiService();

  Future<List<DepartmentModel>> getDepartments(String hospitalId) async {
    final response = await api.dio.get("/departments/$hospitalId");

    return (response.data as List)
        .map((e) => DepartmentModel.fromJson(e))
        .toList();
  }
}