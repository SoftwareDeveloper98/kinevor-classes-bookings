import '../models/gym_class.dart';
import 'kinevor_classes_bookings_client.dart';

/// Data source for the class schedule and booking screens.
abstract interface class ClassesBookingsRepository {
  /// Loads upcoming sessions.
  Future<ClassPage> getClasses({String? type, DateTime? fromDate});

  /// Loads the class catalogue.
  Future<List<CatalogueItem>> getCatalogue();

  /// Loads one class with roster and the member's booking.
  Future<GymClassDetail> getClass(String classId);

  /// Books a seat or joins the waitlist.
  Future<BookClassResult> bookClass(
    String classId, {
    String? memberId,
    String? memberName,
  });

  /// Cancels a booking or leaves a waitlist.
  Future<void> cancelBooking(String bookingId, {String? reason});

  /// Loads the member's upcoming or past bookings.
  Future<List<MyBooking>> getMyBookings({String scope = 'upcoming'});
}

/// [ClassesBookingsRepository] backed by [KinevorClassesBookingsClient].
class RemoteClassesBookingsRepository implements ClassesBookingsRepository {
  /// Creates a repository over [client].
  const RemoteClassesBookingsRepository(this.client);

  /// HTTP client used for every call.
  final KinevorClassesBookingsClient client;

  @override
  Future<ClassPage> getClasses({String? type, DateTime? fromDate}) =>
      client.fetchClasses(type: type, fromDate: fromDate);

  @override
  Future<List<CatalogueItem>> getCatalogue() => client.fetchCatalogue();

  @override
  Future<GymClassDetail> getClass(String classId) => client.fetchClass(classId);

  @override
  Future<BookClassResult> bookClass(
    String classId, {
    String? memberId,
    String? memberName,
  }) => client.bookClass(classId, memberId: memberId, memberName: memberName);

  @override
  Future<void> cancelBooking(String bookingId, {String? reason}) =>
      client.cancelBooking(bookingId, reason: reason);

  @override
  Future<List<MyBooking>> getMyBookings({String scope = 'upcoming'}) =>
      client.fetchMyBookings(scope: scope);
}
