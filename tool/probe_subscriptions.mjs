// Read-only probe of the public US subscription sources, saved under build/.
import { mkdir, writeFile } from 'node:fs/promises';
const sources = {
  pscatalog: 'https://www.playstation.com/bin/imagic/gameslist?locale=en-us&categoryList=plus-games-list',
  psclassics: 'https://www.playstation.com/bin/imagic/gameslist?locale=en-us&categoryList=plus-classics-list',
  psmonthly: 'https://www.playstation.com/bin/imagic/gameslist?locale=en-us&categoryList=plus-monthly-games-list',
  psnews: 'https://blog.playstation.com/category/ps-plus/feed/',
  nintendo: 'https://www.nintendo.com/us/online/nintendo-switch-online/classic-games/',
  genesis: 'https://www.nintendo.com/us/store/products/sega-genesis-nintendo-switch-online-switch/',
  nintendonews: 'https://www.nintendo.com/us/whatsnew/',
  xboxnews: 'https://news.xbox.com/en-us/tag/xbox-game-pass/feed/',
  xboxcatalog: 'https://catalog.gamepass.com/sigls/v3?id=97c6c862-d28a-4907-a3d5-c401f2296a53&language=en-us&market=US&platformContext=ConsoleGen8%3BConsoleGen9&subscriptionContext=cfq7ttc0khs0',
};
await mkdir('build/subscription-probe', { recursive: true });
for (const [name, url] of Object.entries(sources)) {
  try {
    const response = await fetch(url, { signal: AbortSignal.timeout(25000) });
    const body = await response.text();
    await writeFile(`build/subscription-probe/${name}.html`, body);
    console.log(JSON.stringify({ name, url: response.url, status: response.status, bytes: body.length }));
    if (!response.ok) process.exitCode = 1;
    if (name === 'xboxcatalog' && response.ok) {
      const ids = JSON.parse(body).slice(1,5).map(x=>x.id).join(',');
      const result = await fetch(`https://displaycatalog.mp.microsoft.com/v7.0/products?bigIds=${ids}&market=US&languages=en-us`, { signal: AbortSignal.timeout(25000) });
      const text = await result.text();
      await writeFile('build/subscription-probe/xboxproducts.html', text);
      console.log('products',result.status,text.length);
      if (!result.ok) process.exitCode = 1;
    }
  } catch (error) {
    console.log(JSON.stringify({ name, error: error.message }));
    process.exitCode = 1;
  }
}
