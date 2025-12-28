class UnblockUserRequest {
  final String userToken;
  final int blockedUserID;

  UnblockUserRequest({required this.userToken, required this.blockedUserID});

  Map<String, dynamic> toJson() {
    return {'userToken': userToken, 'blockedUserID': blockedUserID};
  }
}
