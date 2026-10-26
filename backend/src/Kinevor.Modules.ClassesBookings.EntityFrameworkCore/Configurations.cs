using Kinevor.Modules.ClassesBookings.Domain;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Kinevor.Modules.ClassesBookings.EntityFrameworkCore;

internal sealed class GymClassConfiguration : IEntityTypeConfiguration<GymClass>
{
    public void Configure(EntityTypeBuilder<GymClass> builder)
    {
        builder.ToTable("GymClasses");
        builder.HasKey(gymClass => gymClass.Id);

        builder.Property(gymClass => gymClass.Name).HasMaxLength(120).IsRequired();
        builder.Property(gymClass => gymClass.Description).HasMaxLength(1000);
        builder.Property(gymClass => gymClass.Type).HasConversion<string>().HasMaxLength(30).IsRequired();
        builder.Property(gymClass => gymClass.TrainerName).HasMaxLength(120).IsRequired();
        builder.Property(gymClass => gymClass.Room).HasMaxLength(80).IsRequired();
        builder.Property(gymClass => gymClass.Notes).HasMaxLength(1000);
        builder.Property(gymClass => gymClass.Status).HasConversion<string>().HasMaxLength(20).IsRequired();
        builder.Property(gymClass => gymClass.CancellationReason).HasMaxLength(500);
        builder.Property(gymClass => gymClass.RowVersion).IsConcurrencyToken();

        builder.HasIndex(gymClass => gymClass.ScheduledAt);
        builder.HasIndex(gymClass => new { gymClass.Status, gymClass.ScheduledAt });
    }
}

internal sealed class ClassBookingConfiguration : IEntityTypeConfiguration<ClassBooking>
{
    public void Configure(EntityTypeBuilder<ClassBooking> builder)
    {
        builder.ToTable("ClassBookings");
        builder.HasKey(booking => booking.Id);

        builder.Property(booking => booking.MemberName).HasMaxLength(120).IsRequired();
        builder.Property(booking => booking.ClassName).HasMaxLength(120).IsRequired();
        builder.Property(booking => booking.Status).HasConversion<string>().HasMaxLength(20).IsRequired();
        builder.Property(booking => booking.CancellationReason).HasMaxLength(500);

        builder.HasIndex(booking => new { booking.MemberId, booking.ClassStartsAt });
        builder.HasIndex(booking => new { booking.ClassId, booking.Status });
        builder.HasIndex(booking => new { booking.ClassId, booking.MemberId })
            .IsUnique()
            .HasFilter("\"Status\" IN ('Confirmed', 'WaitListed')");
    }
}
