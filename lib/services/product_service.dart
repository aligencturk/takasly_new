import 'api_service.dart';
import '../core/constants/api_constants.dart';
import '../models/products/product_models.dart';
import '../models/product_detail_model.dart';

class ProductService {
  final ApiService _apiService = ApiService();

  Future<ProductResponseModel> getAllProducts(
    ProductRequestModel request,
  ) async {
    try {
      final response = await _apiService.post(
        ApiConstants.allProductList,
        request.toJson(),
      );
      return ProductResponseModel.fromJson(response);
    } catch (e) {
      // If it's a 410, ApiService throws EndOfListException
      rethrow;
    }
  }

  Future<ProductDetailModel> getProductDetail(
    int productId, {
    String? userToken,
  }) async {
    try {
      String url = '${ApiConstants.productDetail}$productId/productDetail';
      if (userToken != null && userToken.isNotEmpty) {
        url += '?userToken=$userToken';
      }
      final response = await _apiService.get(url);
      // The _handleResponse returns dynamic (Map<String, dynamic>), so we parse it here
      return ProductDetailModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }
}
