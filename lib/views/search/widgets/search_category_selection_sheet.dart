import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../viewmodels/search_viewmodel.dart';
import '../../../../models/home/home_models.dart';
import '../../../../theme/app_theme.dart';

class SearchCategorySelectionSheet extends StatefulWidget {
  const SearchCategorySelectionSheet({super.key});

  @override
  State<SearchCategorySelectionSheet> createState() =>
      _SearchCategorySelectionSheetState();
}

class _SearchCategorySelectionSheetState
    extends State<SearchCategorySelectionSheet> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        children: [
          // Handle Bar
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Consumer<SearchViewModel>(
            builder: (context, vm, child) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    if (vm.selectedCategory != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: AppTheme.textPrimary,
                          ),
                          onPressed: () {
                            vm.setSelectedCategory(null);
                          },
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          style: const ButtonStyle(
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        vm.selectedCategory?.catName ?? 'Tüm Kategoriler',
                        style: AppTheme.safePoppins(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              );
            },
          ),

          const Divider(height: 1),

          // Content
          Expanded(
            child: Consumer<SearchViewModel>(
              builder: (context, vm, child) {
                final listToShow = (vm.selectedCategory == null)
                    ? vm.categories
                    : vm.subCategories;

                if (listToShow.isEmpty && vm.selectedCategory != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              size: 48,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            "${vm.selectedCategory!.catName} Seçildi",
                            textAlign: TextAlign.center,
                            style: AppTheme.safePoppins(
                              color: AppTheme.textPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Bu kategorideki ürünleri görüntüleyebilirsiniz.",
                            textAlign: TextAlign.center,
                            style: AppTheme.safePoppins(
                              color: AppTheme.textSecondary,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Tamamla",
                              style: AppTheme.safePoppins(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: listToShow.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final cat = listToShow[index];
                    return _buildCategoryItem(context, vm, cat);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryItem(
    BuildContext context,
    SearchViewModel vm,
    Category cat,
  ) {
    return InkWell(
      onTap: () {
        vm.setSelectedCategory(cat);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey[100]!),
              ),
              child: cat.catImage.isNotEmpty
                  ? ClipOval(
                      child: Image.network(
                        cat.catImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.category,
                          size: 20,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.category,
                      size: 20,
                      color: AppTheme.textSecondary,
                    ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                cat.catName,
                style: AppTheme.safePoppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
