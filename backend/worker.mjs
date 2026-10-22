const headers = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, OPTIONS',
  'Access-Control-Allow-Headers': 'Cache-Control',
  'Cache-Control': 'no-store',
};

const source = 'https://github.com/users/hesu-dev/contributions';

function attribute(tag, name) {
  return tag.match(new RegExp(`\\b${name}="([^"]*)"`))?.[1];
}

export function parseContributions(html) {
  const counts = new Map();
  for (const tooltip of html.matchAll(/<tool-tip\b([^>]*)>([\s\S]*?)<\/tool-tip>/g)) {
    const count = tooltip[2].trim().match(/^(No|[\d,]+) contributions? on\b/);
    if (count) counts.set(attribute(tooltip[1], 'for'), count[1] === 'No' ? 0 : Number(count[1].replaceAll(',', '')));
  }
  const contributions = [];
  const dates = new Set();
  for (const cell of html.matchAll(/<td\b[^>]*\bdata-date="[^">]*"[^>]*>/g)) {
    const date = attribute(cell[0], 'data-date');
    const level = Number(attribute(cell[0], 'data-level'));
    const count = counts.get(attribute(cell[0], 'id'));
    const parsed = new Date(`${date}T00:00:00Z`);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date) || !Number.isFinite(parsed.getTime()) ||
        parsed.toISOString().slice(0, 10) !== date || dates.has(date) ||
        !Number.isInteger(level) || level < 0 || level > 4 ||
        !Number.isSafeInteger(count) || count < 0) {
      throw new Error('Invalid GitHub contribution calendar');
    }
    dates.add(date);
    contributions.push({ date, count, level });
  }
  if (contributions.length === 0) throw new Error('Missing GitHub contribution calendar');
  return contributions.sort((a, b) => a.date.localeCompare(b.date));
}

export default {
  async fetch(request) {
    const path = new URL(request.url).pathname;
    if (path !== '/health' && path !== '/api/github/contributions') {
      return Response.json({ error: 'Not found' }, { status: 404, headers });
    }
    if (request.method === 'OPTIONS') return new Response(null, { status: 204, headers });
    if (request.method !== 'GET') {
      return Response.json({ error: 'Method not allowed' }, {
        status: 405, headers: { ...headers, Allow: 'GET, OPTIONS' },
      });
    }
    if (path === '/health') return Response.json({ status: 'ok' }, { headers });
    try {
      const url = new URL(source);
      url.searchParams.set('_request', crypto.randomUUID());
      const response = await fetch(url, {
        cache: 'no-store',
        headers: { 'Cache-Control': 'no-cache', Accept: 'text/html', 'Accept-Language': 'en-US' },
        signal: AbortSignal.timeout(8000),
      });
      if (!response.ok) throw new Error('Upstream request failed');
      const contributions = parseContributions(await response.text());
      return Response.json({ source, fetchedAt: new Date().toISOString(), contributions }, { headers });
    } catch {
      return Response.json({ error: 'GitHub contributions unavailable' }, { status: 502, headers });
    }
  },
};
