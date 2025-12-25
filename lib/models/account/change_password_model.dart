class ChangePasswordRequestModel {
  String? userToken;
  String? currentPassword;
  String? password;
  String? passwordAgain;

  ChangePasswordRequestModel({
    this.userToken,
    this.currentPassword,
    this.password,
    this.passwordAgain,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (userToken != null) data['userToken'] = userToken;
    if (currentPassword != null) data['currentPassword'] = currentPassword;
    if (password != null) data['password'] = password;
    if (passwordAgain != null) data['passwordAgain'] = passwordAgain;
    return data;
  }
}

class ChangePasswordResponseModel {
  bool? error;
  bool? success;
  dynamic data; // Sometimes verification data or just success message

  ChangePasswordResponseModel({this.error, this.success, this.data});

  ChangePasswordResponseModel.fromJson(Map<String, dynamic> json) {
    error = json['error'];
    success = json['success'];
    data = json['data'];
  }
}
