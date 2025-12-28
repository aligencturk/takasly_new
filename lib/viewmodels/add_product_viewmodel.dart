import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';
import 'package:geolocator/geolocator.dart';

import '../services/product_service.dart';
import '../services/general_service.dart';
import '../models/products/add_product_request_model.dart';
import '../models/general_models.dart';
import '../models/products/product_models.dart'
    show
        Category; // Use Category from product models if general models doesn't have it, or check definition.

// Checking imports: GeneralService returns specific models.
// I'll assume Category is in product_models as seen in Product structure,
// or I'll check where SearchViewModel gets it. SearchViewModel imports product_models hide Category
// and imports general_models. But general_models didn't show Category.
// Let's check SearchViewModel again. It says "import '../models/products/product_models.dart' hide Category;"
// and "import '../models/general_models.dart';"
// Wait, SearchViewModel has "List<Category> categories = [];". Where does this Category come from?
// It comes from... wait. SearchViewModel imports `product_models` hiding `Category`.
// So `Category` must be in `general_models`? But I just read `general_models.dart` and it only had City, District, Condition, ContactSubject.
// Ah, SearchViewModel line 103: `categories = cats.map((e) => Category.fromJson(e)).toList();`.
// If `general_models` doesn't have it, maybe it's defined in `SearchViewModel` file or implicitly imported?
// Re-reading `SearchViewModel`:
// `import '../models/products/product_models.dart' hide Category;`
// `import '../models/general_models.dart';`
// Maybe I missed it in `general_models` because of scroll? Or maybe it's in `product_models` and I misread the hide?
// Actually `product_models` HAD `Category` class at the bottom!
// So SearchViewModel hides it... why?
// "List<Category> categories = []; // For filter selection if needed"
// If it hides it from product_models, where does it get it?
// Maybe `popular_category_model.dart`?
// Let's assume `Category` is in `product_models.dart` and just use that one.

class AddProductViewModel extends ChangeNotifier {
  final ProductService _productService = ProductService();
  final GeneralService _generalService = GeneralService();
  final Logger _logger = Logger();

  // Form Controllers
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController tradeForController = TextEditingController();

  // Models
  List<Category> categories = [];
  List<Condition> conditions = [];
  List<City> cities = [];
  List<District> districts = [];

  // Selections
  Category? selectedCategory;
  Condition? selectedCondition;
  City? selectedCity;
  District? selectedDistrict;
  bool isShowContact = true;

  // Images
  List<File> selectedImages = [];
  final ImagePicker _picker = ImagePicker();

  // Location
  double? productLat;
  double? productLong;

  // State
  bool isLoading = false;
  String? errorMessage;

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
    } catch (e) {
      errorMessage = "Başlangıç verileri yüklenemedi: $e";
      _logger.e(errorMessage);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Fetchers
  Future<void> _fetchCategories() async {
    try {
      final response = await _generalService
          .getCategories(); // Gets all top level
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data']['categories'];
        categories = list.map((e) => Category.fromJson(e)).toList();
      }
    } catch (e) {
      _logger.e("Error fetching categories: $e");
    }
  }

  Future<void> _fetchConditions() async {
    try {
      conditions = await _generalService.getConditions();
    } catch (e) {
      _logger.e("Error fetching conditions: $e");
    }
  }

  Future<void> _fetchCities() async {
    try {
      cities = await _generalService.getCities();
    } catch (e) {
      _logger.e("Error fetching cities: $e");
    }
  }

  // Setters
  void setSelectedCategory(Category? category) {
    selectedCategory = category;
    notifyListeners();
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
        isLoading = true; // Local load for districts
        notifyListeners();
        districts = await _generalService.getDistricts(city.cityNo!);
      } catch (e) {
        _logger.e("Error fetching districts: $e");
      } finally {
        isLoading = false;
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
        selectedImages.addAll(pickedFiles.map((e) => File(e.path)));
        notifyListeners();
      }
    } catch (e) {
      _logger.e("Error picking images: $e");
      errorMessage = "Resim seçilirken hata oluştu.";
      notifyListeners();
    }
  }

  void removeImage(int index) {
    if (index >= 0 && index < selectedImages.length) {
      selectedImages.removeAt(index);
      notifyListeners();
    }
  }

  // Location Logic
  Future<void> fetchCurrentLocation() async {
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

      if (permission == LocationPermission.deniedForever) {
        errorMessage = "Konum izni kalıcı olarak reddedildi.";
        notifyListeners();
        return;
      }

      isLoading = true;
      notifyListeners();

      Position position = await Geolocator.getCurrentPosition();
      productLat = position.latitude;
      productLong = position.longitude;
    } catch (e) {
      _logger.e("Location error: $e");
      errorMessage = "Konum alınamadı.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // Submission
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
        categoryID: selectedCategory!.catID!,
        conditionID: selectedCondition!.id!,
        tradeFor: tradeForController.text.trim(),
        productImages: selectedImages,
        productCity: selectedCity!.cityNo!.toString(),
        productDistrict: selectedDistrict!.districtNo!.toString(),
        productLat: productLat ?? 0.0,
        productLong: productLong ?? 0.0,
        isShowContact: isShowContact ? 1 : 0,
      );

      await _productService.addProduct(request, userId);
      return true;
    } catch (e) {
      _logger.e("Submit error: $e");
      if (e is BusinessException) {
        errorMessage = e.message;
      } else {
        errorMessage = "Ürün yüklenirken bir hata oluştu: $e";
      }
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  bool _validate() {
    if (titleController.text.trim().isEmpty) {
      errorMessage = "Lütfen ürün başlığı giriniz.";
      return false;
    }
    if (descController.text.trim().isEmpty) {
      errorMessage = "Lütfen ürün açıklaması giriniz.";
      return false;
    }
    if (selectedCategory == null) {
      errorMessage = "Lütfen kategori seçiniz.";
      return false;
    }
    if (selectedCondition == null) {
      errorMessage = "Lütfen durum seçiniz.";
      return false;
    }
    if (selectedCity == null || selectedDistrict == null) {
      errorMessage = "Lütfen il ve ilçe seçiniz.";
      return false;
    }
    if (productLat == null || productLong == null) {
      errorMessage = "Lütfen konum bilgisi alınız."; // Or enforce taking it
      return false;
    }
    if (selectedImages.isEmpty) {
      errorMessage = "Lütfen en az bir resim ekleyiniz.";
      return false;
    }
    return true;
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
