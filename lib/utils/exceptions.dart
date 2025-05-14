class LocationPermissionNotGrantedException implements Exception {
  final String message;
  LocationPermissionNotGrantedException(this.message);

  @override
  String toString() => 'LocationPermissionNotGrantedException: $message';
}
