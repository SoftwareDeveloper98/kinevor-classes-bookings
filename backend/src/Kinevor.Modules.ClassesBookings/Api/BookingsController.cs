using Kinevor.Modules.ClassesBookings.Application;
using Kinevor.Platform.Api;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Kinevor.Modules.ClassesBookings.Api;

[ApiController]
[Route("api/v1/bookings")]
[Authorize(Policy = Policies.MemberOrAbove)]
public class BookingsController(ISender sender) : ControllerBase
{
    [HttpDelete("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse>> Cancel(
        Guid id,
        [FromQuery] string? reason,
        CancellationToken ct)
    {
        await sender.Send(new CancelBookingCommand(id, reason), ct);
        return Ok(ApiResponse.Ok("Booking cancelled."));
    }

    [HttpPost("{id:guid}/promote")]
    [Authorize(Policy = Policies.TrainerOrAbove)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse>> Promote(Guid id, CancellationToken ct)
    {
        await sender.Send(new PromoteWaitListCommand(id), ct);
        return Ok(ApiResponse.Ok("Booking promoted."));
    }

    [HttpPatch("{id:guid}/attendance")]
    [Authorize(Policy = Policies.TrainerOrAbove)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse>> Attendance(
        Guid id,
        [FromBody] AttendanceRequest request,
        CancellationToken ct)
    {
        await sender.Send(new MarkAttendanceCommand(id, request.Attended), ct);
        return Ok(ApiResponse.Ok("Attendance recorded."));
    }
}
