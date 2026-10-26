using Kinevor.Platform.Domain.Common;

namespace Kinevor.Modules.ClassesBookings.Domain;

public sealed class ClassBooking : AggregateRoot
{
    public Guid ClassId { get; private set; }

    public Guid MemberId { get; private set; }

    public string MemberName { get; private set; } = string.Empty;

    public string ClassName { get; private set; } = string.Empty;

    public DateTime ClassStartsAt { get; private set; }

    public BookingStatus Status { get; private set; } = BookingStatus.Confirmed;

    public bool IsWaitListed { get; private set; }

    public DateTime BookedAt { get; private set; }

    public DateTime? CancelledAt { get; private set; }

    public string? CancellationReason { get; private set; }

    public DateTime? CheckedInAt { get; private set; }

    public Guid? BranchId { get; private set; }

    private ClassBooking()
    {
    }

    public static ClassBooking Create(
        Guid classId,
        string className,
        DateTime classStartsAt,
        Guid memberId,
        string memberName,
        bool isWaitListed,
        DateTime now)
    {
        return new ClassBooking
        {
            ClassId = classId,
            ClassName = className,
            ClassStartsAt = classStartsAt,
            MemberId = memberId,
            MemberName = memberName.Trim(),
            IsWaitListed = isWaitListed,
            Status = isWaitListed ? BookingStatus.WaitListed : BookingStatus.Confirmed,
            BookedAt = now,
        };
    }

    public Result Cancel(DateTime now, string? reason)
    {
        if (Status == BookingStatus.Cancelled)
            return Result.Failure(Error.Business("Booking.AlreadyCancelled", "Booking is already cancelled."));
        if (Status is BookingStatus.Attended or BookingStatus.NoShow)
            return Result.Failure(Error.Business("Booking.Closed", "Attendance has already been recorded."));

        Status = BookingStatus.Cancelled;
        CancelledAt = now;
        CancellationReason = string.IsNullOrWhiteSpace(reason) ? null : reason.Trim();
        return Result.Success();
    }

    public void PromoteFromWaitList()
    {
        IsWaitListed = false;
        Status = BookingStatus.Confirmed;
    }

    public Result MarkAttended(DateTime now)
    {
        if (Status != BookingStatus.Confirmed)
            return Result.Failure(Error.Business("Booking.NotConfirmed", "Only confirmed bookings can be checked in."));

        Status = BookingStatus.Attended;
        CheckedInAt = now;
        return Result.Success();
    }

    public Result MarkNoShow()
    {
        if (Status != BookingStatus.Confirmed)
            return Result.Failure(Error.Business("Booking.NotConfirmed", "Only confirmed bookings can be marked as a no-show."));

        Status = BookingStatus.NoShow;
        return Result.Success();
    }

    public void AssignBranch(Guid branchId) => BranchId = branchId;
}
