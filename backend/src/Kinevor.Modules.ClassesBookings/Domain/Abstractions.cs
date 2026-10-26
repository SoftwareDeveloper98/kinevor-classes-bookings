using Kinevor.Platform.Domain.Enums;

namespace Kinevor.Modules.ClassesBookings.Domain;

public interface IGymClassRepository
{
    Task<GymClass?> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<(IReadOnlyList<GymClass> Items, int Total)> SearchAsync(
        ClassType? type,
        ClassStatus? status,
        DateTime? from,
        DateTime? to,
        int page,
        int pageSize,
        CancellationToken ct = default);

    Task<IReadOnlyList<GymClass>> GetUpcomingAsync(DateTime now, int limit, CancellationToken ct = default);

    Task AddAsync(GymClass gymClass, CancellationToken ct = default);

    void Update(GymClass gymClass);
}

public interface IClassBookingRepository
{
    Task<ClassBooking?> GetByIdAsync(Guid id, CancellationToken ct = default);

    Task<IReadOnlyList<ClassBooking>> GetByClassAsync(Guid classId, CancellationToken ct = default);

    Task<ClassBooking?> GetActiveAsync(Guid memberId, Guid classId, CancellationToken ct = default);

    Task<ClassBooking?> GetLatestAsync(Guid memberId, Guid classId, CancellationToken ct = default);

    Task<IReadOnlyList<ClassBooking>> GetByMemberAsync(
        Guid memberId,
        DateTime now,
        bool upcoming,
        CancellationToken ct = default);

    Task<ClassBooking?> GetWaitListHeadAsync(Guid classId, CancellationToken ct = default);

    Task AddAsync(ClassBooking booking, CancellationToken ct = default);

    void Update(ClassBooking booking);
}

public interface IClassesBookingsUnitOfWork
{
    Task<int> SaveChangesAsync(CancellationToken ct = default);

    Task<bool> TrySaveChangesAsync(CancellationToken ct = default);
}
