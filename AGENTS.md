# AGENTS.md — Studio EEF website

Project: statische één-pager (Nederlands, geen build-stap) in `site/`.
Open `site/index.html` in een browser; er is verder niets nodig.

## Mappenstructuur (sinds de v2-redesignronde)

- `site/` — de actieve site (v2: flitsend redesign met beweging)
- `site-v1/` — archief van de eerste opzet (huisje/verfstalen-look), ter referentie
- `_vision/` — inspectie- en testtooling + rapporten (versie-onafhankelijk)
- `logo-alternatieven/`, `studio-eef-logo.svg`, `eef.pdf.pdf`, `_gen_*.py` —
  bronmateriaal en generatiescripts (niet verplaatsen: de scripts verwijzen
  naar relatieve paden vanuit de projectroot)

## Modellenvaste per rol (afgesproken met de eigenaar)

| Rol | Model | Route |
| --- | --- | --- |
| Orchestrator (planning, coördinatie) | glm-5.3 | sessie-default (zai) |
| **Fullstack engineer (implementatie)** | **glm-5.3** | subagent op sessie-default (geen override) |
| **Reviewer (code/diff)** | **deepseek-v4-pro** | provider `deepseek` (native API) |
| Tester (tests/builds) | glm-5.3-flash | provider `zai` (flat-rate) |
| Vision-check (routine screenshots) | glm-5.3-flash | provider `zai` (flat-rate, text+image) |
| Vision-eindoordeel (nulmeting) | deepseek-v4-flash-vision-exp | provider `deepseek` |
| **Researcher (achtergrond/web)** | **glm-5.3-flash** | provider `zai` (flat-rate, 1M context) |
| Beeldgenerator (AI-beelden) | glm-5.3 | subagent (sessie-default) met replicate-skills |

De providers `zai` (GLM Coding Plan, flat-rate) en `deepseek` staan in
`~/.dsh/settings.yaml` (deepseek-key: `DEEPSEEK_API_KEY` uit
`~/.dsh/.credentials.yaml`). Volumerollen (tester, vision-check, researcher)
draaien op zai/glm-5.3-flash; review als workflow-agent met
`{ provider: "deepseek", model: "deepseek-v4-pro" }` en het vision-eindoordeel
idem met `model: "deepseek-v4-flash-vision-exp"` — DeepSeek blijft bewust
ingezet waar onafhankelijkheid van de implementerende modelfamilie telt.
deepseek-v4-flash blijft fallback voor research als de zai-route onverhoopt
niet beschikbaar is.

De fullstack engineer is een gewone subagent zonder provider/model-override
(draait dus op glm-5.3): krijgt de goedgekeurde punten + deze vaste regels
mee, laadt vóór UI-werk de `frontend-design` skill, werkt in batches en
levert per batch af voor review. Bij grotere changes meerdere engineers
parallel over onafhankelijke bestanden.

Let op: op OpenRouter is de vision-slug geblokkeerd door het databeleid van
die key — altijd de native provider gebruiken. deepseek-v4-flash is
tekst-only (geen read_image); glm-5.3-flash wél vision-capable
(`input: [text, image]` in settings.yaml).

## vaste regels voor dit project

1. **TODO-placeholders nooit zelf invullen.** Zoek op `class="todo"`, `data-todo`
   of `TODO` in `site/index.html`. Markeringsstijl: `.todo` (mosterthalo +
   stippellijn). De eigenaar vult telefoon, e-mail, KvK/BTW/adres, werkgebied
   en de JSON-LD zelf in.
2. **AI-impressies (`site/assets/img/werk-*.jpg`) niet vervangen of regenereren**
   — daar komen echte projectfoto's (zelfde bestandsnamen, alt-teksten bijwerken).
3. **Huisstijl:** olijf `#424631`, mosterd `#D6AF29`, roze `#F37C96`,
   inkt `#231F20`, papier `#FAF8F4`. Tokens in `:root` van `site/css/style.css`.
   Geen generieke AI-looks (cream+serif+terracotta, paarse gradients).
4. **README-sync:** wijzigingen in typografie/kleuren/structuur ook vastleggen
   in `site/README.md`.

## standaardprompts & skills (bewezen in dit project)

**Engineer (glm-5.3, subagent):** roept vóór UI-werk eerst de skill-tool aan
met de exacte naam `frontend-design`. Prompt-inhoud per batch: de
goedgekeurde punten, de vaste regels hierboven, en "werk in batches, lever
per batch af". Grotere changes: meerdere engineers parallel over
onafhankelijke bestanden (workflow met `agent()`-hooks of losse subagents).

**Reviewer (deepseek-v4-pro):** geef mee (a) de lijst wijzigingen sinds
vorige review, (b) laat hem index.html + style.css volledig lezen, (c) de
rubric: A CSS-correctheid/cascade/specificity, B HTML-geldigheid/aria/refs/
ankers, C toegankelijkheid/contrast (claims laten narekenen), D
huisstijl-en codestijl-consistentie, E rot/restjes. Vraag altijd om
`OORDEEL: GOED / GOED-MET-OPMERKINGEN / AFKEUR` + quick wins, en
"pas niets aan — alleen review".

**Vision-inspectie (two-tier):** routine-checks tijdens iteratie via
`subagent_vision_quick` (zai/glm-5.3-flash, flat-rate); eindoordeel via
`subagent_vision` of ask-vision.ps1 (deepseek-v4-flash-vision-exp,
-MaxTokens ≥ 6000 — het model redeneert vóór het antwoordt). Vraag per sectie
concreet (hiërarchie, witruimte, contrast, huisstijl, storende elementen), noem
secties bij naam, en laat eindigen met "OORDEEL:" + rapportcijfer +
samenvatting. Screenshots > 2000px hoog knippen in plakken van ~1100px met 80px
overlap (assess-final.ps1 heeft daar een Get-Slices-helper).

**Researcher (glm-5.3-flash):** één zelfstandige achtergrondvraag per agent,
antwoord met bronnen, parallel starten aan het begin van de ronde (kan de
web_search-tool gebruiken; deepseek-v4-flash als fallback).

**Beeldgenerator (AI-beelden via Replicate):** gewone subagent die allereerst
de skills `run-models` + `prompt-images` laadt (`prompt-videos` voor video).
Vaste spelregels:
- Token uit `.replicate_token` in de projectroot — nóóit printen of
  committen (staat in `.gitignore`).
- Vóór elke serie: budget checken; zonder expliciete opdracht max ~€0,50 per
  keer, boven €2,-- eerst overleggen met de eigenaar.
- Raw generaties naar `img-gen/` (projectroot, naam als
  ` <onderwerp>-<model>-<n>.png/jpg/webp`); alléén gecureerde assets
  verhuizen naar `site/assets/`, mét alt-tekst en README-sync (regel 4).
- Harde vuistregels: nóóit tekst/letters door het model laten genereren
  (tekst = echte HTML/SVG eroverheen); huisstijlkleuren expliciet in de
  prompt benoemen; `werk-*.jpg` nooit vervangen (regel 2); AI-beelden die
  als "werk" getoond worden zijn impressies → als zodanig labelen.
- Replicate-output-URL's verlopen na 1 uur → direct downloaden naar `img-gen/`.
- PoC en werkwijze staan in de gitgeschiedenis (eerste run: hout-macro,
  flux-schnell, sept. 2026).

**Skills:** `frontend-design` (UI-werk, bovenstaande), geen overige nodig;
`cordis-plugin-development` / `editing-cordis-compositions` alleen bij
harness-uitbreidingen; replicate-skills (`run-models`, `prompt-images`,
`prompt-videos`, `find-models`) alleen voor de beeldgenerator-rol.

## testprotocol vóór oplevering (scripts in `_vision/`)

```pwsh
# console-fouten + kapotte afbeeldingen (desktop en mobiel)
node _vision/console-test.js "file:///D:/Projects/Eva Aukema/Studio-Eef/site/index.html" 1280 900
node _vision/console-test.js "file:///D:/Projects/Eva Aukema/Studio-Eef/site/index.html" 390 844

# anker-landing onder de sticky header
node _vision/anchor-test.js werkwijze 390

# full-page screenshots (daarna vision-check)
node _vision/screenshot-full.js "file:///D:/Projects/Eva Aukema/Studio-Eef/site/index.html" 1280 site/_inspect-desktop.png
```

Vision-check: `_vision/ask-vision.ps1 -Image <png> -Vraag "..."`.
Poort-tip: na elkaar gestarte CDP-scripts botsen soms op de debug-poort —
een `Start-Sleep 3` ertussen lost dat op.

## status

- **Route A + logo B (live, sept. 2026):** Eefs originele logo-tegel keerde
  terug (olijf-contrastfix #6A7150, 3,18:1 decoratief) in header/Over/favicon
  (bands-variant). Hero kreeg fotorealistisch materiaal via de
  beeldgenerator-pijplijn: eiken plank-foto (hout-macro-final), mosterd
  verfstreek-cut-out (naar #D6AF29 getint), ronde huisschilderskwast-cut-out
  (qwen-3, na vergelijking gehandhaafd boven qwen-4 i.v.m. pseudo-tekst op
  de klem). Kwaliteitsronde: review deepseek-v4-pro
  **GOED-MET-OPMERKINGEN** (quick wins toegepast, incl. herstel TODO-halo's
  op contactwaardes — oorzaak: `class="contact-value todo"` matchte niet op
  naive greps; nu v1-patroon); tester 5/6 PASS (telconventie gepind: **7×
  class="todo" + 5× data-todo = 12 elementen**; commentaar-regels met de
  letterlijke tekst `class="todo"` tellen niet); vision-eindoordeel
  **8,5/10 desktop, 9/10 mobiel** (rapporten `_vision/final-routea-*.txt`).
  Beeldgenerator-totaalkosten heel traject: ±$0,30.
- **v2 "Verse verf" (actief, in `site/`)** — opgeleverd 2025-09: flitsend redesign
  met kwast-over-hout-hero (signature-animatie), nieuw logo (balkenmotief +
  kwastveeg), trustbar, interactieve kleurengevel, scroll-reveals, mobiele
  CTA-balk. Kwaliteitsronde: review deepseek-v4-pro
  **GOED-MET-OPMERKINGEN** (alle quick wins toegepast: README-sync,
  contrastgetallen 7,8/15,4/5,2/9,7:1, typo, unused id); tester 7/8 PASS
  (enige afwijking was een TODO-telconventie; 13 markeringen = v1-set +
  mobiele Bel-knop, niets ingevuld); vision-eindoordeel
  deepseek-v4-flash-vision-exp **8,5/10 desktop, 9/10 mobiel**
  (rapporten: `_vision/final-v2-desktop.txt`, `_vision/final-v2-mobile.txt`;
  eindmeting via `_vision/assess-final-v2.ps1`). Ontwerpbrief:
  `site/ONTWERP-V2.md` (incl. onderzoeksinput).
- v1 (archief in `site-v1/`): laatste review deepseek-v4-pro **GOED** — 2025-10,
  nulmeting 8/10 desktop en 8,5/10 mobiel (rapporten in `_vision/*.txt`).
- **GitHub:** nieuwe repo `nielslagas/studio-eef-v2` (main = heel dit project,
  gh-pages = alleen de site zelf) — live voor Eef:
  **<https://nielslagas.github.io/studio-eef-v2/>**. De oude v1-repo
  `nielslagas/studio-eef` is onaangeroerd gelaten; de oude lokale .git staat
  in `.git-v1-backup/` (ge-ignored).
- Open voor de eigenaar: de TODO-placeholders uit regel 1 hierboven.
- Optioneel batch C: e-opening in logo.svg voor echt 24px-gebruik, echte
  Archivo-glyph-paden in de wordmark, gevoelscheck mobiel op echt apparaat
  (safe-area + reveal-timing).
