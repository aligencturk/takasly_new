import 'package:flutter/material.dart';
import '../../models/products/product_models.dart';
import '../../services/general_service.dart';
import '../../theme/app_theme.dart';

class CategorySelectionView extends StatefulWidget {
  final String title;
  final Category? initialCategory;
  final bool
  allowAnyLevel; // If true, can select non-leaf categories (useful for search)
  final Function(Category category, List<Category> path) onCategorySelected;

  const CategorySelectionView({
    super.key,
    this.title = 'Kategori Seçin',
    this.initialCategory,
    this.allowAnyLevel = false,
    required this.onCategorySelected,
  });

  @override
  State<CategorySelectionView> createState() => _CategorySelectionViewState();
}

class _CategorySelectionViewState extends State<CategorySelectionView> {
  final GeneralService _generalService = GeneralService();
  bool _isLoading = false;
  List<Category> _currentItems = [];
  final List<Category> _selectionPath = [];
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchItems(widget.initialCategory?.catID ?? 0);
    if (widget.initialCategory != null) {
      _selectionPath.add(widget.initialCategory!);
    }
  }

  Future<void> _fetchItems(int parentId) async {
    setState(() => _isLoading = true);
    try {
      final response = await _generalService.getCategories(parentId);
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data']['categories'] ?? [];
        setState(() {
          _currentItems = list.map((e) => Category.fromJson(e)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategoriler yüklenirken hata oluştu: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onItemTap(Category category) async {
    // Check if this category has children
    setState(() => _isLoading = true);
    try {
      final response = await _generalService.getCategories(category.catID ?? 0);
      if (response['success'] == true && response['data'] != null) {
        final List list = response['data']['categories'] ?? [];
        if (list.isNotEmpty) {
          // Has children, dive deeper
          setState(() {
            _selectionPath.add(category);
            _currentItems = list.map((e) => Category.fromJson(e)).toList();
            _searchController.clear();
            _searchQuery = '';
          });
        } else {
          // No children, final selection
          widget.onCategorySelected(category, [..._selectionPath, category]);
          Navigator.pop(context);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Hata oluştu: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goBack() {
    if (_selectionPath.isEmpty) {
      Navigator.pop(context);
    } else {
      _selectionPath.removeLast();
      _fetchItems(_selectionPath.isEmpty ? 0 : _selectionPath.last.catID ?? 0);
      _searchController.clear();
      _searchQuery = '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _currentItems
        .where(
          (item) => (item.catName ?? '').toLowerCase().contains(
            _searchQuery.toLowerCase(),
          ),
        )
        .toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppTheme.primary,
        elevation: 0.5,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            _selectionPath.isEmpty
                ? Icons.close
                : Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
            size: 25,
          ),
          onPressed: _goBack,
        ),
        title: Text(
          _selectionPath.isEmpty
              ? widget.title
              : _selectionPath.last.catName ?? widget.title,
          style: AppTheme.safePoppins(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Path Breadcrumbs
          if (_selectionPath.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              color: Colors.grey[50],
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectionPath.clear();
                          _fetchItems(0);
                        });
                      },
                      child: Text(
                        'Kategoriler',
                        style: AppTheme.safePoppins(
                          color: AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (var cat in _selectionPath) ...[
                      const Icon(
                        Icons.chevron_right,
                        size: 16,
                        color: Colors.grey,
                      ),
                      Text(
                        cat.catName ?? '',
                        style: AppTheme.safePoppins(
                          color: cat == _selectionPath.last
                              ? Colors.grey[600]!
                              : AppTheme.primary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  icon: Icon(Icons.search, color: Colors.grey[400], size: 20),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),

          // Selection logic for Search (Allow selecting "All of X")
          if (widget.allowAnyLevel && _searchQuery.isEmpty)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 4,
              ),
              onTap: () {
                if (_selectionPath.isEmpty) {
                  widget.onCategorySelected(
                    Category(catID: 0, catName: 'Tüm Kategoriler'),
                    [],
                  );
                } else {
                  widget.onCategorySelected(
                    _selectionPath.last,
                    _selectionPath,
                  );
                }
                Navigator.pop(context);
              },
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: AppTheme.primary,
                  size: 20,
                ),
              ),
              title: Text(
                _selectionPath.isEmpty
                    ? 'Tüm Kategoriler'
                    : 'Tüm "${_selectionPath.last.catName}" Ürünleri',
                style: AppTheme.safePoppins(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppTheme.primary,
                ),
              ),
              subtitle: Text(
                _selectionPath.isEmpty
                    ? 'Tüm kategorilerdeki ürünleri gösterir'
                    : 'Bu kategorinin altındaki tüm ürünleri gösterir',
                style: AppTheme.safePoppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey,
                ),
              ),
            ),

          const Divider(height: 1),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: filteredItems.length,
                    separatorBuilder: (context, index) =>
                        Divider(height: 1, color: Colors.grey[100]),
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        onTap: () => _onItemTap(item),
                        title: Text(
                          item.catName ?? '',
                          style: AppTheme.safePoppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.grey[300],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
