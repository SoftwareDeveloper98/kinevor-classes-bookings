import 'package:flutter/material.dart';

import '../data/classes_bookings_api_exception.dart';
import '../data/classes_bookings_repository.dart';
import '../models/gym_class.dart';
import '../theme/classes_bookings_strings.dart';
import '../theme/kinevor_classes_bookings_theme.dart';
import 'class_detail_screen.dart';

/// The member's confirmed seats, waitlists and past sessions.
class MemberBookingsScreen extends StatefulWidget {
  /// Creates the member bookings screen.
  const MemberBookingsScreen({
    super.key,
    required this.repository,
    this.strings = const ClassesBookingsStrings(),
  });

  /// Data source used for bookings and cancellations.
  final ClassesBookingsRepository repository;

  /// Localized labels.
  final ClassesBookingsStrings strings;

  @override
  State<MemberBookingsScreen> createState() => _MemberBookingsScreenState();
}

class _MemberBookingsScreenState extends State<MemberBookingsScreen> {
  List<MyBooking> _bookings = const [];
  bool _loading = true;
  bool _busy = false;
  String _scope = 'upcoming';
  String? _error;

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
      final bookings = await widget.repository.getMyBookings(scope: _scope);
      if (!mounted) return;
      setState(() {
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

  Future<void> _show(String scope) async {
    if (_scope == scope) return;
    setState(() {
      _scope = scope;
      _bookings = const [];
    });
    await _load();
  }

  Future<void> _openClass(MyBooking booking) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ClassDetailScreen(
          repository: widget.repository,
          classId: booking.classId,
          strings: widget.strings,
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _cancel(MyBooking booking) async {
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
              ? widget.strings.waitNote
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
                  : widget.strings.cancel,
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _busy = true);
    try {
      await widget.repository.cancelBooking(
        booking.id,
        reason: 'Cancelled by member',
      );
      await _load();
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage(
        booking.isWaitListed
            ? widget.strings.waitlistLeft
            : widget.strings.bookingCancelled,
      );
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _busy = false);
      _showMessage(_clean(error));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final strings = widget.strings;
    return Scaffold(
      appBar: AppBar(
        title: Text(strings.bookingsTitle),
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
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_error != null)
              _BookingsError(
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
                    Text(
                      strings.bookingsEyebrow,
                      style: const TextStyle(
                        color: KinevorClassesBookingsTheme.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.bookingsSubtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.55,
                        color: KinevorClassesBookingsTheme.textMuted,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: _ScopeTab(
                            label: strings.upcoming,
                            selected: _scope == 'upcoming',
                            onTap: () => _show('upcoming'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _ScopeTab(
                            label: strings.pastSessions,
                            selected: _scope == 'past',
                            onTap: () => _show('past'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_bookings.isEmpty)
                      _EmptyBookings(
                        strings: strings,
                        upcoming: _scope == 'upcoming',
                        onBrowse: () {
                          if (Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      )
                    else
                      for (final booking in _bookings)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BookingCard(
                            booking: booking,
                            strings: strings,
                            busy: _busy,
                            onView: () => _openClass(booking),
                            onCancel: () => _cancel(booking),
                          ),
                        ),
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

class _ScopeTab extends StatelessWidget {
  const _ScopeTab({
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
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected
                  ? KinevorClassesBookingsTheme.accent
                  : KinevorClassesBookingsTheme.border,
            ),
          ),
          alignment: Alignment.center,
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

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.strings,
    required this.busy,
    required this.onView,
    required this.onCancel,
  });

  final MyBooking booking;
  final ClassesBookingsStrings strings;
  final bool busy;
  final VoidCallback onView;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final color = KinevorClassesBookingsTheme.classColor(booking.classType);
    final status = strings.bookingLabel(
      bookingStatus: booking.bookingStatus,
      classStatus: booking.classStatus,
      isWaitListed: booking.isWaitListed,
    );
    final statusColor = booking.isWaitListed
        ? KinevorClassesBookingsTheme.warning
        : KinevorClassesBookingsTheme.statusColor(status);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: KinevorClassesBookingsTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KinevorClassesBookingsTheme.border),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 54,
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: KinevorClassesBookingsTheme.surface,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(
                              color: KinevorClassesBookingsTheme.border,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                strings.weekday(booking.startsAt),
                                style: const TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                  color: KinevorClassesBookingsTheme.textMuted,
                                ),
                              ),
                              Text(
                                strings.day(booking.startsAt),
                                style: const TextStyle(
                                  fontSize: 22,
                                  height: 1.2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                strings.month(booking.startsAt),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: color.withValues(alpha: 0.16),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      strings
                                          .typeLabel(booking.classType)
                                          .toUpperCase(),
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: statusColor.withValues(
                                        alpha: 0.14,
                                      ),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.6,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                booking.className,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.titleLarge
                                    ?.copyWith(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: 3),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  _BookingMeta(
                                    icon: Icons.schedule,
                                    label: strings.timeRange(
                                      booking.startsAt,
                                      booking.endsAt,
                                    ),
                                  ),
                                  _BookingMeta(
                                    icon: Icons.person_outline,
                                    label: booking.trainerName,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              _BookingMeta(
                                icon: Icons.meeting_room_outlined,
                                label: booking.room,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (booking.isWaitListed) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.hourglass_top,
                            size: 14,
                            color: KinevorClassesBookingsTheme.warning,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              strings.waitNote,
                              style: const TextStyle(
                                fontSize: 10,
                                height: 1.45,
                                color: KinevorClassesBookingsTheme.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onView,
                            child: Text(strings.viewClass),
                          ),
                        ),
                        if (booking.canCancel) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextButton(
                              onPressed: busy ? null : onCancel,
                              style: TextButton.styleFrom(
                                foregroundColor:
                                    KinevorClassesBookingsTheme.error,
                                minimumSize: const Size.fromHeight(46),
                              ),
                              child: Text(
                                booking.isWaitListed
                                    ? strings.leaveWaitlist
                                    : strings.cancel,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingMeta extends StatelessWidget {
  const _BookingMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: KinevorClassesBookingsTheme.textMuted),
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

class _EmptyBookings extends StatelessWidget {
  const _EmptyBookings({
    required this.strings,
    required this.upcoming,
    required this.onBrowse,
  });

  final ClassesBookingsStrings strings;
  final bool upcoming;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: KinevorClassesBookingsTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: KinevorClassesBookingsTheme.border),
      ),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: KinevorClassesBookingsTheme.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              upcoming ? Icons.event_available : Icons.history,
              color: KinevorClassesBookingsTheme.accent,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            upcoming ? strings.noBookings : strings.noPast,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 5),
          Text(
            upcoming ? strings.noBookingsBody : strings.noPastBody,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: KinevorClassesBookingsTheme.textMuted,
            ),
          ),
          if (upcoming) ...[
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onBrowse,
              child: Text(strings.browseClasses),
            ),
          ],
        ],
      ),
    );
  }
}

class _BookingsError extends StatelessWidget {
  const _BookingsError({
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
