using Kinevor.Modules.ClassesBookings.Application;
using Kinevor.Platform.Api;
using Kinevor.Platform.Application.Common;
using MediatR;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;

namespace Kinevor.Modules.ClassesBookings.Api;

[ApiController]
[Route("api/v1/classes")]
[Authorize(Policy = Policies.MemberOrAbove)]
public class ClassesController(ISender sender) : ControllerBase
{
    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<PagedResult<ClassSummaryDto>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<PagedResult<ClassSummaryDto>>>> GetAll(
        [FromQuery] string? type,
        [FromQuery] string? status,
        [FromQuery] DateTime? fromDate,
        [FromQuery] DateTime? toDate,
        [FromQuery] int page = 1,
        [FromQuery] int pageSize = 20,
        CancellationToken ct = default)
    {
        var result = await sender.Send(
            new GetClassesQuery(type, status, fromDate, toDate, page, pageSize), ct);
        return Ok(ApiResponse<PagedResult<ClassSummaryDto>>.Ok(result));
    }

    [HttpGet("catalogue")]
    [ProducesResponseType(typeof(ApiResponse<IReadOnlyList<CatalogueItemDto>>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<IReadOnlyList<CatalogueItemDto>>>> Catalogue(CancellationToken ct)
    {
        var result = await sender.Send(new GetClassCatalogueQuery(), ct);
        return Ok(ApiResponse<IReadOnlyList<CatalogueItemDto>>.Ok(result));
    }

    [HttpGet("{id:guid}")]
    [ProducesResponseType(typeof(ApiResponse<ClassDetailDto>), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse<ClassDetailDto>>> GetById(Guid id, CancellationToken ct)
    {
        var result = await sender.Send(new GetClassDetailQuery(id), ct);
        return Ok(ApiResponse<ClassDetailDto>.Ok(result));
    }

    [HttpPost]
    [Authorize(Policy = Policies.TrainerOrAbove)]
    [ProducesResponseType(typeof(ApiResponse<Guid>), StatusCodes.Status201Created)]
    public async Task<ActionResult<ApiResponse<Guid>>> Schedule(
        [FromBody] ScheduleClassRequest request,
        CancellationToken ct)
    {
        var id = await sender.Send(new ScheduleClassCommand(request), ct);
        return CreatedAtAction(
            nameof(GetById),
            new { id },
            ApiResponse<Guid>.Ok(id, "Class scheduled."));
    }

    [HttpPut("{id:guid}")]
    [Authorize(Policy = Policies.TrainerOrAbove)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse>> Update(
        Guid id,
        [FromBody] ScheduleClassRequest request,
        CancellationToken ct)
    {
        await sender.Send(new UpdateClassCommand(id, request), ct);
        return Ok(ApiResponse.Ok("Class updated."));
    }

    [HttpPost("{id:guid}/cancel")]
    [Authorize(Policy = Policies.TrainerOrAbove)]
    [ProducesResponseType(typeof(ApiResponse), StatusCodes.Status200OK)]
    public async Task<ActionResult<ApiResponse>> Cancel(
        Guid id,
        [FromBody] CancelClassRequest? request,
        CancellationToken ct)
    {
        await sender.Send(new CancelClassCommand(id, request?.Reason), ct);
        return Ok(ApiResponse.Ok("Class cancelled."));
    }

    [HttpPost("{id:guid}/bookings")]
    [ProducesResponseType(typeof(ApiResponse<BookClassResultDto>), StatusCodes.Status201Created)]
    public async Task<ActionResult<ApiResponse<BookClassResultDto>>> Book(
        Guid id,
        [FromBody] BookClassRequest? request,
        CancellationToken ct)
    {
        var result = await sender.Send(
            new BookClassCommand(id, request?.MemberId, request?.MemberName), ct);
        return StatusCode(
            StatusCodes.Status201Created,
            ApiResponse<BookClassResultDto>.Ok(
                result,
                result.IsWaitListed ? "Added to the waitlist." : "Class booked."));
    }
}
