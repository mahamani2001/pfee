class ErrorResponse {
  final int? errorCode;
  final String? errorDescription;
  final dynamic error;
  final int? errorDescripDetails;

  ErrorResponse(
      {this.errorCode,
      this.errorDescription,
      this.error,
      this.errorDescripDetails,});
}
