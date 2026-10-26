using Kinevor.Modules.ClassesBookings.Domain;
using Kinevor.Modules.ClassesBookings.EntityFrameworkCore;
using Kinevor.Platform.Domain.Common;
using Kinevor.Platform.Domain.Enums;
using Microsoft.EntityFrameworkCore;

namespace Kinevor.Modules.ClassesBookings.DemoApi.Data;

public static class DemoDataSeeder
{
    public static readonly Guid MayaMemberId = Guid.Parse("11111111-1111-1111-1111-111111111111");
    public static readonly Guid DanielMemberId = Guid.Parse("22222222-2222-2222-2222-222222222222");
    public static readonly Guid SofiaMemberId = Guid.Parse("33333333-3333-3333-3333-333333333333");

    public static readonly Guid SunriseYogaClassId = Guid.Parse("c0000000-0000-0000-0000-000000000001");
    public static readonly Guid HiitBurnClassId = Guid.Parse("c0000000-0000-0000-0000-000000000002");
    public static readonly Guid ReformerPilatesClassId = Guid.Parse("c0000000-0000-0000-0000-000000000003");
    public static readonly Guid PowerSpinClassId = Guid.Parse("c0000000-0000-0000-0000-000000000004");
    public static readonly Guid BoxingClassId = Guid.Parse("c0000000-0000-0000-0000-000000000005");
    public static readonly Guid BodyPumpClassId = Guid.Parse("c0000000-0000-0000-0000-000000000006");
    public static readonly Guid ZumbaClassId = Guid.Parse("c0000000-0000-0000-0000-000000000007");
    public static readonly Guid AquaClassId = Guid.Parse("c0000000-0000-0000-0000-000000000008");
    public static readonly Guid SoundBathClassId = Guid.Parse("c0000000-0000-0000-0000-000000000009");
    public static readonly Guid MobilityClassId = Guid.Parse("c0000000-0000-0000-0000-000000000010");

    private static readonly Guid AmaraId = Guid.Parse("a1111111-1111-1111-1111-111111111111");
    private static readonly Guid MarcusId = Guid.Parse("a2222222-2222-2222-2222-222222222222");
    private static readonly Guid ElenaId = Guid.Parse("a3333333-3333-3333-3333-333333333333");
    private static readonly Guid JordanId = Guid.Parse("a4444444-4444-4444-4444-444444444444");
    private static readonly Guid TariqId = Guid.Parse("a5555555-5555-5555-5555-555555555555");
    private static readonly Guid PriyaId = Guid.Parse("a6666666-6666-6666-6666-666666666666");
    private static readonly Guid NadiaId = Guid.Parse("a7777777-7777-7777-7777-777777777777");

    private static readonly IReadOnlyList<(Guid Id, string Name)> Members =
    [
        (MayaMemberId, "Maya Thompson"),
        (DanielMemberId, "Daniel Okafor"),
        (SofiaMemberId, "Sofia Rossi"),
        (MemberId(4), "Noah Williams"),
        (MemberId(5), "Isla Bennett"),
        (MemberId(6), "Liam Carter"),
        (MemberId(7), "Ava Patel"),
        (MemberId(8), "Ethan Brooks"),
        (MemberId(9), "Chloe Nguyen"),
        (MemberId(10), "Owen Hughes"),
        (MemberId(11), "Zara Ali"),
        (MemberId(12), "Leo Martin"),
        (MemberId(13), "Grace Kim"),
        (MemberId(14), "Adam Clarke"),
        (MemberId(15), "Nina Petrov"),
        (MemberId(16), "Sam Wilson"),
        (MemberId(17), "Layla Hassan"),
        (MemberId(18), "Theo James"),
        (MemberId(19), "Ruby Evans"),
        (MemberId(20), "Kai Morgan"),
        (MemberId(21), "Freya Scott"),
        (MemberId(22), "Hugo Phillips"),
        (MemberId(23), "Amelia Wright"),
        (MemberId(24), "Isaac Turner"),
    ];

    public static async Task SeedAsync(ClassesBookingsDbContext db)
    {
        ArgumentNullException.ThrowIfNull(db);

        if (await db.Classes.AnyAsync())
            return;

        var now = DateTime.UtcNow;
        var today = now.Date;

        var classes = new List<GymClass>
        {
            CreateClass(SunriseYogaClassId, now, "Sunrise Yoga", "Slow flow, breath work and a gentle start to the day.", ClassType.Yoga, AmaraId, "Amara Okafor", today.AddDays(1).AddHours(6.5), 60, 18, "Studio One", "Mats and blocks provided."),
            CreateClass(HiitBurnClassId, now, "HIIT Burn", "Short, sharp intervals built around full-body conditioning.", ClassType.HIIT, MarcusId, "Marcus Reed", today.AddDays(1).AddHours(7.25), 45, 20, "Performance Floor", "Bring a towel and water."),
            CreateClass(ReformerPilatesClassId, now, "Reformer Pilates", "Controlled strength and mobility on the reformer.", ClassType.Pilates, ElenaId, "Elena Rossi", today.AddDays(1).AddHours(9), 50, 12, "Studio Two", "Grip socks required."),
            CreateClass(PowerSpinClassId, now, "Power Spin", "Climb-heavy ride with a high-energy final sprint.", ClassType.Spinning, JordanId, "Jordan Blake", today.AddDays(1).AddHours(12.5), 45, 24, "Cycle Studio", "Arrive ten minutes early for bike setup."),
            CreateClass(BoxingClassId, now, "Boxing Fundamentals", "Stance, footwork, combinations and pad work.", ClassType.Boxing, TariqId, "Tariq Khan", today.AddDays(1).AddHours(18), 60, 16, "Ring Floor", "Wraps available at reception."),
            CreateClass(BodyPumpClassId, now, "BodyPump Strength", "Full-body barbell class with light weights and high reps.", ClassType.BodyPump, PriyaId, "Priya Nair", today.AddDays(2).AddHours(7), 55, 20, "Studio One", null),
            CreateClass(ZumbaClassId, now, "Sunset Zumba", "Latin rhythms, easy-to-follow choreography and a big finish.", ClassType.Zumba, NadiaId, "Nadia Cole", today.AddDays(2).AddHours(18.5), 45, 22, "Studio Three", null),
            CreateClass(AquaClassId, now, "Aqua Reset", "Low-impact pool conditioning for every level.", ClassType.Aqua, AmaraId, "Amara Okafor", today.AddDays(3).AddHours(10), 45, 14, "Hydro Pool", "Bring swimwear."),
            CreateClass(SoundBathClassId, now, "Sound Bath Meditation", "Guided rest with singing bowls and deep breathing.", ClassType.Meditation, PriyaId, "Priya Nair", today.AddDays(3).AddHours(19), 60, 6, "Quiet Studio", "Bolsters provided."),
            CreateClass(MobilityClassId, now, "Mobility & Stretch", "Hips, shoulders and spine with long passive holds.", ClassType.Stretching, ElenaId, "Elena Rossi", today.AddDays(4).AddHours(8), 50, 16, "Studio Two", null),
        };

        var morningFlow = CreateHistoricalClass(
            Guid.Parse("c0000000-0000-0000-0000-000000000011"),
            "Morning Flow",
            "A steady vinyasa sequence to open the shoulders and hips.",
            ClassType.Yoga,
            AmaraId,
            "Amara Okafor",
            today.AddDays(-2).AddHours(7),
            60,
            16,
            "Studio One");
        morningFlow.Complete();

        var strengthLab = CreateHistoricalClass(
            Guid.Parse("c0000000-0000-0000-0000-000000000012"),
            "Strength Lab",
            "Barbell technique and progressive overload in small groups.",
            ClassType.CrossFit,
            MarcusId,
            "Marcus Reed",
            today.AddDays(-5).AddHours(18),
            60,
            12,
            "Performance Floor");
        strengthLab.Complete();

        classes.Add(morningFlow);
        classes.Add(strengthLab);
        db.Classes.AddRange(classes);

        var byId = classes.ToDictionary(gymClass => gymClass.Id);

        await SeedBookingsAsync(db, byId[SunriseYogaClassId], 0, 12, 0, now);
        await SeedBookingsAsync(db, byId[HiitBurnClassId], 1, 23, 0, now);
        await SeedBookingsAsync(db, byId[ReformerPilatesClassId], 0, 8, 0, now);
        await SeedBookingsAsync(db, byId[PowerSpinClassId], 3, 19, 0, now);
        await SeedBookingsAsync(db, byId[BoxingClassId], 4, 14, 0, now);
        await SeedBookingsAsync(db, byId[BodyPumpClassId], 5, 15, 0, now);
        await SeedBookingsAsync(db, byId[ZumbaClassId], 2, 11, 0, now);
        await SeedBookingsAsync(db, byId[AquaClassId], 4, 7, 0, now);
        await SeedBookingsAsync(db, byId[SoundBathClassId], 1, 6, 0, now);
        await SeedBookingsAsync(db, byId[SoundBathClassId], 0, 1, 0, now);
        await SeedBookingsAsync(db, byId[SoundBathClassId], 7, 2, 0, now);
        await SeedBookingsAsync(db, byId[MobilityClassId], 3, 9, 0, now);

        await SeedPastBookingAsync(db, byId[morningFlow.Id], 0, BookingStatus.Attended, now.AddHours(-1));
        await SeedPastBookingAsync(db, byId[morningFlow.Id], 1, BookingStatus.NoShow, now.AddHours(-1));
        await SeedPastBookingAsync(db, byId[morningFlow.Id], 2, BookingStatus.Attended, now.AddHours(-1));
        await SeedPastBookingAsync(db, byId[strengthLab.Id], 1, BookingStatus.Attended, now.AddHours(-1));
        await SeedPastBookingAsync(db, byId[strengthLab.Id], 3, BookingStatus.Attended, now.AddHours(-1));

        await db.SaveChangesAsync();
    }

    private static GymClass CreateClass(
        Guid id,
        DateTime now,
        string name,
        string description,
        ClassType type,
        Guid trainerId,
        string trainerName,
        DateTime startsAt,
        int durationMinutes,
        int capacity,
        string room,
        string? notes)
    {
        var result = GymClass.Create(
            now, name, description, type, trainerId, trainerName, startsAt,
            durationMinutes, capacity, room, notes, true, id);
        return Require(result);
    }

    private static GymClass CreateHistoricalClass(
        Guid id,
        string name,
        string description,
        ClassType type,
        Guid trainerId,
        string trainerName,
        DateTime startsAt,
        int durationMinutes,
        int capacity,
        string room)
    {
        var result = GymClass.Import(
            name, description, type, trainerId, trainerName, startsAt,
            durationMinutes, capacity, room, null, true, id);
        return Require(result);
    }

    private static GymClass Require(Result<GymClass> result)
    {
        if (result.IsFailure)
            throw new InvalidOperationException(result.Error.Message);
        return result.Value;
    }

    private static async Task SeedBookingsAsync(
        ClassesBookingsDbContext db,
        GymClass gymClass,
        int start,
        int count,
        int extraWaitList,
        DateTime now)
    {
        var indexes = Enumerable.Range(start, count).Select(index => index % Members.Count).Distinct().ToList();
        for (var position = 0; position < indexes.Count; position++)
            await AddBookingAsync(db, gymClass, Members[indexes[position]], now.AddMinutes(position - 60));

        if (extraWaitList <= 0)
            return;

        var waitStart = (start + count) % Members.Count;
        for (var position = 0; position < extraWaitList; position++)
        {
            var member = Members[(waitStart + position) % Members.Count];
            await AddBookingAsync(db, gymClass, member, now.AddMinutes(position));
        }
    }

    private static async Task AddBookingAsync(
        ClassesBookingsDbContext db,
        GymClass gymClass,
        (Guid Id, string Name) member,
        DateTime bookedAt)
    {
        var result = gymClass.Book(DateTime.UtcNow, member.Id);
        if (result.IsFailure)
            throw new InvalidOperationException(result.Error.Message);

        var booking = ClassBooking.Create(
            gymClass.Id,
            gymClass.Name,
            gymClass.ScheduledAt,
            member.Id,
            member.Name,
            result.Value,
            bookedAt);
        await db.Bookings.AddAsync(booking);
    }

    private static async Task SeedPastBookingAsync(
        ClassesBookingsDbContext db,
        GymClass gymClass,
        int memberIndex,
        BookingStatus status,
        DateTime now)
    {
        var member = Members[memberIndex];
        var result = gymClass.ImportBooking(false);
        if (result.IsFailure)
            throw new InvalidOperationException(result.Error.Message);

        var booking = ClassBooking.Create(
            gymClass.Id,
            gymClass.Name,
            gymClass.ScheduledAt,
            member.Id,
            member.Name,
            false,
            now.AddDays(-3));
        if (status == BookingStatus.Attended)
            booking.MarkAttended(now);
        else
            booking.MarkNoShow();

        await db.Bookings.AddAsync(booking);
    }

    private static Guid MemberId(int index) =>
        Guid.Parse($"44444444-4444-4444-4444-{index:D12}");
}
