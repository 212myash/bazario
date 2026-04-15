class AppException implements Exception {
  AppException(this.message, {this.code});

  final String message;
  final int? code;

  @override
  String toString() => message;
}
