// Console- en foutentest voor de Studio EEF-pagina via CDP (headless Edge).
// Gebruik: node _vision/console-test.js [url] [viewportBreedte] [viewportHoogte]
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
const url = process.argv[2] || 'file:///D:/Projects/Eva Aukema/Studio-Eef/site/index.html';
const W = parseInt(process.argv[3] || '1280', 10);
const H = parseInt(process.argv[4] || '900', 10);
// Willekeurige poort + langere startbudget: een vaste poort raakt geblokkeerd
// door een zombi-proces en dan faalt de test met "geen CDP-endpoint".
const PORT = 10240 + Math.floor(Math.random() * 50000);

const userDataDir = fs.mkdtempSync(path.join(os.tmpdir(), 'eef-cdp-'));
const browser = spawn(BROWSER, [
  '--headless', '--disable-gpu', '--hide-scrollbars',
  `--remote-debugging-port=${PORT}`,
  `--user-data-dir=${userDataDir}`,
  'about:blank',
], { stdio: 'ignore' }); // stdio ignore: geen pipes (sandbox)

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function getWsUrl() {
  // 100 × 250 ms = 25 s: koud gestarte browsers hebben soms meer tijd nodig
  for (let i = 0; i < 100; i++) {
    try {
      const res = await fetch(`http://127.0.0.1:${PORT}/json/list`);
      const list = await res.json();
      const page = list.find((t) => t.type === 'page');
      if (page) return page.webSocketDebuggerUrl;
    } catch (e) { /* nog niet klaar */ }
    await sleep(250);
  }
  throw new Error('geen CDP-endpoint gevonden');
}

let msgId = 0;
const pending = new Map();
const consoleLines = [];
const failures = [];
let ws;

function send(method, params = {}) {
  return new Promise((resolve, reject) => {
    const id = ++msgId;
    pending.set(id, { resolve, reject });
    ws.send(JSON.stringify({ id, method, params }));
  });
}

async function main() {
  const wsUrl = await getWsUrl();
  ws = new WebSocket(wsUrl);
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = rej; });

  ws.onmessage = (ev) => {
    const m = JSON.parse(ev.data);
    if (m.id && pending.has(m.id)) {
      const p = pending.get(m.id);
      pending.delete(m.id);
      if (m.error) p.reject(new Error(m.error.message)); else p.resolve(m.result);
      return;
    }
    if (m.method === 'Runtime.consoleAPICalled') {
      const args = (m.params.args || []).map((a) => a.value !== undefined ? String(a.value) : (a.description || a.type)).join(' ');
      consoleLines.push(`[${m.params.type}] ${args}`);
    }
    if (m.method === 'Runtime.exceptionThrown') {
      const d = m.params.exceptionDetails;
      failures.push(`EXCEPTION: ${d.text} ${d.exception ? d.exception.description : ''}`.trim());
    }
    if (m.method === 'Log.entryAdded') {
      const e = m.params.entry;
      if (['error', 'warning'].includes(e.level)) failures.push(`LOG(${e.level}): ${e.text} ${e.url || ''}`.trim());
    }
    if (m.method === 'Network.loadingFailed') {
      failures.push(`NETWERK: laden mislukt: ${m.params.errorText} ${m.params.type}`);
    }
  };

  await send('Runtime.enable');
  await send('Log.enable');
  await send('Network.enable');
  await send('Page.enable');
  const { targetId } = await send('Target.getTargetInfo');
  await send('Emulation.setDeviceMetricsOverride', { width: W, height: H, deviceScaleFactor: 1, mobile: W < 700 });
  await send('Page.navigate', { url });
  await sleep(6000); // fonts + afbeeldingen de tijd geven

  // extra checks in de pagina zelf
  const checks = await send('Runtime.evaluate', {
    returnByValue: true,
    expression: `(() => {
      const imgs = [...document.images].map(i => ({ src: i.src.split('/').pop(), ok: i.complete && i.naturalWidth > 0 }));
      const links = [...document.querySelectorAll('a[href]')].length;
      return {
        titel: document.title,
        afbeeldingen: imgs,
        afbeeldingenKaput: imgs.filter(i => !i.ok),
        links,
        bodyKinderen: document.body.children.length
      };
    })()`,
  });

  const result = {
    url, viewport: `${W}x${H}`,
    console: consoleLines,
    failures,
    pagina: checks.result.value,
  };
  fs.writeFileSync(path.join(__dirname, 'console-test-result.json'), JSON.stringify(result, null, 2));
  console.log(JSON.stringify(result, null, 2));
  ws.close();
  browser.kill();
  process.exit(0);
}

main().catch((e) => { console.error('TESTSCRIPT-FOUT:', e.message); browser.kill(); process.exit(1); });
