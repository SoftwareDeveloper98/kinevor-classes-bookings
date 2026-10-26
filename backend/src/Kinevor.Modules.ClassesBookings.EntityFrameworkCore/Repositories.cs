using Kinevor.Modules.ClassesBookings.Domain;
using Kinevor.Platform.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Kinevor.Modules.ClassesBookings.EntityFrameworkCore;

internal sealed class GymClassRepository(ClassesBookingsDbContext db) : IGymClassRepository
{
    public Task<GymClass?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        db.Classes.FirstOrDefaultAsync(gymClass => gymClass.Id == id, ct);

    public async Task<(IReadOnlyList<GymClass> Items, int Total)> SearchAsync(
        ClassType? type,
        ClassStatus? status,
        DateTime? from,
        DateTime? to,
        int page,
        int pageSize,
        CancellationToken ct = default)
    {
        var query = db.Classes.AsNoTracking().AsQueryable();

        if (type is { } classType)
            query = query.Where(gymClass => gymClass.Type == classType);
        if (status is { } classStatus)
            query = query.Where(gymClass => gymClass.Status == classStatus);
        if (from is { } fromDate)
            query = query.Where(gymClass => gymClass.ScheduledAt >= fromDate);
        if (to is { } toDate)
            query = query.Where(gymClass => gymClass.ScheduledAt <= toDate);

        var total = await query.CountAsync(ct);
        var items = await query
            .OrderBy(gymClass => gymClass.ScheduledAt)
            .Skip((page - 1) * pageSize)
            .Take(pageSize)
            .ToListAsync(ct);

        return (items, total);
    }

    public async Task<IReadOnlyList<GymClass>> GetUpcomingAsync(DateTime now, int limit, CancellationToken ct = default) =>
        await db.Classes
            .AsNoTracking()
            .Where(gymClass => gymClass.Status == ClassStatus.Scheduled && gymClass.ScheduledAt > now)
            .OrderBy(gymClass => gymClass.ScheduledAt)
            .Take(limit)
            .ToListAsync(ct);

    public async Task AddAsync(GymClass gymClass, CancellationToken ct = default) =>
        await db.Classes.AddAsync(gymClass, ct);

    public void Update(GymClass gymClass) => db.Classes.Update(gymClass);
}

internal sealed class ClassBookingRepository(ClassesBookingsDbContext db) : IClassBookingRepository
{
    public Task<ClassBooking?> GetByIdAsync(Guid id, CancellationToken ct = default) =>
        db.Bookings.FirstOrDefaultAsync(booking => booking.Id == id, ct);

    public async Task<IReadOnlyList<ClassBooking>> GetByClassAsync(Guid classId, CancellationToken ct = default) =>
        await db.Bookings
            .AsNoTracking()
            .Where(booking => booking.ClassId == classId)
            .OrderBy(booking => booking.BookedAt)
            .ToListAsync(ct);

    public Task<ClassBooking?> GetActiveAsync(Guid memberId, Guid classId, CancellationToken ct = default) =>
        db.Bookings.FirstOrDefaultAsync(
            booking => booking.MemberId == memberId
                && booking.ClassId == classId
                && (booking.Status == BookingStatus.Confirmed || booking.Status == BookingStatus.WaitListed),
            ct);

    public Task<ClassBooking?> GetLatestAsync(Guid memberId, Guid classId, CancellationToken ct = default) =>
        db.Bookings
            .Where(booking => booking.MemberId == memberId && booking.ClassId == classId)
            .OrderByDescending(booking => booking.BookedAt)
            .FirstOrDefaultAsync(ct);

    public async Task<IReadOnlyList<ClassBooking>> GetByMemberAsync(
        Guid memberId,
        DateTime now,
        bool upcoming,
        CancellationToken ct = default)
    {
        var query = db.Bookings.AsNoTracking().Where(booking => booking.MemberId == memberId);

        query = upcoming
            ? query.Where(booking =>
                booking.ClassStartsAt >= now
                && (booking.Status == BookingStatus.Confirmed || booking.Status == BookingStatus.WaitListed))
            : query.Where(booking =>
                booking.ClassStartsAt < now
                || (booking.Status != BookingStatus.Confirmed && booking.Status != BookingStatus.WaitListed));

        return upcoming
            ? await query.OrderBy(booking => booking.ClassStartsAt).ToListAsync(ct)
            : await query.OrderByDescending(booking => booking.ClassStartsAt).ToListAsync(ct);
    }

    public Task<ClassBooking?> GetWaitListHeadAsync(Guid classId, CancellationToken ct = default) =>
        db.Bookings
            .Where(booking => booking.ClassId == classId && booking.Status == BookingStatus.WaitListed)
            .OrderBy(booking => booking.BookedAt)
            .FirstOrDefaultAsync(ct);

    public async Task AddAsync(ClassBooking booking, CancellationToken ct = default) =>
        await db.Bookings.AddAsync(booking, ct);

    public void Update(ClassBooking booking) => db.Bookings.Update(booking);
}
