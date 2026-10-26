import { HttpClient, HttpParams } from '@angular/common/http';
import { Injectable, inject } from '@angular/core';
import { firstValueFrom } from 'rxjs';
import {
  ApiEnvelope,
  BookClassInput,
  BookClassResult,
  BookingScope,
  CatalogueItem,
  ClassListQuery,
  CLASSES_API_BASE_URL,
  ClassesGateway,
  ClassScheduleInput,
  GymClassDetail,
  GymClassSummary,
  MyBooking,
  PagedResult,
} from './class.model';

@Injectable()
export class HttpClassesGateway implements ClassesGateway {
  private readonly http = inject(HttpClient);
  private readonly baseUrl = inject(CLASSES_API_BASE_URL).replace(/\/$/, '');

  async list(query: ClassListQuery): Promise<PagedResult<GymClassSummary>> {
    let params = new HttpParams()
      .set('page', query.page ?? 1)
      .set('pageSize', query.pageSize ?? 20);

    if (query.type) params = params.set('type', query.type);
    if (query.status) params = params.set('status', query.status);
    if (query.fromDate) params = params.set('fromDate', query.fromDate);
    if (query.toDate) params = params.set('toDate', query.toDate);

    const response = await firstValueFrom(
      this.http.get<ApiEnvelope<PagedResult<GymClassSummary>>>(`${this.baseUrl}/classes`, { params }),
    );
    return response.data;
  }

  async catalogue(): Promise<readonly CatalogueItem[]> {
    const response = await firstValueFrom(
      this.http.get<ApiEnvelope<readonly CatalogueItem[]>>(`${this.baseUrl}/classes/catalogue`),
    );
    return response.data;
  }

  async byId(id: string): Promise<GymClassDetail> {
    const response = await firstValueFrom(
      this.http.get<ApiEnvelope<GymClassDetail>>(`${this.baseUrl}/classes/${id}`),
    );
    return response.data;
  }

  async book(classId: string, input: BookClassInput): Promise<BookClassResult> {
    const response = await firstValueFrom(
      this.http.post<ApiEnvelope<BookClassResult>>(`${this.baseUrl}/classes/${classId}/bookings`, input),
    );
    return response.data;
  }

  async cancelBooking(bookingId: string, reason?: string): Promise<void> {
    const params = reason ? new HttpParams().set('reason', reason) : undefined;
    await firstValueFrom(
      this.http.delete<ApiEnvelope<unknown>>(`${this.baseUrl}/bookings/${bookingId}`, { params }),
    );
  }

  async myBookings(scope: BookingScope): Promise<readonly MyBooking[]> {
    const params = new HttpParams().set('scope', scope);
    const response = await firstValueFrom(
      this.http.get<ApiEnvelope<readonly MyBooking[]>>(`${this.baseUrl}/me/bookings`, { params }),
    );
    return response.data;
  }

  async schedule(input: ClassScheduleInput): Promise<string> {
    const response = await firstValueFrom(
      this.http.post<ApiEnvelope<string>>(`${this.baseUrl}/classes`, input),
    );
    return response.data;
  }

  async update(classId: string, input: ClassScheduleInput): Promise<void> {
    await firstValueFrom(
      this.http.put<ApiEnvelope<unknown>>(`${this.baseUrl}/classes/${classId}`, input),
    );
  }

  async cancelClass(classId: string, reason?: string): Promise<void> {
    await firstValueFrom(
      this.http.post<ApiEnvelope<unknown>>(`${this.baseUrl}/classes/${classId}/cancel`, { reason }),
    );
  }

  async promoteBooking(bookingId: string): Promise<void> {
    await firstValueFrom(
      this.http.post<ApiEnvelope<unknown>>(`${this.baseUrl}/bookings/${bookingId}/promote`, {}),
    );
  }

  async markAttendance(bookingId: string, attended: boolean): Promise<void> {
    await firstValueFrom(
      this.http.patch<ApiEnvelope<unknown>>(`${this.baseUrl}/bookings/${bookingId}/attendance`, { attended }),
    );
  }
}
