import { Routes } from '@angular/router';
import { CLASSES_ROUTES } from '@softwaredeveloper98/kinevor-classes-bookings-web';

export const appRoutes: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'classes' },
  { path: '', children: CLASSES_ROUTES },
  { path: '**', redirectTo: 'classes' },
];
