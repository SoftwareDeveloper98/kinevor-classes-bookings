# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.1.0] - 2026-10-21

### Added

- Standalone classes and bookings backend with the `GymClass` and `ClassBooking`
  aggregates, capacity and waitlist lifecycle, MediatR commands and queries,
  EF Core persistence, SQLite demo host and platform authorization policies.
- Upcoming schedule, class catalogue and detail endpoints with type/status/date
  filters, live capacity, trainer, room, notes and role-aware roster visibility.
- Booking, waitlist join, cancellation with a two-hour member cutoff, automatic
  waitlist promotion, trainer promotion and attendance recording.
- Member upcoming and past bookings over `/api/v1/me/bookings`.
- Angular library with schedule, class detail and member bookings components,
  typed HTTP gateway, facades, providers and routes.
- Angular demo application with the Kinevor visual system, Sora typography and
  Material icons on port `4204`.
- Flutter package with API client, repository, schedule, detail and member
  bookings screens, theme and strings.
- Flutter example application for Windows and web.
- Real web, mobile and Swagger screenshots under `docs/screenshots`.
- NuGet packing, GitHub Actions CI and tag-based release workflows.
- MIT license and package documentation.
