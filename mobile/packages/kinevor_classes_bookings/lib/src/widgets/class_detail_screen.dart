import 'package:flutter/material.dart';

import '../data/classes_bookings_api_exception.dart';
import '../data/classes_bookings_repository.dart';
import '../models/gym_class.dart';
import '../theme/classes_bookings_strings.dart';
import '../theme/kinevor_classes_bookings_theme.dart';

/// Class detail with capacity, roster, notes and booking actions.
class ClassDetailScreen extends StatefulWidget {
  /// Creates a class detail screen.
  const ClassDetailScreen({
    super.key,
    required this.repository,
    required this.classId,
    this.strings = const ClassesBookingsStrings(),
    this.memberName = 'Maya Thompson',
  });

  /// Data source used for the class and booking actions.
  final ClassesBookingsRepository repository;

  /// Class identifier to load.
  final String classId;

  /// Localized labels.
  final ClassesBookingsStrings strings;

  /// Member name sent when booking a seat.
  final String memberName;

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  GymClassDetail? _detail;
  bool _loading = true;
  bool _busy = false;
  String? _error;
  String? _message;
  bool _messageIsError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool clearMessage = true}) async {
    setState(() {
      _loading = true;
      _error = null;
      if (clearMessage) _message = null;
    });

    try {
      final detail = await widget.repository.getClass(widget.classId);
      if (!mounted) return;
      setState(() {
        _detail = detail;
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
      : widget.strings.actionFailed;

  void _showMessage(String message, {required bool isError}) {
    setState(() {
      _message = message;
      _messageIsError = isError;
    });
  }

  Future<void> _book(GymClassDetail detail) async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final result = await widget.repository.bookClass(
        detail.id,
        memberName: widget.memberName,
      );
      final refreshed = await widget.repository.getClass(detail.id);
      if (!mounted) return;
      setState(() {
        _detail = refreshed;
        _busy = false;
      });
      _showMessage(
        result.isWaitListed
            ? '${widget.strings.waitlistJoined} '
                  'Position ${result.waitListPosition}.'
            : widget.strings.seatBooked,
        isError: false,
      );
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage(_clean(error), isError: true);
    }
  }

  Future<void> _cancel(ClassBooking booking) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          booking.isWaitListed
              ? widget.strings.leavePrompt
              : widget.strings.cancelBooking,
        ),
        content: Text(
          booking.isWaitListed
              ? widget.strings.waitlistHeld
              : widget.strings.cancelPrompt,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(widget.strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              booking.isWaitListed
                  ? widget.strings.leaveWaitlist
                  : widget.strings.cancelBooking,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      await widget.repository.cancelBooking(
        booking.id,
        reason: 'Cancelled by member',
      );
      final refreshed = await widget.repository.getClass(widget.classId);
      if (!mounted) return;
      setState(() {
        _detail = refreshed;
        _busy = false;
      });
      _showMessage(
        booking.isWaitListed
            ? widget.strings.waitlistLeft
            : widget.strings.bookingCancelled,
        isError: false,
      );
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage(_clean(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.classDetail),
        actions: [
          IconButton(
            tooltip: strings.retry,
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            if (_loading && _detail == null)
              const Center(child: CircularProgressIndicator())
            else if (_detail == null)
              _DetailError(
                message: _error ?? strings.loadError,
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
                    _DetailHero(detail: _detail!, strings: strings),
                    if (_message != null) ...[
                      const SizedBox(height: 12),
                      _MessageBanner(
                        message: _message!,
                        isError: _messageIsError,
                        dismissLabel: strings.dismiss,
                        onDismiss: () => setState(() => _message = null),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      _MessageBanner(
                        message: _error!,
                        isError: true,
                        dismissLabel: strings.dismiss,
                        onDismiss: () => setState(() => _error = null),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _BookingPanel(
                      detail: _detail!,
                      strings: strings,
                      busy: _busy,
                      onBook: () => _book(_detail!),
                      onCancel: () => _cancel(_detail!.myBooking!),
                    ),
                    const SizedBox(height: 12),
                    _CapacityPanel(detail: _detail!, strings: strings),
                    if (_detail!.notes != null &&
                        _detail!.notes!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      _NotesPanel(notes: _detail!.notes!, strings: strings),
                    ],
                    const SizedBox(height: 12),
                    _RosterPanel(detail: _detail!, strings: strings),
                  ],
                ),
              ),
            if (_busy)
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

class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.detail, required this.strings});

  final GymClassDetail detail;
  final ClassesBookingsStrings strings;

  @override
  Widget build(BuildContext context) {
    final color = KinevorClassesBookingsTheme.classColor(detail.type);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KinevorClassesBookingsTheme.border),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.24),
            KinevorClassesBookingsTheme.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: color.withValues(alpha: 0.4)),
                ),
                child: Icon(
                  KinevorClassesBookingsTheme.classIcon(detail.type),
                  color: color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Chip(
                      label: strings.typeLabel(detail.type).toUpperCase(),
                      color: color,
                    ),
                    _Chip(
                      label: detail.status == 'InProgress'
                          ? 'In progress'
                          : detail.status,
                      color: KinevorClassesBookingsTheme.statusColor(
                        detail.status,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            detail.name,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: 31,
              height: 1.05,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            detail.description ?? strings.bookingIntro,
            style: const TextStyle(
              fontSize: 13,
              height: 1.55,
              color: KinevorClassesBookingsTheme.textMuted,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 7,
            children: [
              _Fact(
                icon: Icons.calendar_today_outlined,
                label: strings.fullDate(detail.startsAt),
                color: color,
              ),
              _Fact(
                icon: Icons.schedule,
                label: strings.timeRange(detail.startsAt, detail.endsAt),
                color: color,
              ),
              _Fact(
                icon: Icons.meeting_room_outlined,
                label: detail.room,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: KinevorClassesBookingsTheme.ink.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: KinevorClassesBookingsTheme.border),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _initials(detail.trainerName),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        detail.trainerName,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Trainer',
                        style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 0.8,
                          color: KinevorClassesBookingsTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${detail.durationMinutes} min',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: KinevorClassesBookingsTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: KinevorClassesBookingsTheme.text,
          ),
        ),
      ],
    );
  }
}

class _BookingPanel extends StatelessWidget {
  const _BookingPanel({
    required this.detail,
    required this.strings,
    required this.busy,
    required this.onBook,
    required this.onCancel,
  });

  final GymClassDetail detail;
  final ClassesBookingsStrings strings;
  final bool busy;
  final VoidCallback onBook;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final booking = detail.myBooking;
    final isFull = detail.isFull;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KinevorClassesBookingsTheme.border),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            KinevorClassesBookingsTheme.surfaceRaised,
            KinevorClassesBookingsTheme.surface,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            booking != null ? strings.yourBooking : strings.reservePlace,
            style: const TextStyle(
              color: KinevorClassesBookingsTheme.accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            booking != null ? strings.youreOnList : strings.readyToMove,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontSize: 22,
              letterSpacing: -0.4,
            ),
          ),
          if (booking != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                _Chip(
                  label: booking.isWaitListed
                      ? strings.waitlisted.toUpperCase()
                      : strings.seatConfirmed.toUpperCase(),
                  color: booking.isWaitListed
                      ? KinevorClassesBookingsTheme.warning
                      : KinevorClassesBookingsTheme.success,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              booking.isWaitListed ? strings.waitlistHeld : strings.seatHeld,
              style: const TextStyle(
                fontSize: 12,
                height: 1.55,
                color: KinevorClassesBookingsTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: KinevorClassesBookingsTheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: KinevorClassesBookingsTheme.border),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: KinevorClassesBookingsTheme.accent,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        strings.fullDate(detail.startsAt),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule,
                        size: 14,
                        color: KinevorClassesBookingsTheme.accent,
                      ),
                      const SizedBox(width: 7),
                      Text(
                        strings.time(detail.startsAt),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: busy ? null : onCancel,
                style: OutlinedButton.styleFrom(
                  foregroundColor: KinevorClassesBookingsTheme.error,
                  side: BorderSide(
                    color: KinevorClassesBookingsTheme.error.withValues(
                      alpha: 0.5,
                    ),
                  ),
                ),
                child: Text(
                  booking.isWaitListed
                      ? strings.leaveWaitlist
                      : strings.cancelBooking,
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              isFull ? strings.waitlistIntro : strings.bookingIntro,
              style: const TextStyle(
                fontSize: 12,
                height: 1.55,
                color: KinevorClassesBookingsTheme.textMuted,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _BookingStat(
                    label: strings.seatsLeft,
                    value: '${detail.availableSpots}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _BookingStat(
                    label: strings.waitlist,
                    value: '${detail.waitListCount}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: (!detail.isOpenForBooking || busy) ? null : onBook,
                icon: Icon(
                  isFull ? Icons.hourglass_top : Icons.event_available,
                  size: 18,
                ),
                label: Text(
                  detail.isOpenForBooking
                      ? (isFull ? strings.joinWaitlist : strings.bookSeat)
                      : strings.bookingClosed,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.lock_outline,
                size: 13,
                color: KinevorClassesBookingsTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  strings.noPayment,
                  style: const TextStyle(
                    fontSize: 9,
                    height: 1.5,
                    color: KinevorClassesBookingsTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BookingStat extends StatelessWidget {
  const _BookingStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: KinevorClassesBookingsTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KinevorClassesBookingsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: KinevorClassesBookingsTheme.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _CapacityPanel extends StatelessWidget {
  const _CapacityPanel({required this.detail, required this.strings});

  final GymClassDetail detail;
  final ClassesBookingsStrings strings;

  @override
  Widget build(BuildContext context) {
    final percentage = detail.capacity == 0
        ? 0.0
        : (detail.bookedCount / detail.capacity).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KinevorClassesBookingsTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KinevorClassesBookingsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.liveCapacity,
                      style: const TextStyle(
                        color: KinevorClassesBookingsTheme.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.seatsAndWaitlist,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Text(
                detail.isFull ? 'Full' : strings.spots(detail.availableSpots),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: detail.isFull
                      ? KinevorClassesBookingsTheme.warning
                      : KinevorClassesBookingsTheme.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _CapacityStat(
                  value: detail.bookedCount,
                  label: strings.confirmed,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _CapacityStat(
                  value: detail.capacity,
                  label: strings.capacity,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: _CapacityStat(
                  value: detail.waitListCount,
                  label: strings.waiting,
                  valueColor: KinevorClassesBookingsTheme.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: percentage,
              minHeight: 7,
              backgroundColor: KinevorClassesBookingsTheme.surface,
              valueColor: const AlwaysStoppedAnimation<Color>(
                KinevorClassesBookingsTheme.accent,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline,
                size: 14,
                color: KinevorClassesBookingsTheme.info,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  strings.policy,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.5,
                    color: KinevorClassesBookingsTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CapacityStat extends StatelessWidget {
  const _CapacityStat({
    required this.value,
    required this.label,
    this.valueColor,
  });

  final int value;
  final String label;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: KinevorClassesBookingsTheme.surface,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: valueColor ?? KinevorClassesBookingsTheme.text,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: KinevorClassesBookingsTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotesPanel extends StatelessWidget {
  const _NotesPanel({required this.notes, required this.strings});

  final String notes;
  final ClassesBookingsStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KinevorClassesBookingsTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KinevorClassesBookingsTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.beforeYouArrive,
            style: const TextStyle(
              color: KinevorClassesBookingsTheme.accent,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            strings.sessionNotes,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            notes,
            style: const TextStyle(
              fontSize: 12,
              height: 1.55,
              color: KinevorClassesBookingsTheme.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}

class _RosterPanel extends StatelessWidget {
  const _RosterPanel({required this.detail, required this.strings});

  final GymClassDetail detail;
  final ClassesBookingsStrings strings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: KinevorClassesBookingsTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KinevorClassesBookingsTheme.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.classRoster,
                      style: const TextStyle(
                        color: KinevorClassesBookingsTheme.accent,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      strings.whosComing,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: KinevorClassesBookingsTheme.border),
                ),
                child: Text(
                  strings.bookedCount(detail.roster.length),
                  style: const TextStyle(
                    fontSize: 9,
                    color: KinevorClassesBookingsTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (detail.roster.isEmpty)
            Row(
              children: [
                const Icon(
                  Icons.group_off_outlined,
                  size: 18,
                  color: KinevorClassesBookingsTheme.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    strings.rosterPrivate,
                    style: const TextStyle(
                      fontSize: 11,
                      color: KinevorClassesBookingsTheme.textMuted,
                    ),
                  ),
                ),
              ],
            )
          else
            for (var index = 0; index < detail.roster.length; index++)
              _RosterRow(booking: detail.roster[index], first: index == 0),
        ],
      ),
    );
  }
}

class _RosterRow extends StatelessWidget {
  const _RosterRow({required this.booking, required this.first});

  final ClassBooking booking;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final color = booking.isWaitListed
        ? KinevorClassesBookingsTheme.warning
        : KinevorClassesBookingsTheme.success;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: first
            ? null
            : const Border(
                top: BorderSide(color: KinevorClassesBookingsTheme.border),
              ),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: KinevorClassesBookingsTheme.surface,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              booking.initials,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: KinevorClassesBookingsTheme.textMuted,
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              booking.memberName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              booking.isWaitListed ? 'Waitlist' : booking.status,
              style: TextStyle(
                color: color,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBanner extends StatelessWidget {
  const _MessageBanner({
    required this.message,
    required this.isError,
    required this.dismissLabel,
    required this.onDismiss,
  });

  final String message;
  final bool isError;
  final String dismissLabel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final color = isError
        ? KinevorClassesBookingsTheme.error
        : KinevorClassesBookingsTheme.success;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(fontSize: 11, color: color)),
          ),
          TextButton(onPressed: onDismiss, child: Text(dismissLabel)),
        ],
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({
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
              style: const TextStyle(
                fontSize: 13,
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

String _initials(String name) {
  final parts = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty);
  if (parts.isEmpty) return '?';
  return parts.take(2).map((part) => part[0].toUpperCase()).join();
}
