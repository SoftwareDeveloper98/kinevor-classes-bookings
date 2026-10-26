import { Routes } from '@angular/router';
import { ClassDetailComponent } from './class-detail.component';
import { ClassScheduleComponent } from './class-schedule.component';
import { MemberBookingsComponent } from './member-bookings.component';

export const CLASSES_ROUTES: Routes = [
  { path: 'classes/:id', component: ClassDetailComponent },
  { path: 'classes', component: ClassScheduleComponent },
  { path: 'me/bookings', component: MemberBookingsComponent },
];
