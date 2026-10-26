import 'package:flutter/material.dart';
import 'package:kinevor_classes_bookings/kinevor_classes_bookings.dart';

const String _apiBaseUrl = String.fromEnvironment(
  'KINEVOR_CLASSES_API_BASE_URL',
  defaultValue: 'http://localhost:5085/api/v1',
);

void main() {
  final client = KinevorClassesBookingsClient(
    baseUrl: Uri.parse(_apiBaseUrl),
    headers: const {
      'X-Demo-Role': 'Staff',
      'X-Demo-Email': 'staff.demo@kinevor.local',
      'X-Demo-Member': '11111111-1111-1111-1111-111111111111',
    },
  );
  runApp(
    ClassesBookingsDemoApp(repository: RemoteClassesBookingsRepository(client)),
  );
}

/// Demo application hosting the classes package against the standalone API.
class ClassesBookingsDemoApp extends StatelessWidget {
  /// Creates the demo app.
  const ClassesBookingsDemoApp({super.key, required this.repository});

  /// Data source used by the class screens.
  final ClassesBookingsRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kinevor Classes',
      debugShowCheckedModeBanner: false,
      theme: KinevorClassesBookingsTheme.dark(),
      home: ClassScheduleScreen(repository: repository),
    );
  }
}
