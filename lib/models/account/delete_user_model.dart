class DeleteUserRequestModel {
  String? userToken;

  DeleteUserRequestModel({this.userToken});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    if (userToken != null) data['userToken'] = userToken;
    return data;
  }
}
