import { TestBed } from '@angular/core/testing';
import { describe, expect, it, vi } from 'vitest';
import {
  BookClassResult,
  Booking,
  CatalogueItem,
  CLASSES_GATEWAY,
  ClassesGateway,
  GymClassDetail,
  GymClassSummary,
  MyBooking,
  PagedResult,
} from './class.model';
import { ClassesFacade } from './classes.facade';

const summary: GymClassSummary = {
  id: 'c0000000-0000-0000-0000-000000000001',
  name: 'Sunrise Yoga',
  description: 'Wake up with breath-led mobility and a grounding flow.',
  type: 'Yoga',
  trainerId: 't1',
  trainerName: 'Ava Patel',
  startsAt: '2026-10-22T06:30:00Z',
  endsAt: '2026-10-22T07:20:00Z',
  durationMinutes: 50,
  capacity: 16,
  bookedCount: 12,
  availableSpots: 4,
  waitListCount: 0,
  status: 'Scheduled',
  room: 'Studio A',
  requiresMembership: true,
  isFull: false,
  isOpenForBooking: true,
};

const rosterBooking: Booking = {
  id: 'b1',
  classId: summary.id,
  className: summary.name,
  classStartsAt: summary.startsAt,
  memberId: '11111111-1111-1111-1111-111111111111',
  memberName: 'Maya Thompson',
  status: 'Confirmed',
  isWaitListed: false,
  bookedAt: '2026-10-18T09:00:00Z',
  cancelledAt: null,
  cancellationReason: null,
  checkedInAt: null,
};

const detail: GymClassDetail = {
  ...summary,
  notes: 'Bring a mat and water.',
  roster: [rosterBooking],
  myBooking: rosterBooking,
};

const fullDetail: GymClassDetail = {
  ...summary,
  id: 'c0000000-0000-0000-0000-000000000004',
  name: 'HIIT Power',
  type: 'HIIT',
  capacity: 20,
  bookedCount: 20,
  availableSpots: 0,
  waitListCount: 3,
  isFull: true,
  notes: null,
  roster: [],
  myBooking: null,
};

const catalogue: readonly CatalogueItem[] = [
  { type: 'Yoga', upcomingSessions: 1, nextStartsAt: summary.startsAt, nextClassName: summary.name },
  { type: 'HIIT', upcomingSessions: 1, nextStartsAt: summary.startsAt, nextClassName: 'HIIT Power' },
];

const page: PagedResult<GymClassSummary> = {
  items: [summary],
  totalCount: 1,
  page: 1,
  pageSize: 50,
  totalPages: 1,
  hasNext: false,
  hasPrev: false,
};

const bookingResult: BookClassResult = {
  bookingId: 'b2',
  isWaitListed: true,
  status: 'WaitListed',
  availableSpots: 0,
  waitListPosition: 4,
};

const myBooking: MyBooking = {
  id: rosterBooking.id,
  classId: summary.id,
  className: summary.name,
  classType: summary.type,
  trainerName: summary.trainerName,
  room: summary.room,
  startsAt: summary.startsAt,
  endsAt: summary.endsAt,
  bookingStatus: 'Confirmed',
  classStatus: 'Scheduled',
  isWaitListed: false,
  canCancel: true,
  checkedInAt: null,
};

function gatewayMock(): ClassesGateway {
  return {
    list: vi.fn(async () => page),
    catalogue: vi.fn(async () => catalogue),
    byId: vi.fn(async () => detail),
    book: vi.fn(async () => bookingResult),
    cancelBooking: vi.fn(async () => undefined),
    myBookings: vi.fn(async () => [myBooking]),
    schedule: vi.fn(async () => summary.id),
    update: vi.fn(async () => undefined),
    cancelClass: vi.fn(async () => undefined),
    promoteBooking: vi.fn(async () => undefined),
    markAttendance: vi.fn(async () => undefined),
  };
}

function setup() {
  const gateway = gatewayMock();
  TestBed.configureTestingModule({
    providers: [
      ClassesFacade,
      { provide: CLASSES_GATEWAY, useValue: gateway },
    ],
  });

  return { gateway, facade: TestBed.inject(ClassesFacade) };
}

describe('ClassesFacade', () => {
  it('loads the schedule, catalogue and computed capacity stats', async () => {
    const { facade, gateway } = setup();

    await facade.load();

    expect(gateway.list).toHaveBeenCalledWith({ page: 1, pageSize: 50 });
    expect(facade.classes()).toEqual([summary]);
    expect(facade.catalogue()).toEqual(catalogue);
    expect(facade.total()).toBe(1);
    expect(facade.nextClass()?.name).toBe('Sunrise Yoga');
    expect(facade.openSpots()).toBe(4);
    expect(facade.occupancy()).toBe(75);
    expect(facade.loading()).toBe(false);
  });

  it('merges filters and reloads the schedule', async () => {
    const { facade, gateway } = setup();

    await facade.updateQuery({ type: 'Yoga', page: 2 });

    expect(facade.query()).toEqual({ page: 2, pageSize: 50, type: 'Yoga' });
    expect(gateway.list).toHaveBeenCalledWith({ page: 2, pageSize: 50, type: 'Yoga' });
    expect(gateway.catalogue).toHaveBeenCalledTimes(1);
  });

  it('books a full class, joins the waitlist and refreshes the detail', async () => {
    const { facade, gateway } = setup();
    gateway.byId = vi.fn(async () => fullDetail);
    await facade.loadDetail(fullDetail.id);

    const booked = await facade.book(fullDetail.id, 'Maya Thompson');

    expect(booked).toBe(true);
    expect(gateway.book).toHaveBeenCalledWith(fullDetail.id, { memberName: 'Maya Thompson' });
    expect(gateway.byId).toHaveBeenLastCalledWith(fullDetail.id);
    expect(facade.notice()).toContain('waitlist at position 4');
    expect(facade.actionLoading()).toBe(false);
  });

  it('cancels a booking and refreshes bookings and detail', async () => {
    const { facade, gateway } = setup();
    await facade.loadDetail(summary.id);
    await facade.loadMyBookings();

    const cancelled = await facade.cancelBooking(rosterBooking.id, summary.id);

    expect(cancelled).toBe(true);
    expect(gateway.cancelBooking).toHaveBeenCalledWith(rosterBooking.id, 'Cancelled by member');
    expect(gateway.byId).toHaveBeenLastCalledWith(summary.id);
    expect(gateway.myBookings).toHaveBeenLastCalledWith('upcoming');
    expect(facade.notice()).toContain('Booking cancelled');
  });

  it('loads upcoming and past member bookings', async () => {
    const { facade, gateway } = setup();

    await facade.loadMyBookings('past');

    expect(gateway.myBookings).toHaveBeenCalledWith('past');
    expect(facade.bookingsScope()).toBe('past');
    expect(facade.myBookings()).toEqual([myBooking]);
    expect(facade.confirmedBookings()).toBe(1);
    expect(facade.waitListedBookings()).toBe(0);
  });

  it('surfaces API failures as an error message', async () => {
    const { facade, gateway } = setup();
    gateway.list = vi.fn(async () => {
      throw new Error('offline');
    });

    await facade.load();

    expect(facade.error()).toBe('The request failed. Try again.');
    expect(facade.classes()).toEqual([]);
    expect(facade.loading()).toBe(false);
  });
});
