/// Error returned by the Kinevor classes and bookings API.
class ClassesBookingsApiException implements Exception {
  /// Creates an API exception with a human-readable [message].
  const ClassesBookingsApiException(this.message, {this.statusCode});

  /// Safe message suitable for display.
  final String message;

  /// HTTP status code, when a response was received.
  final int? statusCode;

  @override
  String toString() => message;
}
