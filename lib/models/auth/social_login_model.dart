class SocialLoginRequestModel {
  String platform;
  String deviceID;
  String devicePlatform;
  String version;
  String fcmToken;
  String idToken;

  SocialLoginRequestModel({
    required this.platform,
    required this.deviceID,
    required this.devicePlatform,
    required this.version,
    required this.fcmToken,
    required this.idToken,
  });

  Map<String, dynamic> toJson() {
    return {
      'platform': platform,
      'deviceID': deviceID,
      'devicePlatform': devicePlatform,
      'version': version,
      'fcmToken': fcmToken,
      'idToken': idToken,
    };
  }
}
