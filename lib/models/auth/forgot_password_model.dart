class ForgotPasswordRequestModel {
  final String userEmail;

  ForgotPasswordRequestModel({required this.userEmail});

  Map<String, dynamic> toJson() {
    return {"userEmail": userEmail};
  }
}

class ForgotPasswordResponseModel {
  final String codeToken;

  ForgotPasswordResponseModel({required this.codeToken});

  factory ForgotPasswordResponseModel.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponseModel(codeToken: json['codeToken']);
  }
}

class UpdatePasswordRequestModel {
  final String passToken;
  final String password;
  final String passwordAgain;

  UpdatePasswordRequestModel({
    required this.passToken,
    required this.password,
    required this.passwordAgain,
  });

  Map<String, dynamic> toJson() {
    return {
      "passToken": passToken,
      "password": password,
      "passwordAgain": passwordAgain,
    };
  }
}
