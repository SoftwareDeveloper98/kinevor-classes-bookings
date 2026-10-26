import 'package:kinevor_classes_bookings/kinevor_classes_bookings.dart';

class FakeClassesRepository implements ClassesBookingsRepository {
  FakeClassesRepository({this.failure});

  final Object? failure;
  int classCalls = 0;
  int detailCalls = 0;
  int bookingCalls = 0;
  int cancelCalls = 0;
  int myBookingsCalls = 0;
  String? lastScope;
  String? lastMemberName;
  String? lastCancelledId;

  final Map<String, GymClassDetail> _details = {
    for (final item in sampleClasses) item.id: sampleDetailFor(item),
  };
  final List<MyBooking> _upcoming = [...sampleUpcomingBookings];
  final List<MyBooking> _past = [...samplePastBookings];

  void _check() {
    if (failure != null) throw failure!;
  }

  @override
  Future<ClassPage> getClasses({String? type, DateTime? fromDate}) async {
    classCalls++;
    _check();
    final items = type == null || type.isEmpty
        ? sampleClasses
        : sampleClasses.where((item) => item.type == type).toList();
    return ClassPage(items: [...items], totalCount: items.length);
  }

  @override
  Future<List<CatalogueItem>> getCatalogue() async {
    _check();
    return [
      for (final item in sampleClasses)
        CatalogueItem(
          type: item.type,
          upcomingSessions: 1,
          nextStartsAt: item.startsAt,
          nextClassName: item.name,
        ),
    ];
  }

  @override
  Future<GymClassDetail> getClass(String classId) async {
    detailCalls++;
    _check();
    final detail = _details[classId];
    if (detail == null) {
      throw const ClassesBookingsApiException('Class not found.');
    }
    return detail;
  }

  @override
  Future<BookClassResult> bookClass(
    String classId, {
    String? memberId,
    String? memberName,
  }) async {
    bookingCalls++;
    lastMemberName = memberName;
    _check();
    final detail = _details[classId];
    if (detail == null) {
      throw const ClassesBookingsApiException('Class not found.');
    }

    final booking = ClassBooking(
      id: 'booking-new',
      classId: detail.id,
      className: detail.name,
      classStartsAt: detail.startsAt,
      memberId: memberId ?? '11111111-1111-1111-1111-111111111111',
      memberName: memberName ?? 'Maya Thompson',
      status: detail.isFull ? 'WaitListed' : 'Confirmed',
      isWaitListed: detail.isFull,
      bookedAt: DateTime(2026, 10, 21, 10),
    );
    _details[classId] = _updated(
      detail,
      myBooking: booking,
      bookedCount: detail.isFull ? detail.bookedCount : detail.bookedCount + 1,
      waitListCount: detail.isFull
          ? detail.waitListCount + 1
          : detail.waitListCount,
      availableSpots: detail.isFull ? 0 : detail.availableSpots - 1,
      roster: [...detail.roster, booking],
    );
    return BookClassResult(
      bookingId: booking.id,
      isWaitListed: booking.isWaitListed,
      status: booking.status,
      availableSpots: detail.isFull ? 0 : detail.availableSpots - 1,
      waitListPosition: booking.isWaitListed ? detail.waitListCount + 1 : 0,
    );
  }

  @override
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    cancelCalls++;
    lastCancelledId = bookingId;
    _check();
    _upcoming.removeWhere((booking) => booking.id == bookingId);
    _past.removeWhere((booking) => booking.id == bookingId);
    for (final entry in _details.entries.toList()) {
      final booking = entry.value.myBooking;
      if (booking?.id == bookingId) {
        _details[entry.key] = _updated(
          entry.value,
          clearBooking: true,
          bookedCount: booking!.isWaitListed
              ? entry.value.bookedCount
              : entry.value.bookedCount - 1,
          waitListCount: booking.isWaitListed
              ? entry.value.waitListCount - 1
              : entry.value.waitListCount,
          availableSpots: booking.isWaitListed
              ? entry.value.availableSpots
              : entry.value.availableSpots + 1,
          roster: entry.value.roster
              .where((item) => item.id != bookingId)
              .toList(),
        );
      }
    }
  }

  @override
  Future<List<MyBooking>> getMyBookings({String scope = 'upcoming'}) async {
    myBookingsCalls++;
    lastScope = scope;
    _check();
    return [...(scope == 'past' ? _past : _upcoming)];
  }

  GymClassDetail _updated(
    GymClassDetail detail, {
    ClassBooking? myBooking,
    bool clearBooking = false,
    int? bookedCount,
    int? waitListCount,
    int? availableSpots,
    List<ClassBooking>? roster,
  }) {
    return GymClassDetail(
      id: detail.id,
      name: detail.name,
      description: detail.description,
      type: detail.type,
      trainerId: detail.trainerId,
      trainerName: detail.trainerName,
      startsAt: detail.startsAt,
      endsAt: detail.endsAt,
      durationMinutes: detail.durationMinutes,
      capacity: detail.capacity,
      bookedCount: bookedCount ?? detail.bookedCount,
      availableSpots: availableSpots ?? detail.availableSpots,
      waitListCount: waitListCount ?? detail.waitListCount,
      status: detail.status,
      room: detail.room,
      requiresMembership: detail.requiresMembership,
      isFull: detail.isFull,
      isOpenForBooking: detail.isOpenForBooking,
      notes: detail.notes,
      roster: roster ?? detail.roster,
      myBooking: clearBooking ? null : (myBooking ?? detail.myBooking),
    );
  }
}

GymClassDetail sampleDetailFor(
  GymClassSummary item, {
  ClassBooking? myBooking,
}) {
  return GymClassDetail(
    id: item.id,
    name: item.name,
    description: item.description,
    type: item.type,
    trainerId: item.trainerId,
    trainerName: item.trainerName,
    startsAt: item.startsAt,
    endsAt: item.endsAt,
    durationMinutes: item.durationMinutes,
    capacity: item.capacity,
    bookedCount: item.bookedCount,
    availableSpots: item.availableSpots,
    waitListCount: item.waitListCount,
    status: item.status,
    room: item.room,
    requiresMembership: item.requiresMembership,
    isFull: item.isFull,
    isOpenForBooking: item.isOpenForBooking,
    notes:
        'Bring water and arrive ten minutes before the session. Mats and '
        'towels are provided.',
    roster: [
      ClassBooking(
        id: 'roster-1',
        classId: item.id,
        className: item.name,
        classStartsAt: item.startsAt,
        memberId: 'member-2',
        memberName: 'Ethan Thompson',
        status: 'Confirmed',
        isWaitListed: false,
        bookedAt: DateTime(2026, 10, 18, 9),
      ),
      ClassBooking(
        id: 'roster-2',
        classId: item.id,
        className: item.name,
        classStartsAt: item.startsAt,
        memberId: 'member-3',
        memberName: 'Sofia Reyes',
        status: 'Confirmed',
        isWaitListed: false,
        bookedAt: DateTime(2026, 10, 18, 11),
      ),
    ],
    myBooking: myBooking,
  );
}

final sampleClasses = [
  GymClassSummary(
    id: 'class-yoga',
    name: 'Sunrise Yoga',
    description:
        'A grounding flow that pairs breath with slow, deliberate movement '
        'to open the hips, shoulders and spine.',
    type: 'Yoga',
    trainerId: 'trainer-1',
    trainerName: 'Maya Chen',
    startsAt: DateTime(2026, 10, 22, 7),
    endsAt: DateTime(2026, 10, 22, 8),
    durationMinutes: 60,
    capacity: 18,
    bookedCount: 14,
    availableSpots: 4,
    waitListCount: 1,
    status: 'Scheduled',
    room: 'Studio One',
    requiresMembership: true,
    isFull: false,
    isOpenForBooking: true,
  ),
  GymClassSummary(
    id: 'class-hiit',
    name: 'HIIT Burn',
    description:
        'Forty-five minutes of short, sharp intervals that build engine '
        'capacity and leave nothing in the tank.',
    type: 'HIIT',
    trainerId: 'trainer-2',
    trainerName: 'Noah Williams',
    startsAt: DateTime(2026, 10, 22, 12, 30),
    endsAt: DateTime(2026, 10, 22, 13, 15),
    durationMinutes: 45,
    capacity: 20,
    bookedCount: 20,
    availableSpots: 0,
    waitListCount: 3,
    status: 'Scheduled',
    room: 'The Engine Room',
    requiresMembership: true,
    isFull: true,
    isOpenForBooking: true,
  ),
  GymClassSummary(
    id: 'class-reformer',
    name: 'Reformer Pilates',
    description:
        'Precise, controlled sequences on the reformer to build deep core '
        'strength and length.',
    type: 'Pilates',
    trainerId: 'trainer-3',
    trainerName: 'Elena Rossi',
    startsAt: DateTime(2026, 10, 22, 18),
    endsAt: DateTime(2026, 10, 22, 19),
    durationMinutes: 60,
    capacity: 12,
    bookedCount: 9,
    availableSpots: 3,
    waitListCount: 0,
    status: 'Scheduled',
    room: 'Reformer Studio',
    requiresMembership: true,
    isFull: false,
    isOpenForBooking: true,
  ),
  GymClassSummary(
    id: 'class-spin',
    name: 'Power Spin',
    description:
        'A rhythm-led ride with climbs, sprints and a recovery track to '
        'finish.',
    type: 'Spinning',
    trainerId: 'trainer-4',
    trainerName: 'Leo Martins',
    startsAt: DateTime(2026, 10, 23, 6, 30),
    endsAt: DateTime(2026, 10, 23, 7, 15),
    durationMinutes: 45,
    capacity: 24,
    bookedCount: 18,
    availableSpots: 6,
    waitListCount: 0,
    status: 'Scheduled',
    room: 'Cycle Studio',
    requiresMembership: true,
    isFull: false,
    isOpenForBooking: true,
  ),
];

final sampleUpcomingBookings = [
  MyBooking(
    id: 'booking-yoga',
    classId: 'class-yoga',
    className: 'Sunrise Yoga',
    classType: 'Yoga',
    trainerName: 'Maya Chen',
    room: 'Studio One',
    startsAt: DateTime(2026, 10, 22, 7),
    endsAt: DateTime(2026, 10, 22, 8),
    bookingStatus: 'Confirmed',
    classStatus: 'Scheduled',
    isWaitListed: false,
    canCancel: true,
  ),
  MyBooking(
    id: 'booking-reformer',
    classId: 'class-reformer',
    className: 'Reformer Pilates',
    classType: 'Pilates',
    trainerName: 'Elena Rossi',
    room: 'Reformer Studio',
    startsAt: DateTime(2026, 10, 22, 18),
    endsAt: DateTime(2026, 10, 22, 19),
    bookingStatus: 'WaitListed',
    classStatus: 'Scheduled',
    isWaitListed: true,
    canCancel: true,
  ),
];

final samplePastBookings = [
  MyBooking(
    id: 'booking-spin',
    classId: 'class-spin',
    className: 'Power Spin',
    classType: 'Spinning',
    trainerName: 'Leo Martins',
    room: 'Cycle Studio',
    startsAt: DateTime(2026, 10, 18, 6, 30),
    endsAt: DateTime(2026, 10, 18, 7, 15),
    bookingStatus: 'Attended',
    classStatus: 'Completed',
    isWaitListed: false,
    canCancel: false,
    checkedInAt: DateTime(2026, 10, 18, 6, 24),
  ),
];
