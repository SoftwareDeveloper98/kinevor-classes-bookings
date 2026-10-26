using Kinevor.Modules.ClassesBookings.Domain;
using Microsoft.Extensions.DependencyInjection;

namespace Kinevor.Modules.ClassesBookings.EntityFrameworkCore;

public static class ClassesBookingsEntityFrameworkCoreExtensions
{
    public static IServiceCollection AddClassesBookingsEntityFrameworkCore(this IServiceCollection services)
    {
        ArgumentNullException.ThrowIfNull(services);

        services.AddScoped<IGymClassRepository, GymClassRepository>();
        services.AddScoped<IClassBookingRepository, ClassBookingRepository>();
        services.AddScoped<IClassesBookingsUnitOfWork>(provider =>
            provider.GetRequiredService<ClassesBookingsDbContext>());
        return services;
    }
}
