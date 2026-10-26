namespace Kinevor.Modules.ClassesBookings.Domain;

public enum ClassStatus
{
    Scheduled,
    InProgress,
    Completed,
    Cancelled,
}

public enum BookingStatus
{
    Confirmed,
    Cancelled,
    Attended,
    NoShow,
    WaitListed,
}
