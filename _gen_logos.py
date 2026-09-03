"""Genereer logo-alternatieven voor Studio EEF via Nano Banana (Replicate).

Vijf richtingen, allemaal binnen het bestaende palet van het originele
Canva-logo: goud #D6AF29, olijf #424631, roze #F37C96, antraciet #231F20
op papier-wit #FAF8F4.
"""
import json
import time
import urllib.request
from pathlib import Path

TOKEN = Path('.replicate_token').read_text().strip()
API = 'https://api.replicate.com/v1/models/google/nano-banana/predictions'
HDRS = {
    'Authorization': 'Bearer ' + TOKEN,
    'User-Agent': 'StudioEEF-site-builder/1.0',
    'Content-Type': 'application/json',
    'Prefer': 'wait',
}

BASIS = (
    "You are designing a flat vector logo for 'Studio EEF', a small friendly "
    "painting and decorating company in the Netherlands. Strict brand palette: "
    "warm gold #D6AF29, olive green #424631, soft pink #F37C96, deep charcoal "
    "#231F20, warm paper white #FAF8F4. Flat minimal vector style: crisp "
    "geometric shapes, no gradients, no 3D, no photorealism, no mockups, no "
    "watermarks. Any text must be spelled exactly 'Studio EEF' or 'EEF', "
    "perfectly legible. Centered composition with generous margins."
)

RICHTINGEN = [
    ('01-bandmonogram',
     "A square deep-charcoal tile as the logo mark. Inside the tile, the "
     "letters 'EEF' in bold rounded geometric letterforms, each letter built "
     "from horizontal rounded paint bands in gold, olive and pink. Below the "
     "tile the word 'STUDIO' in small clean charcoal capitals. Warm "
     "paper-white background."),
    ('02-kwast-wordmark',
     "A single confident hand-painted brush stroke in warm gold sweeps under "
     "the charcoal wordmark 'Studio EEF', hand-lettered with character. A "
     "small pink brush stroke accents the dot of the 'i', one thin olive "
     "green swash underneath. Warm paper-white background."),
    ('03-verfroller',
     "Icon of a paint roller, tilted at a slight angle, leaving a smooth gold "
     "stripe that underlines the clean charcoal wordmark 'Studio EEF'. One "
     "small pink paint drip from the stripe, one olive green stripe detail. "
     "Warm paper-white background."),
    ('04-gevel',
     "A minimal friendly logo: a simple charcoal house outline whose facade "
     "is painted in three vertical stripes - gold, olive and pink - placed "
     "left of the charcoal wordmark 'Studio EEF' in a clean rounded "
     "typeface. Warm paper-white background."),
    ('05-verfstalen',
     "Three overlapping paint sample cards in gold, olive and soft pink, "
     "fanned out like a hand of cards, each card with a small punched hole "
     "and a thin charcoal outline, next to the charcoal wordmark "
     "'Studio EEF'. Warm paper-white background."),
]

MAP = Path('logo-alternatieven')
MAP.mkdir(exist_ok=True)


def genereer(prompt, doel, pogingen=6):
    body = json.dumps({
        'input': {
            'prompt': prompt,
            'aspect_ratio': '1:1',
            'output_format': 'png',
        }
    }).encode()
    for poging in range(1, pogingen + 1):
        req = urllib.request.Request(API, data=body, headers=HDRS, method='POST')
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                uit = json.load(r)
            url = uit.get('output')
            if isinstance(url, list):
                url = url[0]
            with urllib.request.urlopen(
                    urllib.request.Request(url, headers=HDRS),
                    timeout=120) as r:
                doel.write_bytes(r.read())
            return True
        except urllib.error.HTTPError as e:
            if e.code == 429 and poging < pogingen:
                wacht = 20 * poging
                print('   429, wacht %ds...' % wacht)
                time.sleep(wacht)
                continue
            print('   FOUT: %s' % e)
            return False
    return False


for naam, richting in RICHTINGEN:
    doel = MAP / (naam + '.png')
    if doel.exists():
        print('bestaat al, overslaan:', doel)
        continue
    t0 = time.time()
    ok = genereer(BASIS + ' ' + richting, doel)
    print('%s  %.0f s  %s' % (naam, time.time() - t0,
                              'OK' if ok else 'MISLUKT'))
    time.sleep(12)

print('klaar')
