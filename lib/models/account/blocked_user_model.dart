class BlockedUserRequest {
  final String userToken;
  final int blockedUserID;
  final String? reason;

  BlockedUserRequest({
    required this.userToken,
    required this.blockedUserID,
    this.reason,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'blockedUserID': blockedUserID,
      if (reason != null) 'reason': reason,
    };
  }
}
