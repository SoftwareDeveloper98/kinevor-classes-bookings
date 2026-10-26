using Kinevor.Modules.ClassesBookings.Domain;
using Kinevor.Platform.Application.Common;
using Kinevor.Platform.Application.Exceptions;
using Kinevor.Platform.Domain.Enums;
using MediatR;

namespace Kinevor.Modules.ClassesBookings.Application;

public record GetClassesQuery(
    string? Type,
    string? Status,
    DateTime? From,
    DateTime? To,
    int Page,
    int PageSize) : IRequest<PagedResult<ClassSummaryDto>>;

public class GetClassesHandler(IGymClassRepository classes, TimeProvider clock)
    : IRequestHandler<GetClassesQuery, PagedResult<ClassSummaryDto>>
{
    public async Task<PagedResult<ClassSummaryDto>> Handle(GetClassesQuery query, CancellationToken ct)
    {
        var page = Math.Max(1, query.Page);
        var pageSize = Math.Clamp(query.PageSize, 1, 100);
        var type = ParseType(query.Type);
        var status = ParseStatus(query.Status);
        var now = clock.GetUtcNow().UtcDateTime;

        var (items, total) = await classes.SearchAsync(
            type, status, query.From, query.To, page, pageSize, ct);

        return new PagedResult<ClassSummaryDto>(
            items.Select(item => ClassMapping.ToSummary(item, now)).ToList(),
            total,
            page,
            pageSize);
    }

    private static ClassType? ParseType(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return null;
        if (Enum.TryParse<ClassType>(value, true, out var type))
            return type;
        throw new DomainException($"Unknown class type '{value}'.");
    }

    private static ClassStatus? ParseStatus(string? value)
    {
        if (string.IsNullOrWhiteSpace(value))
            return null;
        if (Enum.TryParse<ClassStatus>(value, true, out var status))
            return status;
        throw new DomainException($"Unknown class status '{value}'.");
    }
}

public record GetClassCatalogueQuery : IRequest<IReadOnlyList<CatalogueItemDto>>;

public class GetClassCatalogueHandler(IGymClassRepository classes, TimeProvider clock)
    : IRequestHandler<GetClassCatalogueQuery, IReadOnlyList<CatalogueItemDto>>
{
    public async Task<IReadOnlyList<CatalogueItemDto>> Handle(GetClassCatalogueQuery query, CancellationToken ct)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var items = await classes.GetUpcomingAsync(now, 200, ct);
        return items
            .GroupBy(item => item.Type)
            .OrderBy(group => group.Key.ToString())
            .Select(group => new CatalogueItemDto(
                group.Key.ToString(),
                group.Count(),
                group.Min(item => item.ScheduledAt),
                group.OrderBy(item => item.ScheduledAt).First().Name))
            .ToList();
    }
}

public record GetClassDetailQuery(Guid Id) : IRequest<ClassDetailDto>;

public class GetClassDetailHandler(
    IGymClassRepository classes,
    IClassBookingRepository bookings,
    ICurrentUser currentUser,
    TimeProvider clock)
    : IRequestHandler<GetClassDetailQuery, ClassDetailDto>
{
    public async Task<ClassDetailDto> Handle(GetClassDetailQuery query, CancellationToken ct)
    {
        var gymClass = await classes.GetByIdAsync(query.Id, ct)
            ?? throw new NotFoundException("Class", query.Id);

        if (currentUser.IsTrainerOnly() && gymClass.TrainerId != currentUser.TrainerId)
            throw new ForbiddenException("Trainers may only view their own classes.");

        var now = clock.GetUtcNow().UtcDateTime;
        var canSeeRoster = currentUser.IsStaffOrAdmin() || currentUser.IsTrainerOnly();
        var roster = canSeeRoster
            ? (await bookings.GetByClassAsync(query.Id, ct))
                .Where(booking => booking.Status is not BookingStatus.Cancelled)
                .OrderBy(booking => booking.BookedAt)
                .Select(ClassMapping.ToDto)
                .ToList()
            : [];

        var myBooking = currentUser.MemberId is { } memberId
            ? await bookings.GetActiveAsync(memberId, query.Id, ct)
            : null;

        return new ClassDetailDto(
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
            gymClass.Notes,
            gymClass.RequiresMembership,
            gymClass.IsFull,
            gymClass.IsOpenAt(now),
            roster,
            myBooking is null ? null : ClassMapping.ToDto(myBooking));
    }
}

public record GetMyBookingsQuery(Guid MemberId, string? Scope) : IRequest<IReadOnlyList<MyBookingDto>>;

public class GetMyBookingsHandler(
    IClassBookingRepository bookings,
    IGymClassRepository classes,
    TimeProvider clock)
    : IRequestHandler<GetMyBookingsQuery, IReadOnlyList<MyBookingDto>>
{
    public async Task<IReadOnlyList<MyBookingDto>> Handle(GetMyBookingsQuery query, CancellationToken ct)
    {
        var now = clock.GetUtcNow().UtcDateTime;
        var upcoming = !string.Equals(query.Scope, "past", StringComparison.OrdinalIgnoreCase);
        var items = await bookings.GetByMemberAsync(query.MemberId, now, upcoming, ct);

        var results = new List<MyBookingDto>(items.Count);
        foreach (var booking in items)
        {
            var gymClass = await classes.GetByIdAsync(booking.ClassId, ct);
            if (gymClass is not null)
                results.Add(ClassMapping.ToMyBooking(booking, gymClass, now));
        }

        return results;
    }
}
