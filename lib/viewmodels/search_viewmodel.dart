import 'package:flutter/material.dart';
import '../models/products/product_models.dart';
import '../services/product_service.dart';
import 'package:logger/logger.dart';

class SearchViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final Logger _logger = Logger();

  List<Product> products = [];
  bool isLoading = false;
  bool isLoadMoreRunning = false;
  bool isLastPage = false;
  int currentPage = 1;
  String? errorMessage;
  String _currentQuery = "";

  // Debounce helper could be added here if we were doing live search,
  // but for a dedicated search page triggered by "enter", simple state is enough.

  Future<void> search(String query, {bool isRefresh = true}) async {
    if (query.trim().isEmpty) {
      products = [];
      notifyListeners();
      return;
    }

    if (isRefresh) {
      _currentQuery = query;
      isLoading = true;
      isLastPage = false;
      currentPage = 1;
      products = [];
      errorMessage = null;
      notifyListeners();
    } else {
      // Load more checks
      if (isLoadMoreRunning || isLastPage) return;
      isLoadMoreRunning = true;
      notifyListeners();
    }

    try {
      final requestModel = ProductRequestModel(
        page: currentPage,
        searchText: _currentQuery,
        // Optional: Include other filters if needed, e.g. from user preferences
      );

      final response = await _productService.getAllProducts(requestModel);

      if (response.success == true && response.data != null) {
        final newProducts = response.data!.products ?? [];

        if (isRefresh) {
          products = newProducts;
        } else {
          products.addAll(newProducts);
        }

        // Pagination Check
        if (newProducts.isEmpty) {
          isLastPage = true;
        } else if (response.data?.totalPages != null &&
            currentPage >= response.data!.totalPages!) {
          isLastPage = true;
        } else {
          currentPage++;
        }
      } else {
        errorMessage = response.message ?? "Arama sonucu alınamadı.";
      }
    } catch (e) {
      _logger.e("Search error: $e");
      errorMessage = "Bir hata oluştu.";
    } finally {
      isLoading = false;
      isLoadMoreRunning = false;
      notifyListeners();
    }
  }

  void loadMore() {
    if (_currentQuery.isNotEmpty &&
        !isLoading &&
        !isLoadMoreRunning &&
        !isLastPage) {
      search(_currentQuery, isRefresh: false);
    }
  }

  void clearSearch() {
    _currentQuery = "";
    products = [];
    errorMessage = null;
    isLastPage = false;
    currentPage = 1;
    notifyListeners();
  }
}
