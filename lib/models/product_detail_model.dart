class ProductDetailModel {
  bool? error;
  bool? success;
  ProductDetailData? data;

  ProductDetailModel({this.error, this.success, this.data});

  ProductDetailModel.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    success = json['success'];
    data = json['data'] != null
        ? ProductDetailData.fromJson(json['data'])
        : null;
  }
}

class ProductDetailData {
  ProductDetail? product;

  ProductDetailData({this.product});

  ProductDetailData.fromJson(Map<String, dynamic> json) {
    product = json['product'] != null
        ? ProductDetail.fromJson(json['product'])
        : null;
  }
}

class ProductDetail {
  int? productID;
  String? productCode;
  String? productTitle;
  String? productTitleSEO;
  String? productDesc;
  String? productImage;
  List<String>? productGallery;
  String? productCondition;
  String? shareLink;
  String? tradeFor;
  List<Category>? categoryList;
  int? userID;
  int? categoryID;
  int? conditionID;
  int? cityID;
  int? districtID;
  String? cityTitle;
  String? districtTitle;
  String? productLat;
  String? productLong;
  String? userFullname;
  String? userFirstname;
  String? userLastname;
  String? profilePhoto;
  String? userPhone;
  num? averageRating;
  num? totalReviews;
  String? createdAt;
  String? proView;
  int? favoriteCount;
  bool? isShowContact;
  bool? isFavorite;
  bool? isSponsor;
  bool? isTrade;

  ProductDetail({
    this.productID,
    this.productCode,
    this.productTitle,
    this.productTitleSEO,
    this.productDesc,
    this.productImage,
    this.productGallery,
    this.productCondition,
    this.shareLink,
    this.tradeFor,
    this.categoryList,
    this.userID,
    this.categoryID,
    this.conditionID,
    this.cityID,
    this.districtID,
    this.cityTitle,
    this.districtTitle,
    this.productLat,
    this.productLong,
    this.userFullname,
    this.userFirstname,
    this.userLastname,
    this.profilePhoto,
    this.userPhone,
    this.averageRating,
    this.totalReviews,
    this.createdAt,
    this.proView,
    this.favoriteCount,
    this.isShowContact,
    this.isFavorite,
    this.isSponsor,
    this.isTrade,
  });

  ProductDetail.fromJson(Map<String, dynamic> json) {
    productID = json['productID'];
    productCode = json['productCode'];
    productTitle = json['productTitle'];
    productTitleSEO = json['productTitleSEO'];
    productDesc = json['productDesc'];
    productImage = json['productImage'];
    productGallery = json['productGallery'] != null
        ? List<String>.from(json['productGallery'])
        : null;
    productCondition = json['productCondition'];
    shareLink = json['shareLink'];
    tradeFor = json['tradeFor'];
    if (json['categoryList'] != null) {
      categoryList = <Category>[];
      json['categoryList'].forEach((v) {
        categoryList!.add(Category.fromJson(v));
      });
    }
    userID = json['userID'];
    categoryID = json['categoryID'];
    conditionID = json['conditionID'];
    cityID = json['cityID'];
    districtID = json['districtID'];
    cityTitle = json['cityTitle'];
    districtTitle = json['districtTitle'];
    productLat = json['productLat'];
    productLong = json['productLong'];
    userFullname = json['userFullname'];
    userFirstname = json['userFirstname'];
    userLastname = json['userLastname'];
    profilePhoto = json['profilePhoto'];
    userPhone = json['userPhone'];
    averageRating = json['averageRating'];
    totalReviews = json['totalReviews'];
    createdAt = json['createdAt'];
    proView = json['proView'];
    favoriteCount = json['favoriteCount'];
    isShowContact = json['isShowContact'];
    isFavorite = json['isFavorite'];
    isSponsor = json['isSponsor'];
    isTrade = json['isTrade'];
  }
}

class Category {
  int? catID;
  String? catName;

  Category({this.catID, this.catName});

  Category.fromJson(Map<String, dynamic> json) {
    catID = json['catID'];
    catName = json['catName'];
  }
}
