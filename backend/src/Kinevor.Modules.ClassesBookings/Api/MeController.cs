using Kinevor.Modules.ClassesBookings.Application;
using Kinevor.Platform.Api;
using Kinevor.Platform.Application.Common;
using Kinevor.Platform.Application.Exceptions;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Kinevor.Modules.ClassesBookings.Api;

[ApiController]
[Route("api/v1/me")]
[Authorize(Policy = Policies.MemberOrAbove)]
public class MeController(ISender sender, ICurrentUser currentUser) : ControllerBase
{
    [HttpGet("bookings")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<MyBookingDto>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<MyBookingDto>>>> Bookings(
        [FromQuery] string? scope,
        CancellationToken ct)
    {
        var memberId = currentUser.MemberId
            ?? throw new ForbiddenException("No linked member profile.");

        var result = await sender.Send(new GetMyBookingsQuery(memberId, scope), ct);
        return Ok(ApiResponse<IReadOnlyList<MyBookingDto>>.Ok(result));
    }
}
