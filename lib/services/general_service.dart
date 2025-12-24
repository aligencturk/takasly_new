import 'api_service.dart';
import '../core/constants/api_constants.dart';

class GeneralService {
  final ApiService _apiService = ApiService();

  Future<Map<String, dynamic>> getLogos() async {
    try {
      final response = await _apiService.get(ApiConstants.logos);
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCategories([int parentId = 0]) async {
    try {
      // Using 0 as default parentId as per requirement "id asla statik gidemez"
      // but 0 is the root category ID typically.
      // We allow passing it in now.
      final response = await _apiService.get(
        '${ApiConstants.categories}$parentId',
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }
}
