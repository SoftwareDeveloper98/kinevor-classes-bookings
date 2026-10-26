using Xunit;
using Kinevor.Modules.ClassesBookings.Domain;
using Kinevor.Platform.Domain.Common;
using Kinevor.Platform.Domain.Enums;

namespace Kinevor.Modules.ClassesBookings.Tests;

public class DomainTests
{
    private static readonly DateTime Now = new(2026, 10, 20, 12, 0, 0, DateTimeKind.Utc);
    private static readonly Guid TrainerId = Guid.Parse("a1111111-1111-1111-1111-111111111111");
    private static readonly Guid MemberId = Guid.Parse("11111111-1111-1111-1111-111111111111");

    [Fact]
    public void Create_RejectsPastClasses()
    {
        var result = NewClass(Now.AddMinutes(-1), 10);

        Assert.True(result.IsFailure);
        Assert.Equal("Class.PastDate", result.Error.Code);
    }

    [Fact]
    public void Create_RequiresCapacityWithinRange()
    {
        var result = NewClass(Now.AddHours(2), 0);

        Assert.True(result.IsFailure);
        Assert.Equal("Validation.Capacity", result.Error.Code);
    }

    [Fact]
    public void Booking_FillsSeatsThenUsesWaitList()
    {
        var gymClass = Require(NewClass(Now.AddHours(2), 2));

        Assert.False(gymClass.Book(Now, MemberId).Value);
        Assert.False(gymClass.Book(Now, Guid.NewGuid()).Value);
        Assert.True(gymClass.IsFull);

        var waitListed = gymClass.Book(Now, Guid.NewGuid());

        Assert.True(waitListed.IsSuccess);
        Assert.True(waitListed.Value);
        Assert.Equal(2, gymClass.BookedCount);
        Assert.Equal(1, gymClass.WaitListCount);
    }

    [Fact]
    public void Promote_WaitListedMemberTakesFreedSeat()
    {
        var gymClass = Require(NewClass(Now.AddHours(2), 1));
        gymClass.Book(Now, MemberId);

        Assert.True(gymClass.Book(Now, Guid.NewGuid()).Value);
        Assert.True(gymClass.CancelBooking(false).IsSuccess);
        Assert.False(gymClass.IsFull);
        Assert.True(gymClass.PromoteFromWaitList().IsSuccess);
        Assert.Equal(1, gymClass.BookedCount);
        Assert.Equal(0, gymClass.WaitListCount);
    }

    [Fact]
    public void Update_CannotReduceCapacityBelowConfirmedBookings()
    {
        var gymClass = Require(NewClass(Now.AddHours(2), 4));
        gymClass.Book(Now, MemberId);
        gymClass.Book(Now, Guid.NewGuid());
        gymClass.Book(Now, Guid.NewGuid());

        var result = gymClass.Update(
            Now, gymClass.Name, gymClass.Description, gymClass.Type, gymClass.TrainerId,
            gymClass.TrainerName, gymClass.ScheduledAt, gymClass.DurationMinutes, 2,
            gymClass.Room, gymClass.Notes, gymClass.RequiresMembership);

        Assert.True(result.IsFailure);
        Assert.Equal("Class.CapacityBelowBookings", result.Error.Code);
    }

    [Fact]
    public void Cancel_ClassesAreTerminal()
    {
        var gymClass = Require(NewClass(Now.AddHours(2), 4));

        Assert.True(gymClass.Cancel(Now, "Trainer unavailable").IsSuccess);
        Assert.Equal(ClassStatus.Cancelled, gymClass.Status);
        Assert.Equal("Trainer unavailable", gymClass.CancellationReason);
        Assert.True(gymClass.Cancel(Now, "Again").IsFailure);
        Assert.True(gymClass.Book(Now, MemberId).IsFailure);
    }

    [Fact]
    public void Booking_CancelAndAttendanceFollowLifecycle()
    {
        var booking = ClassBooking.Create(
            Guid.NewGuid(), "Sunrise Yoga", Now.AddHours(4), MemberId, "Maya Thompson", false, Now);

        Assert.Equal(BookingStatus.Confirmed, booking.Status);
        Assert.True(booking.MarkAttended(Now.AddHours(4)).IsSuccess);
        Assert.Equal(BookingStatus.Attended, booking.Status);
        Assert.True(booking.Cancel(Now.AddHours(5), null).IsFailure);
    }

    private static Result<GymClass> NewClass(DateTime scheduledAt, int capacity) =>
        GymClass.Create(
            Now,
            "Sunrise Yoga",
            "A gentle flow.",
            ClassType.Yoga,
            TrainerId,
            "Amara Okafor",
            scheduledAt,
            60,
            capacity,
            "Studio One",
            null,
            true);

    private static GymClass Require(Result<GymClass> result)
    {
        Assert.True(result.IsSuccess);
        return result.Value;
    }
}
