import assert from 'node:assert/strict';
import { test } from 'node:test';

const calendar = `<td data-date="2026-10-20" data-level="4" id="day-1"></td>
<tool-tip for="day-1">1,001 contributions on October 20th.</tool-tip>
<td id="day-2" data-level="0" data-date="2026-10-21"></td>
<tool-tip for="day-2">No contributions on October 21st.</tool-tip>`;

test('parses GitHub dates and exact counts, rejecting missing or malformed days', async () => {
  const { parseContributions } = await import('./worker.mjs');
  assert.deepEqual(parseContributions(calendar), [
    { date: '2026-10-20', count: 1001, level: 4 },
    { date: '2026-10-21', count: 0, level: 0 },
  ]);
  for (const html of ['', calendar.replace('1,001 contributions', 'unknown'), calendar.replace('2026-10-21', '2026-02-30'), calendar + calendar]) {
    assert.throws(() => parseContributions(html));
  }
});

test('health, fixed contribution route, methods and upstream errors', async () => {
  const worker = (await import('./worker.mjs')).default;
  const request = (path, method = 'GET') =>
    new Request(`https://portfolio.example${path}`, { method });
  assert.equal((await worker.fetch(request('/health'))).status, 200);
  assert.equal((await worker.fetch(request('/unknown'))).status, 404);
  assert.equal((await worker.fetch(request('/api/github/contributions', 'POST'))).status, 405);
  assert.equal((await worker.fetch(request('/api/github/contributions', 'OPTIONS'))).status, 204);

  const originalFetch = globalThis.fetch;
  try {
    const urls = [];
    globalThis.fetch = async (url, options) => {
      assert.equal(new URL(url).origin + new URL(url).pathname, 'https://github.com/users/hesu-dev/contributions');
      urls.push(String(url));
      assert.equal(options.headers['Cache-Control'], 'no-cache');
      assert.equal(options.cache, 'no-store');
      assert.equal(options.headers.Authorization, undefined);
      return new Response(calendar);
    };
    const response = await worker.fetch(request('/api/github/contributions?url=https://other.example'));
    assert.equal(response.status, 200);
    assert.equal(response.headers.get('Access-Control-Allow-Origin'), '*');
    assert.equal(response.headers.get('Cache-Control'), 'no-store');
    const payload = await response.json();
    assert.equal(payload.contributions[0].count, 1001);
    assert.equal(payload.source, 'https://github.com/users/hesu-dev/contributions');
    assert.ok(Number.isFinite(Date.parse(payload.fetchedAt)));
    assert.equal((await worker.fetch(request('/api/github/contributions'))).status, 200);
    assert.equal(urls.length, 2);
    assert.notEqual(urls[0], urls[1]);
    for (const result of [Response.json({}, { status: 503 }), Response.json({}), new Response('bad json')]) {
      globalThis.fetch = async () => result;
      assert.equal((await worker.fetch(request('/api/github/contributions'))).status, 502);
    }
    globalThis.fetch = async () => { throw new Error('upstream unavailable'); };
    assert.equal((await worker.fetch(request('/api/github/contributions'))).status, 502);
  } finally {
    globalThis.fetch = originalFetch;
  }
});
