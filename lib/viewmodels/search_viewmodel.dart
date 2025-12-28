import 'package:flutter/material.dart';
import '../models/products/product_models.dart';
import '../services/product_service.dart';
import 'package:logger/logger.dart';

import '../services/general_service.dart';
import '../models/search/popular_category_model.dart';

class SearchViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final GeneralService _generalService = GeneralService();
  final Logger _logger = Logger();

  List<Product> products = [];
  List<PopularCategory> popularCategories = [];
  bool isLoading = false;
  bool isLoadMoreRunning = false;
  bool isLastPage = false;
  int currentPage = 1;
  String? errorMessage;
  String _currentQuery = "";

  int? _currentCategoryId;
  String? _currentCategoryName;

  int totalItems = 0;

  String get currentQuery => _currentQuery;
  String? get currentCategoryName => _currentCategoryName;

  // Debounce helper could be added here if we were doing live search,
  // but for a dedicated search page triggered by "enter", simple state is enough.

  Future<void> init() async {
    await fetchPopularCategories();
  }

  Future<void> fetchPopularCategories() async {
    try {
      popularCategories = await _generalService.getPopularCategories();
      notifyListeners();
    } catch (e) {
      _logger.e("Error fetching popular categories: $e");
    }
  }

  Future<void> searchByCategory(int categoryId, String categoryName) async {
    _currentCategoryId = categoryId;
    _currentCategoryName = categoryName;
    _currentQuery = ""; // Clear text search
    await _performSearchRequest(isRefresh: true);
  }

  Future<void> search(String query, {bool isRefresh = true}) async {
    if (isRefresh) {
      _currentCategoryId = null; // Clear category filter
      _currentCategoryName = null;
    }

    if (query.trim().isEmpty && _currentCategoryId == null) {
      products = [];
      _currentQuery = "";
      totalItems = 0;
      notifyListeners();
      return;
    }

    if (isRefresh) {
      _currentQuery = query;
      isLoading = true;
      isLastPage = false;
      currentPage = 1;
      products = [];
      totalItems = 0;
      errorMessage = null;
      notifyListeners();
    } else {
      if (isLoadMoreRunning || isLastPage) return;
      isLoadMoreRunning = true;
      notifyListeners();
    }

    await _performSearchRequest(isRefresh: isRefresh);
  }

  Future<void> _performSearchRequest({required bool isRefresh}) async {
    try {
      final requestModel = ProductRequestModel(
        page: currentPage,
        searchText: _currentQuery,
        categoryID: _currentCategoryId,
      );

      final response = await _productService.getAllProducts(requestModel);

      if (response.success == true && response.data != null) {
        final newProducts = response.data!.products ?? [];

        // Update total items count
        if (response.data!.totalItems != null) {
          totalItems = response.data!.totalItems!;
        }

        if (isRefresh) {
          products = newProducts;
        } else {
          products.addAll(newProducts);
        }

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
    if ((_currentQuery.isNotEmpty || _currentCategoryId != null) &&
        !isLoading &&
        !isLoadMoreRunning &&
        !isLastPage) {
      isLoadMoreRunning = true;
      notifyListeners();
      _performSearchRequest(isRefresh: false);
    }
  }

  void clearSearch() {
    _currentQuery = "";
    _currentCategoryId = null;
    _currentCategoryName = null;
    products = [];
    errorMessage = null;
    isLastPage = false;
    currentPage = 1;
    notifyListeners();
  }
}
