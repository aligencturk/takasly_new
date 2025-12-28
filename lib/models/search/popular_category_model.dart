class PopularCategory {
  final int catID;
  final String catName;
  final String catImage;
  final int productCount;

  PopularCategory({
    required this.catID,
    required this.catName,
    required this.catImage,
    required this.productCount,
  });

  factory PopularCategory.fromJson(Map<String, dynamic> json) {
    return PopularCategory(
      catID: json['catID'] ?? 0,
      catName: json['catName'] ?? '',
      catImage: json['catImage'] ?? '',
      productCount: json['productCount'] ?? 0,
    );
  }
}
