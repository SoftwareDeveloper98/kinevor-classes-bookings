import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kinevor_classes_bookings/kinevor_classes_bookings.dart';

import 'fake_classes_repository.dart';

Future<void> _loadFonts() async {
  final bytes = await File('assets/fonts/Sora-Variable.ttf').readAsBytes();
  final sora = FontLoader('Sora')
    ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  await sora.load();

  final material = await rootBundle.load('fonts/MaterialIcons-Regular.otf');
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future<ByteData>.value(material));
  await icons.load();
}

Future<void> _setPhoneSize(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _detailRoute(ClassesBookingsRepository repository) {
  return MaterialApp(
    theme: KinevorClassesBookingsTheme.dark(),
    initialRoute: '/detail',
    routes: {
      '/': (_) => const Scaffold(body: SizedBox.shrink()),
      '/detail': (_) =>
          ClassDetailScreen(repository: repository, classId: 'class-hiit'),
    },
  );
}

Widget _bookingsRoute(ClassesBookingsRepository repository) {
  return MaterialApp(
    theme: KinevorClassesBookingsTheme.dark(),
    initialRoute: '/bookings',
    routes: {
      '/': (_) => const Scaffold(body: SizedBox.shrink()),
      '/bookings': (_) => MemberBookingsScreen(repository: repository),
    },
  );
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('schedule golden', (tester) async {
    await _setPhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: KinevorClassesBookingsTheme.dark(),
        home: ClassScheduleScreen(repository: FakeClassesRepository()),
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ClassScheduleScreen),
      matchesGoldenFile('goldens/class_schedule.png'),
    );
  });

  testWidgets('class detail golden', (tester) async {
    await _setPhoneSize(tester);
    await tester.pumpWidget(_detailRoute(FakeClassesRepository()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(ClassDetailScreen),
      matchesGoldenFile('goldens/class_detail.png'),
    );
  });

  testWidgets('member bookings golden', (tester) async {
    await _setPhoneSize(tester);
    await tester.pumpWidget(_bookingsRoute(FakeClassesRepository()));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MemberBookingsScreen),
      matchesGoldenFile('goldens/member_bookings.png'),
    );
  });
}
