import { InjectionToken, Type } from '@angular/core';

export interface ApiEnvelope<T> {
  readonly success: boolean;
  readonly data: T;
  readonly message?: string | null;
  readonly errors?: readonly string[] | null;
}

export interface PagedResult<T> {
  readonly items: readonly T[];
  readonly totalCount: number;
  readonly page: number;
  readonly pageSize: number;
  readonly totalPages: number;
  readonly hasNext: boolean;
  readonly hasPrev: boolean;
}

export type ClassType =
  | 'Yoga'
  | 'Pilates'
  | 'Zumba'
  | 'HIIT'
  | 'Spinning'
  | 'Boxing'
  | 'CrossFit'
  | 'Aqua'
  | 'BodyPump'
  | 'Kickboxing'
  | 'Stretching'
  | 'Meditation';

export type ClassStatus = 'Scheduled' | 'InProgress' | 'Completed' | 'Cancelled';

export type BookingStatus = 'Confirmed' | 'Cancelled' | 'Attended' | 'NoShow' | 'WaitListed';

export type BookingScope = 'upcoming' | 'past';

export interface GymClassSummary {
  readonly id: string;
  readonly name: string;
  readonly description: string | null;
  readonly type: ClassType;
  readonly trainerId: string;
  readonly trainerName: string;
  readonly startsAt: string;
  readonly endsAt: string;
  readonly durationMinutes: number;
  readonly capacity: number;
  readonly bookedCount: number;
  readonly availableSpots: number;
  readonly waitListCount: number;
  readonly status: ClassStatus;
  readonly room: string;
  readonly requiresMembership: boolean;
  readonly isFull: boolean;
  readonly isOpenForBooking: boolean;
}

export interface Booking {
  readonly id: string;
  readonly classId: string;
  readonly className: string;
  readonly classStartsAt: string;
  readonly memberId: string;
  readonly memberName: string;
  readonly status: BookingStatus;
  readonly isWaitListed: boolean;
  readonly bookedAt: string;
  readonly cancelledAt: string | null;
  readonly cancellationReason: string | null;
  readonly checkedInAt: string | null;
}

export interface GymClassDetail extends GymClassSummary {
  readonly notes: string | null;
  readonly roster: readonly Booking[];
  readonly myBooking: Booking | null;
}

export interface CatalogueItem {
  readonly type: ClassType;
  readonly upcomingSessions: number;
  readonly nextStartsAt: string | null;
  readonly nextClassName: string | null;
}

export interface BookClassResult {
  readonly bookingId: string;
  readonly isWaitListed: boolean;
  readonly status: BookingStatus;
  readonly availableSpots: number;
  readonly waitListPosition: number;
}

export interface MyBooking {
  readonly id: string;
  readonly classId: string;
  readonly className: string;
  readonly classType: ClassType;
  readonly trainerName: string;
  readonly room: string;
  readonly startsAt: string;
  readonly endsAt: string;
  readonly bookingStatus: BookingStatus;
  readonly classStatus: ClassStatus;
  readonly isWaitListed: boolean;
  readonly canCancel: boolean;
  readonly checkedInAt: string | null;
}

export interface ClassListQuery {
  readonly type?: string;
  readonly status?: string;
  readonly fromDate?: string;
  readonly toDate?: string;
  readonly page?: number;
  readonly pageSize?: number;
}

export interface BookClassInput {
  readonly memberId?: string;
  readonly memberName?: string;
}

export interface ClassScheduleInput {
  readonly name: string;
  readonly description?: string | null;
  readonly type: string;
  readonly trainerId: string;
  readonly trainerName: string;
  readonly startsAt: string;
  readonly durationMinutes: number;
  readonly capacity: number;
  readonly room: string;
  readonly notes?: string | null;
  readonly requiresMembership: boolean;
}

export interface ClassesGateway {
  list(query: ClassListQuery): Promise<PagedResult<GymClassSummary>>;
  catalogue(): Promise<readonly CatalogueItem[]>;
  byId(id: string): Promise<GymClassDetail>;
  book(classId: string, input: BookClassInput): Promise<BookClassResult>;
  cancelBooking(bookingId: string, reason?: string): Promise<void>;
  myBookings(scope: BookingScope): Promise<readonly MyBooking[]>;
  schedule(input: ClassScheduleInput): Promise<string>;
  update(classId: string, input: ClassScheduleInput): Promise<void>;
  cancelClass(classId: string, reason?: string): Promise<void>;
  promoteBooking(bookingId: string): Promise<void>;
  markAttendance(bookingId: string, attended: boolean): Promise<void>;
}

export const CLASSES_API_BASE_URL = new InjectionToken<string>('CLASSES_API_BASE_URL');
export const CLASSES_GATEWAY = new InjectionToken<ClassesGateway>('CLASSES_GATEWAY');
export const CLASSES_MEMBER_NAME = new InjectionToken<string>('CLASSES_MEMBER_NAME', {
  providedIn: 'root',
  factory: () => 'Kinevor member',
});

export interface ClassesOptions {
  readonly apiBaseUrl?: string;
  readonly gateway?: Type<ClassesGateway>;
  readonly memberName?: string;
}
