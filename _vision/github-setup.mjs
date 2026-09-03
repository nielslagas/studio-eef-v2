// Kleine GitHub-API helper voor de eerste setup van de studio-eef repo.
// Token komt via de omgeving (GH_TOKEN) en wordt nooit geprint.
import fs from 'fs';

const token = process.env.GH_TOKEN;
const [, , mode, owner, name] = process.argv;
if (!token || !mode || !owner || !name) {
  console.error('gebruik: node github-setup.mjs <create|pages> <owner> <name>  (GH_TOKEN gezet)');
  process.exit(1);
}

const api = async (path, method, body) => {
  const res = await fetch('https://api.github.com' + path, {
    method,
    headers: {
      Authorization: 'Bearer ' + token,
      Accept: 'application/vnd.github+json',
      'User-Agent': 'studio-eef-setup',
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  let parsed = {};
  try { parsed = text ? JSON.parse(text) : {}; } catch { parsed = { raw: text.slice(0, 300) }; }
  return { status: res.status, body: parsed };
};

if (mode === 'create') {
  const r = await api('/user/repos', 'POST', {
    name,
    private: false,
    has_wiki: false,
    description: 'Studio EEF — schilderwerken binnen en buiten (statische site)',
    homepage: `https://${owner}.github.io/${name}/`,
  });
  if (r.status === 201) console.log('repo aangemaakt: ' + r.body.full_name);
  else if (r.status === 422) console.log('repo bestond al, we gebruiken die: ' + owner + '/' + name);
  else { console.log('FOUT create (' + r.status + '): ' + JSON.stringify(r.body).slice(0, 400)); process.exit(1); }
} else if (mode === 'pages') {
  const r = await api(`/repos/${owner}/${name}/pages`, 'POST', { source: { branch: 'main', path: '/' } });
  if (r.status === 201 || r.status === 204) console.log('Pages ingeschakeld (bron: main / )');
  else if (r.status === 409) console.log('Pages stond al aan');
  else { console.log('FOUT pages (' + r.status + '): ' + JSON.stringify(r.body).slice(0, 400)); process.exit(1); }
} else {
  console.error('onbekende modus: ' + mode);
  process.exit(1);
}
