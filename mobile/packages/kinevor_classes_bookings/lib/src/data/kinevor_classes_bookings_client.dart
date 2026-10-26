import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/gym_class.dart';
import 'classes_bookings_api_exception.dart';

/// HTTP client for the Kinevor classes and bookings API.
///
/// Extra [headers] are attached to every request. The demo uses them for the
/// development-only `X-Demo-Role` and `X-Demo-Member` trust headers, while a
/// production host can supply an authenticated client instead.
class KinevorClassesBookingsClient {
  /// Creates a client rooted at [baseUrl], for example
  /// `https://api.example.com/api/v1`.
  KinevorClassesBookingsClient({
    required Uri baseUrl,
    http.Client? httpClient,
    Map<String, String> headers = const {},
  }) : _baseUrl = baseUrl,
       _http = httpClient ?? http.Client(),
       _ownsClient = httpClient == null,
       _headers = Map.unmodifiable(headers);

  final Uri _baseUrl;
  final http.Client _http;
  final bool _ownsClient;
  final Map<String, String> _headers;

  /// Loads upcoming sessions, optionally filtered by type or start date.
  Future<ClassPage> fetchClasses({
    String? type,
    DateTime? fromDate,
    int page = 1,
    int pageSize = 50,
  }) async {
    final data = await _object(
      'GET',
      'classes',
      query: {
        'page': '$page',
        'pageSize': '$pageSize',
        if (type != null && type.isNotEmpty) 'type': type,
        if (fromDate != null) 'fromDate': fromDate.toUtc().toIso8601String(),
      },
    );
    return ClassPage.fromJson(data);
  }

  /// Loads the class catalogue with upcoming session counts.
  Future<List<CatalogueItem>> fetchCatalogue() async {
    final data = await _list('GET', 'classes/catalogue');
    return [
      for (final item in data)
        CatalogueItem.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  /// Loads one class with capacity, roster and the member's booking.
  Future<GymClassDetail> fetchClass(String classId) async {
    final data = await _object(
      'GET',
      'classes/${Uri.encodeComponent(classId)}',
    );
    return GymClassDetail.fromJson(data);
  }

  /// Books a seat or joins the waitlist for [classId].
  Future<BookClassResult> bookClass(
    String classId, {
    String? memberId,
    String? memberName,
  }) async {
    final data = await _object(
      'POST',
      'classes/${Uri.encodeComponent(classId)}/bookings',
      body: {
        if (memberId != null && memberId.isNotEmpty) 'memberId': memberId,
        if (memberName != null && memberName.isNotEmpty)
          'memberName': memberName,
      },
    );
    return BookClassResult.fromJson(data);
  }

  /// Cancels a confirmed booking or leaves a waitlist.
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    await _send(
      'DELETE',
      'bookings/${Uri.encodeComponent(bookingId)}',
      query: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
  }

  /// Loads the authenticated member's upcoming or past bookings.
  Future<List<MyBooking>> fetchMyBookings({String scope = 'upcoming'}) async {
    final data = await _list('GET', 'me/bookings', query: {'scope': scope});
    return [
      for (final item in data)
        MyBooking.fromJson(Map<String, dynamic>.from(item as Map)),
    ];
  }

  /// Closes the underlying HTTP client when this instance created it.
  void close() {
    if (_ownsClient) _http.close();
  }

  Uri _endpoint(String path, {Map<String, String>? query}) {
    final base = _baseUrl.toString().replaceFirst(RegExp(r'/+$'), '');
    final uri = Uri.parse('$base/$path');
    return query == null || query.isEmpty
        ? uri
        : uri.replace(queryParameters: query);
  }

  Future<Map<String, dynamic>> _object(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final data = await _send(method, path, body: body, query: query);
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ClassesBookingsApiException(
      'The classes response has no data object.',
    );
  }

  Future<List<Object?>> _list(
    String method,
    String path, {
    Map<String, String>? query,
  }) async {
    final data = await _send(method, path, query: query);
    if (data is List) return data;
    throw const ClassesBookingsApiException(
      'The classes response has no data array.',
    );
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    final request = http.Request(method, _endpoint(path, query: query))
      ..headers.addAll({
        'Accept': 'application/json',
        if (body != null) 'Content-Type': 'application/json',
        ..._headers,
      });
    if (body != null) request.body = jsonEncode(body);

    final http.StreamedResponse streamed;
    try {
      streamed = await _http.send(request);
    } on Exception catch (error) {
      throw ClassesBookingsApiException(
        'Could not reach the classes API: $error',
      );
    }

    final response = await http.Response.fromStream(streamed);
    final Object? decoded;
    try {
      decoded = response.body.isEmpty ? null : jsonDecode(response.body);
    } on FormatException {
      throw ClassesBookingsApiException(
        'The classes API returned invalid JSON.',
        statusCode: response.statusCode,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw ClassesBookingsApiException(
        'The classes API returned an unexpected payload.',
        statusCode: response.statusCode,
      );
    }

    final success = decoded['success'] != false;
    if (response.statusCode < 200 || response.statusCode >= 300 || !success) {
      throw ClassesBookingsApiException(
        _errorMessage(decoded) ?? 'The classes request failed.',
        statusCode: response.statusCode,
      );
    }

    return decoded['data'];
  }

  String? _errorMessage(Map<String, dynamic> body) {
    final message = body['message'];
    if (message is String && message.isNotEmpty) return message;
    final errors = body['errors'];
    if (errors is List) {
      for (final error in errors) {
        if (error is String && error.isNotEmpty) return error;
        if (error is Map && error['message'] is String) {
          return error['message'] as String;
        }
      }
    }
    final detail = body['detail'];
    return detail is String && detail.isNotEmpty ? detail : null;
  }
}
