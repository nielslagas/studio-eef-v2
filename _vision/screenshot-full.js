// Volledige-pagina screenshot via CDP (werkbaar boven de viewport-hoogte uit).
// Gebruik: node screenshot-full.js [url] [breedte] [uitvoerpad]
const { spawn } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

// Browserkeuze: Chrome heeft de voorkeur (stabilere CDP-start dan Edge op
// deze machine), Edge als fallback zodat het script overal draait.
const BROWSERS = [
  'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
  'C:\\Program Files (x86)\\Google\\Chrome\\Application\\chrome.exe',
  process.env.LOCALAPPDATA && path.join(process.env.LOCALAPPDATA, 'Google', 'Chrome', 'Application', 'chrome.exe'),
  'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
];
const BROWSER = BROWSERS.find((p) => p && fs.existsSync(p));
if (!BROWSER) throw new Error('geen Chrome of Edge gevonden');
const url = process.argv[2];
const W = parseInt(process.argv[3] || '1280', 10);
const out = process.argv[4];
// Willekeurige poort: een vast poortje raakt geblokkeerd door een zombi-proces
// en dan faalt het script met "geen CDP-endpoint".
const PORT = 10240 + Math.floor(Math.random() * 50000);

const userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'eef-shot-'));
const browser = spawn(BROWSER, [
  '--headless', '--disable-gpu', '--hide-scrollbars',
  `--remote-debugging-port=${PORT}`,
  `--user-data-dir=${userDataDir}`,
  'about:blank',
], { stdio: 'ignore' });

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
let msgId = 0;
const pending = new Map();
let ws;

function send(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = ++msgId;
    pending.set(id, { resolve, reject });
    ws.send(JSON.stringify({ id, method, params }));
  });
}

async function main() {
  let wsUrl = null;
  // 100 × 250 ms = 25 s: koud gestarte browsers hebben soms meer tijd nodig
  for (let i = 0; i < 100 && !wsUrl; i++) {
    try {
      const res = await fetch(`http://127.0.0.1:${PORT}/json/list`);
      const list = await res.json();
      const page = list.find((t) => t.type === 'page');
      if (page) wsUrl = page.webSocketDebuggerUrl;
    } catch (e) { /* wachten */ }
    if (!wsUrl) await sleep(250);
  }
  if (!wsUrl) throw new Error('geen CDP-endpoint');
  ws = new WebSocket(wsUrl);
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = rej; });
  ws.onmessage = (ev) => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) {
      const p = pending.get(m.id);
      pending.delete(m.id);
      if (m.error) p.reject(new Error(m.error.message)); else p.resolve(m.result);
    }
  };
  await send('Page.enable');
  await send('Emulation.setDeviceMetricsOverride', { width: W, height: 900, deviceScaleFactor: 1, mobile: W < 700 });
  await send('Page.navigate', { url });
  await sleep(5000);
  const metrics = await send('Page.getLayoutMetrics');
  const content = metrics.contentSize;
  await send('Emulation.setDeviceMetricsOverride', {
    width: W, height: Math.ceil(content.height), deviceScaleFactor: 1, mobile: W < 700,
  });
  await sleep(800);
  const shot = await send('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true });
  fs.writeFileSync(out, Buffer.from(shot.data, 'base64'));
  console.log(`${out}: ${Math.ceil(content.width)}x${Math.ceil(content.height)} pagina, opgeslagen`);
  ws.close();
  browser.kill();
  process.exit(0);
}

main().catch((e) => { console.error('FOUT:', e.message); browser.kill(); process.exit(1); });
