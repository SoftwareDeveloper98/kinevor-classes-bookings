import { HttpInterceptorFn } from '@angular/common/http';

/**
 * Adds the demo trust headers so the standalone host can authenticate requests.
 * Staff access reveals the class roster; the linked member is Maya Thompson.
 */
export const demoApiInterceptor: HttpInterceptorFn = (req, next) => {
  if (!req.url.includes('/api/')) return next(req);

  return next(
    req.clone({
      setHeaders: {
        'X-Demo-Role': 'Staff',
        'X-Demo-Email': 'staff.demo@kinevor.local',
        'X-Demo-Member': '11111111-1111-1111-1111-111111111111',
      },
    }),
  );
};
