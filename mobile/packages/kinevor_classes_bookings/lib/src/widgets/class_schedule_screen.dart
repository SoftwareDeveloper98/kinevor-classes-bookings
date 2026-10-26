import 'package:flutter/material.dart';

import '../data/classes_bookings_api_exception.dart';
import '../data/classes_bookings_repository.dart';
import '../models/gym_class.dart';
import '../theme/classes_bookings_strings.dart';
import '../theme/kinevor_classes_bookings_theme.dart';
import 'class_detail_screen.dart';
import 'member_bookings_screen.dart';

/// Live class timetable with capacity, filters and waitlist state.
class ClassScheduleScreen extends StatefulWidget {
  /// Creates the class schedule.
  const ClassScheduleScreen({
    super.key,
    required this.repository,
    this.strings = const ClassesBookingsStrings(),
    this.memberName = 'Maya Thompson',
  });

  /// Data source used for classes and member bookings.
  final ClassesBookingsRepository repository;

  /// Localized labels.
  final ClassesBookingsStrings strings;

  /// Member name sent when booking a seat.
  final String memberName;

  @override
  State<ClassScheduleScreen> createState() => _ClassScheduleScreenState();
}

class _ClassScheduleScreenState extends State<ClassScheduleScreen> {
  List<GymClassSummary> _classes = const [];
  List<MyBooking> _bookings = const [];
  bool _loading = true;
  String? _error;
  String _type = 'All';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final results = await Future.wait<Object>([
        widget.repository.getClasses(fromDate: start),
        widget.repository.getMyBookings(),
      ]);
      final page = results[0] as ClassPage;
      final bookings = results[1] as List<MyBooking>;
      if (!mounted) return;
      setState(() {
        _classes = page.items;
        _bookings = bookings;
        _loading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() {
        _error = _clean(error);
        _loading = false;
      });
    }
  }

  String _clean(Object error) => error is ClassesBookingsApiException
      ? error.message
      : widget.strings.loadError;

  List<String> get _types {
    final seen = <String>{};
    return [
      for (final item in _classes)
        if (seen.add(item.type)) item.type,
    ];
  }

  List<GymClassSummary> get _visibleClasses => _type == 'All'
      ? _classes
      : _classes.where((item) => item.type == _type).toList();

  int get _openSeats =>
      _classes.fold(0, (total, item) => total + item.availableSpots);

  int get _occupancy {
    final capacity = _classes.fold(0, (total, item) => total + item.capacity);
    final booked = _classes.fold(0, (total, item) => total + item.bookedCount);
    return capacity == 0 ? 0 : ((booked / capacity) * 100).round();
  }

  GymClassSummary? get _nextClass => _classes.isEmpty ? null : _classes.first;

  Future<void> _openClass(GymClassSummary item) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ClassDetailScreen(
          repository: widget.repository,
          classId: item.id,
          strings: widget.strings,
          memberName: widget.memberName,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _openBookings() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MemberBookingsScreen(
          repository: widget.repository,
          strings: widget.strings,
        ),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                gradient: KinevorClassesBookingsTheme.brandGradient,
                borderRadius: BorderRadius.circular(9),
              ),
              alignment: Alignment.center,
              child: const Text(
                'K',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: KinevorClassesBookingsTheme.onAccent,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(strings.title),
          ],
        ),
        actions: [
          IconButton(
            tooltip: strings.myBookings,
            onPressed: _openBookings,
            icon: Badge(
              isLabelVisible: _bookings.isNotEmpty,
              label: Text('${_bookings.length}'),
              backgroundColor: KinevorClassesBookingsTheme.accent,
              child: const Icon(Icons.confirmation_number_outlined),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_loading && _classes.isEmpty)
              const Center(child: CircularProgressIndicator())
            else if (_classes.isEmpty && _error != null)
              _ErrorState(
                message: _error!,
                retryLabel: strings.retry,
                onRetry: _load,
              )
            else
              RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 32),
                  children: [
                    _ScheduleHero(
                      strings: strings,
                      sessions: _classes.length,
                      openSeats: _openSeats,
                      occupancy: _occupancy,
                    ),
                    if (_nextClass != null) ...[
                      const SizedBox(height: 12),
                      _NextClassCard(
                        item: _nextClass!,
                        strings: strings,
                        onTap: () => _openClass(_nextClass!),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _InlineError(
                        message: _error!,
                        retryLabel: strings.retry,
                        onRetry: _load,
                      ),
                    ],
                    const SizedBox(height: 22),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            strings.thisWeek,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        Text(
                          strings.sessions(_classes.length),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: KinevorClassesBookingsTheme.textMuted,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TypeFilters(
                      strings: strings,
                      types: _types,
                      selected: _type,
                      onSelected: (value) => setState(() => _type = value),
                    ),
                    const SizedBox(height: 16),
                    if (_visibleClasses.isEmpty)
                      _EmptyClasses(strings: strings)
                    else
                      for (final item in _visibleClasses)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _ClassCard(
                            item: item,
                            strings: strings,
                            onTap: () => _openClass(item),
                          ),
                        ),
                  ],
                ),
              ),
            if (_loading && _classes.isNotEmpty)
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LinearProgressIndicator(minHeight: 2),
              ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleHero extends StatelessWidget {
  const _ScheduleHero({
    required this.strings,
    required this.sessions,
    required this.openSeats,
    required this.occupancy,
  });

  final ClassesBookingsStrings strings;
  final int sessions;
  final int openSeats;
  final int occupancy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KinevorClassesBookingsTheme.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KinevorClassesBookingsTheme.accent.withValues(alpha: 0.18),
            KinevorClassesBookingsTheme.surfaceRaised,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: KinevorClassesBookingsTheme.accent,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: KinevorClassesBookingsTheme.accent.withValues(
                        alpha: 0.35,
                      ),
                      blurRadius: 10,
                      spreadRadius: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                strings.eyebrow,
                style: const TextStyle(
                  color: KinevorClassesBookingsTheme.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            strings.scheduleTitle,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 32,
              height: 1.05,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            strings.scheduleSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: KinevorClassesBookingsTheme.textMuted,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _HeroStat(value: '$sessions', label: strings.upcomingSessions),
              const SizedBox(width: 8),
              _HeroStat(value: '$openSeats', label: strings.openSeats),
              const SizedBox(width: 8),
              _HeroStat(value: '$occupancy%', label: strings.filled),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: KinevorClassesBookingsTheme.ink.withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: KinevorClassesBookingsTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: KinevorClassesBookingsTheme.text,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: KinevorClassesBookingsTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextClassCard extends StatelessWidget {
  const _NextClassCard({
    required this.item,
    required this.strings,
    required this.onTap,
  });

  final GymClassSummary item;
  final ClassesBookingsStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = KinevorClassesBookingsTheme.classColor(item.type);
    return Material(
      color: KinevorClassesBookingsTheme.surfaceRaised,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  KinevorClassesBookingsTheme.classIcon(item.type),
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${strings.nextUp} · ${strings.time(item.startsAt)}',
                      style: TextStyle(
                        color: color,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.trainerName} · ${item.room}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        color: KinevorClassesBookingsTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.arrow_forward,
                size: 18,
                color: KinevorClassesBookingsTheme.accent,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeFilters extends StatelessWidget {
  const _TypeFilters({
    required this.strings,
    required this.types,
    required this.selected,
    required this.onSelected,
  });

  final ClassesBookingsStrings strings;
  final List<String> types;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChip(
            label: strings.allClasses,
            selected: selected == 'All',
            onTap: () => onSelected('All'),
          ),
          for (final type in types) ...[
            const SizedBox(width: 8),
            _FilterChip(
              label: strings.typeLabel(type),
              selected: selected == type,
              onTap: () => onSelected(type),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? KinevorClassesBookingsTheme.accent
          : KinevorClassesBookingsTheme.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? KinevorClassesBookingsTheme.accent
                  : KinevorClassesBookingsTheme.border,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected
                  ? KinevorClassesBookingsTheme.onAccent
                  : KinevorClassesBookingsTheme.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}

class _ClassCard extends StatelessWidget {
  const _ClassCard({
    required this.item,
    required this.strings,
    required this.onTap,
  });

  final GymClassSummary item;
  final ClassesBookingsStrings strings;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = KinevorClassesBookingsTheme.classColor(item.type);
    final percentage = item.capacity == 0
        ? 0.0
        : (item.bookedCount / item.capacity).clamp(0.0, 1.0);
    return Material(
      color: KinevorClassesBookingsTheme.surfaceRaised,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: KinevorClassesBookingsTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: KinevorClassesBookingsTheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: KinevorClassesBookingsTheme.border,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          strings.weekday(item.startsAt),
                          style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.1,
                            color: KinevorClassesBookingsTheme.textMuted,
                          ),
                        ),
                        Text(
                          strings.day(item.startsAt),
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        Text(
                          strings.month(item.startsAt),
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            strings.typeLabel(item.type).toUpperCase(),
                            style: TextStyle(
                              color: color,
                              fontSize: 8,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          strings.timeRange(item.startsAt, item.endsAt),
                          style: const TextStyle(
                            fontSize: 12,
                            color: KinevorClassesBookingsTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 8,
                    height: 8,
                    margin: const EdgeInsets.only(top: 5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: item.isFull
                          ? KinevorClassesBookingsTheme.warning
                          : KinevorClassesBookingsTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 14,
                runSpacing: 6,
                children: [
                  _Meta(icon: Icons.person_outline, label: item.trainerName),
                  _Meta(icon: Icons.meeting_room_outlined, label: item.room),
                  _Meta(
                    icon: Icons.schedule,
                    label: '${item.durationMinutes} min',
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      strings.bookedOf(item.bookedCount, item.capacity),
                      style: const TextStyle(
                        fontSize: 10,
                        color: KinevorClassesBookingsTheme.textMuted,
                      ),
                    ),
                  ),
                  Text(
                    item.isFull
                        ? strings.waitlist
                        : strings.spots(item.availableSpots),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: item.isFull
                          ? KinevorClassesBookingsTheme.warning
                          : KinevorClassesBookingsTheme.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: percentage,
                  minHeight: 5,
                  backgroundColor: KinevorClassesBookingsTheme.surface,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onTap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(strings.viewClass),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_forward, size: 15),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: KinevorClassesBookingsTheme.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: KinevorClassesBookingsTheme.textMuted,
          ),
        ),
      ],
    );
  }
}

class _EmptyClasses extends StatelessWidget {
  const _EmptyClasses({required this.strings});

  final ClassesBookingsStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: KinevorClassesBookingsTheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KinevorClassesBookingsTheme.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_busy,
            color: KinevorClassesBookingsTheme.textMuted,
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            'No classes match this filter',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            strings.scheduleSubtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: KinevorClassesBookingsTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: KinevorClassesBookingsTheme.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: KinevorClassesBookingsTheme.error.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: KinevorClassesBookingsTheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 12,
                color: KinevorClassesBookingsTheme.error,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 42,
              color: KinevorClassesBookingsTheme.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: KinevorClassesBookingsTheme.textMuted,
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ),
      ),
    );
  }
}
