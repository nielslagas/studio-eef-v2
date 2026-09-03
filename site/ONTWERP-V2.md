# Ontwerpbrief v2 — "Verse verf" (flitsend & modern)

Opdracht van de eigenaar: v1 (het huisje met kleuren, gebaseerd op het
bestaande logo) voelt oudbollig. De nieuwe site moet flitsender en moderner,
met bewegende beelden — bijvoorbeeld een kwast die over een stuk hout gaat
en verf achterlaat. Logo en stijl mogen mee-evolueren. Kwaliteitsnorm:
Emil Kowalski's design-engineering filosofie + de `animate`-skill
(beslissingsvolgorde: moet het bewegen → doel → tool → properties →
easing/duur → interruptie → reduced-motion).

## Concept

De pagina is een net geschilderd doek. Beweging = verf: alles wat verschijnt,
wordt geschilderd, gewist of herschilderd. Eén signature moment (de kwast in
de hero), daarna restraint: snelle, subtiele reveals en één echte
interactie (de gevel herschilderen). Geen beweging zonder doel, geen loops
die blijven doorratelen.

## Stijl — evolutie, geen revolutie

- Behoud de vijf verplichte tokens (regel 3 in AGENTS.md): olijf `#424631`,
  mosterd `#D6AF29`, roze `#F37C96`, inkt `#231F20`, papier `#FAF8F4` —
  maar gedurfer ingezet: **inkt/olijf als groot canvas**, mosterd als verse
  verf, roze als scherp accent. Contrastrijker en donkerder dan v1.
- Toegestane extra materiaaltinten (zoals v1 ook had): kalkwit `#F1EDE4`,
  houtblauw `#3E5C76`, plus hout-tint voor de hero-plank (warm neutraal,
  bijv. `#9C7A54`-achtig, alleen als "materiaal", nooit als accentkleur).
- Typografie: **Archivo** (display, weight 700, width 110–125%) +
  **Atkinson Hyperlegible** (loop) + **IBM Plex Mono** (labels/codes) —
  zelfde Google Fonts-link als v1. Grote, krappe koppen
  (clamp ≈ 2.8rem–5.5rem, line-height 1.02, negative tracking).
- Vormtaal: strakke grote blokken, radius 16–20px, één schuin element
  (−1,5°) als energie (marquee-band), vette mosterd-strepen als dividers.
- Logo-evolutie (bijgestuurd na vision-baseline van het huidige logo + de
  eerder verkende "Kwast-wordmark"-richting): nieuw `assets/logo.svg` dat het
  **driekleurige balkenmotief** van het huidige logo (mosterd/olijf/roze als
  verfstalen die de letters vormen — hét herkenbare merkenmerk) behoudt, maar
  **gebaar** krijgt: één vloeiende kwastveeg die bijv. de E opbouwt of
  doorkruist, met één roze druppel/accentpunt als knipoog. Wordmark "Studio
  Eef" in Archivo (gewicht 700, breed) — géén handschrift-script (leesbaarheid
  op klein formaat) en géén generieke "streep-onder-de-naam"-truc. Let op
  contrast: nooit olijf-op-inkt voor kritieke onderdelen (zwakte van het
  huidige logo); mosterd/papier op inkt mag. Nieuwe `assets/favicon.svg`:
  kwastveeg-E op inkt-tegel. Het oude logo blijft onaangeroerd als
  bronmateriaal in de root en in `site-v1/`.

## Motion-plan (per element: frequentie-tier → doel → ingrediënten)

Tokens in `:root`: `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)`,
`--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1)`. UI-interacties ≤ 300ms;
marketing-mag langer.

1. **Hero-signature (rare/first-time → Delight): kwast over hout.**
   Een houten plank (SVG-houtnering via feTurbulence of strakke CSS-lamellen)
   over de volle breedte van de hero-copy. Een getekende SVG-kwast (steel +
  haar, inktlijnen) beweegt in één vloeiende slag van links naar rechts
   (±1,8–2,4s, `--ease-in-out`); vlak achter het haar verschijnt een mosterd
   verfstreek met licht ruige rand (stroke-dashoffset-reveal op een pad, of
   clip-path-wipe gesynchroniseerd via `getPointAtLength`). De streek
   onthult de headline-tekst (tekst = mask/pad in de streek, of tekst
   eronder die door de wipe zichtbaar wordt). Kwast exit rechts; daarna
   eenmalige subtiele "natte-glans"-sheen over de streep. **Eenmalig bij
   load, geen loop.** Kwastbeweging: CSS offset-path met JS-fallback
   (`getPointAtLength` + WAAPI), lichte rotatie/wiebel voor leven.
   `prefers-reduced-motion`: direct de geschilderde eindstand.
2. **Scroll-reveals (occasional → Preventing jarring changes):** secties en
   kaarten komen binnen met een korte "verf-wipe" (clip-path inset, 400–600ms,
   ease-out) + stagger 30–80ms per element; IntersectionObserver, `once`.
   Content staat er altijd al (progressive enhancement zonder JS = zichtbaar).
3. **Kleuren-gevel (state indication / explanation):** de opvolger van het
   v1-huisje, flitsender: grote strakke gevel-outline (SVG, lijnwerk inkt op
   papier) waar verfstalen direct grote vlakken (wand, kozijnen, deur)
   herschilderen — fill/color-transition ±450ms ease. Kleurnaam prominent
   met `aria-live="polite"` (patroon uit v1 hergebruiken).
4. **Marquee-band (constant → linear):** één schuine mosterd band (−1,5°)
   tussen hero en diensten met de dienstwoorden, `animation-timeline`
   niet nodig — CSS keyframes linear, `aria-hidden` duplicaat, pauzeert op
   hover. Reduced-motion: statische regel.
5. **Micro-interacties (tens/day → near-imperceptible):** buttons
   `scale(0.97)` op `:active` (120–160ms ease-out), nav-onderstreep als
   kwastveeg die `scaleX` van links opbouwt (200ms ease-out), kaart-lift
   ≤4px. Hover-motion alléén binnen `@media (hover: hover) and
   (pointer: fine)`.

**Never** (automatische AFKEUR): `transition: all`, entrées vanaf
`scale(0)`, `ease-in` op UI-animaties, keyframes op rapid-trigger elementen,
`width/height/margin/padding/top/left` animeren, ongegate hover-motion,
ontbrekende `prefers-reduced-motion`.

## Paginastructuur (één-pager, NL)

1. **Header** — sticky, inkt; compacte wordmark + nav + Bel-knop (TODO's
   behouden!). Bij scrollen subtiel smaller/donkerder (250ms ease-out).
2. **Hero** — inkt canvas; hout-plank + kwast-signature; headline
   "Een frisse laag verf voor je huis." (of strakker: laat engineer de
   v1-copy herzien met behoud van boodschap); sub + 2 CTA's (mosterd primair,
   ghost secundair).
3. **Marquee-band** — mosterd, schuin, dienstenwoorden.
4. **Diensten** — papier sectie; verfstalen-kaarten uit v1 geherinterpreteerd:
   strakker, groter, met EEF-codes (mono) en kleurband mosterd/olijf/roze.
5. **Werk / impressies** — de drie bestaande `werk-*.jpg` (regel 2: niet
   vervangen), paint-wipe reveal, caption met tag "Impressie".
6. **Kleuren** — interactieve gevel (zie motion-plan 3) + stalen; tekst over
   kleuradvies ("Twijfel je? We nemen de verfstalen mee.")
7. **Werkwijze** — inkt sectie, 5 genummerde stappen (v1-copy), stagger
   reveal, mosterd nummer-cirkels.
8. **Over Eef** — nieuw logo groot + de vier kleuren als mini-stalen; v1-copy
   met TODO-placeholders ([plaats + regio] etc.).
9. **Contact** — olijf sectie; Bel/Mail/App-kaarten (TODO's behouden).
10. **Footer** — inkt; KvK/BTW/adres-TODO's behouden.

Alle v1-copy hergebruiken waar mogelijk (`site-v1/index.html` als bron).
JSON-LD + meta overnemen uit v1 (incl. TODO-commentaar).

## Techniek

- `index.html` + `css/style.css` + `js/main.js` — vanilla, geen build-stap,
  geen libraries (GSAP nódig zou moeten zijn; WAAIO + CSS + SVG volstaan).
- Toegankelijkheid: skip-link, `:focus-visible` (currentColor-patroon v1),
  contrast ≥ AA (goud nooit als tekstkleur op licht; gold-soft `#E8C558` op
  donker), `prefers-reduced-motion` overal, geen essentiële info alléén in
  animatie.
- Performance: alleen `transform`/`opacity`/`clip-path` animeren;
  `will-change` spaarzaam; hero-animatie één keer; fonts `display=swap`.
- Responsive: mobiel-eerst check op 390px; menu ≤900px (details/patroon v1
  mag, strakker gestyled).

## Vaste regels (uit AGENTS.md, onverkort)

1. TODO-placeholders nooit invullen — overnemen uit v1 (class="todo",
   data-todo, JSON-LD-commentaar).
2. `assets/img/werk-*.jpg` niet vervangen/regenereren — staan al in
   `site/assets/img/`.
3. Huisstijl-tokens in `:root`; geen generieke AI-looks.
4. README-sync: beslissingen vastleggen in `site/README.md`.

## Onderzoeksinput

### Benchmark schilderswebsites (researcher-rapport, 2025-09)

Kernbevindingen (bron: bureaucases NL/BE + internationale sites, o.a.
Improovy, The Good Painter, Draaisma, ACTLD, Mylands):

1. **Boven de vouw: wat + waar + bewijs + één actie.** Hero belooft het
   vak, direct daaronder een **trustbar** met concrete procesfeiten.
2. **Werk eerst, woorden later** — gecureerd (3 impressies is goed), groot
   en rustig tonen.
3. **Rustige basis + één krachtig accent per vlak** — kleur tonen via
   beheersing (grote vlakken), nooit via veel kleuren tegelijk (Mylands-les).
4. **Beweging demonstreert vakmanschap** (kwaststreek, voor/na), het is geen
   decoratie. Precies onze kwast-signature.
5. **Cliché-lijst (verboden in v2):** stockfoto-helm/overall-clichés,
   kleurenchaos/regenboog-gradients, autoplay-video met geluid, hero-carousel,
   "Welkom op onze website"-copy, superlatieven zonder bewijs, en de
   **skeuomorfe huisje/verfblik-look** (= precies de v1-look die we vervangen).
6. **Één dominante CTA** ("Vraag een offerte") overal de primaire actie;
   secundaire actie altijd rustiger (ghost).

### Directives voor batch B (uit de benchmark)

- **Trustbar direct onder de hero/marquee:** smalle band met 3 concrete
  procesfeiten uit de v1-copy (geen verzonnen cijfers!): "Offerte binnen
  2 werkdagen" · "Elke dag netjes opgeruimd" · "Altijd dezelfde schilder".
  Statisch, mono-labels, mosterd accentlijnen.
- **Sticky mobiele CTA-balk** (alleen ≤640px): "Bel" + "Offerte" als anchors
  naar #contact / tel:-link (TODO-telefoonlink hergebruiken); verdwijnt wanneer
  #contact in beeld is (IntersectionObserver). Reduced-motion: gewoon tonen.
- **Geen FAQ/carousel/review-widget toevoegen** — geen echte reviews van
  eigenaar bekend; anonieme of verzonnen reviews zijn verboden volgens het
  onderzoek. Schaalbaar later toe te voegen.
- Voor/na-slider en review-cards zijn **toekomstige** uitbreidingen zodra er
  echte projectfoto's/reviews zijn (werkt niet met de AI-impressies).

### Technieken kwast-animatie (researcher-rapport, bronnen in het rapport)

Verwerk deze bevindingen in de hero (batch A/B) en scroll-reveals:

1. **Verfstreek:** `pathLength="1"` op het pad → `stroke-dasharray: 1;
   stroke-dashoffset: 1` naar `0` animeren (geen maten rekenen).
   Realisme: 2–4 gelaagde parallelle strokes (mosterd + donkerder ondertoon +
   lichte highlight, eigen width/opacity/kleine timing-stagger),
   `stroke-linecap="round"`, en een statisch feTurbulence + feDisplacementMap
   (scale ~4–8) óver de verfgroep voor rafelige randen. Filters nòit animeren.
2. **Headline-reveal:** in **één inline SVG** met `<mask>` waarin `<text>`
   zit (Safari ondersteunt animerende SVG-masks via CSS `mask-image` niet —
   WebKit bug 296619). De echte `<h1>` blijft in de DOM (SEO/screenreaders);
   de SVG is `aria-hidden="true" focusable="false"`.
3. **Kwastbeweging:** robuustste aanpak = één rAF-loop als dirigent die
   progress (met easing) berekent en zowel `stroke-dashoffset` als de
   kwast-`<g>`-transform stuurt (positie via `getPointAtLength`, hoek via
   twee nabije punten) — geen drift, werkt overal (ook oudere Safari), en
   responsief omdat kwast en streek in dezelfde SVG-ruimte leven. CSS
   `offset-path` mag als progressive enhancement.
4. **Hout:** CSS repeating-linear-gradients (planken + nerf) als lichtgewicht
   basis, eventueel aangevuld met statische anisotrope feTurbulence
   (`baseFrequency` ≈ `0.012 0.14`) voor nerf; `mix-blend-mode: multiply`
   op de verf over hout.
5. **Scroll-reveals:** IntersectionObserver zet één keer een class (daarna
   unobserve); CSS doet `clip-path: inset(0 100% 0 0) → inset(0)` met
   transition-delay-stagger. Initieel verbergen alléén via die JS-class →
   zonder JS blijft alles zichtbaar.
6. **Valkuilen:** geen oneindige dashoffset-loops (Safari-CPU); start
   dashoffset op exacte waarden (geen negatieven); meerdere gelijktijdige
   paden in Safari staggern; bij `prefers-reduced-motion` direct de
   eindstand tonen en de kwast verbergen; `will-change` alleen tijdens de
   animatie.
