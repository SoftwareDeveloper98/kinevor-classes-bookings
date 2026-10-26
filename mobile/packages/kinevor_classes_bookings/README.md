# kinevor_classes_bookings

Standalone Flutter UI for the Kinevor classes and bookings module.

The package provides:

- a live class schedule with capacity, filters and waitlist state
- a class detail screen with trainer, room, notes, roster and booking actions
- booking, cancellation and automatic waitlist handling
- upcoming and past member bookings
- a typed HTTP client and repository for the Kinevor classes API

## Use

```dart
final client = KinevorClassesBookingsClient(
  baseUrl: Uri.parse('http://localhost:5085/api/v1'),
  headers: const {
    'X-Demo-Role': 'Staff',
    'X-Demo-Member': '11111111-1111-1111-1111-111111111111',
  },
);

runApp(
  MaterialApp(
    theme: KinevorClassesBookingsTheme.dark(),
    home: ClassScheduleScreen(
      repository: RemoteClassesBookingsRepository(client),
    ),
  ),
);
```

`ClassScheduleScreen` opens `ClassDetailScreen` for a session and
`MemberBookingsScreen` for the member's upcoming and past bookings. The roster
is populated only for staff and trainer identities; member responses show only
the member's own booking.

## Test

```bash
flutter analyze
flutter test
flutter test --update-goldens test/classes_golden_test.dart
```

The suite covers the typed client, schedule filters, detail booking, member
cancellation, load failures and `390x844` golden images.

## Example

The `example/` app runs against the standalone Demo API on port 5085.

```bash
cd example
flutter run -d chrome
```
