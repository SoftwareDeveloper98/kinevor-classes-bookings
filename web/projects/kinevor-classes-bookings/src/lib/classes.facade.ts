import { Injectable, computed, inject, signal } from '@angular/core';
import {
  BookingScope,
  CatalogueItem,
  ClassListQuery,
  CLASSES_GATEWAY,
  CLASSES_MEMBER_NAME,
  GymClassDetail,
  GymClassSummary,
  MyBooking,
} from './class.model';

function messageOf(error: unknown): string {
  const candidate = error as { error?: { message?: string }; message?: string } | null;
  return candidate?.error?.message ?? 'The request failed. Try again.';
}

@Injectable()
export class ClassesFacade {
  private readonly gateway = inject(CLASSES_GATEWAY);
  private readonly defaultMemberName = inject(CLASSES_MEMBER_NAME);

  private readonly classesState = signal<readonly GymClassSummary[]>([]);
  private readonly catalogueState = signal<readonly CatalogueItem[]>([]);
  private readonly totalState = signal(0);
  private readonly loadingState = signal(false);
  private readonly errorState = signal<string | null>(null);
  private readonly detailState = signal<GymClassDetail | null>(null);
  private readonly detailLoadingState = signal(false);
  private readonly actionLoadingState = signal(false);
  private readonly actionErrorState = signal<string | null>(null);
  private readonly noticeState = signal<string | null>(null);
  private readonly myBookingsState = signal<readonly MyBooking[]>([]);
  private readonly myBookingsLoadingState = signal(false);
  private readonly myBookingsErrorState = signal<string | null>(null);
  private readonly bookingsScopeState = signal<BookingScope>('upcoming');
  private readonly queryState = signal<ClassListQuery>({ page: 1, pageSize: 50 });

  readonly classes = this.classesState.asReadonly();
  readonly catalogue = this.catalogueState.asReadonly();
  readonly total = this.totalState.asReadonly();
  readonly loading = this.loadingState.asReadonly();
  readonly error = this.errorState.asReadonly();
  readonly detail = this.detailState.asReadonly();
  readonly detailLoading = this.detailLoadingState.asReadonly();
  readonly actionLoading = this.actionLoadingState.asReadonly();
  readonly actionError = this.actionErrorState.asReadonly();
  readonly notice = this.noticeState.asReadonly();
  readonly myBookings = this.myBookingsState.asReadonly();
  readonly myBookingsLoading = this.myBookingsLoadingState.asReadonly();
  readonly myBookingsError = this.myBookingsErrorState.asReadonly();
  readonly bookingsScope = this.bookingsScopeState.asReadonly();
  readonly query = this.queryState.asReadonly();

  readonly nextClass = computed(() => this.classesState()[0] ?? null);
  readonly openSpots = computed(() =>
    this.classesState().reduce((total, gymClass) => total + gymClass.availableSpots, 0));
  readonly waitListCount = computed(() =>
    this.classesState().reduce((total, gymClass) => total + gymClass.waitListCount, 0));
  readonly occupancy = computed(() => {
    const classes = this.classesState();
    const capacity = classes.reduce((total, gymClass) => total + gymClass.capacity, 0);
    const booked = classes.reduce((total, gymClass) => total + gymClass.bookedCount, 0);
    return capacity === 0 ? 0 : Math.round((booked / capacity) * 100);
  });
  readonly confirmedBookings = computed(() =>
    this.myBookingsState().filter((booking) => booking.bookingStatus === 'Confirmed').length);
  readonly waitListedBookings = computed(() =>
    this.myBookingsState().filter((booking) => booking.isWaitListed).length);

  async load(override: Partial<ClassListQuery> = {}): Promise<void> {
    const query = { ...this.queryState(), ...override };
    this.queryState.set(query);
    this.loadingState.set(true);
    this.errorState.set(null);

    try {
      const [page, catalogue] = await Promise.all([
        this.gateway.list(query),
        this.gateway.catalogue(),
      ]);
      this.classesState.set(page.items);
      this.totalState.set(page.totalCount);
      this.catalogueState.set(catalogue);
    } catch (error) {
      this.classesState.set([]);
      this.errorState.set(messageOf(error));
    } finally {
      this.loadingState.set(false);
    }
  }

  updateQuery(partial: Partial<ClassListQuery>): Promise<void> {
    return this.load(partial);
  }

  async loadDetail(id: string): Promise<void> {
    this.detailLoadingState.set(true);
    this.actionErrorState.set(null);
    this.noticeState.set(null);

    try {
      this.detailState.set(await this.gateway.byId(id));
    } catch (error) {
      this.detailState.set(null);
      this.actionErrorState.set(messageOf(error));
    } finally {
      this.detailLoadingState.set(false);
    }
  }

  async book(classId: string, memberName?: string): Promise<boolean> {
    this.actionLoadingState.set(true);
    this.actionErrorState.set(null);
    this.noticeState.set(null);

    try {
      const result = await this.gateway.book(classId, { memberName: memberName ?? this.defaultMemberName });
      await this.loadDetail(classId);
      this.noticeState.set(
        result.isWaitListed
          ? `You joined the waitlist at position ${result.waitListPosition}.`
          : 'Your seat is confirmed.',
      );
      return true;
    } catch (error) {
      this.actionErrorState.set(messageOf(error));
      return false;
    } finally {
      this.actionLoadingState.set(false);
    }
  }

  async cancelBooking(bookingId: string, classId?: string): Promise<boolean> {
    this.actionLoadingState.set(true);
    this.actionErrorState.set(null);
    this.noticeState.set(null);

    try {
      await this.gateway.cancelBooking(bookingId, 'Cancelled by member');
      if (classId) await this.loadDetail(classId);
      if (this.myBookingsState().length > 0) await this.loadMyBookings(this.bookingsScopeState());
      this.noticeState.set('Booking cancelled. A waitlisted member may take the seat.');
      return true;
    } catch (error) {
      this.actionErrorState.set(messageOf(error));
      return false;
    } finally {
      this.actionLoadingState.set(false);
    }
  }

  async loadMyBookings(scope: BookingScope = 'upcoming'): Promise<void> {
    this.bookingsScopeState.set(scope);
    this.myBookingsLoadingState.set(true);
    this.myBookingsErrorState.set(null);

    try {
      this.myBookingsState.set(await this.gateway.myBookings(scope));
    } catch (error) {
      this.myBookingsState.set([]);
      this.myBookingsErrorState.set(messageOf(error));
    } finally {
      this.myBookingsLoadingState.set(false);
    }
  }

  clearNotice(): void {
    this.noticeState.set(null);
  }
}
