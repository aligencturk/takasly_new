class UpdateUserRequestModel {
  String? userToken;
  String? userFirstname;
  String? userLastname;
  String? userEmail;
  String? userPhone;
  String? userBirthday;
  int? userGender; // 1- Erkek, 2- Kadın, 3- Belirtilmemiş
  String? profilePhoto;
  int? showContact; // 1: Yes, 0: No

  UpdateUserRequestModel({
    this.userToken,
    this.userFirstname,
    this.userLastname,
    this.userEmail,
    this.userPhone,
    this.userBirthday,
    this.userGender,
    this.profilePhoto,
    this.showContact,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (userToken != null) data['userToken'] = userToken;
    if (userFirstname != null) data['userFirstname'] = userFirstname;
    if (userLastname != null) data['userLastname'] = userLastname;
    if (userEmail != null) data['userEmail'] = userEmail;
    if (userPhone != null) data['userPhone'] = userPhone;
    if (userBirthday != null) data['userBirthday'] = userBirthday;
    if (userGender != null) data['userGender'] = userGender;
    if (profilePhoto != null) data['profilePhoto'] = profilePhoto;
    if (showContact != null) data['showContact'] = showContact;
    return data;
  }
}

class UpdateUserResponseModel {
  bool? error;
  bool? success;
  String? message;

  UpdateUserResponseModel({this.error, this.success, this.message});

  UpdateUserResponseModel.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    success = json['success'];
    message = json['message'];
  }
}
