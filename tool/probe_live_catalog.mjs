// Network verification only: saves current public responses under build/.
// Run with node --use-system-ca tool/probe_live_catalog.mjs.
import { mkdir, writeFile } from 'node:fs/promises';
const root = 'https://www.dekudeals.com';
const directory = 'build/live-probe';
await mkdir(directory, { recursive: true });
const form = new URLSearchParams({ _method: 'PUT', return_to: '/', platform_steam: 'false' });
for (const console of ['switch', 'switch_2', 'ps5', 'ps4', 'xbox_one', 'xbox_series']) {
  form.set(`platform_${console}`, 'true');
  form.set(`games_filter_${console}`, 'digital');
}
const session = await fetch(`${root}/platforms`, { method: 'POST', body: form, redirect: 'manual' });
if (session.status !== 303 && session.status !== 302) throw new Error(`Preferences HTTP ${session.status}`);
const cookie = session.headers.getSetCookie().find(c => c.startsWith('rack.session='))?.split(';')[0];
if (!cookie) throw new Error('Missing anonymous preferences');
const manifest = [];
for (const query of ['Wolverine', 'Pokémon', 'Halo', null]) {
  const url = new URL(query ? '/search' : '/recent-drops', root);
  url.searchParams.set('country', 'us');
  if (query) url.searchParams.set('q', query);
  const result = await fetch(url, { headers: { cookie }, signal: AbortSignal.timeout(20000) });
  if (!result.ok) throw new Error(`Listing HTTP ${result.status}`);
  const body = await result.text();
  const slug = query ?? 'offers';
  await writeFile(`${directory}/${slug}-listing.html`, body);
  const links = [...new Set([...body.matchAll(/<a\b[^>]*>/g)]
    .map(m => m[0]).filter(tag => /class=['"][^'"]*\bmain-link\b/.test(tag))
    .map(tag => tag.match(/href=['"](\/items\/[^'"?]+)['"]/)?.[1]).filter(Boolean))];
  console.log(JSON.stringify({ query: query ?? 'offers', status: result.status, links: links.length, first: links.slice(0, 6) }));
  // Enough live details to exercise each storefront without crawling the catalog.
  for (const path of links.slice(0, query ? 2 : 3)) {
    const itemUrl = `${root}${path}?country=us`;
    const item = await fetch(itemUrl, { headers: { cookie }, signal: AbortSignal.timeout(20000) });
    if (!item.ok) throw new Error(`Item HTTP ${item.status}`);
    const file = `${path.split('/').at(-1)}.html`;
    await writeFile(`${directory}/${file}`, await item.text());
    manifest.push({ query, file, url: itemUrl });
  }
}
await writeFile(`${directory}/manifest.json`, JSON.stringify(manifest, null, 2));
