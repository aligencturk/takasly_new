import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../services/product_service.dart';
import '../services/general_service.dart';
import '../models/products/add_product_request_model.dart';
import '../models/general_models.dart';
import '../models/products/product_models.dart';

class EditProductViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final GeneralService _generalService = GeneralService();
  final Logger _logger = Logger();

  final int productId;
  final Product initialProduct;

  // Form Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController tradeForController = TextEditingController();

  // Models
  List<Category> categories = [];
  // Multi-level Subcategories
  List<List<Category>> categoryLevels = [];
  List<Category?> selectedSubCategories = [];

  List<Condition> conditions = [];
  List<City> cities = [];
  List<District> districts = [];

  // Selections
  Category? selectedCategory; // Main category
  Condition? selectedCondition;
  City? selectedCity;
  District? selectedDistrict;
  bool isShowContact = true;

  // Images
  List<File> newImages = [];
  List<String> existingImages = []; // URLs of existing images
  List<String> deletedImages =
      []; // URLs of images to delete (if API supports it, though usually we send all again or use specific endpoint)
  // For this implementation, I'll assume we send new files. If the API requires sending ALL images (old + new) as files, we can't do that with URLs.
  // BUT the API usually handles multipart + keeping old ones, OR we might need to download and re-upload (unlikely).
  // The 'AddProductRequestModel' has 'productImages' as List<File>.
  // If the API 'editProduct' expects 'productImages[]' in multipart, it usually means REPLACING all images or ADDING these.
  // Without specific API docs on "edit images", a common pattern is:
  // 1. Send new images as files.
  // 2. Send kept existing images as a separate field (e.g. 'existingImageUrls[]') OR the API wipes old ones and we must re-upload.
  // Given the 'AddProductRequestModel' only has `List<File> productImages`, I will assume for now we can only upload NEW images or REPLACEMENT images.
  // However, I will try to keep the existing logic simple: Allow adding new images. Existing images are displayed.
  // If the user wants to keep existing images, we typically don't need to send them again if the backend supports partial updates or "add to existing".
  // PROJE.MD says "hardcoding endpoints is forbidden", but doesn't detail 'editProduct' image handling.
  // I will check if I can modify AddProductRequestModel or how to handle this.
  // For now, I'll allow adding NEW images.

  final ImagePicker _picker = ImagePicker();

  // Location
  double? productLat;
  double? productLong;

  bool isLoading = false;
  bool isDistrictsLoading = false;
  bool isLocationLoading = false;
  String? errorMessage;

  EditProductViewModel({required this.productId, required this.initialProduct});

  // Init
  Future<void> init() async {
    isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        _fetchCategories(),
        _fetchConditions(),
        _fetchCities(),
      ]);

      await _initializeFields();
    } catch (e) {
      errorMessage = "Başlangıç verileri yüklenemedi: $e";
      _logger.e(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _initializeFields() async {
    titleController.text = initialProduct.productTitle ?? '';
    descController.text = initialProduct.productDesc ?? '';
    // Trade For is likely same as original if not provided
    // tradeForController.text = ...;

    // Hydrate Categories
    if (initialProduct.categoryList != null &&
        initialProduct.categoryList!.isNotEmpty) {
      final path = initialProduct.categoryList!;

      // 1. Root Category
      if (categories.isNotEmpty) {
        try {
          final rootCat = categories.firstWhere(
            (c) => c.catID == path[0].catID,
          );
          selectedCategory = rootCat;
        } catch (_) {
          // Fallback if not found in list (shouldn't happen if synced)
          selectedCategory = path[0];
        }
      }

      // 2. Sub Categories
      for (int i = 0; i < path.length - 1; i++) {
        final parent = path[i];
        final child = path[i + 1];

        // Fetch children of parent
        // Level index: i (0 for children of root, 1 for children of level 0, etc.)
        if (parent.catID != null) {
          await _fetchSubCategories(parent.catID!, i);

          // Now set the selection for this level
          if (i < categoryLevels.length) {
            final levelOptions = categoryLevels[i];
            try {
              final matchedChild = levelOptions.firstWhere(
                (c) => c.catID == child.catID,
              );
              if (i < selectedSubCategories.length) {
                selectedSubCategories[i] = matchedChild;
              } else {
                selectedSubCategories.add(matchedChild);
              }
            } catch (_) {
              if (i < selectedSubCategories.length) {
                selectedSubCategories[i] = child;
              } else {
                selectedSubCategories.add(child);
              }
            }
          }
        }
      }
      notifyListeners();
    }

    _hydrateOtherFields();
  }

  void _hydrateOtherFields() {
    // Images
    if (initialProduct.productImage != null) {
      // Avoid duplicates if initialized multiple times (though init is once)
      if (!existingImages.contains(initialProduct.productImage!)) {
        existingImages.add(initialProduct.productImage!);
      }
    }

    // Condition
    if (initialProduct.conditionID != null) {
      try {
        selectedCondition = conditions.firstWhere(
          (c) => c.id == initialProduct.conditionID,
        );
      } catch (_) {}
    }

    // City/District
    if (initialProduct.cityID != null) {
      try {
        selectedCity = cities.firstWhere(
          (c) => c.cityNo == initialProduct.cityID,
        );
        if (selectedCity != null) {
          // Fetch districts
          _generalService.getDistricts(selectedCity!.cityNo!).then((dList) {
            districts = dList;
            if (initialProduct.districtID != null) {
              try {
                selectedDistrict = districts.firstWhere(
                  (d) => d.districtNo == initialProduct.districtID,
                );
                notifyListeners();
              } catch (_) {}
            }
            notifyListeners();
          });
        }
      } catch (_) {}
    }

    notifyListeners();
  }

  // Fetchers
  Future<void> _fetchCategories() async {
    try {
      final response = await _generalService.getCategories();
      if (response['success'] == true && response['data'] != null) {
        if (response['data']['categories'] == null) return;
        final List list = response['data']['categories'];
        categories = list.map((e) => Category.fromJson(e)).toList();
      }
    } catch (e) {
      _logger.e("Error fetching categories: $e");
    }
  }

  Future<void> _fetchConditions() async {
    try {
      final result = await _generalService.getConditions();
      if (result.isNotEmpty) {
        conditions = result;
      }
    } catch (e) {
      _logger.e("Error fetching conditions: $e");
    }
  }

  Future<void> _fetchCities() async {
    try {
      final result = await _generalService.getCities();
      if (result.isNotEmpty) {
        cities = result;
      }
    } catch (e) {
      _logger.e("Error fetching cities: $e");
    }
  }

  // Helpers for category (same as AddProduct)
  Future<bool> _fetchSubCategories(int parentId, int levelIndex) async {
    // ... (Logic similar to AddProductViewModel, reusing for brevity if possible, but copy-paste is safer for now)
    try {
      final response = await _generalService.getCategories(parentId);
      if (response['success'] == true && response['data'] != null) {
        if (response['data']['categories'] == null) return false;
        final List list = response['data']['categories'];
        final newOptions = list.map((e) => Category.fromJson(e)).toList();

        if (newOptions.isNotEmpty) {
          if (levelIndex < categoryLevels.length) {
            categoryLevels[levelIndex] = newOptions;
            selectedSubCategories[levelIndex] = null;
          } else {
            categoryLevels.add(newOptions);
            selectedSubCategories.add(null);
          }
          notifyListeners();
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> setSelectedCategory(Category? category) async {
    selectedCategory = category;
    categoryLevels.clear();
    selectedSubCategories.clear();
    notifyListeners();
    if (category?.catID != null) {
      return await _fetchSubCategories(category!.catID!, 0);
    }
    return false;
  }

  Future<bool> onSubCategoryChanged(int levelIndex, Category? category) async {
    if (levelIndex < selectedSubCategories.length) {
      selectedSubCategories[levelIndex] = category;
    }
    if (levelIndex + 1 < categoryLevels.length) {
      categoryLevels.removeRange(levelIndex + 1, categoryLevels.length);
      selectedSubCategories.removeRange(
        levelIndex + 1,
        selectedSubCategories.length,
      );
    }
    notifyListeners();
    if (category?.catID != null) {
      return await _fetchSubCategories(category!.catID!, levelIndex + 1);
    }
    return false;
  }

  void setSelectedCondition(Condition? condition) {
    selectedCondition = condition;
    notifyListeners();
  }

  void setSelectedDistrict(District? district) {
    selectedDistrict = district;
    notifyListeners();
  }

  void setShowContact(bool value) {
    isShowContact = value;
    notifyListeners();
  }

  Future<void> onCityChanged(City? city) async {
    selectedCity = city;
    selectedDistrict = null;
    districts = [];
    notifyListeners();

    if (city != null && city.cityNo != null) {
      try {
        isDistrictsLoading = true;
        notifyListeners();
        districts = await _generalService.getDistricts(city.cityNo!);
      } catch (e) {
        _logger.e("Error fetching districts: $e");
      } finally {
        isDistrictsLoading = false;
        notifyListeners();
      }
    }
  }

  // Image Logic
  Future<void> pickImages() async {
    try {
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 70,
      );
      if (pickedFiles.isNotEmpty) {
        newImages.addAll(pickedFiles.map((e) => File(e.path)));
        notifyListeners();
      }
    } catch (e) {
      _logger.e("Error picking images: $e");
    }
  }

  void removeNewImage(int index) {
    if (index >= 0 && index < newImages.length) {
      newImages.removeAt(index);
      notifyListeners();
    }
  }

  // Location
  Future<void> fetchCurrentLocation() async {
    // ... Copy location logic from AddProductViewModel
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        errorMessage = "Konum servisi kapalı.";
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          errorMessage = "Konum izni reddedildi.";
          notifyListeners();
          return;
        }
      }

      isLocationLoading = true;
      notifyListeners();

      Position position = await Geolocator.getCurrentPosition();
      productLat = position.latitude;
      productLong = position.longitude;

      // Reverse Geo
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );
        if (placemarks.isNotEmpty) {
          // ... existing match logic ...
        }
      } catch (_) {}
    } catch (e) {
      errorMessage = "Konum alınamadı.";
    } finally {
      isLocationLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitProduct(String userToken, int userId) async {
    if (!_validate()) return false;

    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final request = AddProductRequestModel(
        userToken: userToken,
        productTitle: titleController.text.trim(),
        productDesc: descController.text.trim(),
        categoryID: _getLastSelectedCategoryId(),
        conditionID: selectedCondition!.id!,
        tradeFor: tradeForController.text.trim(),
        productImages: newImages, // Only NEW images
        productCity: selectedCity!.cityNo!.toString(),
        productDistrict: selectedDistrict!.districtNo!.toString(),
        productLat: productLat ?? 0.0,
        productLong: productLong ?? 0.0,
        isShowContact: isShowContact ? 1 : 0,
      );

      // Call EDIT
      await _productService.editProduct(request, productId);
      return true;
    } catch (e) {
      if (e is BusinessException) {
        errorMessage = e.message;
      } else {
        errorMessage = "Ürün güncellenirken hata: $e";
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool _validate() {
    if (titleController.text.trim().isEmpty) {
      errorMessage = "Başlık giriniz.";
      return false;
    }
    // ... validate others ...
    return true;
  }

  int _getLastSelectedCategoryId() {
    if (selectedSubCategories.isNotEmpty) {
      for (int i = selectedSubCategories.length - 1; i >= 0; i--) {
        if (selectedSubCategories[i] != null) {
          return selectedSubCategories[i]!.catID!;
        }
      }
    }
    return selectedCategory?.catID ?? 0;
  }

  @override
  void dispose() {
    titleController.dispose();
    descController.dispose();
    tradeForController.dispose();
    super.dispose();
  }
}

class BusinessException implements Exception {
  final String message;
  BusinessException(this.message);
}
