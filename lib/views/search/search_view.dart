import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../viewmodels/search_viewmodel.dart';
import '../../viewmodels/product_detail_viewmodel.dart'; // For navigation to details
import '../../theme/app_theme.dart';
import '../widgets/product_card.dart';
import '../products/product_detail_view.dart';
import '../../models/search/popular_category_model.dart';

class SearchView extends StatefulWidget {
  const SearchView({super.key});

  @override
  State<SearchView> createState() => _SearchViewState();
}

class _SearchViewState extends State<SearchView> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SearchViewModel>().init();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      context.read<SearchViewModel>().loadMore();
    }
  }

  void _performSearch(String query) {
    if (query.trim().isNotEmpty) {
      context.read<SearchViewModel>().search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(160),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primary.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 44,
                    width: double.infinity,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Back Button
                        Positioned(
                          left: 0,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Text(
                          'Ürün Ara',
                          style: AppTheme.safePoppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      // Search Field
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ValueListenableBuilder<TextEditingValue>(
                            valueListenable: _searchController,
                            builder: (context, value, child) {
                              return TextField(
                                controller: _searchController,
                                autofocus: true,
                                textInputAction: TextInputAction.done,
                                onSubmitted: (_) {
                                  FocusScope.of(context).unfocus();
                                },
                                style: AppTheme.safePoppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppTheme.textPrimary,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'Neye ihtiyacın var?',
                                  hintStyle: AppTheme.safePoppins(
                                    color: Colors.grey.shade500,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.search_rounded,
                                    color: AppTheme.primary,
                                    size: 22,
                                  ),
                                  suffixIcon: value.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(
                                            Icons.cancel_rounded,
                                            color: Colors.grey,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            _searchController.clear();
                                            context
                                                .read<SearchViewModel>()
                                                .clearSearch();
                                          },
                                        )
                                      : null,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Search Button
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          _performSearch(_searchController.text);
                        },
                        child: Container(
                          height: 52,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Ara',
                              style: AppTheme.safePoppins(
                                color: AppTheme.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Consumer<SearchViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.products.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
            );
          }

          if (viewModel.errorMessage != null) {
            return _buildEmptyState(
              icon: Icons.error_outline_rounded,
              title: "Bir Sorun Oluştu",
              subtitle: viewModel.errorMessage!,
              color: Colors.redAccent,
            );
          }

          if (viewModel.products.isEmpty) {
            if (_searchController.text.isEmpty) {
              if (viewModel.popularCategories.isNotEmpty) {
                return _buildPopularCategories(viewModel.popularCategories);
              }
              return _buildEmptyState(
                icon: Icons.manage_search_rounded,
                title: "Keşfetmeye Hazır mısın?",
                subtitle: "Aradığın her şeyi burada bulabilirsin.",
              );
            }

            return _buildEmptyState(
              icon: Icons.search_off_rounded,
              title: "Sonuç Bulunamadı",
              subtitle:
                  "'${_searchController.text}' için uygun sonuç bulamadık.",
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (viewModel.currentCategoryName != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppTheme.primary.withOpacity(0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Kategori: ${viewModel.currentCategoryName}",
                              style: AppTheme.safePoppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                context.read<SearchViewModel>().clearSearch();
                                _searchController.clear();
                              },
                              child: const Icon(
                                Icons.close_rounded,
                                size: 18,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Text(
                  "${viewModel.totalItems} Sonuç Bulundu",
                  style: AppTheme.safePoppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.65, // Adjust for card height
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount:
                      viewModel.products.length +
                      (viewModel.isLoadMoreRunning ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == viewModel.products.length) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      );
                    }

                    final product = viewModel.products[index];
                    return ProductCard(
                      product: product,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ChangeNotifierProvider(
                              create: (_) => ProductDetailViewModel(),
                              child: ProductDetailView(
                                productId: product.productID!,
                              ),
                            ),
                          ),
                        );
                      },
                      onFavoritePressed: () {
                        // Optional: Implement favorite logic here if needed
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPopularCategories(List<PopularCategory> categories) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      children: [
        Text(
          "Popüler Kategoriler",
          style: AppTheme.safePoppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textSecondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 20),
        ...categories.map((category) => _buildPopularCategoryItem(category)),
      ],
    );
  }

  Widget _buildPopularCategoryItem(PopularCategory category) {
    return InkWell(
      onTap: () {
        context.read<SearchViewModel>().searchByCategory(
          category.catID,
          category.catName,
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: category.catImage.toLowerCase().endsWith('.svg')
                  ? SvgPicture.network(
                      category.catImage,
                      placeholderBuilder: (context) => const SizedBox.shrink(),
                    )
                  : Image.network(category.catImage),
            ),
            const SizedBox(width: 16),
            // Title
            Expanded(
              child: Text(
                category.catName,
                style: AppTheme.safePoppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            // Product count chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${category.productCount}",
                style: AppTheme.safePoppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    Color color = AppTheme.textSecondary,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 80, color: color.withOpacity(0.6)),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                color: AppTheme.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTheme.safePoppins(
                color: AppTheme.textSecondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
