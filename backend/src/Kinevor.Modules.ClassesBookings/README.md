# Kinevor.Modules.ClassesBookings

Class scheduling, capacity, booking and waitlist module for the Kinevor gym platform.

## Install

```powershell
dotnet add package Kinevor.Modules.ClassesBookings --version 0.1.0
```

## What it provides

- `GymClass` aggregate with trainer, room, start and end time, capacity, booking
  counters, waitlist and cancellation lifecycle.
- `ClassBooking` records for confirmed seats, waitlists, attendance and no-shows.
- Staff scheduling, updating, cancellation and roster endpoints under
  `api/v1/classes`.
- Member booking, waitlist, cancellation and upcoming/past booking endpoints.
- MediatR handlers and platform response envelopes.

Register the module with `AddClassesBookingsModule()` and the EF Core persistence
with `AddClassesBookingsEntityFrameworkCore()`. The host supplies `ICurrentUser`
and `IBranchContext`. Member and trainer ids are external references; this module
never accesses another module's database.
