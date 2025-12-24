import 'package:flutter/material.dart';
import '../services/general_service.dart';
import '../models/home/home_models.dart';
import 'package:logger/logger.dart';

class HomeViewModel extends ChangeNotifier {
  final GeneralService _generalService = GeneralService();
  final Logger _logger = Logger();

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  HomeLogos? _logos;
  HomeLogos? get logos => _logos;

  List<Category> _categories = [];
  List<Category> get categories => _categories;

  Future<void> init() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await Future.wait([fetchLogos(), fetchCategories()]);
    } catch (e) {
      _errorMessage = e.toString();
      _logger.e('Home init error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchLogos() async {
    try {
      final response = await _generalService.getLogos();
      if (response['success'] == true && response['data'] != null) {
        _logos = HomeLogos.fromJson(response['data']['logos']);
      }
    } catch (e) {
      _logger.e('Error fetching logos: $e');
      rethrow;
    }
  }

  Future<void> fetchCategories() async {
    try {
      final response = await _generalService.getCategories();
      if (response['success'] == true && response['data'] != null) {
        final List cats = response['data']['categories'];
        _categories = cats.map((e) => Category.fromJson(e)).toList();
      }
    } catch (e) {
      _logger.e('Error fetching categories: $e');
      rethrow;
    }
  }
}
