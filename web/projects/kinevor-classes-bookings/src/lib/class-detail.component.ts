import { ChangeDetectionStrategy, Component, OnInit, inject } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { ActivatedRoute, RouterLink } from '@angular/router';
import { ClassesFacade } from './classes.facade';

@Component({
  selector: 'kinevor-class-detail',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, MatButtonModule, MatIconModule, MatProgressSpinnerModule],
  template: `
    <div class="detail-page">
      <a class="back-link" routerLink="/classes">
        <mat-icon>arrow_back</mat-icon>
        Back to schedule
      </a>

      @if (facade.detailLoading() && !facade.detail()) {
        <div class="loading-state">
          <mat-spinner diameter="36"></mat-spinner>
          <span>Loading class…</span>
        </div>
      } @else if (facade.actionError() && !facade.detail()) {
        <div class="notice error" role="alert">
          <mat-icon>error_outline</mat-icon>
          <span>{{ facade.actionError() }}</span>
          <button type="button" (click)="reload()">Try again</button>
        </div>
      } @else if (facade.detail(); as detail) {
        <section class="hero" [class]="'hero type-' + typeClass(detail.type)">
          <div class="hero-glow"></div>
          <div class="hero-copy">
            <div class="hero-tags">
              <span class="type-chip">{{ typeLabel(detail.type) }}</span>
              <span class="status-chip" [class]="statusClass(detail.status)">{{ statusLabel(detail.status) }}</span>
              @if (detail.requiresMembership) {
                <span class="members-chip"><mat-icon>verified</mat-icon> Membership class</span>
              }
            </div>
            <h1>{{ detail.name }}</h1>
            <p class="hero-description">{{ detail.description ?? 'A focused group session led by the Kinevor training team.' }}</p>
            <div class="hero-facts">
              <span><mat-icon>calendar_today</mat-icon>{{ formatFullDate(detail.startsAt) }}</span>
              <span><mat-icon>schedule</mat-icon>{{ formatTime(detail.startsAt) }} – {{ formatTime(detail.endsAt) }}</span>
              <span><mat-icon>meeting_room</mat-icon>{{ detail.room }}</span>
            </div>
          </div>
          <div class="hero-trainer">
            <span class="trainer-avatar">{{ initials(detail.trainerName) }}</span>
            <div>
              <span class="trainer-label">Your trainer</span>
              <strong>{{ detail.trainerName }}</strong>
            </div>
            <span class="duration">{{ detail.durationMinutes }} min</span>
          </div>
        </section>

        @if (facade.notice(); as notice) {
          <div class="notice success" role="status">
            <mat-icon>check_circle</mat-icon>
            <span>{{ notice }}</span>
            <button type="button" (click)="facade.clearNotice()" aria-label="Dismiss message">Dismiss</button>
          </div>
        }
        @if (facade.actionError(); as error) {
          <div class="notice error" role="alert">
            <mat-icon>error_outline</mat-icon>
            <span>{{ error }}</span>
          </div>
        }

        <div class="content-grid">
          <div class="main-column">
            <section class="panel">
              <div class="panel-head">
                <div>
                  <span class="eyebrow">Live capacity</span>
                  <h2>Seats and waitlist</h2>
                </div>
                <strong [class.full]="detail.isFull">{{ detail.isFull ? 'Full' : detail.availableSpots + ' left' }}</strong>
              </div>
              <div class="capacity-stats">
                <div>
                  <span class="capacity-value">{{ detail.bookedCount }}</span>
                  <span>Confirmed</span>
                </div>
                <div>
                  <span class="capacity-value">{{ detail.capacity }}</span>
                  <span>Capacity</span>
                </div>
                <div>
                  <span class="capacity-value wait">{{ detail.waitListCount }}</span>
                  <span>Waiting</span>
                </div>
              </div>
              <div
                class="meter"
                role="progressbar"
                aria-label="Seats booked"
                [attr.aria-valuenow]="detail.bookedCount"
                [attr.aria-valuemin]="0"
                [attr.aria-valuemax]="detail.capacity">
                <span [style.width.%]="occupancy(detail.bookedCount, detail.capacity)"></span>
              </div>
              <p class="policy">
                <mat-icon>info</mat-icon>
                Confirmed bookings can be cancelled up to two hours before the session. Waitlist promotions happen automatically.
              </p>
            </section>

            @if (detail.notes) {
              <section class="panel notes-panel">
                <span class="eyebrow">Before you arrive</span>
                <h2>Session notes</h2>
                <p>{{ detail.notes }}</p>
              </section>
            }

            <section class="panel roster-panel">
              <div class="panel-head">
                <div>
                  <span class="eyebrow">Class roster</span>
                  <h2>Who's coming</h2>
                </div>
                <span class="count">{{ detail.roster.length }} booked</span>
              </div>

              @if (detail.roster.length === 0) {
                <div class="roster-empty">
                  <mat-icon>group_off</mat-icon>
                  <span>Roster details are available to the Kinevor team.</span>
                </div>
              } @else {
                <div class="roster-list">
                  @for (booking of detail.roster; track booking.id) {
                    <div class="roster-row">
                      <span class="member-avatar">{{ initials(booking.memberName) }}</span>
                      <div class="member-copy">
                        <strong>{{ booking.memberName }}</strong>
                        <span>Booked {{ formatShortDate(booking.bookedAt) }}</span>
                      </div>
                      <span class="booking-chip" [class.wait]="booking.isWaitListed">
                        {{ booking.isWaitListed ? 'Waitlist' : booking.status }}
                      </span>
                    </div>
                  }
                </div>
              }
            </section>
          </div>

          <aside class="booking-column">
            <section class="booking-card">
              <span class="eyebrow">{{ detail.myBooking ? 'Your booking' : 'Reserve your place' }}</span>
              <h2>{{ detail.myBooking ? 'You’re on the list' : 'Ready to move?' }}</h2>

              @if (detail.myBooking; as booking) {
                <div class="my-booking">
                  <span class="booking-status" [class.wait]="booking.isWaitListed">
                    {{ booking.isWaitListed ? 'Waitlisted' : 'Seat confirmed' }}
                  </span>
                  <p>
                    {{ booking.isWaitListed
                      ? 'We’ll promote you automatically when a seat opens. You can leave the waitlist at any time.'
                      : 'Your seat is held. Arrive ten minutes early and check in at reception.' }}
                  </p>
                  <div class="booking-meta">
                    <span><mat-icon>event</mat-icon>{{ formatFullDate(detail.startsAt) }}</span>
                    <span><mat-icon>schedule</mat-icon>{{ formatTime(detail.startsAt) }}</span>
                  </div>
                  <button
                    mat-stroked-button
                    color="warn"
                    type="button"
                    [disabled]="facade.actionLoading()"
                    (click)="cancel(booking.id)">
                    {{ booking.isWaitListed ? 'Leave waitlist' : 'Cancel booking' }}
                  </button>
                </div>
              } @else {
                <p class="booking-intro">
                  {{ detail.isFull
                    ? 'This session is full. Join the waitlist and we’ll automatically move you into a seat when one frees up.'
                    : 'Book now and your seat is confirmed instantly. Waitlist and cancellations update in real time.' }}
                </p>
                <div class="booking-facts">
                  <div><span>Seats left</span><strong>{{ detail.availableSpots }}</strong></div>
                  <div><span>Waitlist</span><strong>{{ detail.waitListCount }}</strong></div>
                </div>
                <button
                  mat-flat-button
                  color="primary"
                  class="book-button"
                  type="button"
                  [disabled]="!detail.isOpenForBooking || facade.actionLoading()"
                  (click)="book(detail.id)">
                  @if (facade.actionLoading()) {
                    <mat-spinner diameter="18"></mat-spinner>
                  } @else {
                    <span class="book-label">
                      <mat-icon>{{ detail.isFull ? 'hourglass_top' : 'event_available' }}</mat-icon>
                      {{ detail.isOpenForBooking ? (detail.isFull ? 'Join the waitlist' : 'Book this class') : 'Booking closed' }}
                    </span>
                  }
                </button>
              }

              <div class="reassure">
                <mat-icon>lock</mat-icon>
                <span>Bookings are tied to your Kinevor member profile. No payment is taken in this demo.</span>
              </div>
            </section>

            <section class="mini-panel">
              <span class="mini-icon"><mat-icon>fitness_center</mat-icon></span>
              <div>
                <strong>{{ typeLabel(detail.type) }}</strong>
                <span>{{ detail.durationMinutes }} minutes · {{ detail.room }}</span>
              </div>
            </section>
          </aside>
        </div>
      }
    </div>
  `,
  styles: [`
    :host { display: block; }
    .detail-page { max-width: 1240px; margin: 0 auto; padding: 24px 24px 80px; }
    .back-link { display: inline-flex; align-items: center; gap: 6px; color: var(--color-text-muted); font-size: 12px; font-weight: 600; text-decoration: none; margin-bottom: 18px; }
    .back-link:hover { color: var(--color-accent-text); }
    .back-link mat-icon { font-size: 18px; width: 18px; height: 18px; }
    .hero { --class-accent: var(--color-cat-default); position: relative; display: flex; align-items: flex-end; justify-content: space-between; gap: 24px; overflow: hidden; padding: 40px; border: 1px solid var(--color-border); border-radius: 28px; background: linear-gradient(135deg, color-mix(in srgb, var(--class-accent) 22%, var(--color-surface-raised)) 0%, var(--color-surface) 55%, var(--color-surface-raised) 100%); }
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
    .hero-glow { position: absolute; width: 360px; height: 360px; border-radius: 50%; right: 8%; top: -220px; background: color-mix(in srgb, var(--class-accent) 26%, transparent); filter: blur(100px); }
    .hero-copy, .hero-trainer { position: relative; z-index: 1; }
    .hero-copy { max-width: 690px; }
    .hero-tags { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; }
    .type-chip, .status-chip, .members-chip { display: inline-flex; align-items: center; gap: 4px; border-radius: 999px; padding: 5px 11px; font-size: 10px; font-weight: 800; letter-spacing: .08em; text-transform: uppercase; }
    .type-chip { background: color-mix(in srgb, var(--class-accent) 18%, transparent); color: var(--class-accent); border: 1px solid color-mix(in srgb, var(--class-accent) 32%, transparent); }
    .status-scheduled { background: color-mix(in srgb, var(--color-success) 14%, transparent); color: var(--color-success); }
    .status-inprogress { background: color-mix(in srgb, var(--color-warning) 14%, transparent); color: var(--color-warning); }
    .status-completed { background: var(--color-surface); color: var(--color-text-muted); }
    .status-cancelled { background: color-mix(in srgb, var(--color-error) 14%, transparent); color: var(--color-error); }
    .members-chip { background: var(--color-surface); color: var(--color-text-muted); letter-spacing: .02em; text-transform: none; font-weight: 600; }
    .members-chip mat-icon { font-size: 13px; width: 13px; height: 13px; color: var(--color-success); }
    h1 { margin: 16px 0 10px; font-size: clamp(38px, 5vw, 60px); line-height: 1.02; letter-spacing: -.05em; color: var(--color-text); }
    .hero-description { max-width: 60ch; margin: 0; color: var(--color-text-muted); line-height: 1.65; }
    .hero-facts { display: flex; flex-wrap: wrap; gap: 8px 18px; margin-top: 22px; color: var(--color-text); font-size: 12px; font-weight: 600; }
    .hero-facts span { display: inline-flex; align-items: center; gap: 6px; }
    .hero-facts mat-icon { font-size: 16px; width: 16px; height: 16px; color: var(--class-accent); }
    .hero-trainer { flex: none; display: flex; align-items: center; gap: 12px; border: 1px solid var(--color-border); border-radius: 18px; background: color-mix(in srgb, var(--color-bg) 66%, transparent); backdrop-filter: blur(8px); padding: 14px 16px; }
    .trainer-avatar { width: 44px; height: 44px; display: grid; place-items: center; border-radius: 50%; background: var(--class-accent); color: #111317; font-size: 13px; font-weight: 800; }
    .trainer-label { display: block; color: var(--color-text-muted); font-size: 9px; text-transform: uppercase; letter-spacing: .12em; font-weight: 700; }
    .hero-trainer strong { display: block; font-size: 13px; color: var(--color-text); }
    .duration { border-left: 1px solid var(--color-border); padding-left: 12px; color: var(--color-text-muted); font-size: 11px; font-weight: 700; }
    .content-grid { display: grid; grid-template-columns: minmax(0, 1.55fr) minmax(320px, .8fr); gap: 18px; margin-top: 18px; align-items: start; }
    .main-column, .booking-column { display: flex; flex-direction: column; gap: 18px; }
    .panel, .booking-card, .mini-panel { border: 1px solid var(--color-border); border-radius: 22px; background: var(--color-surface-raised); padding: 24px; }
    .panel-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 16px; }
    .eyebrow { color: var(--color-accent-text); font-size: 10px; font-weight: 800; letter-spacing: .14em; text-transform: uppercase; }
    .panel h2, .booking-card h2 { margin: 7px 0 0; font-size: 22px; letter-spacing: -.03em; color: var(--color-text); }
    .panel-head > strong { color: var(--color-success); font-size: 13px; }
    .panel-head > strong.full { color: var(--color-warning); }
    .capacity-stats { display: grid; grid-template-columns: repeat(3, 1fr); gap: 10px; margin: 20px 0 14px; }
    .capacity-stats div { border-radius: 14px; background: var(--color-surface); padding: 12px 14px; display: flex; flex-direction: column; gap: 2px; }
    .capacity-stats span:last-child { color: var(--color-text-muted); font-size: 10px; font-weight: 600; }
    .capacity-value { font-size: 24px; font-weight: 800; color: var(--color-text); }
    .capacity-value.wait { color: var(--color-warning); }
    .meter { height: 8px; border-radius: 999px; background: var(--color-surface); overflow: hidden; }
    .meter span { display: block; height: 100%; border-radius: inherit; background: linear-gradient(90deg, var(--color-accent-fill), var(--color-info)); }
    .policy { display: flex; align-items: flex-start; gap: 6px; margin: 16px 0 0; color: var(--color-text-muted); font-size: 11px; line-height: 1.55; }
    .policy mat-icon { font-size: 15px; width: 15px; height: 15px; flex: none; color: var(--color-info); }
    .notes-panel p { margin: 10px 0 0; color: var(--color-text-muted); line-height: 1.65; font-size: 13px; }
    .count { color: var(--color-text-muted); font-size: 11px; font-weight: 600; border: 1px solid var(--color-border); border-radius: 999px; padding: 4px 10px; white-space: nowrap; }
    .roster-list { display: flex; flex-direction: column; margin-top: 16px; }
    .roster-row { display: flex; align-items: center; gap: 10px; padding: 10px 0; border-top: 1px solid var(--color-border); }
    .roster-row:first-child { border-top: 0; }
    .member-avatar { width: 32px; height: 32px; flex: none; display: grid; place-items: center; border-radius: 50%; background: var(--color-surface); color: var(--color-text-muted); font-size: 10px; font-weight: 800; }
    .member-copy { display: flex; flex-direction: column; min-width: 0; }
    .member-copy strong { color: var(--color-text); font-size: 12px; }
    .member-copy span { color: var(--color-text-muted); font-size: 10px; }
    .booking-chip { margin-left: auto; border-radius: 999px; padding: 3px 9px; font-size: 9px; font-weight: 800; text-transform: uppercase; letter-spacing: .06em; background: color-mix(in srgb, var(--color-success) 12%, transparent); color: var(--color-success); }
    .booking-chip.wait { background: color-mix(in srgb, var(--color-warning) 12%, transparent); color: var(--color-warning); }
    .roster-empty { display: flex; align-items: center; gap: 10px; margin-top: 18px; color: var(--color-text-muted); font-size: 12px; }
    .booking-card { position: sticky; top: 84px; padding: 26px; background: linear-gradient(160deg, var(--color-surface-raised), var(--color-surface)); }
    .booking-card h2 { font-size: 26px; }
    .booking-intro { color: var(--color-text-muted); font-size: 13px; line-height: 1.65; margin: 12px 0 18px; }
    .booking-facts { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 18px; }
    .booking-facts div { background: var(--color-surface); border: 1px solid var(--color-border); border-radius: 14px; padding: 11px 14px; display: flex; flex-direction: column; gap: 2px; }
    .booking-facts span { color: var(--color-text-muted); font-size: 10px; }
    .booking-facts strong { color: var(--color-text); font-size: 20px; }
    .book-button { width: 100%; min-height: 50px; font-weight: 700; }
    .book-label { display: inline-flex; align-items: center; justify-content: center; gap: 6px; }
    .book-button mat-icon { margin-right: 0; }
    .book-button mat-spinner { display: inline-block; margin-right: 8px; }
    .my-booking { margin-top: 16px; display: flex; flex-direction: column; gap: 14px; }
    .booking-status { align-self: flex-start; border-radius: 999px; padding: 5px 12px; background: color-mix(in srgb, var(--color-success) 14%, transparent); color: var(--color-success); font-size: 10px; font-weight: 800; letter-spacing: .08em; text-transform: uppercase; }
    .booking-status.wait { background: color-mix(in srgb, var(--color-warning) 14%, transparent); color: var(--color-warning); }
    .my-booking p { margin: 0; color: var(--color-text-muted); font-size: 12px; line-height: 1.6; }
    .booking-meta { display: flex; flex-direction: column; gap: 6px; border: 1px solid var(--color-border); border-radius: 14px; padding: 12px; }
    .booking-meta span { display: inline-flex; align-items: center; gap: 6px; color: var(--color-text); font-size: 11px; }
    .booking-meta mat-icon { font-size: 15px; width: 15px; height: 15px; color: var(--color-accent-text); }
    .reassure { display: flex; gap: 7px; align-items: flex-start; margin-top: 18px; padding-top: 16px; border-top: 1px solid var(--color-border); color: var(--color-text-muted); font-size: 10px; line-height: 1.55; }
    .reassure mat-icon { font-size: 14px; width: 14px; height: 14px; }
    .mini-panel { display: flex; align-items: center; gap: 12px; padding: 16px 20px; }
    .mini-icon { width: 38px; height: 38px; display: grid; place-items: center; border-radius: 12px; background: var(--color-accent-soft); color: var(--color-accent-text); }
    .mini-panel div { display: flex; flex-direction: column; gap: 2px; }
    .mini-panel strong { color: var(--color-text); font-size: 12px; }
    .mini-panel span { color: var(--color-text-muted); font-size: 10px; }
    .notice { display: flex; align-items: center; gap: 10px; padding: 13px 17px; border-radius: 14px; margin-top: 16px; font-size: 13px; }
    .notice.success { background: color-mix(in srgb, var(--color-success) 10%, transparent); border: 1px solid color-mix(in srgb, var(--color-success) 38%, transparent); color: var(--color-success); }
    .notice.error { background: color-mix(in srgb, var(--color-error) 10%, transparent); border: 1px solid color-mix(in srgb, var(--color-error) 38%, transparent); color: var(--color-error); }
    .notice button { margin-left: auto; border: 0; background: none; color: inherit; font: inherit; font-weight: 700; cursor: pointer; }
    .loading-state { display: flex; align-items: center; justify-content: center; gap: 12px; min-height: 420px; color: var(--color-text-muted); }
    @media (max-width: 980px) { .hero { align-items: flex-start; flex-direction: column; padding: 30px; } .content-grid { grid-template-columns: 1fr; } .booking-card { position: static; } }
    @media (max-width: 620px) { .detail-page { padding: 14px 14px 60px; } .hero { padding: 24px 20px; border-radius: 22px; } .hero-trainer { width: 100%; } .panel, .booking-card { padding: 20px; } .capacity-stats { gap: 6px; } .capacity-stats div { padding: 10px; } }
  `],
})
export class ClassDetailComponent implements OnInit {
  readonly facade = inject(ClassesFacade);
  private readonly route = inject(ActivatedRoute);

  ngOnInit(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) void this.facade.loadDetail(id);
  }

  reload(): void {
    const id = this.route.snapshot.paramMap.get('id');
    if (id) void this.facade.loadDetail(id);
  }

  book(id: string): void {
    void this.facade.book(id);
  }

  cancel(bookingId: string): void {
    const id = this.facade.detail()?.id;
    if (window.confirm('Cancel this booking? Your seat may be offered to the waitlist.'))
      void this.facade.cancelBooking(bookingId, id);
  }

  typeLabel(type: string): string {
    return type === 'BodyPump' ? 'Body Pump' : type;
  }

  typeClass(type: string): string {
    return type.toLowerCase();
  }

  statusClass(status: string): string {
    return `status-${status.toLowerCase()}`;
  }

  statusLabel(status: string): string {
    return status === 'InProgress' ? 'In progress' : status;
  }

  occupancy(booked: number, capacity: number): number {
    return capacity === 0 ? 0 : Math.min(100, Math.round((booked / capacity) * 100));
  }

  formatFullDate(value: string): string {
    return new Intl.DateTimeFormat('en-GB', {
      weekday: 'long', day: 'numeric', month: 'long',
    }).format(new Date(value));
  }

  formatShortDate(value: string): string {
    return new Intl.DateTimeFormat('en-GB', { day: 'numeric', month: 'short' }).format(new Date(value));
  }

  formatTime(value: string): string {
    return new Intl.DateTimeFormat('en-GB', { hour: '2-digit', minute: '2-digit', hour12: false })
      .format(new Date(value));
  }

  initials(name: string): string {
    return name.split(' ').filter(Boolean).map((part) => part[0]).slice(0, 2).join('').toUpperCase();
  }
}
