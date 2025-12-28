class ReportUserRequest {
  final String userToken;
  final int reportedUserID;
  final String reason;
  final String step;
  final int? productID;
  final int? offerID;

  ReportUserRequest({
    required this.userToken,
    required this.reportedUserID,
    required this.reason,
    required this.step,
    this.productID,
    this.offerID,
  });

  Map<String, dynamic> toJson() {
    return {
      'userToken': userToken,
      'reportedUserID': reportedUserID,
      'reason': reason,
      'step': step,
      if (productID != null) 'productID': productID,
      if (offerID != null) 'offerID': offerID,
    };
  }
}
