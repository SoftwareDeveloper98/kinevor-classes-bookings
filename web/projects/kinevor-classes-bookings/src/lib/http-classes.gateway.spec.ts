import { provideHttpClient } from '@angular/common/http';
import { HttpTestingController, provideHttpClientTesting } from '@angular/common/http/testing';
import { TestBed } from '@angular/core/testing';
import { afterEach, beforeEach, describe, expect, it } from 'vitest';
import { CLASSES_API_BASE_URL, GymClassSummary, PagedResult } from './class.model';
import { HttpClassesGateway } from './http-classes.gateway';

describe('HttpClassesGateway', () => {
  let gateway: HttpClassesGateway;
  let http: HttpTestingController;

  const summary: GymClassSummary = {
    id: 'c1',
    name: 'Sunrise Yoga',
    description: 'Start gently.',
    type: 'Yoga',
    trainerId: 't1',
    trainerName: 'Maya Thompson',
    startsAt: '2026-10-21T06:00:00Z',
    endsAt: '2026-10-21T07:00:00Z',
    durationMinutes: 60,
    capacity: 14,
    bookedCount: 9,
    availableSpots: 5,
    waitListCount: 0,
    status: 'Scheduled',
    room: 'Studio One',
    requiresMembership: true,
    isFull: false,
    isOpenForBooking: true,
  };

  const page: PagedResult<GymClassSummary> = {
    items: [summary],
    totalCount: 1,
    page: 2,
    pageSize: 10,
    totalPages: 1,
    hasNext: false,
    hasPrev: true,
  };

  beforeEach(() => {
    TestBed.configureTestingModule({
      providers: [
        provideHttpClient(),
        provideHttpClientTesting(),
        HttpClassesGateway,
        { provide: CLASSES_API_BASE_URL, useValue: 'http://api.test/api/v1/' },
      ],
    });
    gateway = TestBed.inject(HttpClassesGateway);
    http = TestBed.inject(HttpTestingController);
  });

  afterEach(() => http.verify());

  it('lists classes with filters and unwraps the envelope', async () => {
    const resultPromise = gateway.list({
      type: 'Yoga',
      page: 2,
      pageSize: 10,
      fromDate: '2026-10-20',
    });

    const request = http.expectOne((req) => req.url === 'http://api.test/api/v1/classes' && req.method === 'GET');
    expect(request.request.params.get('type')).toBe('Yoga');
    expect(request.request.params.get('page')).toBe('2');
    expect(request.request.params.get('fromDate')).toBe('2026-10-20');
    request.flush({ success: true, data: page });

    await expect(resultPromise).resolves.toEqual(page);
  });

  it('posts a booking to the class booking route', async () => {
    const booking = {
      bookingId: 'b1',
      isWaitListed: false,
      status: 'Confirmed',
      availableSpots: 4,
      waitListPosition: 0,
    };
    const resultPromise = gateway.book('c1', { memberName: 'Maya Thompson' });

    const request = http.expectOne('http://api.test/api/v1/classes/c1/bookings');
    expect(request.request.method).toBe('POST');
    expect(request.request.body).toEqual({ memberName: 'Maya Thompson' });
    request.flush({ success: true, data: booking });

    await expect(resultPromise).resolves.toEqual(booking);
  });

  it('passes the scope when loading member bookings', async () => {
    const resultPromise = gateway.myBookings('past');

    const request = http.expectOne((req) => req.url === 'http://api.test/api/v1/me/bookings');
    expect(request.request.params.get('scope')).toBe('past');
    request.flush({ success: true, data: [] });

    await expect(resultPromise).resolves.toEqual([]);
  });

  it('sends the cancellation reason as a query parameter', async () => {
    const resultPromise = gateway.cancelBooking('b1', 'Schedule clash');

    const request = http.expectOne((req) => req.url === 'http://api.test/api/v1/bookings/b1');
    expect(request.request.method).toBe('DELETE');
    expect(request.request.params.get('reason')).toBe('Schedule clash');
    request.flush({ success: true, data: null });

    await expect(resultPromise).resolves.toBeUndefined();
  });
});
