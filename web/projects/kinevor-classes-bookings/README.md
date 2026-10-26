# @softwaredeveloper98/kinevor-classes-bookings-web

Angular UI for the Kinevor classes and bookings module: the weekly class
schedule and catalogue, class detail with capacity and roster, booking,
cancellation, waitlist state and the member's upcoming and past bookings.

## GitHub Packages access

This package is private. Configure the scope and token before installing:

```ini
@softwaredeveloper98:registry=https://npm.pkg.github.com
//npm.pkg.github.com/:_authToken=${KINEVOR_PACKAGES_TOKEN}
```

## Install

```bash
npm install @softwaredeveloper98/kinevor-classes-bookings-web
```

The package expects Angular 21, Angular Material 21 and RxJS 7.8.

## Provide the feature

```ts
import { provideHttpClient } from '@angular/common/http';
import { ApplicationConfig } from '@angular/core';
import { provideRouter } from '@angular/router';
import {
  CLASSES_ROUTES,
  provideClassesBookings,
} from '@softwaredeveloper98/kinevor-classes-bookings-web';

export const appConfig: ApplicationConfig = {
  providers: [
    provideHttpClient(),
    provideClassesBookings({ apiBaseUrl: 'http://localhost:5085/api/v1' }),
    provideRouter([...CLASSES_ROUTES]),
  ],
};
```

The host owns authentication. Requests must carry the API bearer token or the
standalone demo's `X-Demo-Role` / `X-Demo-Member` headers.

## Routes

| Route | Screen |
| --- | --- |
| `/classes` | Schedule, catalogue filters, capacity and next session |
| `/classes/:id` | Class detail, roster, booking and cancellation |
| `/me/bookings` | Member upcoming and past bookings |

Import `CLASSES_ROUTES` into the host router or mount the standalone components
directly.

## Development

```bash
npm install
npm test
npm run build:all
npm start
```

The demo host lives in `projects/demo` and expects the Classes API on
`http://localhost:5085`.
