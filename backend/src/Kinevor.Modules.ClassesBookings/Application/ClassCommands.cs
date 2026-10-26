using Kinevor.Modules.ClassesBookings.Domain;
using Kinevor.Platform.Application.Common;
using Kinevor.Platform.Application.Exceptions;
using Kinevor.Platform.Domain.Common;
using Kinevor.Platform.Domain.Enums;
using MediatR;

namespace Kinevor.Modules.ClassesBookings.Application;

public record ScheduleClassCommand(ScheduleClassRequest Request) : ICommand<Guid>;

public class ScheduleClassHandler(
    IGymClassRepository classes,
    IClassesBookingsUnitOfWork unitOfWork,
    IBranchContext branchContext,
    ICurrentUser currentUser,
    TimeProvider clock)
    : IRequestHandler<ScheduleClassCommand, Guid>
{
    public async Task<Guid> Handle(ScheduleClassCommand command, CancellationToken ct)
    {
        if (!Enum.TryParse<ClassType>(command.Request.Type, true, out var type))
            throw new DomainException($"Unknown class type '{command.Request.Type}'.");

        if (currentUser.IsTrainerOnly() && currentUser.TrainerId != command.Request.TrainerId)
            throw new ForbiddenException("Trainers may only schedule their own classes.");

        var now = clock.GetUtcNow().UtcDateTime;
        var result = GymClass.Create(
            now,
            command.Request.Name,
            command.Request.Description,
            type,
            command.Request.TrainerId,
            command.Request.TrainerName,
            command.Request.StartsAt,
            command.Request.DurationMinutes,
            command.Request.Capacity,
            command.Request.Room,
            command.Request.Notes,
            command.Request.RequiresMembership);

        if (result.IsFailure)
            throw new DomainException(result.Error.Message);

        if (branchContext.BranchId is { } branchId)
            result.Value.AssignBranch(branchId);

        await classes.AddAsync(result.Value, ct);
        await unitOfWork.SaveChangesAsync(ct);
        return result.Value.Id;
    }
}

public record UpdateClassCommand(Guid Id, ScheduleClassRequest Request) : ICommand;

public class UpdateClassHandler(
    IGymClassRepository classes,
    IClassesBookingsUnitOfWork unitOfWork,
    ICurrentUser currentUser,
    TimeProvider clock)
    : IRequestHandler<UpdateClassCommand>
{
    public async Task Handle(UpdateClassCommand command, CancellationToken ct)
    {
        if (!Enum.TryParse<ClassType>(command.Request.Type, true, out var type))
            throw new DomainException($"Unknown class type '{command.Request.Type}'.");

        var gymClass = await classes.GetByIdAsync(command.Id, ct)
            ?? throw new NotFoundException("Class", command.Id);

        if (currentUser.IsTrainerOnly() && gymClass.TrainerId != currentUser.TrainerId)
            throw new ForbiddenException("Trainers may only edit their own classes.");

        var now = clock.GetUtcNow().UtcDateTime;
        var result = gymClass.Update(
            now,
            command.Request.Name,
            command.Request.Description,
            type,
            command.Request.TrainerId,
            command.Request.TrainerName,
            command.Request.StartsAt,
            command.Request.DurationMinutes,
            command.Request.Capacity,
            command.Request.Room,
            command.Request.Notes,
            command.Request.RequiresMembership);

        if (result.IsFailure)
            throw new DomainException(result.Error.Message);

        classes.Update(gymClass);
        if (!await unitOfWork.TrySaveChangesAsync(ct))
            throw new ConflictException("The class was updated by another request. Refresh and try again.");
    }
}

public record CancelClassCommand(Guid Id, string? Reason) : ICommand;

public class CancelClassHandler(
    IGymClassRepository classes,
    IClassBookingRepository bookings,
    IClassesBookingsUnitOfWork unitOfWork,
    ICurrentUser currentUser,
    TimeProvider clock)
    : IRequestHandler<CancelClassCommand>
{
    public async Task Handle(CancelClassCommand command, CancellationToken ct)
    {
        var gymClass = await classes.GetByIdAsync(command.Id, ct)
            ?? throw new NotFoundException("Class", command.Id);

        if (currentUser.IsTrainerOnly() && gymClass.TrainerId != currentUser.TrainerId)
            throw new ForbiddenException("Trainers may only cancel their own classes.");

        var now = clock.GetUtcNow().UtcDateTime;
        var result = gymClass.Cancel(now, command.Reason);
        if (result.IsFailure)
            throw new DomainException(result.Error.Message);

        foreach (var booking in await bookings.GetByClassAsync(command.Id, ct))
        {
            if (booking.Status is BookingStatus.Confirmed or BookingStatus.WaitListed)
            {
                booking.Cancel(now, string.IsNullOrWhiteSpace(command.Reason) ? "Class cancelled." : command.Reason);
                bookings.Update(booking);
            }
        }

        classes.Update(gymClass);
        await unitOfWork.SaveChangesAsync(ct);
    }
}

public record BookClassCommand(Guid ClassId, Guid? MemberId, string? MemberName) : ICommand<BookClassResultDto>;

public class BookClassHandler(
    IGymClassRepository classes,
    IClassBookingRepository bookings,
    IClassesBookingsUnitOfWork unitOfWork,
    IBranchContext branchContext,
    ICurrentUser currentUser,
    TimeProvider clock)
    : IRequestHandler<BookClassCommand, BookClassResultDto>
{
    public async Task<BookClassResultDto> Handle(BookClassCommand command, CancellationToken ct)
    {
        var memberId = ResolveMemberId(command);
        var now = clock.GetUtcNow().UtcDateTime;
        var gymClass = await classes.GetByIdAsync(command.ClassId, ct)
            ?? throw new NotFoundException("Class", command.ClassId);

        if (!gymClass.IsOpenAt(now))
            throw new DomainException("Class is not available for booking.");

        var existing = await bookings.GetActiveAsync(memberId, command.ClassId, ct);
        if (existing is not null)
            throw new ConflictException("Member is already booked or waitlisted for this class.");

        var bookResult = gymClass.Book(now, memberId);
        if (bookResult.IsFailure)
            throw new DomainException(bookResult.Error.Message);

        var memberName = string.IsNullOrWhiteSpace(command.MemberName)
            ? currentUser.Email ?? "Kinevor member"
            : command.MemberName.Trim();

        var booking = ClassBooking.Create(
            gymClass.Id,
            gymClass.Name,
            gymClass.ScheduledAt,
            memberId,
            memberName,
            bookResult.Value,
            now);

        if (branchContext.BranchId is { } branchId)
            booking.AssignBranch(branchId);

        await bookings.AddAsync(booking, ct);
        classes.Update(gymClass);

        if (!await unitOfWork.TrySaveChangesAsync(ct))
            throw new ConflictException("The class changed while booking. Refresh and try again.");

        return new BookClassResultDto(
            booking.Id,
            booking.IsWaitListed,
            booking.Status.ToString(),
            gymClass.AvailableSpots,
            booking.IsWaitListed ? gymClass.WaitListCount : 0);
    }

    private Guid ResolveMemberId(BookClassCommand command)
    {
        if (currentUser.IsStaffOrAdmin())
        {
            if (command.MemberId is { } requested && requested != Guid.Empty)
                return requested;
            if (currentUser.MemberId is { } linked)
                return linked;
            throw new DomainException("Booking on behalf of a member requires the member id.");
        }

        var self = currentUser.MemberId
            ?? throw new ForbiddenException("No linked member profile.");

        if (command.MemberId is { } memberId && memberId != Guid.Empty && memberId != self)
            throw new ForbiddenException("Members may only book classes for themselves.");

        return self;
    }
}

public record CancelBookingCommand(Guid BookingId, string? Reason) : ICommand;

public class CancelBookingHandler(
    IClassBookingRepository bookings,
    IGymClassRepository classes,
    IClassesBookingsUnitOfWork unitOfWork,
    ICurrentUser currentUser,
    TimeProvider clock)
    : IRequestHandler<CancelBookingCommand>
{
    public async Task Handle(CancelBookingCommand command, CancellationToken ct)
    {
        var booking = await bookings.GetByIdAsync(command.BookingId, ct)
            ?? throw new NotFoundException("Booking", command.BookingId);

        var gymClass = await classes.GetByIdAsync(booking.ClassId, ct);
        EnsureMayCancel(booking, gymClass);

        var now = clock.GetUtcNow().UtcDateTime;
        if (!currentUser.IsStaffOrAdmin()
            && !booking.IsWaitListed
            && booking.Status == BookingStatus.Confirmed
            && booking.ClassStartsAt - now <= TimeSpan.FromHours(2))
        {
            throw new DomainException("Confirmed bookings cannot be cancelled within two hours of the class.");
        }

        var cancelResult = booking.Cancel(now, command.Reason);
        if (cancelResult.IsFailure)
            throw new DomainException(cancelResult.Error.Message);

        bookings.Update(booking);

        if (gymClass is not null)
        {
            gymClass.CancelBooking(booking.IsWaitListed);
            if (!booking.IsWaitListed && gymClass.Status == ClassStatus.Scheduled)
            {
                var promoted = await bookings.GetWaitListHeadAsync(gymClass.Id, ct);
                if (promoted is not null && gymClass.PromoteFromWaitList().IsSuccess)
                {
                    promoted.PromoteFromWaitList();
                    bookings.Update(promoted);
                }
            }

            classes.Update(gymClass);
        }

        await unitOfWork.SaveChangesAsync(ct);
    }

    private void EnsureMayCancel(ClassBooking booking, GymClass? gymClass)
    {
        if (currentUser.IsStaffOrAdmin())
            return;
        if (currentUser.MemberId is { } memberId && memberId == booking.MemberId)
            return;
        if (currentUser.IsTrainerOnly()
            && gymClass is not null
            && gymClass.TrainerId == currentUser.TrainerId)
            return;
        throw new ForbiddenException("Booking does not belong to the current member.");
    }
}

public record PromoteWaitListCommand(Guid BookingId) : ICommand;

public class PromoteWaitListHandler(
    IClassBookingRepository bookings,
    IGymClassRepository classes,
    IClassesBookingsUnitOfWork unitOfWork,
    ICurrentUser currentUser)
    : IRequestHandler<PromoteWaitListCommand>
{
    public async Task Handle(PromoteWaitListCommand command, CancellationToken ct)
    {
        var booking = await bookings.GetByIdAsync(command.BookingId, ct)
            ?? throw new NotFoundException("Booking", command.BookingId);
        var gymClass = await classes.GetByIdAsync(booking.ClassId, ct)
            ?? throw new NotFoundException("Class", booking.ClassId);

        if (currentUser.IsTrainerOnly() && gymClass.TrainerId != currentUser.TrainerId)
            throw new ForbiddenException("Trainers may only manage their own classes.");

        if (booking.Status != BookingStatus.WaitListed)
            throw new DomainException("Only waitlisted bookings can be promoted.");

        var result = gymClass.PromoteFromWaitList();
        if (result.IsFailure)
            throw new DomainException(result.Error.Message);

        booking.PromoteFromWaitList();
        bookings.Update(booking);
        classes.Update(gymClass);
        await unitOfWork.SaveChangesAsync(ct);
    }
}

public record MarkAttendanceCommand(Guid BookingId, bool Attended) : ICommand;

public class MarkAttendanceHandler(
    IClassBookingRepository bookings,
    IGymClassRepository classes,
    IClassesBookingsUnitOfWork unitOfWork,
    ICurrentUser currentUser,
    TimeProvider clock)
    : IRequestHandler<MarkAttendanceCommand>
{
    public async Task Handle(MarkAttendanceCommand command, CancellationToken ct)
    {
        var booking = await bookings.GetByIdAsync(command.BookingId, ct)
            ?? throw new NotFoundException("Booking", command.BookingId);
        var gymClass = await classes.GetByIdAsync(booking.ClassId, ct)
            ?? throw new NotFoundException("Class", booking.ClassId);

        if (currentUser.IsTrainerOnly() && gymClass.TrainerId != currentUser.TrainerId)
            throw new ForbiddenException("Trainers may only manage their own classes.");

        var result = command.Attended
            ? booking.MarkAttended(clock.GetUtcNow().UtcDateTime)
            : booking.MarkNoShow();

        if (result.IsFailure)
            throw new DomainException(result.Error.Message);

        bookings.Update(booking);
        await unitOfWork.SaveChangesAsync(ct);
    }
}
