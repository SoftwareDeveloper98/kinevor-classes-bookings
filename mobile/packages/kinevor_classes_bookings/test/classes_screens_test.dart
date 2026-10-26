import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinevor_classes_bookings/kinevor_classes_bookings.dart';

import 'fake_classes_repository.dart';

Future<void> _pumpPhone(WidgetTester tester, Widget home) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    MaterialApp(theme: KinevorClassesBookingsTheme.dark(), home: home),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('schedule renders the hero, capacity and next session', (
    tester,
  ) async {
    final repository = FakeClassesRepository();
    await _pumpPhone(tester, ClassScheduleScreen(repository: repository));

    expect(repository.classCalls, 1);
    expect(repository.myBookingsCalls, 1);
    expect(find.text('KINEVOR MOVEMENT'), findsOneWidget);
    expect(find.text('Train with intent.'), findsOneWidget);
    expect(find.text('NEXT UP · 07:00'), findsOneWidget);
    expect(find.text('Sunrise Yoga'), findsWidgets);
    expect(find.text('14 of 18 booked'), findsOneWidget);
    expect(find.text('4 spots left'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('HIIT Burn'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(find.text('Waitlist'), findsOneWidget);
  });

  testWidgets('schedule filters the timetable by class type', (tester) async {
    await _pumpPhone(
      tester,
      ClassScheduleScreen(repository: FakeClassesRepository()),
    );

    await tester.ensureVisible(find.text('Pilates'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilates'));
    await tester.pumpAndSettle();

    expect(find.text('Reformer Pilates'), findsOneWidget);
    expect(find.text('HIIT Burn'), findsNothing);
    expect(find.text('Power Spin'), findsNothing);
  });

  testWidgets('schedule opens my bookings and switches to past sessions', (
    tester,
  ) async {
    final repository = FakeClassesRepository();
    await _pumpPhone(tester, ClassScheduleScreen(repository: repository));

    await tester.tap(find.byTooltip('My bookings'));
    await tester.pumpAndSettle();

    expect(find.text('My bookings'), findsOneWidget);
    expect(find.text('Sunrise Yoga'), findsOneWidget);
    expect(find.text('Reformer Pilates'), findsOneWidget);
    expect(find.text('WAITLISTED'), findsOneWidget);

    await tester.tap(find.text('Past sessions'));
    await tester.pumpAndSettle();

    expect(repository.lastScope, 'past');
    expect(find.text('Power Spin'), findsOneWidget);
    expect(find.text('COMPLETED'), findsOneWidget);
  });

  testWidgets('my bookings cancels a confirmed seat', (tester) async {
    final repository = FakeClassesRepository();
    await _pumpPhone(tester, MemberBookingsScreen(repository: repository));

    await tester.tap(find.widgetWithText(TextButton, 'Cancel').first);
    await tester.pumpAndSettle();

    expect(find.text('Cancel booking'), findsOneWidget);
    expect(
      find.text(
        'Cancel this booking? Your seat may be offered to the waitlist.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Cancel'));
    await tester.pumpAndSettle();

    expect(repository.cancelCalls, 1);
    expect(repository.lastCancelledId, 'booking-yoga');
    expect(find.text('Booking cancelled.'), findsOneWidget);
    expect(find.text('Sunrise Yoga'), findsNothing);
  });

  testWidgets('detail shows capacity, notes and the class roster', (
    tester,
  ) async {
    await _pumpPhone(
      tester,
      ClassDetailScreen(
        repository: FakeClassesRepository(),
        classId: 'class-yoga',
      ),
    );

    expect(find.text('Sunrise Yoga'), findsOneWidget);
    expect(find.text('Thursday 22 October'), findsOneWidget);
    expect(find.text('07:00 – 08:00'), findsOneWidget);
    expect(find.text('Maya Chen'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text("Who's coming"),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Seats and waitlist'), findsOneWidget);
    expect(
      find.text(
        'Bring water and arrive ten minutes before the session. Mats and towels are provided.',
      ),
      findsOneWidget,
    );
    expect(find.text('Ethan Thompson'), findsOneWidget);
    expect(find.text('2 booked'), findsOneWidget);
  });

  testWidgets('detail books a seat and refreshes the member booking', (
    tester,
  ) async {
    final repository = FakeClassesRepository();
    await _pumpPhone(
      tester,
      ClassDetailScreen(repository: repository, classId: 'class-yoga'),
    );

    await tester.scrollUntilVisible(
      find.text('Book this class'),
      220,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Book this class'));
    await tester.pumpAndSettle();

    expect(repository.bookingCalls, 1);
    expect(repository.lastMemberName, 'Maya Thompson');
    expect(find.text("You're on the list"), findsOneWidget);
    expect(find.text('SEAT CONFIRMED'), findsOneWidget);
  });

  testWidgets('load failures show a retry action', (tester) async {
    final repository = FakeClassesRepository(
      failure: const ClassesBookingsApiException('Classes API unavailable.'),
    );
    await _pumpPhone(tester, ClassScheduleScreen(repository: repository));

    expect(find.text('Classes API unavailable.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
