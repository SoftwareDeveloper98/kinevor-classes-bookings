import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:kinevor_classes_bookings/kinevor_classes_bookings.dart';

Map<String, dynamic> classJson({
  String id = 'class-yoga',
  String name = 'Sunrise Yoga',
  bool full = false,
}) => {
  'id': id,
  'name': name,
  'description': 'A grounding morning flow.',
  'type': 'Yoga',
  'trainerId': 'trainer-1',
  'trainerName': 'Maya Chen',
  'startsAt': '2026-10-22T07:00:00',
  'endsAt': '2026-10-22T08:00:00',
  'durationMinutes': 60,
  'capacity': 18,
  'bookedCount': full ? 18 : 14,
  'availableSpots': full ? 0 : 4,
  'waitListCount': full ? 2 : 0,
  'status': 'Scheduled',
  'room': 'Studio One',
  'requiresMembership': true,
  'isFull': full,
  'isOpenForBooking': true,
};

Map<String, dynamic> detailJson() => {
  ...classJson(),
  'notes': 'Bring water.',
  'roster': [
    {
      'id': 'booking-1',
      'classId': 'class-yoga',
      'className': 'Sunrise Yoga',
      'classStartsAt': '2026-10-22T07:00:00',
      'memberId': 'member-2',
      'memberName': 'Ethan Thompson',
      'status': 'Confirmed',
      'isWaitListed': false,
      'bookedAt': '2026-10-18T09:00:00',
      'checkedInAt': null,
    },
  ],
  'myBooking': {
    'id': 'booking-mine',
    'classId': 'class-yoga',
    'className': 'Sunrise Yoga',
    'classStartsAt': '2026-10-22T07:00:00',
    'memberId': '11111111-1111-1111-1111-111111111111',
    'memberName': 'Maya Thompson',
    'status': 'Confirmed',
    'isWaitListed': false,
    'bookedAt': '2026-10-18T08:00:00',
  },
};

Map<String, dynamic> myBookingJson() => {
  'id': 'booking-mine',
  'classId': 'class-yoga',
  'className': 'Sunrise Yoga',
  'classType': 'Yoga',
  'trainerName': 'Maya Chen',
  'room': 'Studio One',
  'startsAt': '2026-10-22T07:00:00',
  'endsAt': '2026-10-22T08:00:00',
  'bookingStatus': 'Confirmed',
  'classStatus': 'Scheduled',
  'isWaitListed': false,
  'canCancel': true,
  'checkedInAt': null,
};

http.Response envelope(Object? data, {int status = 200}) => http.Response(
  jsonEncode({'success': true, 'data': data}),
  status,
  headers: {'content-type': 'application/json'},
);

void main() {
  test(
    'classes request sends filters, demo headers and parses the page',
    () async {
      late http.Request captured;
      final client = KinevorClassesBookingsClient(
        baseUrl: Uri.parse('http://localhost:5085/api/v1/'),
        headers: const {'X-Demo-Role': 'Staff'},
        httpClient: MockClient((request) async {
          captured = request;
          return envelope({
            'items': [classJson()],
            'totalCount': 1,
          });
        }),
      );

      final page = await client.fetchClasses(
        fromDate: DateTime.utc(2026, 10, 21),
      );

      expect(captured.method, 'GET');
      expect(captured.url.path, '/api/v1/classes');
      expect(captured.url.queryParameters['page'], '1');
      expect(captured.url.queryParameters['pageSize'], '50');
      expect(
        captured.url.queryParameters['fromDate'],
        startsWith('2026-10-21T00:00:00'),
      );
      expect(captured.headers['X-Demo-Role'], 'Staff');
      expect(page.totalCount, 1);
      expect(page.items.single.name, 'Sunrise Yoga');
      expect(page.items.single.availableSpots, 4);
      expect(page.items.single.startsAt, DateTime(2026, 10, 22, 7));
    },
  );

  test('detail parses the roster and the member booking', () async {
    final client = KinevorClassesBookingsClient(
      baseUrl: Uri.parse('http://localhost:5085/api/v1'),
      httpClient: MockClient((_) async => envelope(detailJson())),
    );

    final detail = await client.fetchClass('class-yoga');

    expect(detail.name, 'Sunrise Yoga');
    expect(detail.notes, 'Bring water.');
    expect(detail.roster.single.memberName, 'Ethan Thompson');
    expect(detail.roster.single.initials, 'ET');
    expect(detail.myBooking?.id, 'booking-mine');
    expect(detail.myBooking?.classStartsAt, DateTime(2026, 10, 22, 7));
  });

  test(
    'booking, cancellation and member bookings use the right verbs',
    () async {
      final requests = <http.Request>[];
      final client = KinevorClassesBookingsClient(
        baseUrl: Uri.parse('http://localhost:5085/api/v1'),
        httpClient: MockClient((request) async {
          requests.add(request);
          if (request.method == 'POST') {
            return envelope({
              'bookingId': 'booking-new',
              'isWaitListed': true,
              'status': 'WaitListed',
              'availableSpots': 0,
              'waitListPosition': 3,
            }, status: 201);
          }
          if (request.method == 'DELETE') {
            return envelope(null);
          }
          return envelope([myBookingJson()]);
        }),
      );

      final result = await client.bookClass(
        'class-hiit',
        memberName: 'Maya Thompson',
      );
      await client.cancelBooking('booking-new', reason: 'Schedule change');
      final bookings = await client.fetchMyBookings();

      expect(result.bookingId, 'booking-new');
      expect(result.isWaitListed, isTrue);
      expect(result.waitListPosition, 3);

      expect(requests[0].method, 'POST');
      expect(requests[0].url.path, '/api/v1/classes/class-hiit/bookings');
      expect(jsonDecode(requests[0].body), {'memberName': 'Maya Thompson'});

      expect(requests[1].method, 'DELETE');
      expect(requests[1].url.path, '/api/v1/bookings/booking-new');
      expect(requests[1].url.queryParameters['reason'], 'Schedule change');

      expect(requests[2].method, 'GET');
      expect(requests[2].url.path, '/api/v1/me/bookings');
      expect(requests[2].url.queryParameters['scope'], 'upcoming');
      expect(bookings.single.className, 'Sunrise Yoga');
      expect(bookings.single.canCancel, isTrue);
    },
  );

  test('catalogue parses upcoming counts', () async {
    final client = KinevorClassesBookingsClient(
      baseUrl: Uri.parse('http://localhost:5085/api/v1'),
      httpClient: MockClient(
        (_) async => envelope([
          {
            'type': 'Yoga',
            'upcomingSessions': 3,
            'nextStartsAt': '2026-10-22T07:00:00',
            'nextClassName': 'Sunrise Yoga',
          },
        ]),
      ),
    );

    final catalogue = await client.fetchCatalogue();

    expect(catalogue.single.type, 'Yoga');
    expect(catalogue.single.upcomingSessions, 3);
    expect(catalogue.single.nextClassName, 'Sunrise Yoga');
  });

  test('failed requests surface the API message', () async {
    final client = KinevorClassesBookingsClient(
      baseUrl: Uri.parse('http://localhost:5085/api/v1'),
      httpClient: MockClient(
        (_) async => http.Response(
          jsonEncode({
            'success': false,
            'message': 'This class is not open for booking.',
          }),
          409,
        ),
      ),
    );

    await expectLater(
      client.bookClass('class-yoga'),
      throwsA(
        isA<ClassesBookingsApiException>()
            .having((error) => error.statusCode, 'status', 409)
            .having(
              (error) => error.message,
              'message',
              'This class is not open for booking.',
            ),
      ),
    );
  });

  test('network failures are wrapped', () async {
    final client = KinevorClassesBookingsClient(
      baseUrl: Uri.parse('http://localhost:5085/api/v1'),
      httpClient: MockClient((_) async => throw Exception('offline')),
    );

    await expectLater(
      client.fetchClasses(),
      throwsA(
        isA<ClassesBookingsApiException>().having(
          (error) => error.message,
          'message',
          contains('Could not reach'),
        ),
      ),
    );
  });
}
