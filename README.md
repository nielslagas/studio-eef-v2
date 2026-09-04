# Studio EEF — site v2 "Verse verf"

Statische één-pager (Nederlands, geen build-stap, geen libraries).
Open `index.html` in een browser; verder is er niets nodig.
Ontwerpbrief: `ONTWERP-V2.md`. Versie 1 (archief): `../site-v1/`.

## Structuur

```
index.html          één-pager: header, hero+kwast, marquee, trustbar,
                    diensten, werk, kleuren (interactieve gevel),
                    werkwijze, over, contact, footer, mobiele CTA-balk
css/style.css       tokens, basis, header, hero-signature, trustbar,
                    secties, scroll-reveals, mobiele CTA
js/main.js          kwast-signature (offset-path + rAF-fallback),
                    header-scrollstate, gevel-verfstalen (--staal),
                    scroll-reveals (IO one-shot), mobiele CTA-IO
assets/logo.svg     B-tegel: Eefs eigen logotegel (uit logo-keuze/ gekopieerd)
assets/favicon.svg  bands-variant van de B-tegel (16px-leesbaar)
assets/img/         hero-materiaal (AI: hero-hout.jpg, verfstreek-mosterd.png,
                    kwast-ronde.png) + werk-*.jpg AI-impressies — echte
                    projectfoto's volgen (werk-*.jpg niet vervangen)
```

## Huisstijl (tokens in `:root`)

| Token | Waarde | Gebruik |
| --- | --- | --- |
| `--olijf` | `#424631` | canvas contact-sectie, dienstkleur |
| `--mosterd` | `#D6AF29` | verse verf: CTA's, streek, cirkels, marquee |
| `--roze` | `#F37C96` | scherp accent (o.a. druppel in logo) |
| `--inkt` | `#231F20` | groot canvas: hero, header, werkwijze, footer |
| `--papier` | `#FAF8F4` | lichte secties, tekst op donker |
| `--gold-soft` | `#E8C558` | mosterd-tekst op donker (9,7:1 op inkt) |
| `--kalkwit` | `#F1EDE4` | materiaal: ruiten, kwast-steel |
| `--houtblauw` | `#3E5C76` | materiaal: dakpannen, kwast-ferrule |
| `--hout` | `#B08A5E` | materiaal: hero-plank (inkt erop: 5,2:1, AA groot) |

Contrastuitgangspunten: inkt op mosterd 7,8:1; papier op inkt 15,4:1;
hero-kop (inkt) staat op het foto-hout onder de inkt-gradient-overlay —
de overlay garandeert het contrast (donkerste banden boven/onder); nooit
goud/mosterd als kleine tekstkleur op licht, nooit olijf-op-inkt voor
kritieke onderdelen. Logo: olijf #6A7150 op inkt ≈ 3,18:1, puur decoratief.

## Typografie

- **Archivo** 700, `font-stretch` 112–115% — koppen, clamp ≈ 2,8–5,5rem,
  `line-height` 1,02, negatieve tracking (−0,015em).
- **Atkinson Hyperlegible** — lopende tekst.
- **IBM Plex Mono** — eyebrow-labels, EEF-codes, verfstaalnamen.
- Zelfde Google Fonts-link als v1 (`display=swap`).

## Motion (kort)

- Easing-tokens: `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)` en
  `--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1)`.
- Hero-signature (materiaal nu fotorealistisch, motion-concept ongewijzigd):
  kwast over de houten plank, ±2,2s, één keer bij load. Het plank-oppervlak
  is `img/hero-hout.jpg` (AI-macro, 1664×600, cover) met een donkere
  inkt-gradient-overlay voor tekstcontrast en
  `filter: saturate(.9) brightness(.95)`. De mosterd streek is
  `img/verfstreek-mosterd.png` (transparante rembg-cut-out, over de volle
  breedte, `object-fit: cover; object-position: 50% 52%`) boven op een
  mosterd-basislak die de droge uitlopende rand aanvult; de streek loopt
  — zoals in het v2-concept — over de volle plankbreedte achter de
  middelste titelregel, met rechts de organische dry-brush-uitloop mét
  druiper en links het strakke begin aan de plankrand); de kwast is de
  fotorealistische ronde kwast met mosterdresten
  (`img/kwast-ronde.png`, cut-out; bron 1664×928, getoond op
  `clamp(88px, 11vw, 140px)` breed — width/height-attributen 140×78,
  vrijwel dezelfde ratio — met de haarpunt linksonder als offset-anchor
  die het pad volgt). Kop + streek worden onthuld door één clip-wipe, synchroon
  met de kwast; daarna eenmalig natte-glans-sheen en druppel. De statische
  afplaktape blijft het foto-hout sluiten (leest ook op echt hout); de
  getekende druppel blijft hangen als accent. CSS `offset-path` met
  JS-fallback (`getPointAtLength` + rAF, zelfde curve). Zonder JS of
  bij `prefers-reduced-motion`: direct de geschilderde eindstand.
- Marquee: mosterd band, schuin −1,5°, `linear`, pauzeert op hover,
  statisch bij reduced motion.
- Trustbar direct onder de marquee: drie procesfeiten uit de eigen
  v1-copy ("Offerte binnen 2 werkdagen" · "Elke dag netjes opgeruimd"
  · "Altijd dezelfde schilder"), statisch, mono-labels, mosterd
  accentlijn — geen verzonnen cijfers (benchmark-directive).
- Scroll-reveals: IntersectionObserver zet één keer `.zichtbaar`
  (daarna `unobserve`); CSS doet `clip-path: inset(0 100% 0 0) →
  inset(0)` (460ms ease-out) met stagger-delays van 60/120/180/240ms per groep.
  Initial hidden alléén onder `html.js-reveal` → zonder JS zichtbaar;
  geen oneindige dashoffset-loops (Safari-valkuil).
- Mobiele CTA-balk (≤640px): "Bel" (tel:-TODO-link) + "Offerte"
  (#contact); verdwijnt via IO zodra #contact in beeld is, safe-area
  bewust; reduced motion: zelfde gedrag zonder transitie.
- Kleuren-gevel: strakke outline (grote vlakken); één `--staal` op de
  kaart herschildert wand, kozijnen en deur (±450ms fill); kozijn/deur
  donkerder via tint-overlay; kleurnaam via `aria-live` (v1-patroon).
- Micro: buttons `scale(0.97)` op `:active` (160ms), nav-onderstreep
  als `scaleX`-kwastveeg (200ms), kaart-lift ≤ 4px. Hover-motion
  alléén binnen `@media (hover: hover) and (pointer: fine)`.
- Geanimeerd wordt uitsluitend `transform` / `opacity` / `clip-path`
  (plus kleur/fill voor statustoestanden zoals de gevel, 450ms).

## Logo (B-keuze, eigen tegel van Eef)

- `assets/logo.svg`: Eefs eigen tegel (keuze B uit `logo-keuze/`), 1-op-1
  gekopieerd uit `logo-keuze/logo-opgeschoond.svg`: inkt-tegel met
  mosterd/roze/olijf verfstalen en de verticale "STUDIO"-letters in wit.
  Enige ingreep in het origineel was de olijf-contrastfix **#6A7150**
  (olijf-op-inkt ≈ 3,18:1 — puur decoratief, geen tekst/informatie in
  die kleur, dus geen contrast-eis). De kwastveeg-wordmark van v2 is
  hiermee uit de site verdwenen (de kwast leeft voort in de hero).
- Header: de tegel op 46px met een dunne papieren rand
  (`box-shadow`-ring, zelfde patroon als de footer-tegel) + "Studio Eef"
  in Archivo ernaast. Over-sectie: de grote plek (±440px) toont dezelfde
  tegel; de "onze vier kleuren"-strook eronder blijft staan.
- `assets/favicon.svg`: vereenvoudigde bands-variant van de B-tegel
  (v1-bouw als referentie): alleen de kleurbanden op posities uit de
  tegel — mosterd/roze per rij, olijf-accenten (#6A7150) en rechts de
  lange olijfstam. De STUDIO-letters en taps-toelopende randjes vallen
  weg: onleesbaar/ruis op 16px.

## TODO's voor de eigenaar

Zoek op `class="todo"`, `data-todo` of `TODO` in `index.html`:
telefoonnummer (header + contact + JSON-LD), e-mail, WhatsApp-link,
KvK/BTW/adres in de footer, `[plaats + regio]` bij Over, en de
placeholdergegevens in de JSON-LD in de `<head>`.

TODO-telconventie: **elementen** met `class="todo"` of `data-todo`
tellen — 7 class-elementen ([plaats+regio], tel, mail, app, KvK, BTW,
adres) + 5 data-todo-elementen. Commentaar-regels met de letterlijke
tekst `class="todo"` matchen mee in naive greps en horen níet tot de
elementtelling.
