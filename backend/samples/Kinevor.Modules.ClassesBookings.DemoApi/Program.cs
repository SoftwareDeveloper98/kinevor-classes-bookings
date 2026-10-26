using Kinevor.Modules.ClassesBookings.DemoApi.Authentication;
using Kinevor.Modules.ClassesBookings.DemoApi.Authorization;
using Kinevor.Modules.ClassesBookings.DemoApi.Data;
using Kinevor.Modules.ClassesBookings.DemoApi.Middleware;
using Kinevor.Modules.ClassesBookings.DependencyInjection;
using Kinevor.Modules.ClassesBookings.EntityFrameworkCore;
using Kinevor.Platform.Api;
using Kinevor.Platform.Application.Common;
using Microsoft.AspNetCore.Authentication;
using Microsoft.EntityFrameworkCore;
using Microsoft.OpenApi.Models;

var builder = WebApplication.CreateBuilder(args);
var connectionString = builder.Configuration.GetConnectionString("ClassesBookings")
    ?? "Data Source=classes-bookings-demo.db";

builder.Services.AddDbContext<ClassesBookingsDbContext>(options => options.UseSqlite(connectionString));
builder.Services.AddClassesBookingsModule();
builder.Services.AddClassesBookingsEntityFrameworkCore();
builder.Services.AddHttpContextAccessor();
builder.Services.AddScoped<ICurrentUser, HttpCurrentUser>();
builder.Services.AddScoped<IBranchContext, HttpBranchContext>();

builder.Services
    .AddAuthentication(DemoAuthenticationHandler.SchemeName)
    .AddScheme<AuthenticationSchemeOptions, DemoAuthenticationHandler>(
        DemoAuthenticationHandler.SchemeName, _ => { });
builder.Services.AddAuthorization(options => options.AddKinevorPolicies());

builder.Services
    .AddControllers()
    .AddApplicationPart(typeof(Kinevor.Modules.ClassesBookings.Api.ClassesController).Assembly);

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(options =>
{
    options.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "Kinevor Classes & Bookings Module API",
        Version = "v1",
        Description = "Class schedule, capacity, roster, booking, cancellation and waitlist host.",
    });
    options.AddSecurityDefinition("DemoRole", new OpenApiSecurityScheme
    {
        Name = "X-Demo-Role",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Description = "Demo role: Admin, Staff, Trainer or Member.",
    });
    options.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        [new OpenApiSecurityScheme
        {
            Reference = new OpenApiReference
            {
                Type = ReferenceType.SecurityScheme,
                Id = "DemoRole",
            },
        }] = Array.Empty<string>(),
    });
});

builder.Services.AddCors(options => options.AddPolicy("web", policy =>
    policy.WithOrigins("http://localhost:4204")
        .AllowAnyHeader()
        .AllowAnyMethod()));

var app = builder.Build();

await using (var scope = app.Services.CreateAsyncScope())
{
    var db = scope.ServiceProvider.GetRequiredService<ClassesBookingsDbContext>();
    await db.Database.EnsureCreatedAsync();
    await DemoDataSeeder.SeedAsync(db);
}

app.UseCors("web");
app.UseMiddleware<ApiExceptionMiddleware>();
app.UseSwagger();
app.UseSwaggerUI();
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "Healthy" }));
app.Run();

public partial class Program { }
