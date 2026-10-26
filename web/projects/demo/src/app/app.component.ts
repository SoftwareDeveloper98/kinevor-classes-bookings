import { ChangeDetectionStrategy, Component } from '@angular/core';
import { MatButtonModule } from '@angular/material/button';
import { MatIconModule } from '@angular/material/icon';
import { MatToolbarModule } from '@angular/material/toolbar';
import { RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

@Component({
  selector: 'demo-root',
  standalone: true,
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [RouterOutlet, RouterLink, RouterLinkActive, MatToolbarModule, MatButtonModule, MatIconModule],
  template: `
    <header class="demo-topbar">
      <a class="demo-brand" routerLink="/classes">
        <span class="demo-logo" aria-hidden="true">K</span>
        <span>Kinevor<span class="demo-brand-accent">Classes</span></span>
      </a>

      <nav class="demo-nav" aria-label="Demo sections">
        <a mat-button routerLink="/classes" routerLinkActive="active">
          <mat-icon aria-hidden="true">calendar_month</mat-icon>
          Schedule
        </a>
        <a mat-button routerLink="/me/bookings" routerLinkActive="active">
          <mat-icon aria-hidden="true">confirmation_number</mat-icon>
          My bookings
        </a>
      </nav>

      <span class="demo-actor">Staff · Maya Thompson</span>
      <span class="demo-badge">Demo</span>
    </header>

    <main>
      <router-outlet />
    </main>
  `,
  styles: [`
    .demo-topbar { display:flex; align-items:center; gap:20px; padding:0 28px; height:64px; background:var(--color-surface-raised); border-bottom:1px solid var(--color-border); position:sticky; top:0; z-index:20; }
    .demo-brand { display:flex; align-items:center; gap:10px; text-decoration:none; color:var(--color-text); font-weight:800; font-size:16px; letter-spacing:-.3px; }
    .demo-brand-accent { color:var(--color-accent-text); margin-inline-start:4px; }
    .demo-logo { width:34px; height:34px; border-radius:10px; background:var(--gradient-brandWarm); color:var(--color-on-accent); display:flex; align-items:center; justify-content:center; font-weight:900; }
    .demo-nav { display:flex; gap:4px; margin-inline-start:auto; }
    .demo-nav a.active { color:var(--color-accent-text); }
    .demo-nav mat-icon { margin-inline-end:6px; }
    .demo-actor { font-size:11px; color:var(--color-text-muted); white-space:nowrap; }
    .demo-badge { font-size:11px; font-weight:700; text-transform:uppercase; letter-spacing:1px; color:var(--color-accent-text); border:1px solid var(--color-accent-text); border-radius:20px; padding:4px 10px; }
    @media(max-width:900px) { .demo-actor { display:none; } }
    @media(max-width:720px) { .demo-topbar { padding:0 14px; gap:10px; } .demo-nav a { font-size:0; min-width:0; padding:8px; } .demo-nav mat-icon { margin:0; } .demo-badge { display:none; } }
  `],
})
export class AppComponent {}
