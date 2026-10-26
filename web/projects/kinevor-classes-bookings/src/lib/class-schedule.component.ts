import { ChangeDetectionStrategy, Component, OnInit, computed, inject, signal } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatProgressSpinnerModule } from '@angular/material/progress-spinner';
import { RouterLink } from '@angular/router';
import { ClassesFacade } from './classes.facade';

@Component({
  selector: 'kinevor-class-schedule',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterLink, MatButtonModule, MatIconModule, MatProgressSpinnerModule],
  template: `
    <div class="schedule-page">
      <section class="hero">
        <div class="hero-glow hero-glow-a"></div>
        <div class="hero-glow hero-glow-b"></div>

        <div class="hero-copy">
          <span class="eyebrow"><span class="pulse-dot"></span> Kinevor movement</span>
          <h1>Find your next<br /><span class="accent">strong session.</span></h1>
          <p>
            Yoga, strength, cycle and recovery sessions led by the Kinevor team.
            Seats update live, with an automatic waitlist when a class fills.
          </p>
          <div class="hero-actions">
            <a mat-flat-button color="primary" routerLink="/me/bookings">
              <mat-icon>confirmation_number</mat-icon>
              My bookings
            </a>
            <a mat-stroked-button routerLink="/classes" fragment="schedule">
              Browse schedule
            </a>
          </div>

          <div class="hero-stats">
            <div class="stat">
              <span class="stat-value">{{ facade.total() }}</span>
              <span class="stat-label">Upcoming sessions</span>
            </div>
            <div class="stat">
              <span class="stat-value">{{ facade.openSpots() }}</span>
              <span class="stat-label">Open seats</span>
            </div>
            <div class="stat">
              <span class="stat-value">{{ facade.occupancy() }}%</span>
              <span class="stat-label">Filled</span>
            </div>
          </div>
        </div>

        @if (facade.nextClass(); as next) {
          <a class="next-card" [routerLink]="['/classes', next.id]">
            <span class="next-kicker">Next up</span>
            <div class="next-date">
              <strong>{{ formatDay(next.startsAt) }}</strong>
              <span>{{ formatMonth(next.startsAt) }}</span>
            </div>
            <h2>{{ next.name }}</h2>
            <p>{{ formatTime(next.startsAt) }} · {{ next.room }}</p>
            <div class="next-foot">
              <span class="trainer-avatar">{{ initials(next.trainerName) }}</span>
              <span>{{ next.trainerName }}</span>
              <mat-icon>arrow_forward</mat-icon>
            </div>
          </a>
        }
      </section>

      <section class="schedule" id="schedule">
        <div class="section-head">
          <div>
            <span class="eyebrow">Weekly timetable</span>
            <h2>Classes at Kinevor</h2>
          </div>
          <span class="count">{{ facade.total() }} sessions</span>
        </div>

        <div class="filters" aria-label="Filter classes by type">
          <button class="filter" [class.active]="activeType() === 'All'" (click)="selectType('All')">
            All classes
          </button>
          @for (type of types(); track type) {
            <button class="filter" [class.active]="activeType() === type" (click)="selectType(type)">
              {{ typeLabel(type) }}
            </button>
          }
        </div>

        @if (facade.error(); as error) {
          <div class="notice error" role="alert">
            <mat-icon>error_outline</mat-icon>
            <span>{{ error }}</span>
            <button type="button" (click)="reload()">Try again</button>
          </div>
        }

        @if (facade.loading()) {
          <div class="loading-grid" aria-label="Loading classes">
            @for (item of [1, 2, 3, 4, 5, 6]; track item) {
              <div class="skeleton-card"></div>
            }
          </div>
        } @else if (facade.classes().length === 0) {
          <div class="empty-state">
            <span class="empty-icon"><mat-icon>event_busy</mat-icon></span>
            <h3>No classes match this filter</h3>
            <p>Try another class type or check the full timetable.</p>
            <button mat-stroked-button type="button" (click)="selectType('All')">Show all classes</button>
          </div>
        } @else {
          <div class="class-grid">
            @for (item of facade.classes(); track item.id) {
              <article [class]="'class-card type-' + typeClass(item.type) + (item.isFull ? ' is-full' : '')">
                <span class="type-rail"></span>
                <div class="card-top">
                  <div class="date-block">
                    <span class="day">{{ formatDay(item.startsAt) }}</span>
                    <strong>{{ formatDateNumber(item.startsAt) }}</strong>
                    <span class="month">{{ formatMonth(item.startsAt) }}</span>
                  </div>
                  <div class="card-heading">
                    <span class="type-chip">{{ typeLabel(item.type) }}</span>
                    <h3>{{ item.name }}</h3>
                    <p class="time">{{ formatTime(item.startsAt) }} – {{ formatTime(item.endsAt) }}</p>
                  </div>
                  <span class="status-dot" [class.full]="item.isFull" [attr.aria-label]="item.isFull ? 'Full' : 'Open'"></span>
                </div>

                <div class="card-meta">
                  <span><mat-icon>person</mat-icon>{{ item.trainerName }}</span>
                  <span><mat-icon>meeting_room</mat-icon>{{ item.room }}</span>
                  <span><mat-icon>schedule</mat-icon>{{ item.durationMinutes }} min</span>
                </div>

                <p class="description">{{ item.description ?? 'A focused session led by the Kinevor training team.' }}</p>

                <div class="capacity">
                  <div class="capacity-copy">
                    <span>{{ item.bookedCount }} of {{ item.capacity }} booked</span>
                    <strong [class.full]="item.isFull">
                      {{ item.isFull ? 'Waitlist only' : item.availableSpots + ' spots left' }}
                    </strong>
                  </div>
                  <div
                    class="meter"
                    role="progressbar"
                    [attr.aria-valuenow]="item.bookedCount"
                    [attr.aria-valuemin]="0"
                    [attr.aria-valuemax]="item.capacity">
                    <span [style.width.%]="occupancy(item.bookedCount, item.capacity)"></span>
                  </div>
                  @if (item.waitListCount > 0) {
                    <span class="waitlist-note">{{ item.waitListCount }} waiting</span>
                  }
                </div>

                <a mat-stroked-button class="card-action" [routerLink]="['/classes', item.id]">
                  {{ item.isOpenForBooking ? (item.isFull ? 'Join waitlist' : 'Book a seat') : 'View class' }}
                  <span class="card-arrow" aria-hidden="true">→</span>
                </a>
              </article>
            }
          </div>
        }
      </section>

      @if (facade.loading()) {
        <div class="page-spinner"><mat-spinner diameter="28"></mat-spinner></div>
      }
    </div>
  `,
  styles: [`
    :host { display: block; }
    .schedule-page { max-width: 1240px; margin: 0 auto; padding: 24px 24px 80px; }
    .hero { position: relative; display: grid; grid-template-columns: 1.35fr .8fr; gap: 36px; align-items: center; overflow: hidden; border: 1px solid var(--color-border); border-radius: 30px; padding: 44px; background: linear-gradient(135deg, var(--color-surface-raised), var(--color-surface)); }
    .hero-glow { position: absolute; border-radius: 999px; filter: blur(95px); pointer-events: none; }
    .hero-glow-a { width: 340px; height: 340px; right: -80px; top: -120px; background: color-mix(in srgb, var(--color-accent-fill) 22%, transparent); }
    .hero-glow-b { width: 260px; height: 260px; left: 28%; bottom: -170px; background: color-mix(in srgb, var(--color-info) 14%, transparent); }
    .hero-copy, .next-card { position: relative; z-index: 1; }
    .eyebrow { display: inline-flex; align-items: center; gap: 8px; color: var(--color-accent-text); font-size: 11px; font-weight: 800; letter-spacing: .16em; text-transform: uppercase; }
    .pulse-dot { width: 8px; height: 8px; border-radius: 50%; background: var(--color-accent-fill); box-shadow: 0 0 0 5px color-mix(in srgb, var(--color-accent-fill) 14%, transparent); }
    h1 { margin: 16px 0 12px; font-size: clamp(38px, 5vw, 62px); line-height: 1.02; letter-spacing: -.05em; font-weight: 800; color: var(--color-text); }
    .accent { color: var(--color-accent-text); }
    .hero-copy > p { max-width: 58ch; margin: 0; color: var(--color-text-muted); line-height: 1.7; font-size: 16px; }
    .hero-actions { display: flex; flex-wrap: wrap; gap: 12px; margin-top: 24px; }
    .hero-stats { display: flex; gap: 10px; margin-top: 30px; flex-wrap: wrap; }
    .stat { min-width: 118px; border: 1px solid var(--color-border); background: color-mix(in srgb, var(--color-bg) 55%, transparent); border-radius: 16px; padding: 12px 16px; display: flex; flex-direction: column; gap: 2px; }
    .stat-value { font-size: 24px; font-weight: 800; color: var(--color-text); }
    .stat-label { font-size: 11px; color: var(--color-text-muted); font-weight: 600; letter-spacing: .04em; }
    .next-card { display: flex; flex-direction: column; gap: 6px; text-decoration: none; color: var(--color-text); border: 1px solid color-mix(in srgb, var(--color-accent-fill) 28%, var(--color-border)); border-radius: 24px; padding: 24px; background: color-mix(in srgb, var(--color-bg) 68%, transparent); backdrop-filter: blur(8px); transition: transform .2s ease, border-color .2s ease; }
    .next-card:hover { transform: translateY(-4px); border-color: var(--color-accent-fill); }
    .next-kicker { font-size: 10px; font-weight: 800; letter-spacing: .16em; text-transform: uppercase; color: var(--color-accent-text); }
    .next-date { display: flex; align-items: baseline; gap: 8px; margin-top: 10px; color: var(--color-text-muted); }
    .next-date strong { font-size: 40px; line-height: 1; color: var(--color-text); }
    .next-date span { font-size: 12px; font-weight: 700; text-transform: uppercase; letter-spacing: .12em; }
    .next-card h2 { margin: 8px 0 0; font-size: 24px; letter-spacing: -.03em; }
    .next-card p { margin: 0; color: var(--color-text-muted); font-size: 13px; }
    .next-foot { display: flex; align-items: center; gap: 8px; margin-top: 20px; border-top: 1px solid var(--color-border); padding-top: 16px; font-size: 12px; font-weight: 600; }
    .next-foot mat-icon { margin-left: auto; color: var(--color-accent-text); }
    .trainer-avatar { width: 30px; height: 30px; display: grid; place-items: center; border-radius: 50%; background: var(--color-accent-soft); color: var(--color-accent-text); font-size: 10px; font-weight: 800; }
    .schedule { padding-top: 46px; }
    .section-head { display: flex; align-items: end; justify-content: space-between; gap: 16px; margin-bottom: 18px; }
    .section-head h2 { margin: 8px 0 0; font-size: 30px; letter-spacing: -.04em; }
    .count { color: var(--color-text-muted); font-size: 12px; font-weight: 600; border: 1px solid var(--color-border); border-radius: 999px; padding: 6px 12px; }
    .filters { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 24px; }
    .filter { min-height: 38px; border: 1px solid var(--color-border); background: var(--color-surface); color: var(--color-text-muted); border-radius: 999px; padding: 0 16px; font: inherit; font-size: 12px; font-weight: 600; cursor: pointer; transition: all .15s ease; }
    .filter:hover { color: var(--color-text); border-color: var(--color-text-muted); }
    .filter.active { background: var(--color-accent-fill); border-color: var(--color-accent-fill); color: var(--color-on-accent); }
    .class-grid { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 16px; }
    .class-card { --class-accent: var(--color-cat-default); position: relative; display: flex; flex-direction: column; gap: 16px; overflow: hidden; padding: 20px; padding-left: 24px; border: 1px solid var(--color-border); border-radius: 22px; background: var(--color-surface-raised); transition: transform .2s ease, border-color .2s ease, box-shadow .2s ease; }
    .class-card:hover { transform: translateY(-4px); border-color: color-mix(in srgb, var(--class-accent) 52%, var(--color-border)); box-shadow: 0 18px 36px -22px color-mix(in srgb, var(--class-accent) 38%, transparent); }
    .type-rail { position: absolute; inset: 0 auto 0 0; width: 4px; background: var(--class-accent); }
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
    .card-top { display: flex; gap: 14px; align-items: flex-start; }
    .date-block { flex: none; width: 58px; border-radius: 14px; background: var(--color-surface); border: 1px solid var(--color-border); padding: 8px 6px; text-align: center; display: flex; flex-direction: column; align-items: center; }
    .day { font-size: 9px; letter-spacing: .14em; font-weight: 800; color: var(--color-text-muted); }
    .date-block strong { font-size: 25px; line-height: 1.15; color: var(--color-text); }
    .month { font-size: 9px; font-weight: 800; letter-spacing: .1em; color: var(--color-accent-text); }
    .card-heading { min-width: 0; flex: 1; }
    .type-chip { display: inline-flex; align-items: center; padding: 3px 9px; border-radius: 999px; background: color-mix(in srgb, var(--class-accent) 16%, transparent); color: var(--class-accent); font-size: 9px; font-weight: 800; letter-spacing: .1em; text-transform: uppercase; }
    .card-heading h3 { margin: 7px 0 2px; font-size: 18px; line-height: 1.2; letter-spacing: -.025em; color: var(--color-text); }
    .time { margin: 0; font-size: 12px; color: var(--color-text-muted); }
    .status-dot { width: 8px; height: 8px; border-radius: 50%; margin-top: 6px; background: var(--color-success); box-shadow: 0 0 0 4px color-mix(in srgb, var(--color-success) 12%, transparent); }
    .status-dot.full { background: var(--color-warning); box-shadow: 0 0 0 4px color-mix(in srgb, var(--color-warning) 12%, transparent); }
    .card-meta { display: flex; flex-wrap: wrap; gap: 10px 14px; color: var(--color-text-muted); font-size: 11px; }
    .card-meta span { display: inline-flex; align-items: center; gap: 4px; }
    .card-meta mat-icon { font-size: 14px; width: 14px; height: 14px; }
    .description { margin: 0; color: var(--color-text-muted); font-size: 12px; line-height: 1.6; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
    .capacity { margin-top: auto; display: flex; flex-direction: column; gap: 7px; }
    .capacity-copy { display: flex; align-items: center; justify-content: space-between; gap: 8px; font-size: 10px; color: var(--color-text-muted); }
    .capacity-copy strong { color: var(--color-success); font-size: 10px; }
    .capacity-copy strong.full { color: var(--color-warning); }
    .meter { height: 5px; border-radius: 999px; background: var(--color-surface); overflow: hidden; }
    .meter span { display: block; height: 100%; border-radius: inherit; background: linear-gradient(90deg, var(--class-accent), color-mix(in srgb, var(--class-accent) 55%, var(--color-info))); }
    .waitlist-note { font-size: 10px; color: var(--color-warning); }
    .card-action { width: 100%; font-size: 12px; }
    .card-arrow { margin-left: 8px; color: var(--color-accent-text); font-size: 15px; line-height: 1; }
    .notice { display: flex; align-items: center; gap: 10px; padding: 14px 18px; border-radius: 14px; margin-bottom: 18px; }
    .notice.error { background: color-mix(in srgb, var(--color-error) 10%, transparent); border: 1px solid color-mix(in srgb, var(--color-error) 40%, transparent); color: var(--color-error); }
    .notice button { margin-left: auto; background: none; border: 0; color: inherit; font: inherit; font-weight: 700; cursor: pointer; }
    .loading-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
    .skeleton-card { height: 350px; border-radius: 22px; background: linear-gradient(90deg, var(--color-surface) 25%, var(--color-surface-raised) 50%, var(--color-surface) 75%); background-size: 200% 100%; animation: shimmer 1.4s infinite; }
    @keyframes shimmer { from { background-position: 200% 0; } to { background-position: -200% 0; } }
    .empty-state { display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 10px; min-height: 340px; text-align: center; border: 1px dashed var(--color-border); border-radius: 24px; background: var(--color-surface); }
    .empty-icon { width: 70px; height: 70px; display: grid; place-items: center; border-radius: 50%; background: var(--color-accent-soft); color: var(--color-accent-text); }
    .empty-icon mat-icon { font-size: 30px; width: 30px; height: 30px; }
    .empty-state h3 { margin: 8px 0 0; color: var(--color-text); }
    .empty-state p { margin: 0 0 8px; color: var(--color-text-muted); }
    .page-spinner { position: fixed; right: 24px; bottom: 24px; padding: 10px; border-radius: 50%; background: var(--color-surface-raised); border: 1px solid var(--color-border); }
    @media (max-width: 1050px) { .class-grid, .loading-grid { grid-template-columns: repeat(2, minmax(0, 1fr)); } .hero { grid-template-columns: 1fr; } .next-card { max-width: 420px; } }
    @media (max-width: 680px) { .schedule-page { padding: 14px 14px 60px; } .hero { padding: 28px 22px; border-radius: 22px; } .class-grid, .loading-grid { grid-template-columns: 1fr; } .hero-stats { gap: 8px; } .stat { flex: 1; min-width: 96px; } .section-head { align-items: flex-start; flex-direction: column; } }
  `],
})
export class ClassScheduleComponent implements OnInit {
  readonly facade = inject(ClassesFacade);
  readonly activeType = signal('All');
  readonly types = computed(() =>
    this.facade.catalogue().map((item) => item.type).filter((type, index, values) => values.indexOf(type) === index));

  ngOnInit(): void {
    const start = new Date();
    start.setHours(0, 0, 0, 0);
    void this.facade.load({ fromDate: start.toISOString() });
  }

  selectType(type: string): void {
    this.activeType.set(type);
    void this.facade.updateQuery({ type: type === 'All' ? undefined : type });
  }

  reload(): void {
    void this.facade.load();
  }

  typeLabel(type: string): string {
    return type === 'BodyPump' ? 'Body Pump' : type;
  }

  typeClass(type: string): string {
    return type.toLowerCase();
  }

  occupancy(booked: number, capacity: number): number {
    return capacity === 0 ? 0 : Math.min(100, Math.round((booked / capacity) * 100));
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

  initials(name: string): string {
    return name.split(' ').filter(Boolean).map((part) => part[0]).slice(0, 2).join('').toUpperCase();
  }
}
