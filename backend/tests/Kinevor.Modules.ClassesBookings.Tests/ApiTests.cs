using Xunit;
using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Kinevor.Modules.ClassesBookings.DemoApi.Data;

namespace Kinevor.Modules.ClassesBookings.Tests;

public class ApiTests
{
    private static HttpClient Actor(
        TestWebApplicationFactory factory,
        string role,
        Guid? memberId = null)
    {
        var client = factory.CreateClient();
        client.DefaultRequestHeaders.Add("X-Demo-Role", role);
        if (memberId is { } id)
            client.DefaultRequestHeaders.Add("X-Demo-Member", id.ToString());
        return client;
    }

    [Fact]
    public async Task Classes_ListAndCatalogueReturnSeededSessions()
    {
        using var factory = new TestWebApplicationFactory();
        using var client = Actor(factory, "Member", DemoDataSeeder.MayaMemberId);

        var list = await client.GetAsync("/api/v1/classes?fromDate=2026-01-01&page=1&pageSize=50");
        Assert.Equal(HttpStatusCode.OK, list.StatusCode);

        using var listDocument = JsonDocument.Parse(await list.Content.ReadAsStringAsync());
        var items = listDocument.RootElement.GetProperty("data").GetProperty("items");
        Assert.Equal(12, items.GetArrayLength());
        Assert.Contains(items.EnumerateArray(), item => item.GetProperty("name").GetString() == "Sunrise Yoga");

        var catalogue = await client.GetAsync("/api/v1/classes/catalogue");
        Assert.Equal(HttpStatusCode.OK, catalogue.StatusCode);
        using var catalogueDocument = JsonDocument.Parse(await catalogue.Content.ReadAsStringAsync());
        Assert.Contains(
            catalogueDocument.RootElement.GetProperty("data").EnumerateArray(),
            item => item.GetProperty("type").GetString() == "Yoga");
    }

    [Fact]
    public async Task Detail_ShowsRosterToStaffAndHidesItFromMembers()
    {
        using var factory = new TestWebApplicationFactory();
        var path = $"/api/v1/classes/{DemoDataSeeder.SunriseYogaClassId}";

        using var staff = Actor(factory, "Staff", DemoDataSeeder.MayaMemberId);
        var staffResponse = await staff.GetAsync(path);
        Assert.Equal(HttpStatusCode.OK, staffResponse.StatusCode);
        using var staffDocument = JsonDocument.Parse(await staffResponse.Content.ReadAsStringAsync());
        var staffData = staffDocument.RootElement.GetProperty("data");
        Assert.True(staffData.GetProperty("roster").GetArrayLength() >= 12);
        Assert.Equal("Maya Thompson", staffData.GetProperty("myBooking").GetProperty("memberName").GetString());

        using var member = Actor(factory, "Member", DemoDataSeeder.MayaMemberId);
        var memberResponse = await member.GetAsync(path);
        using var memberDocument = JsonDocument.Parse(await memberResponse.Content.ReadAsStringAsync());
        Assert.Equal(0, memberDocument.RootElement.GetProperty("data").GetProperty("roster").GetArrayLength());
    }

    [Fact]
    public async Task Booking_WaitlistsWhenFullAndRejectsDuplicates()
    {
        using var factory = new TestWebApplicationFactory();
        using var client = Actor(factory, "Member", DemoDataSeeder.MayaMemberId);

        var response = await client.PostAsJsonAsync(
            $"/api/v1/classes/{DemoDataSeeder.HiitBurnClassId}/bookings",
            new { memberName = "Maya Thompson" });

        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var data = document.RootElement.GetProperty("data");
        Assert.True(data.GetProperty("isWaitListed").GetBoolean());
        var bookingId = data.GetProperty("bookingId").GetGuid();

        var duplicate = await client.PostAsJsonAsync(
            $"/api/v1/classes/{DemoDataSeeder.HiitBurnClassId}/bookings",
            new { memberName = "Maya Thompson" });
        Assert.Equal(HttpStatusCode.Conflict, duplicate.StatusCode);

        var cancelled = await client.DeleteAsync($"/api/v1/bookings/{bookingId}?reason=Schedule+change");
        Assert.Equal(HttpStatusCode.OK, cancelled.StatusCode);
    }

    [Fact]
    public async Task Booking_CreatesSeatAndCancellationFreesIt()
    {
        using var factory = new TestWebApplicationFactory();
        using var client = Actor(factory, "Member", DemoDataSeeder.MayaMemberId);
        var path = $"/api/v1/classes/{DemoDataSeeder.PowerSpinClassId}";

        var response = await client.PostAsJsonAsync(path + "/bookings", new { memberName = "Maya Thompson" });
        Assert.Equal(HttpStatusCode.Created, response.StatusCode);
        using var document = JsonDocument.Parse(await response.Content.ReadAsStringAsync());
        var data = document.RootElement.GetProperty("data");
        Assert.False(data.GetProperty("isWaitListed").GetBoolean());

        var detail = await client.GetAsync(path);
        using var detailDocument = JsonDocument.Parse(await detail.Content.ReadAsStringAsync());
        Assert.NotEqual(JsonValueKind.Null, detailDocument.RootElement.GetProperty("data")
            .GetProperty("myBooking").ValueKind);

        var cancelled = await client.DeleteAsync(
            $"/api/v1/bookings/{data.GetProperty("bookingId").GetGuid()}?reason=Plans+changed");
        Assert.Equal(HttpStatusCode.OK, cancelled.StatusCode);

        var after = await client.GetAsync(path);
        using var afterDocument = JsonDocument.Parse(await after.Content.ReadAsStringAsync());
        Assert.Equal(JsonValueKind.Null, afterDocument.RootElement.GetProperty("data")
            .GetProperty("myBooking").ValueKind);
    }

    [Fact]
    public async Task MyBookings_SeparatesUpcomingAndPast()
    {
        using var factory = new TestWebApplicationFactory();
        using var client = Actor(factory, "Member", DemoDataSeeder.MayaMemberId);

        var upcoming = await client.GetAsync("/api/v1/me/bookings?scope=upcoming");
        Assert.Equal(HttpStatusCode.OK, upcoming.StatusCode);
        using var upcomingDocument = JsonDocument.Parse(await upcoming.Content.ReadAsStringAsync());
        var upcomingItems = upcomingDocument.RootElement.GetProperty("data");
        Assert.Contains(upcomingItems.EnumerateArray(), item => item.GetProperty("className").GetString() == "Sunrise Yoga");
        Assert.Contains(upcomingItems.EnumerateArray(), item => item.GetProperty("isWaitListed").GetBoolean());

        var past = await client.GetAsync("/api/v1/me/bookings?scope=past");
        using var pastDocument = JsonDocument.Parse(await past.Content.ReadAsStringAsync());
        Assert.Contains(
            pastDocument.RootElement.GetProperty("data").EnumerateArray(),
            item => item.GetProperty("className").GetString() == "Morning Flow");
    }

    [Fact]
    public async Task Scheduling_RequiresTrainerOrAbove()
    {
        using var factory = new TestWebApplicationFactory();
        using var client = Actor(factory, "Member", DemoDataSeeder.MayaMemberId);

        var response = await client.PostAsJsonAsync("/api/v1/classes", new
        {
            name = "Member Class",
            type = "Yoga",
            trainerId = Guid.Parse("a1111111-1111-1111-1111-111111111111"),
            trainerName = "Amara Okafor",
            startsAt = DateTime.UtcNow.AddDays(2),
            durationMinutes = 60,
            capacity = 10,
            room = "Studio One",
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [Fact]
    public async Task Health_IsAnonymous()
    {
        using var factory = new TestWebApplicationFactory();
        using var client = factory.CreateClient();

        var response = await client.GetAsync("/health");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
