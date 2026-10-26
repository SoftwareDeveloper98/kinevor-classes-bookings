# Kinevor.Modules.ClassesBookings.EntityFrameworkCore

EF Core persistence for the Kinevor classes and bookings module.

## Install

```powershell
dotnet add package Kinevor.Modules.ClassesBookings.EntityFrameworkCore --version 0.1.0
```

Register the context with your provider, then call
`AddClassesBookingsEntityFrameworkCore()`. The module owns the `GymClasses` and
`ClassBookings` tables and a filtered unique index that prevents a member from
holding two active bookings for the same class.
