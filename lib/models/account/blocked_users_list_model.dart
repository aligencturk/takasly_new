class BlockedUsersListResponse {
  final bool? error;
  final bool? success;
  final BlockedUsersData? data;
  final String? message;

  BlockedUsersListResponse({this.error, this.success, this.data, this.message});

  factory BlockedUsersListResponse.fromJson(Map<String, dynamic> json) {
    return BlockedUsersListResponse(
      error: json['error'],
      success: json['success'],
      data: json['data'] != null
          ? BlockedUsersData.fromJson(json['data'])
          : null,
      message: json['message'],
    );
  }
}

class BlockedUsersData {
  final List<BlockedUser>? users;

  BlockedUsersData({this.users});

  factory BlockedUsersData.fromJson(Map<String, dynamic> json) {
    return BlockedUsersData(
      users: json['users'] != null
          ? (json['users'] as List).map((i) => BlockedUser.fromJson(i)).toList()
          : null,
    );
  }
}

class BlockedUser {
  final int? userID;
  final String? userFullname;
  final String? profilePhoto;

  BlockedUser({this.userID, this.userFullname, this.profilePhoto});

  factory BlockedUser.fromJson(Map<String, dynamic> json) {
    return BlockedUser(
      userID: json['userID'],
      userFullname: json['userFullname'],
      profilePhoto: json['profilePhoto'],
    );
  }
}
