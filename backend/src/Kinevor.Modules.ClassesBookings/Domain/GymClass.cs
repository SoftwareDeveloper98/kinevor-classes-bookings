using Kinevor.Platform.Domain.Common;
using Kinevor.Platform.Domain.Enums;

namespace Kinevor.Modules.ClassesBookings.Domain;

public sealed class GymClass : AggregateRoot
{
    public string Name { get; private set; } = string.Empty;

    public string? Description { get; private set; }

    public ClassType Type { get; private set; }

    public Guid TrainerId { get; private set; }

    public string TrainerName { get; private set; } = string.Empty;

    public DateTime ScheduledAt { get; private set; }

    public int DurationMinutes { get; private set; }

    public int Capacity { get; private set; }

    public int BookedCount { get; private set; }

    public int WaitListCount { get; private set; }

    public ClassStatus Status { get; private set; } = ClassStatus.Scheduled;

    public string Room { get; private set; } = string.Empty;

    public string? Notes { get; private set; }

    public bool RequiresMembership { get; private set; } = true;

    public Guid? BranchId { get; private set; }

    public Guid RowVersion { get; private set; } = Guid.NewGuid();

    public DateTime? CancelledAt { get; private set; }

    public string? CancellationReason { get; private set; }

    public DateTime EndsAt => ScheduledAt.AddMinutes(DurationMinutes);

    public int AvailableSpots => Math.Max(0, Capacity - BookedCount);

    public bool IsFull => AvailableSpots == 0;

    private GymClass()
    {
    }

    public static Result<GymClass> Create(
        DateTime now,
        string name,
        string? description,
        ClassType type,
        Guid trainerId,
        string trainerName,
        DateTime scheduledAt,
        int durationMinutes,
        int capacity,
        string room,
        string? notes,
        bool requiresMembership,
        Guid? id = null)
    {
        if (scheduledAt <= now)
            return Result.Failure<GymClass>(Error.Business("Class.PastDate", "Class must be scheduled in the future."));

        return Build(name, description, type, trainerId, trainerName, scheduledAt, durationMinutes,
            capacity, room, notes, requiresMembership, id);
    }

    public static Result<GymClass> Import(
        string name,
        string? description,
        ClassType type,
        Guid trainerId,
        string trainerName,
        DateTime scheduledAt,
        int durationMinutes,
        int capacity,
        string room,
        string? notes,
        bool requiresMembership,
        Guid? id = null)
    {
        return Build(name, description, type, trainerId, trainerName, scheduledAt, durationMinutes,
            capacity, room, notes, requiresMembership, id);
    }

    private static Result<GymClass> Build(
        string name,
        string? description,
        ClassType type,
        Guid trainerId,
        string trainerName,
        DateTime scheduledAt,
        int durationMinutes,
        int capacity,
        string room,
        string? notes,
        bool requiresMembership,
        Guid? id = null)
    {
        if (string.IsNullOrWhiteSpace(name))
            return Result.Failure<GymClass>(Error.Validation("Name", "Class name is required."));
        if (name.Trim().Length > 120)
            return Result.Failure<GymClass>(Error.Validation("Name", "Class name must be 120 characters or fewer."));
        if (trainerId == Guid.Empty)
            return Result.Failure<GymClass>(Error.Validation("TrainerId", "A trainer is required."));
        if (string.IsNullOrWhiteSpace(trainerName))
            return Result.Failure<GymClass>(Error.Validation("TrainerName", "Trainer name is required."));
        if (durationMinutes is < 15 or > 240)
            return Result.Failure<GymClass>(Error.Validation("Duration", "Duration must be between 15 and 240 minutes."));
        if (capacity is < 1 or > 200)
            return Result.Failure<GymClass>(Error.Validation("Capacity", "Capacity must be between 1 and 200."));
        if (string.IsNullOrWhiteSpace(room))
            return Result.Failure<GymClass>(Error.Validation("Room", "Room is required."));

        return Result.Success(new GymClass
        {
            Name = name.Trim(),
            Description = Normalize(description),
            Type = type,
            TrainerId = trainerId,
            TrainerName = trainerName.Trim(),
            ScheduledAt = scheduledAt.Kind == DateTimeKind.Utc ? scheduledAt : scheduledAt.ToUniversalTime(),
            DurationMinutes = durationMinutes,
            Capacity = capacity,
            Room = room.Trim(),
            Notes = Normalize(notes),
            RequiresMembership = requiresMembership,
            Id = id ?? Guid.NewGuid(),
        });
    }

    public Result Update(
        DateTime now,
        string name,
        string? description,
        ClassType type,
        Guid trainerId,
        string trainerName,
        DateTime scheduledAt,
        int durationMinutes,
        int capacity,
        string room,
        string? notes,
        bool requiresMembership)
    {
        if (Status != ClassStatus.Scheduled)
            return Result.Failure(Error.Business("Class.NotEditable", "Only scheduled classes can be changed."));
        if (scheduledAt <= now)
            return Result.Failure(Error.Business("Class.PastDate", "Class must be scheduled in the future."));
        if (string.IsNullOrWhiteSpace(name))
            return Result.Failure(Error.Validation("Name", "Class name is required."));
        if (trainerId == Guid.Empty)
            return Result.Failure(Error.Validation("TrainerId", "A trainer is required."));
        if (string.IsNullOrWhiteSpace(trainerName))
            return Result.Failure(Error.Validation("TrainerName", "Trainer name is required."));
        if (durationMinutes is < 15 or > 240)
            return Result.Failure(Error.Validation("Duration", "Duration must be between 15 and 240 minutes."));
        if (capacity is < 1 or > 200)
            return Result.Failure(Error.Validation("Capacity", "Capacity must be between 1 and 200."));
        if (capacity < BookedCount)
            return Result.Failure(Error.Business("Class.CapacityBelowBookings", "Capacity cannot be below the confirmed booking count."));
        if (string.IsNullOrWhiteSpace(room))
            return Result.Failure(Error.Validation("Room", "Room is required."));

        Name = name.Trim();
        Description = Normalize(description);
        Type = type;
        TrainerId = trainerId;
        TrainerName = trainerName.Trim();
        ScheduledAt = scheduledAt.Kind == DateTimeKind.Utc ? scheduledAt : scheduledAt.ToUniversalTime();
        DurationMinutes = durationMinutes;
        Capacity = capacity;
        Room = room.Trim();
        Notes = Normalize(notes);
        RequiresMembership = requiresMembership;
        RowVersion = Guid.NewGuid();
        return Result.Success();
    }

    public bool IsOpenAt(DateTime now) => Status == ClassStatus.Scheduled && ScheduledAt > now;

    public Result<bool> Book(DateTime now, Guid memberId)
    {
        if (!IsOpenAt(now))
            return Result.Failure<bool>(Error.Business("Class.NotOpen", "Class is not available for booking."));

        var waitListed = IsFull;
        if (waitListed)
            WaitListCount++;
        else
            BookedCount++;

        RowVersion = Guid.NewGuid();
        return Result.Success(waitListed);
    }

    public Result CancelBooking(bool wasWaitListed)
    {
        if (wasWaitListed)
            WaitListCount = Math.Max(0, WaitListCount - 1);
        else
            BookedCount = Math.Max(0, BookedCount - 1);

        RowVersion = Guid.NewGuid();
        return Result.Success();
    }

    public Result ImportBooking(bool waitListed)
    {
        if (waitListed)
            WaitListCount++;
        else
            BookedCount++;

        RowVersion = Guid.NewGuid();
        return Result.Success();
    }

    public Result PromoteFromWaitList()
    {
        if (Status != ClassStatus.Scheduled)
            return Result.Failure(Error.Business("Class.NotOpen", "Class is not open."));
        if (WaitListCount <= 0)
            return Result.Failure(Error.Business("Class.WaitListEmpty", "The waitlist is empty."));
        if (IsFull)
            return Result.Failure(Error.Business("Class.Full", "No seats are available."));

        WaitListCount--;
        BookedCount++;
        RowVersion = Guid.NewGuid();
        return Result.Success();
    }

    public Result Cancel(DateTime now, string? reason)
    {
        if (Status == ClassStatus.Cancelled)
            return Result.Failure(Error.Business("Class.AlreadyCancelled", "Class is already cancelled."));
        if (Status == ClassStatus.Completed)
            return Result.Failure(Error.Business("Class.Completed", "A completed class cannot be cancelled."));

        Status = ClassStatus.Cancelled;
        CancelledAt = now;
        CancellationReason = Normalize(reason);
        RowVersion = Guid.NewGuid();
        return Result.Success();
    }

    public void Start()
    {
        if (Status == ClassStatus.Scheduled)
            Status = ClassStatus.InProgress;
    }

    public void Complete()
    {
        if (Status is ClassStatus.Scheduled or ClassStatus.InProgress)
            Status = ClassStatus.Completed;
    }

    public void AssignBranch(Guid branchId) => BranchId = branchId;

    private static string? Normalize(string? value) =>
        string.IsNullOrWhiteSpace(value) ? null : value.Trim();
}
