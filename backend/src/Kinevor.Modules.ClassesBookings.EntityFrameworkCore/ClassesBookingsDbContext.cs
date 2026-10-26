using Kinevor.Modules.ClassesBookings.Domain;
using Microsoft.EntityFrameworkCore;

namespace Kinevor.Modules.ClassesBookings.EntityFrameworkCore;

public sealed class ClassesBookingsDbContext(DbContextOptions<ClassesBookingsDbContext> options)
    : DbContext(options), IClassesBookingsUnitOfWork
{
    public DbSet<GymClass> Classes => Set<GymClass>();

    public DbSet<ClassBooking> Bookings => Set<ClassBooking>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        ArgumentNullException.ThrowIfNull(modelBuilder);

        modelBuilder.ApplyConfiguration(new GymClassConfiguration());
        modelBuilder.ApplyConfiguration(new ClassBookingConfiguration());
        base.OnModelCreating(modelBuilder);
    }

    public override Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        var now = DateTime.UtcNow;
        foreach (var entry in ChangeTracker.Entries<Kinevor.Platform.Domain.Common.Entity>())
        {
            if (entry.State == EntityState.Added)
                entry.Property(nameof(Kinevor.Platform.Domain.Common.Entity.CreatedAt)).CurrentValue = now;

            if (entry.State == EntityState.Modified)
                entry.Property(nameof(Kinevor.Platform.Domain.Common.Entity.UpdatedAt)).CurrentValue = now;
        }

        return base.SaveChangesAsync(cancellationToken);
    }

    public async Task<bool> TrySaveChangesAsync(CancellationToken ct = default)
    {
        try
        {
            await SaveChangesAsync(ct);
            return true;
        }
        catch (DbUpdateConcurrencyException)
        {
            return false;
        }
    }
}
