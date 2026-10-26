/// One page of upcoming class sessions.
class ClassPage {
  /// Creates a class page.
  const ClassPage({required this.items, required this.totalCount});

  /// Sessions in this page.
  final List<GymClassSummary> items;

  /// Total sessions matching the query.
  final int totalCount;

  /// Parses a defensive paged class payload.
  factory ClassPage.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    return ClassPage(
      items: rawItems is List
          ? [
              for (final item in rawItems)
                if (item is Map)
                  GymClassSummary.fromJson(Map<String, dynamic>.from(item)),
            ]
          : const [],
      totalCount:
          (json['totalCount'] as num?)?.toInt() ??
          (rawItems is List ? rawItems.length : 0),
    );
  }
}

/// A single class session in the schedule.
class GymClassSummary {
  /// Creates a class summary.
  const GymClassSummary({
    required this.id,
    required this.name,
    required this.type,
    required this.trainerId,
    required this.trainerName,
    required this.startsAt,
    required this.endsAt,
    required this.durationMinutes,
    required this.capacity,
    required this.bookedCount,
    required this.availableSpots,
    required this.waitListCount,
    required this.status,
    required this.room,
    required this.requiresMembership,
    required this.isFull,
    required this.isOpenForBooking,
    this.description,
  });

  /// Stable class identifier.
  final String id;

  /// Session name.
  final String name;

  /// Optional session description.
  final String? description;

  /// Class type, for example `Yoga` or `HIIT`.
  final String type;

  /// Trainer identifier.
  final String trainerId;

  /// Trainer display name.
  final String trainerName;

  /// Session start.
  final DateTime startsAt;

  /// Session end.
  final DateTime endsAt;

  /// Session length in minutes.
  final int durationMinutes;

  /// Maximum seats.
  final int capacity;

  /// Confirmed bookings.
  final int bookedCount;

  /// Seats still available.
  final int availableSpots;

  /// Members waiting for a seat.
  final int waitListCount;

  /// Scheduled, InProgress, Completed or Cancelled.
  final String status;

  /// Studio or training area.
  final String room;

  /// Whether an active membership is required.
  final bool requiresMembership;

  /// Whether every seat is taken.
  final bool isFull;

  /// Whether the session still accepts bookings or waitlist joins.
  final bool isOpenForBooking;

  /// Parses a defensive class summary payload.
  factory GymClassSummary.fromJson(
    Map<String, dynamic> json,
  ) => GymClassSummary(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString(),
    type: json['type']?.toString() ?? '',
    trainerId: json['trainerId']?.toString() ?? '',
    trainerName: json['trainerName']?.toString() ?? '',
    startsAt:
        DateTime.tryParse(json['startsAt']?.toString() ?? '') ?? DateTime(1970),
    endsAt:
        DateTime.tryParse(json['endsAt']?.toString() ?? '') ?? DateTime(1970),
    durationMinutes: (json['durationMinutes'] as num?)?.toInt() ?? 0,
    capacity: (json['capacity'] as num?)?.toInt() ?? 0,
    bookedCount: (json['bookedCount'] as num?)?.toInt() ?? 0,
    availableSpots: (json['availableSpots'] as num?)?.toInt() ?? 0,
    waitListCount: (json['waitListCount'] as num?)?.toInt() ?? 0,
    status: json['status']?.toString() ?? 'Scheduled',
    room: json['room']?.toString() ?? '',
    requiresMembership: json['requiresMembership'] == true,
    isFull: json['isFull'] == true,
    isOpenForBooking: json['isOpenForBooking'] == true,
  );
}

/// Full class detail including notes, roster and the member's booking.
class GymClassDetail extends GymClassSummary {
  /// Creates a class detail.
  const GymClassDetail({
    required super.id,
    required super.name,
    required super.type,
    required super.trainerId,
    required super.trainerName,
    required super.startsAt,
    required super.endsAt,
    required super.durationMinutes,
    required super.capacity,
    required super.bookedCount,
    required super.availableSpots,
    required super.waitListCount,
    required super.status,
    required super.room,
    required super.requiresMembership,
    required super.isFull,
    required super.isOpenForBooking,
    required this.roster,
    super.description,
    this.notes,
    this.myBooking,
  });

  /// Session notes shown before arrival.
  final String? notes;

  /// Confirmed and waitlisted bookings visible to staff.
  final List<ClassBooking> roster;

  /// The authenticated member's booking, when one exists.
  final ClassBooking? myBooking;

  /// Parses a defensive class detail payload.
  factory GymClassDetail.fromJson(Map<String, dynamic> json) {
    final summary = GymClassSummary.fromJson(json);
    final rawRoster = json['roster'];
    final rawBooking = json['myBooking'];
    return GymClassDetail(
      id: summary.id,
      name: summary.name,
      description: summary.description,
      type: summary.type,
      trainerId: summary.trainerId,
      trainerName: summary.trainerName,
      startsAt: summary.startsAt,
      endsAt: summary.endsAt,
      durationMinutes: summary.durationMinutes,
      capacity: summary.capacity,
      bookedCount: summary.bookedCount,
      availableSpots: summary.availableSpots,
      waitListCount: summary.waitListCount,
      status: summary.status,
      room: summary.room,
      requiresMembership: summary.requiresMembership,
      isFull: summary.isFull,
      isOpenForBooking: summary.isOpenForBooking,
      notes: json['notes']?.toString(),
      roster: rawRoster is List
          ? [
              for (final item in rawRoster)
                if (item is Map)
                  ClassBooking.fromJson(Map<String, dynamic>.from(item)),
            ]
          : const [],
      myBooking: rawBooking is Map
          ? ClassBooking.fromJson(Map<String, dynamic>.from(rawBooking))
          : null,
    );
  }
}

/// A booking or waitlist entry attached to a class.
class ClassBooking {
  /// Creates a class booking.
  const ClassBooking({
    required this.id,
    required this.classId,
    required this.className,
    required this.classStartsAt,
    required this.memberId,
    required this.memberName,
    required this.status,
    required this.isWaitListed,
    required this.bookedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.checkedInAt,
  });

  /// Stable booking identifier.
  final String id;

  /// Class identifier.
  final String classId;

  /// Class name.
  final String className;

  /// Class start time.
  final DateTime classStartsAt;

  /// Member identifier.
  final String memberId;

  /// Member display name.
  final String memberName;

  /// Confirmed, Cancelled, Attended, NoShow or WaitListed.
  final String status;

  /// Whether the booking is on the waitlist.
  final bool isWaitListed;

  /// When the booking was created.
  final DateTime bookedAt;

  /// When the booking was cancelled.
  final DateTime? cancelledAt;

  /// Optional cancellation reason.
  final String? cancellationReason;

  /// Staff check-in timestamp.
  final DateTime? checkedInAt;

  /// First letters of the first two name parts.
  String get initials {
    final parts = memberName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty);
    if (parts.isEmpty) return '?';
    return parts.take(2).map((part) => part[0].toUpperCase()).join();
  }

  /// Parses a defensive booking payload.
  factory ClassBooking.fromJson(Map<String, dynamic> json) => ClassBooking(
    id: json['id']?.toString() ?? '',
    classId: json['classId']?.toString() ?? '',
    className: json['className']?.toString() ?? '',
    classStartsAt:
        DateTime.tryParse(json['classStartsAt']?.toString() ?? '') ??
        DateTime(1970),
    memberId: json['memberId']?.toString() ?? '',
    memberName: json['memberName']?.toString() ?? '',
    status: json['status']?.toString() ?? 'Confirmed',
    isWaitListed: json['isWaitListed'] == true,
    bookedAt:
        DateTime.tryParse(json['bookedAt']?.toString() ?? '') ?? DateTime(1970),
    cancelledAt: DateTime.tryParse(json['cancelledAt']?.toString() ?? ''),
    cancellationReason: json['cancellationReason']?.toString(),
    checkedInAt: DateTime.tryParse(json['checkedInAt']?.toString() ?? ''),
  );
}

/// Outcome of a booking request.
class BookClassResult {
  /// Creates a booking result.
  const BookClassResult({
    required this.bookingId,
    required this.isWaitListed,
    required this.status,
    required this.availableSpots,
    required this.waitListPosition,
  });

  /// Created booking identifier.
  final String bookingId;

  /// Whether the member joined the waitlist.
  final bool isWaitListed;

  /// Confirmed or WaitListed.
  final String status;

  /// Seats still available after the request.
  final int availableSpots;

  /// Position on the waitlist, or zero when confirmed.
  final int waitListPosition;

  /// Parses a defensive booking result.
  factory BookClassResult.fromJson(Map<String, dynamic> json) =>
      BookClassResult(
        bookingId: json['bookingId']?.toString() ?? '',
        isWaitListed: json['isWaitListed'] == true,
        status: json['status']?.toString() ?? '',
        availableSpots: (json['availableSpots'] as num?)?.toInt() ?? 0,
        waitListPosition: (json['waitListPosition'] as num?)?.toInt() ?? 0,
      );
}

/// One of the authenticated member's bookings.
class MyBooking {
  /// Creates a member booking.
  const MyBooking({
    required this.id,
    required this.classId,
    required this.className,
    required this.classType,
    required this.trainerName,
    required this.room,
    required this.startsAt,
    required this.endsAt,
    required this.bookingStatus,
    required this.classStatus,
    required this.isWaitListed,
    required this.canCancel,
    this.checkedInAt,
  });

  /// Stable booking identifier.
  final String id;

  /// Class identifier.
  final String classId;

  /// Class name.
  final String className;

  /// Class type.
  final String classType;

  /// Trainer display name.
  final String trainerName;

  /// Studio or training area.
  final String room;

  /// Session start.
  final DateTime startsAt;

  /// Session end.
  final DateTime endsAt;

  /// Booking lifecycle status.
  final String bookingStatus;

  /// Class lifecycle status.
  final String classStatus;

  /// Whether the booking is on the waitlist.
  final bool isWaitListed;

  /// Whether the member can still cancel or leave the waitlist.
  final bool canCancel;

  /// Check-in timestamp, when attended.
  final DateTime? checkedInAt;

  /// Parses a defensive member booking payload.
  factory MyBooking.fromJson(Map<String, dynamic> json) => MyBooking(
    id: json['id']?.toString() ?? '',
    classId: json['classId']?.toString() ?? '',
    className: json['className']?.toString() ?? '',
    classType: json['classType']?.toString() ?? '',
    trainerName: json['trainerName']?.toString() ?? '',
    room: json['room']?.toString() ?? '',
    startsAt:
        DateTime.tryParse(json['startsAt']?.toString() ?? '') ?? DateTime(1970),
    endsAt:
        DateTime.tryParse(json['endsAt']?.toString() ?? '') ?? DateTime(1970),
    bookingStatus: json['bookingStatus']?.toString() ?? 'Confirmed',
    classStatus: json['classStatus']?.toString() ?? 'Scheduled',
    isWaitListed: json['isWaitListed'] == true,
    canCancel: json['canCancel'] == true,
    checkedInAt: DateTime.tryParse(json['checkedInAt']?.toString() ?? ''),
  );
}

/// Class type with upcoming sessions.
class CatalogueItem {
  /// Creates a catalogue item.
  const CatalogueItem({
    required this.type,
    required this.upcomingSessions,
    this.nextStartsAt,
    this.nextClassName,
  });

  /// Class type.
  final String type;

  /// Number of upcoming sessions.
  final int upcomingSessions;

  /// Start of the next session.
  final DateTime? nextStartsAt;

  /// Name of the next session.
  final String? nextClassName;

  /// Parses a defensive catalogue payload.
  factory CatalogueItem.fromJson(Map<String, dynamic> json) => CatalogueItem(
    type: json['type']?.toString() ?? '',
    upcomingSessions: (json['upcomingSessions'] as num?)?.toInt() ?? 0,
    nextStartsAt: DateTime.tryParse(json['nextStartsAt']?.toString() ?? ''),
    nextClassName: json['nextClassName']?.toString(),
  );
}
