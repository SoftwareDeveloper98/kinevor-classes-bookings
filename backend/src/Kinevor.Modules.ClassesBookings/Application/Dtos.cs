using Kinevor.Modules.ClassesBookings.Domain;

namespace Kinevor.Modules.ClassesBookings.Application;

public record ClassSummaryDto(
    Guid Id,
    string Name,
    string? Description,
    string Type,
    Guid TrainerId,
    string TrainerName,
    DateTime StartsAt,
    DateTime EndsAt,
    int DurationMinutes,
    int Capacity,
    int BookedCount,
    int AvailableSpots,
    int WaitListCount,
    string Status,
    string Room,
    bool RequiresMembership,
    bool IsFull,
    bool IsOpenForBooking);

public record BookingDto(
    Guid Id,
    Guid ClassId,
    string ClassName,
    DateTime ClassStartsAt,
    Guid MemberId,
    string MemberName,
    string Status,
    bool IsWaitListed,
    DateTime BookedAt,
    DateTime? CancelledAt,
    string? CancellationReason,
    DateTime? CheckedInAt);

public record ClassDetailDto(
    Guid Id,
    string Name,
    string? Description,
    string Type,
    Guid TrainerId,
    string TrainerName,
    DateTime StartsAt,
    DateTime EndsAt,
    int DurationMinutes,
    int Capacity,
    int BookedCount,
    int AvailableSpots,
    int WaitListCount,
    string Status,
    string Room,
    string? Notes,
    bool RequiresMembership,
    bool IsFull,
    bool IsOpenForBooking,
    IReadOnlyList<BookingDto> Roster,
    BookingDto? MyBooking);

public record CatalogueItemDto(
    string Type,
    int UpcomingSessions,
    DateTime? NextStartsAt,
    string? NextClassName);

public record BookClassResultDto(
    Guid BookingId,
    bool IsWaitListed,
    string Status,
    int AvailableSpots,
    int WaitListPosition);

public record MyBookingDto(
    Guid Id,
    Guid ClassId,
    string ClassName,
    string ClassType,
    string TrainerName,
    string Room,
    DateTime StartsAt,
    DateTime EndsAt,
    string BookingStatus,
    string ClassStatus,
    bool IsWaitListed,
    bool CanCancel,
    DateTime? CheckedInAt);

public class ScheduleClassRequest
{
    public string Name { get; set; } = string.Empty;

    public string? Description { get; set; }

    public string Type { get; set; } = string.Empty;

    public Guid TrainerId { get; set; }

    public string TrainerName { get; set; } = string.Empty;

    public DateTime StartsAt { get; set; }

    public int DurationMinutes { get; set; } = 60;

    public int Capacity { get; set; } = 20;

    public string Room { get; set; } = string.Empty;

    public string? Notes { get; set; }

    public bool RequiresMembership { get; set; } = true;
}

public class BookClassRequest
{
    public Guid? MemberId { get; set; }

    public string? MemberName { get; set; }
}

public class CancelBookingRequest
{
    public string? Reason { get; set; }
}

public class CancelClassRequest
{
    public string? Reason { get; set; }
}

public class AttendanceRequest
{
    public bool Attended { get; set; } = true;
}

internal static class ClassMapping
{
    internal static ClassSummaryDto ToSummary(GymClass gymClass, DateTime now) =>
        new(
            gymClass.Id,
            gymClass.Name,
            gymClass.Description,
            gymClass.Type.ToString(),
            gymClass.TrainerId,
            gymClass.TrainerName,
            gymClass.ScheduledAt,
            gymClass.EndsAt,
            gymClass.DurationMinutes,
            gymClass.Capacity,
            gymClass.BookedCount,
            gymClass.AvailableSpots,
            gymClass.WaitListCount,
            gymClass.Status.ToString(),
            gymClass.Room,
            gymClass.RequiresMembership,
            gymClass.IsFull,
            gymClass.IsOpenAt(now));

    internal static BookingDto ToDto(ClassBooking booking) =>
        new(
            booking.Id,
            booking.ClassId,
            booking.ClassName,
            booking.ClassStartsAt,
            booking.MemberId,
            booking.MemberName,
            booking.Status.ToString(),
            booking.IsWaitListed,
            booking.BookedAt,
            booking.CancelledAt,
            booking.CancellationReason,
            booking.CheckedInAt);

    internal static MyBookingDto ToMyBooking(ClassBooking booking, GymClass gymClass, DateTime now) =>
        new(
            booking.Id,
            booking.ClassId,
            gymClass.Name,
            gymClass.Type.ToString(),
            gymClass.TrainerName,
            gymClass.Room,
            gymClass.ScheduledAt,
            gymClass.EndsAt,
            booking.Status.ToString(),
            gymClass.Status.ToString(),
            booking.IsWaitListed,
            booking.Status is BookingStatus.Confirmed or BookingStatus.WaitListed
                && gymClass.IsOpenAt(now)
                && (gymClass.ScheduledAt - now).TotalHours >= 2,
            booking.CheckedInAt);
}
