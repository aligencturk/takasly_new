class HomeLogos {
  final String? logoCircle;
  final String? logo;
  final String? logo2;
  final String? favicon;

  HomeLogos({this.logoCircle, this.logo, this.logo2, this.favicon});

  factory HomeLogos.fromJson(Map<String, dynamic> json) {
    return HomeLogos(
      logoCircle: json['logoCircle'],
      logo: json['logo'],
      logo2: json['logo2'],
      favicon: json['favicon'],
    );
  }
}

class Category {
  final int catID;
  final String catName;
  final String catImage;

  Category({
    required this.catID,
    required this.catName,
    required this.catImage,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      catID: json['catID'] ?? 0,
      catName: json['catName'] ?? '',
      catImage: json['catImage'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'catID': catID, 'catName': catName, 'catImage': catImage};
  }
}
