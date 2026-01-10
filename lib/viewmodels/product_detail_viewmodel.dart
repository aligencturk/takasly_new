import 'package:flutter/material.dart';
import '../models/product_detail_model.dart';
import '../services/product_service.dart';
import 'package:logger/logger.dart';

class ProductDetailViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final Logger _logger = Logger();

  ProductDetail? productDetail;
  bool isLoading = false;
  String? errorMessage;

  Future<void> getProductDetail(int productId, {String? userToken}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final response = await _productService.getProductDetail(
        productId,
        userToken: userToken,
      );
      if (response.success == true && response.data?.product != null) {
        productDetail = response.data!.product;
      } else {
        errorMessage = "Ürün detayları alınamadı.";
      }
    } catch (e) {
      _logger.e('Ürün detayı getirilirken hata oluştu', error: e);
      errorMessage = "Bir hata oluştu: $e";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteProduct(String userToken, int userId) async {
    if (productDetail?.productID == null) return false;

    isLoading = true;
    notifyListeners();

    try {
      await _productService.deleteProduct(
        userToken,
        userId,
        productDetail!.productID!,
      );
      productDetail = null;
      return true;
    } catch (e) {
      _logger.e('Ürün silinirken hata oluştu', error: e);
      errorMessage = "Ürün silinemedi: $e";
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
