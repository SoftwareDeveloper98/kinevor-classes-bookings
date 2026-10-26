using Kinevor.Modules.ClassesBookings.Application;
using Microsoft.Extensions.DependencyInjection;

namespace Kinevor.Modules.ClassesBookings.DependencyInjection;

public static class ClassesBookingsModule
{
    public static IServiceCollection AddClassesBookingsModule(this IServiceCollection services)
    {
        ArgumentNullException.ThrowIfNull(services);

        services.AddMediatR(configuration =>
            configuration.RegisterServicesFromAssemblyContaining<GetClassesHandler>());
        services.AddSingleton(TimeProvider.System);
        return services;
    }
}
