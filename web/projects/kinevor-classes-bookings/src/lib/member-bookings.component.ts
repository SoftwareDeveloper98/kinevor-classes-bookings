import { ChangeDetectionStrategy, Component, OnInit, inject, signal } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { RouterLink } from '@angular/router';
import { BookingScope } from './class.model';
import { ClassesFacade } from './classes.facade';

@Component({
  selector: 'kinevor-member-bookings',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, MatButtonModule, MatIconModule, MatProgressSpinnerModule],
  template: `
    <div class="bookings-page">
      <header class="page-head">
        <div>
          <span class="eyebrow"><span class="pulse-dot"></span> Your training</span>
          <h1>My bookings</h1>
          <p>Keep track of confirmed seats, waitlists and the sessions you’ve completed.</p>
        </div>
        <a mat-flat-button color="primary" routerLink="/classes">
          <mat-icon>add</mat-icon>
          Book a class
        </a>
      </header>

      <div class="scope-tabs" role="tablist" aria-label="Booking history">
        <button
          role="tab"
          [attr.aria-selected]="scope() === 'upcoming'"
          [class.active]="scope() === 'upcoming'"
          (click)="show('upcoming')">
          Upcoming
        </button>
        <button
          role="tab"
          [attr.aria-selected]="scope() === 'past'"
          [class.active]="scope() === 'past'"
          (click)="show('past')">
          Past sessions
        </button>
      </div>

      @if (facade.myBookingsError() || facade.actionError(); as error) {
        <div class="notice error" role="alert">
          <mat-icon>error_outline</mat-icon>
          <span>{{ error }}</span>
          <button type="button" (click)="reload()">Try again</button>
        </div>
      }

      @if (facade.notice(); as notice) {
        <div class="notice success" role="status">
          <mat-icon>check_circle</mat-icon>
          <span>{{ notice }}</span>
          <button type="button" (click)="facade.clearNotice()" aria-label="Dismiss message">Dismiss</button>
        </div>
      }

      @if (facade.myBookingsLoading()) {
        <div class="booking-list">
          @for (item of [1, 2, 3]; track item) {
            <div class="skeleton-row"></div>
          }
        </div>
      } @else if (facade.myBookings().length === 0) {
        <div class="empty-state">
          <span class="empty-icon"><mat-icon>{{ scope() === 'upcoming' ? 'event_available' : 'history' }}</mat-icon></span>
          <h2>{{ scope() === 'upcoming' ? 'No upcoming bookings' : 'No past sessions yet' }}</h2>
          <p>
            {{ scope() === 'upcoming'
              ? 'Pick a session from the timetable and your seat will appear here.'
              : 'Your completed and cancelled sessions will be collected here.' }}
          </p>
          @if (scope() === 'upcoming') {
            <a mat-flat-button color="primary" routerLink="/classes">Browse classes</a>
          }
        </div>
      } @else {
        <div class="booking-list">
          @for (booking of facade.myBookings(); track booking.id) {
            <article class="booking-row" [class]="'booking-row type-' + typeClass(booking.classType)">
              <div class="date-tile">
                <span>{{ formatDay(booking.startsAt) }}</span>
                <strong>{{ formatDateNumber(booking.startsAt) }}</strong>
                <span>{{ formatMonth(booking.startsAt) }}</span>
              </div>

              <div class="booking-main">
                <div class="booking-tags">
                  <span class="type-chip">{{ typeLabel(booking.classType) }}</span>
                  <span class="status-chip" [class.wait]="booking.isWaitListed" [class.past]="scope() === 'past'">
                    {{ statusLabel(booking) }}
                  </span>
                </div>
                <h2>{{ booking.className }}</h2>
                <div class="booking-meta">
                  <span><mat-icon>schedule</mat-icon>{{ formatTime(booking.startsAt) }} – {{ formatTime(booking.endsAt) }}</span>
                  <span><mat-icon>person</mat-icon>{{ booking.trainerName }}</span>
                  <span><mat-icon>meeting_room</mat-icon>{{ booking.room }}</span>
                </div>
                @if (booking.isWaitListed) {
                  <p class="wait-note">
                    <mat-icon>hourglass_top</mat-icon>
                    You’re on the waitlist. We’ll move you into a seat automatically when one opens.
                  </p>
                }
              </div>

              <div class="booking-actions">
                <a mat-button [routerLink]="['/classes', booking.classId]">View class</a>
                @if (booking.canCancel) {
                  <button mat-stroked-button color="warn" type="button" (click)="cancel(booking.id, booking.isWaitListed)">
                    {{ booking.isWaitListed ? 'Leave waitlist' : 'Cancel' }}
                  </button>
                }
              </div>
            </article>
          }
        </div>
      }
    </div>
  `,
  styles: [`
    :host { display: block; }
    .bookings-page { max-width: 1040px; margin: 0 auto; padding: 40px 24px 80px; }
    .page-head { display: flex; justify-content: space-between; align-items: flex-end; gap: 24px; }
    .eyebrow { display: inline-flex; align-items: center; gap: 8px; color: var(--color-accent-text); font-size: 10px; font-weight: 800; letter-spacing: .16em; text-transform: uppercase; }
    .pulse-dot { width: 7px; height: 7px; border-radius: 50%; background: var(--color-accent-fill); box-shadow: 0 0 0 4px color-mix(in srgb, var(--color-accent-fill) 14%, transparent); }
    h1 { margin: 14px 0 8px; font-size: clamp(38px, 5vw, 54px); line-height: 1; letter-spacing: -.05em; color: var(--color-text); }
    .page-head p { margin: 0; max-width: 54ch; color: var(--color-text-muted); line-height: 1.65; font-size: 14px; }
    .scope-tabs { display: inline-flex; gap: 4px; margin: 30px 0 18px; padding: 4px; border: 1px solid var(--color-border); border-radius: 999px; background: var(--color-surface); }
    .scope-tabs button { min-height: 36px; border: 0; border-radius: 999px; background: transparent; color: var(--color-text-muted); padding: 0 18px; font: inherit; font-size: 12px; font-weight: 700; cursor: pointer; }
    .scope-tabs button.active { background: var(--color-accent-fill); color: var(--color-on-accent); }
    .booking-list { display: flex; flex-direction: column; gap: 12px; }
    .booking-row { --class-accent: var(--color-cat-default); display: grid; grid-template-columns: 74px minmax(0, 1fr) auto; gap: 18px; align-items: center; border: 1px solid var(--color-border); border-left: 4px solid var(--class-accent); border-radius: 20px; padding: 18px 20px; background: var(--color-surface-raised); }
    .type-yoga { --class-accent: var(--color-cat-yoga); }
    .type-pilates { --class-accent: var(--color-cat-pilates); }
    .type-zumba { --class-accent: var(--color-cat-zumba); }
    .type-hiit { --class-accent: var(--color-cat-hiit); }
    .type-spinning { --class-accent: var(--color-cat-spinning); }
    .type-boxing { --class-accent: var(--color-cat-boxing); }
    .type-crossfit { --class-accent: var(--color-cat-crossfit); }
    .type-aqua { --class-accent: var(--color-cat-aqua); }
    .type-bodypump { --class-accent: var(--color-cat-bodypump); }
    .type-kickboxing { --class-accent: var(--color-cat-kickboxing); }
    .type-stretching { --class-accent: var(--color-cat-stretching); }
    .type-meditation { --class-accent: var(--color-cat-meditation); }
    .date-tile { display: flex; flex-direction: column; align-items: center; justify-content: center; min-height: 86px; border-radius: 14px; background: var(--color-surface); border: 1px solid var(--color-border); }
    .date-tile span { font-size: 9px; font-weight: 800; letter-spacing: .13em; color: var(--color-text-muted); }
    .date-tile strong { font-size: 28px; line-height: 1.15; color: var(--color-text); }
    .booking-main { min-width: 0; }
    .booking-tags { display: flex; flex-wrap: wrap; align-items: center; gap: 7px; }
    .type-chip { border-radius: 999px; padding: 3px 9px; background: color-mix(in srgb, var(--class-accent) 16%, transparent); color: var(--class-accent); font-size: 9px; font-weight: 800; letter-spacing: .08em; text-transform: uppercase; }
    .status-chip { border-radius: 999px; padding: 3px 9px; background: color-mix(in srgb, var(--color-success) 13%, transparent); color: var(--color-success); font-size: 9px; font-weight: 800; letter-spacing: .06em; text-transform: uppercase; }
    .status-chip.wait { background: color-mix(in srgb, var(--color-warning) 13%, transparent); color: var(--color-warning); }
    .status-chip.past { background: var(--color-surface); color: var(--color-text-muted); }
    .booking-main h2 { margin: 7px 0 7px; font-size: 19px; letter-spacing: -.025em; color: var(--color-text); }
    .booking-meta { display: flex; flex-wrap: wrap; gap: 10px 16px; color: var(--color-text-muted); font-size: 11px; }
    .booking-meta span { display: inline-flex; align-items: center; gap: 4px; }
    .booking-meta mat-icon { font-size: 14px; width: 14px; height: 14px; }
    .wait-note { display: flex; align-items: center; gap: 5px; margin: 9px 0 0; color: var(--color-warning); font-size: 10px; line-height: 1.45; }
    .wait-note mat-icon { font-size: 14px; width: 14px; height: 14px; }
    .booking-actions { display: flex; flex-direction: column; gap: 8px; align-items: stretch; min-width: 124px; }
    .booking-actions a, .booking-actions button { font-size: 11px; }
    .notice { display: flex; align-items: center; gap: 10px; padding: 13px 17px; border-radius: 14px; margin-bottom: 16px; font-size: 13px; }
    .notice.success { background: color-mix(in srgb, var(--color-success) 10%, transparent); border: 1px solid color-mix(in srgb, var(--color-success) 36%, transparent); color: var(--color-success); }
    .notice.error { background: color-mix(in srgb, var(--color-error) 10%, transparent); border: 1px solid color-mix(in srgb, var(--color-error) 36%, transparent); color: var(--color-error); }
    .notice button { margin-left: auto; border: 0; background: none; color: inherit; font: inherit; font-weight: 700; cursor: pointer; }
    .skeleton-row { height: 124px; border-radius: 20px; background: linear-gradient(90deg, var(--color-surface) 25%, var(--color-surface-raised) 50%, var(--color-surface) 75%); background-size: 200% 100%; animation: shimmer 1.4s infinite; }
    @keyframes shimmer { from { background-position: 200% 0; } to { background-position: -200% 0; } }
    .empty-state { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 8px; min-height: 380px; text-align: center; border: 1px dashed var(--color-border); border-radius: 24px; background: var(--color-surface); padding: 24px; }
    .empty-icon { width: 74px; height: 74px; display: grid; place-items: center; border-radius: 50%; background: var(--color-accent-soft); color: var(--color-accent-text); margin-bottom: 6px; }
    .empty-icon mat-icon { font-size: 32px; width: 32px; height: 32px; }
    .empty-state h2 { margin: 0; color: var(--color-text); font-size: 22px; letter-spacing: -.03em; }
    .empty-state p { margin: 0 0 10px; max-width: 44ch; color: var(--color-text-muted); font-size: 13px; line-height: 1.6; }
    @media (max-width: 760px) { .bookings-page { padding: 24px 14px 60px; } .page-head { align-items: flex-start; flex-direction: column; } .booking-row { grid-template-columns: 62px minmax(0, 1fr); gap: 14px; padding: 16px; } .booking-actions { grid-column: 1 / -1; flex-direction: row; justify-content: flex-end; } }
  `],
})
export class MemberBookingsComponent implements OnInit {
  readonly facade = inject(ClassesFacade);
  readonly scope = signal<BookingScope>('upcoming');

  ngOnInit(): void {
    void this.facade.loadMyBookings(this.scope());
  }

  show(scope: BookingScope): void {
    this.scope.set(scope);
    void this.facade.loadMyBookings(scope);
  }

  reload(): void {
    void this.facade.loadMyBookings(this.scope());
  }

  cancel(bookingId: string, isWaitListed: boolean): void {
    const prompt = isWaitListed ? 'Leave this waitlist?' : 'Cancel this booking? Your seat may be offered to the waitlist.';
    if (window.confirm(prompt)) void this.facade.cancelBooking(bookingId);
  }

  typeLabel(type: string): string {
    return type === 'BodyPump' ? 'Body Pump' : type;
  }

  typeClass(type: string): string {
    return type.toLowerCase();
  }

  statusLabel(booking: { bookingStatus: string; classStatus: string; isWaitListed: boolean }): string {
    if (booking.isWaitListed) return 'Waitlisted';
    if (booking.classStatus === 'Completed') return 'Completed';
    if (booking.classStatus === 'Cancelled') return 'Class cancelled';
    if (booking.bookingStatus === 'Attended') return 'Attended';
    if (booking.bookingStatus === 'NoShow') return 'No show';
    if (booking.bookingStatus === 'Cancelled') return 'Cancelled';
    return 'Confirmed';
  }

  formatDay(value: string): string {
    return new Intl.DateTimeFormat('en-GB', { weekday: 'short' }).format(new Date(value)).toUpperCase();
  }

  formatMonth(value: string): string {
    return new Intl.DateTimeFormat('en-GB', { month: 'short' }).format(new Date(value)).toUpperCase();
  }

  formatDateNumber(value: string): string {
    return new Intl.DateTimeFormat('en-GB', { day: '2-digit' }).format(new Date(value));
  }

  formatTime(value: string): string {
    return new Intl.DateTimeFormat('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false })
      .format(new Date(value));
  }
}
