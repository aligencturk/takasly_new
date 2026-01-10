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
