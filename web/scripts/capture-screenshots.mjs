import { chromium } from 'playwright';
import { mkdir } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { dirname, resolve } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const output = resolve(here, '..', '..', 'docs', 'screenshots');
const webUrl = process.env.KINEVOR_WEB_URL ?? 'http://localhost:4204';
const apiUrl = process.env.KINEVOR_API_URL ?? 'http://localhost:5085';
const channel = process.env.PLAYWRIGHT_CHANNEL ?? 'chrome';

const browser = await chromium.launch(channel ? { channel } : {});
const page = await browser.newPage({ viewport: { width: 1440, height: 1040 } });

try {
  await mkdir(output, { recursive: true });

  await page.goto(`${webUrl}/classes`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('kinevor-class-schedule .class-card', { timeout: 30000 });
  await page.waitForTimeout(800);
  await page.screenshot({
    path: resolve(output, 'web-schedule.png'),
    fullPage: true,
  });
  console.log('saved web-schedule.png');

  await page.goto(
    `${webUrl}/classes/c0000000-0000-0000-0000-000000000001`,
    { waitUntil: 'domcontentloaded' },
  );
  await page.waitForSelector('kinevor-class-detail .detail-page .hero', { timeout: 20000 });
  await page.waitForTimeout(800);
  await page.screenshot({
    path: resolve(output, 'web-class-detail.png'),
    fullPage: true,
  });
  console.log('saved web-class-detail.png');

  const headers = {
    'X-Demo-Role': 'Staff',
    'X-Demo-Email': 'staff.demo@kinevor.local',
    'X-Demo-Member': '11111111-1111-1111-1111-111111111111',
  };
  const existing = await page.request.get(
    `${apiUrl}/api/v1/me/bookings?scope=upcoming`,
    { headers },
  );
  const bookings = (await existing.json()).data ?? [];
  const previous = bookings.find((booking) => booking.className === 'Power Spin');
  if (previous) {
    await page.request.delete(
      `${apiUrl}/api/v1/bookings/${previous.id}?reason=Reset%20for%20screenshots`,
      { headers },
    );
  }

  await page.goto(
    `${webUrl}/classes/c0000000-0000-0000-0000-000000000004`,
    { waitUntil: 'domcontentloaded' },
  );
  await page.waitForSelector('kinevor-class-detail .book-button', { timeout: 20000 });
  await page.waitForTimeout(500);
  await page.locator('.book-button').click();
  await page.waitForSelector('.notice.success', { timeout: 20000 });
  await page.waitForTimeout(800);
  await page.screenshot({
    path: resolve(output, 'web-booking-confirmed.png'),
    fullPage: true,
  });
  console.log('saved web-booking-confirmed.png');

  await page.goto(`${webUrl}/me/bookings`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('kinevor-member-bookings .booking-row', { timeout: 30000 });
  await page.waitForTimeout(800);
  await page.screenshot({
    path: resolve(output, 'web-my-bookings.png'),
    fullPage: true,
  });
  console.log('saved web-my-bookings.png');

  await page.goto(`${apiUrl}/swagger/index.html`, { waitUntil: 'domcontentloaded' });
  await page.waitForSelector('.swagger-ui .info', { timeout: 30000 });
  await page.waitForTimeout(800);
  await page.screenshot({
    path: resolve(output, 'api-swagger.png'),
    fullPage: true,
  });
  console.log('saved api-swagger.png');
} finally {
  await browser.close();
}
