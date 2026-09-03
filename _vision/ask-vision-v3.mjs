// Vision-beoordeling v4 (logo-centrering + gevelkaart) via DeepSeek vision.
// Node i.p.v. curl: de sandbox weigert schannel-referenties (SEC_E_NO_CREDENTIALS);
// node gebruikt OpenSSL en werkt wél. Sluiten aan op de uitsneden die de
// PowerShell-slice-step op schijf zet.
import fs from 'fs';
import path from 'path';

const dir = 'D:/Projects/Eva Aukema/Studio-Eef/site/_vision';
const dk = fs.readFileSync('C:/Users/Gebruiker/.dsh/.credentials.yaml', 'utf8')
  .match(/DEEPSEEK_API_KEY:\s*(\S+)/)[1];
const kleuren = 'Huisstijl: olijf #424631, mosterd #D6AF29, roze #F37C96, inkt #231F20, papier #FAF8F4. Nederlandse een-pager van schilderbedrijf Studio EEF.';

function dataUrl(p) {
  const mime = p.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
  return 'data:' + mime + ';base64,' + fs.readFileSync(p).toString('base64');
}

async function ask(naam, prompt, files) {
  const content = [{ type: 'text', text: prompt }];
  for (const f of files) content.push({ type: 'image_url', image_url: { url: dataUrl(path.join(dir, f)) } });
  const body = { model: 'deepseek-v4-flash-vision-exp', messages: [{ role: 'user', content }], max_tokens: 6000, temperature: 0.3 };
  try {
    const res = await fetch('https://api.deepseek.com/chat/completions', {
      method: 'POST',
      headers: { Authorization: 'Bearer ' + dk, 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
    });
    const j = await res.json();
    if (j.error) { console.log(`FOUT API ${naam}: ${j.error.message}`); return; }
    let t = j.choices?.[0]?.message?.content || j.choices?.[0]?.message?.reasoning_content || '';
    fs.writeFileSync(path.join(dir, naam + '.txt'), t);
    console.log(`== ${naam} OK (${t.length} tekens) ==`);
  } catch (e) {
    console.log(`FOUT ${naam}: ${e.message}`);
  }
}

const pHero = `Je bent vision inspector. Deze uitsnede toont de herontworpen 'gevelstaal'-kaart in de hero van ${kleuren}. De kaart was eerst een simpel streepjeshuis en is nu opgezet als een verfstaal: kopband in de actieve kleur (met ringgat en de kleurnaam 'Mosterd'), daaronder een geïllustreerde Nederlandse gevel die meekleurt, en zes kleurstalen met namen.

Beoordeel IN HET NEDERLANDS, concreet en kritisch:
1) Kopband: hiërarchie van GEVELSTAAL-label, ringgat en kleurnaam; contrast van de tekst op de band.
2) Huisillustratie: leest het als een vakmatig getekende gevel of nog als kleutertekening? Kijk naar lijnvoering, baksteenstructuur, vensters, deur, dak, stoep, en of elementen correct op elkaar aansluiten (raakvlakken, uitlijningen, overlappende onderdelen).
3) Stalenrij: zijn alle zes namen volledig leesbaar (let specifiek op 'Prima-roze')? Oogt de rij netjes uitgelijnd?
4) Totale kaart: witruimte, samenhang met de rest van de huisstijl, storende elementen.
Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en een zinsnijd samenvatting.`;

const pLogo = `Je bent vision inspector. Deze uitsnede toont het logo van ${kleuren}: een inktkleurige tegel met daarin een verfstaal-rastertje (geel/olijf/roze blokken) en verticale witte letters 'STUDIO'. De inhoud is zojuist gecentreerd in de tegel (eerder hing hij linksboven).

Beoordeel IN HET NEDERLANDS:
1) Zit de inhoud (letters + blokken) nu optisch gecentreerd in de tegel, zowel horizontaal als verticaal? Schat de marges links/rechts en boven/onder.
2) Is er ergens een witte rand, kleurstaart of niet-opgevuld hoekje zichtbaar aan de tegelrand?
3) Oogt het geheel netter en uitgebalanceerd?
Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en een korte samenvatting.`;

const pDesktop = `Je bent vision inspector en beoordeelt de bijgewerkte desktopversie (volledige pagina in plakken van boven naar beneden, met overlap) van ${kleuren}.

Zojuist gewijzigd: (1) het logo (inkttegel in de header en in de Over-sectie) is gecentreerd; (2) de hero-kaart is een 'gevelstaal' met kleurbare huisillustratie en stalenrij met zichtbare namen.

Beoordeel IN HET NEDERLANDS:
1) Sluiten de gewijzigde hero-kaart en het logo visueel aan op de rest van de pagina (diensten-stalen, impressies, werkwijze, over, contact)?
2) Zijn er elders op de pagina elementen stukgegaan of uit balans geraakt?
3) Wat zijn de twee zwakste plekken van de hele pagina nu (concreet, met sectienaam)?
Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en een zinsnijd samenvatting.`;

const pMobile = `Je bent vision inspector en beoordeelt de mobiele versie (390px, volledige pagina in plakken, met overlap) van ${kleuren}.

Zojuist gewijzigd: de hero-kaart ('gevelstaal' met kleurbare huis en stalen-grid) en het gecentreerde logo.

Beoordeel IN HET NEDERLANDS:
1) Hero-kaart op mobiel: band, huis en stalen (3x2) leesbaar en netjes? Alle zes kleurnamen volledig zichtbaar?
2) Header met logo-tegel en menuknop: gebalanceerd?
3) Blijft de rest van de pagina (diensten, impressies, werkwijze, over, contact) netjes?
Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en een zinsnijd samenvatting.`;

// Eindronde: alleen de hero-kaart opnieuw beoordelen (v5, na fixronde).
const slices = (naam) => fs.readdirSync(dir).filter((f) => f.startsWith(naam + '-slice-')).sort();
const pHeroV5 = `Je bent vision inspector. Deze uitsnede toont de herontworpen 'gevelstaal'-kaart in de hero van ${kleuren}, na een fixronde: de kleurnamen wrappen nu (geen afkapping meer), de deurkolom staat op één as met het bovenraam, de baksteenstructuur is zichtbaarder, de schoorsteen zit in het dakvlak, het ringgat in de kopband valt naar binnen gestanst, en het ritme is strakker.

Beoordeel IN HET NEDERLANDS, concreet en kritisch:
1) Zijn de zes kleurnamen volledig leesbaar?
2) Leest het huis nu als vakmatige illustratie? Nog keerpen of aansluitfouten (deur/venster, schoorsteen, dak, stoep)?
3) Kopband met ringgat en kleurnaam: leest het als een echt verfstaal?
4) Witruimte en ritme van de kaart.
Eindig met "OORDEEL:" gevolgd door een rapportcijfer (1-10) en een zinsnijd samenvatting.`;
await ask('v3-hero-v5', pHeroV5, ['../_crop-hero-v5.png']);
console.log('KLAAR');
