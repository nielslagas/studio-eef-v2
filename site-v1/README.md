# Studio EEF — website v1

Eén pagina, geen build-stap nodig: open `index.html` in een browser.

## Structuur
- `index.html` — de hele pagina (Nederlands)
- `css/style.css` — tokens bovenin (`:root`), kleuren uit het logo
- `assets/logo.svg` — het site-logo (donkere tegel met kleurbanden),
  afgeleid van `../studio-eef-logo.svg` maar sinds de centrering niet meer
  identiek aan die bron; groot getoond in de Over-sectie.
  De compositie is gecentreerd op de tegel: het onderste `<use>`-element
  staat op `translate(11 39.1)` (content-bbox lag linksonder) en het
  backingsurfaat eronder is inkt i.p.v. wit, zodat de tegelrand naadloos
  blijft na de shift. De verticale STUDIO-letters lezen van onder naar
  boven (S onderaan, O bovenaan; y-posities van de glyph-uses gespiegeld,
  elke letter hield zijn eigen x-uitlijning).
- `assets/favicon.svg` — favicon van de kleurenbanden
- `assets/img/werk-*.jpg` — drie AI-impressies (FLUX schnell via Replicate,
  gegenereerd met `../_gen_images.py`; te vervangen door echte projectfoto's)
- `preview.png` — screenshot van de desktopweergave

## Typografie
- Koppen: **Archivo** (700, 110% breed) — strak en stoer
- Lopende tekst: Atkinson Hyperlegible
- Labels/codes: IBM Plex Mono
## Nog in te vullen (zoek op `TODO` of `class="todo"` in index.html)
Placeholders in de pagina zijn zichtbaar gemarkeerd met een mosterthalo +
stippellijn (class="todo"); links/formulieren dragen `data-todo`. Na invullen:
class/attribuut en het bijbehorende `<!-- TODO -->`-commentaar weghalen.
1. **Telefoonnummer** — header-knop, contactkaart en WhatsApp-link (staat nu op 06 12 34 56 78)
2. **E-mailadres** — contactkaart (staat nu op hallo@studio-eef.nl)
3. **Werkgebied** — Over-sectie: "[plaats + regio]"
4. **KvK / BTW / adres** — footer (verplicht in Nederland)
5. **Over EEF** — naam eigenaar, aantal jaar ervaring, evt. team
6. **Schema.org-JSON-LD** — telephone, email en url in de `<head>`

## Beeldmateriaal
De "Impressies"-sectie gebruikt drie AI-gegenereerde beelden (woonkamer,
gevel, verfdetail), consistent gestyled op de huisstijlkleuren. Ze zijn
duidelijk als *impressie* gelabeld — vervang ze zodra er echte
projectfoto's zijn (zelfde bestandsnamen gebruiken en de alt-teksten
aanpassen). Regenereren: `python _gen_images.py` vanuit de maproot.

## Design-beslissingen (vastgelegd voor latere iteraties)
- Verfstaal-kaarten als signature voor de diensten (met ringat en EEF-codes)
- Hero-facade-kaart is zélf een verfstaal: kopband (`.facade-band`) in de
  actieve kleur met gestanst ringgat (papier + inset-schaduw, geen platte
  stip) en mono-label "GEVELSTAAL", daaronder de kleurnaam prominent met
  `aria-live="polite"` (de oude "Gekozen kleur:"-caption verviel)
- Elke staal-knop draagt `data-contrast="licht|donker"`: lichte stalen
  (kalkwit, mosterd, prima-roze) geven inkt-tekst op de band, donkere
  (olijf, houtblauw, antraciet) papier-tekst (`.facade-band--donker`)
- Gevelillustratie (SVG 320×300): rijtjeshuis met baksteen-voegwerkpatroon
  (`<pattern id="voeg">`, alpha .14/.11 zodat het op kijkafstand leest),
  raamroeden-vensters, pannendak + dakgoot + regenpijp, gevelsteen boven
  de deur, stoep onderaan. Deur en bovenraam rechts staan op één as
  (x=209) met de raamkop en deurkozijn-top op één horizontaal (y=190);
  de schoorsteen is vóór het dakvlak getekend met de onderrand ín de
  pannen. Lijnwerk in inkt met beperkte alpha (±2px); glas = kalkwit-staal,
  pannen = houtblauw-staal (de twee toegestane extra tinten), verder
  alleen tokens
- Stalen-grid toont de kleurnamen altijd (mono-label onder elk staal,
  geen hover-only): desktop 6 kolommen, mobiel ≤640px 3×2. Namen wrappen
  tot twee gecentreerde regels (geen ellipsis). Actieve staat via
  aria-pressed met dubbele inkt-ring
- Instructieregel boven de stalen: "Tik op een staal en zie de gevel
  meekleuren." — kort en actief
- Bandkleur/wandkleur-wissel zonder overgang bij prefers-reduced-motion
- Archivo (display) + Atkinson Hyperlegible (body) + IBM Plex Mono (codes)
- Werkwijze genummerd, omdat het een echte volgorde is
- Bewaakt tegen de drie AI-standaardlooks (cream+serif+terracotta etc.):
  de vier logo-kleuren dragen het ontwerp in plaats van één trendaccent
- Accentwoord in de hero: inkt op een mosterd-verfstreek (geen gele letters —
  contrast), met hangende druppel als knipoog naar het vak

## Inspectie-artefacten (niet voor productie)
- `_inspect-desktop-v5.png` / `_inspect-mobile-v5.png` — actuele full-page
  screenshots (na logo-centrering + gevelstaal-kaart + fixronde);
  `_inspect-desktop-v4.png` / `_inspect-mobile-v4.png` = staat vóór de
  fixronde, `v2` = vorige eindstaat, `_inspect-desktop-full.png` /
  `_inspect-mobile-full.png` / `_inspect-hero.png` /
  `_inspect-contact-anchor.png` zijn de nulmeting (vóór).
- `_crop-hero-v5.png` / `_crop-logo-v5.png` — uitsneden van de hero-kaart
  en de logo-tegel op volle resolutie;
  `_vision/logo-standalone-v5.png` — losse logo-render waarmee de marges
  pixelgewijs zijn gemeten (27/26/87/87).
- `_vision/` — tooling en rapporten van de visuele inspectie
  (DeepSeek V4 Flash Vision via `ask-vision.ps1` / `ask-vision-v3.mjs`,
  console-test via CDP, screenshot- en anker-scripts). Rapporten:
  `desktop.txt`, `mobile.txt`, `detail.txt` (nulmeting), `final-desktop.txt`,
  `final-mobile.txt` (vorige eindstaat) en `v3-hero.txt`, `v3-logo.txt`,
  `v3-desktop.txt`, `v3-mobile.txt`, `v3-hero-v5.txt` (deze ronde).
