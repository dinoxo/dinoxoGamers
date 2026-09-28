import {mkdir,writeFile} from 'node:fs/promises';
const urls={psbenefits:'https://www.playstation.com/en-us/ps-plus/',nsbenefits:'https://www.nintendo.com/us/online/nintendo-switch-online/',nsexpansion:'https://www.nintendo.com/us/online/nintendo-switch-online/expansion-pack/',xboxbenefits:'https://www.xbox.com/en-US/xbox-game-pass'};
await mkdir('build/subscription-probe',{recursive:true});
for(const [name,url] of Object.entries(urls)) {
  const response=await fetch(url,{signal:AbortSignal.timeout(25000)});
  const body=await response.text();
  await writeFile(`build/subscription-probe/${name}.html`,body);
  console.log(name,response.status,body.length,[...body.matchAll(/<(h[2-5])[^>]*>(.*?)<\/\1>/gs)].map(m=>m[2].replace(/<[^>]+>/g,' ').replace(/\s+/g,' ').trim()).filter(Boolean).slice(0,50));
  if(!response.ok) process.exitCode=1;
}
