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
assets/logo.svg     nieuwe wordmark: balkenmotief + kwastveeg + druppel
assets/favicon.svg  kwastveeg-E op inkt-tegel
assets/img/         AI-impressies (werk-*.jpg) — echte foto's volgen
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
inkt op hout 5,2:1 (donkerste rand 4,4:1; alleen grote displaytekst); nooit goud/mosterd als
kleine tekstkleur op licht, nooit olijf-op-inkt voor kritieke onderdelen.

## Typografie

- **Archivo** 700, `font-stretch` 112–115% — koppen, clamp ≈ 2,8–5,5rem,
  `line-height` 1,02, negatieve tracking (−0,015em).
- **Atkinson Hyperlegible** — lopende tekst.
- **IBM Plex Mono** — eyebrow-labels, EEF-codes, verfstaalnamen.
- Zelfde Google Fonts-link als v1 (`display=swap`).

## Motion (kort)

- Easing-tokens: `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)` en
  `--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1)`.
- Hero-signature: kwast over de houten plank, ±2,2s, één keer bij load.
  Mosterd streek + kop worden onthuld door één clip-wipe, synchroon met
  de kwast; daarna eenmalig natte-glans-sheen en druppel. Rechts op de
  plank een statisch afplaktape-detail ("zorgvuldig afgeplakt", vanaf
  ≤900px verborgen). CSS `offset-path` met JS-fallback
  (`getPointAtLength` + rAF, zelfde curve). Zonder JS of bij
  `prefers-reduced-motion`: direct de geschilderde eindstand
  (initial-hidden states alléén actief onder `data-hero`).
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

## Logo v2

- `assets/logo.svg`: het balkenmotief (mosterd/olijf/roze verfstalen die
  EEF vormen) behouden, met één vloeiende mosterd kwastveeg door het
  teken en één roze druppel; F-stam nu kalkwit i.p.v. olijf (contrast).
  Wordmark "Studio Eef" breed/zwaar als zelfstandige vectoren — het
  bestand mag dus nergens een font verwachten (werkt ook als `<img>`).
  In de site zelf staat de naam in echt Archivo (header/footer-tekst).
- `assets/favicon.svg`: kwastveeg-E op inkt-tegel (geen olijf, geen
  filters — te klein voor bristle-ruis).

## TODO's voor de eigenaar

Zoek op `class="todo"`, `data-todo` of `TODO` in `index.html`:
telefoonnummer (header + contact + JSON-LD), e-mail, WhatsApp-link,
KvK/BTW/adres in de footer, `[plaats + regio]` bij Over, en de
placeholdergegevens in de JSON-LD in de `<head>`.
