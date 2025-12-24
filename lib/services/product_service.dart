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

  Future<ProductResponseModel> getUserFavorites(int userId) async {
    try {
      final url = '${ApiConstants.favoriteList}$userId/favoriteList';
      final response = await _apiService.get(url);
      return ProductResponseModel.fromJson(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addFavorite(String userToken, int productId) async {
    try {
      final payload = {"userToken": userToken, "productID": productId};
      await _apiService.post(ApiConstants.addFavorite, payload);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeFavoriteProduct(String userToken, int productId) async {
    try {
      final payload = {"userToken": userToken, "productID": productId};
      await _apiService.post(ApiConstants.removeFavorite, payload);
    } catch (e) {
      rethrow;
    }
  }
}
