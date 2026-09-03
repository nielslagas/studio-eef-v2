"""Genereer impressiebeelden voor Studio EEF via Replicate (FLUX schnell).

Leest .replicate_token, controleert de account, genereert drie beelden
in consistente stijl en slaat ze op in site/assets/img/.
"""
import json
import time
import urllib.request
import urllib.error
from pathlib import Path

TOKEN = Path('.replicate_token').read_text(encoding='utf-8').strip()
API = 'https://api.replicate.com/v1'
OUT = Path('site/assets/img')
OUT.mkdir(parents=True, exist_ok=True)

STIJL = ('Editorial photograph for a painting company, warm natural daylight, '
         'muted warm palette, calm composition, realistic textures, high detail, '
         'photorealistic, no text, no watermark')

BEELDEN = [
    ('werk-woonkamer.jpg',
     'Editorial interior photograph of a Dutch living room with freshly painted '
     'warm off-white matte walls, crisp white ceiling and door frame, warm afternoon '
     'sunlight through a tall window casting soft shadows, linen sofa with olive '
     'green cushions, oak floor, ' + STIJL),
    ('werk-gevel.jpg',
     'Editorial photograph of a classic Dutch rowhouse with a freshly painted '
     'muted olive green facade and crisp white window frames and front door, '
     'clean painted cornices, soft daylight, quiet street with brick sidewalk, '
     'small front garden with low hedge, ' + STIJL),
    ('werk-detail.jpg',
     'Close-up editorial photograph of a paint roller applying a smooth wet layer '
     'of warm mustard yellow paint onto an interior wall, crisp straight paint edge '
     'along masking tape, subtle texture of fresh paint, shallow depth of field, ' + STIJL),
]


def api_request(url, data=None, wait=False):
    headers = {'Authorization': 'Bearer ' + TOKEN,
               'User-Agent': 'StudioEEF-site-builder/1.0'}
    if wait:
        headers['Prefer'] = 'wait'
    if data is not None:
        headers['Content-Type'] = 'application/json'
        data = json.dumps(data).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers=headers)
    with urllib.request.urlopen(req, timeout=180) as resp:
        return json.loads(resp.read().decode('utf-8'))


def download(url, doel):
    req = urllib.request.Request(url, headers={'User-Agent': 'StudioEEF-site-builder/1.0'})
    with urllib.request.urlopen(req, timeout=120) as resp:
        Path(doel).write_bytes(resp.read())


def main():
    print('== accountcheck ==')
    try:
        account = api_request(API + '/account')
        print('token geldig voor:', account.get('username'), '/', account.get('type'))
    except urllib.error.HTTPError as e:
        print('ONGELDIGE TOKEN of fout:', e.code, e.read().decode('utf-8')[:300])
        return 1

    ok = 0
    for naam, prompt in BEELDEN:
        print('== genereer', naam, '==')
        try:
            pred = api_request(
                API + '/models/black-forest-labs/flux-schnell/predictions',
                data={'input': {'prompt': prompt, 'aspect_ratio': '3:2',
                                'num_outputs': 1, 'output_format': 'jpg',
                                'output_quality': 90}},
                wait=True)
        except urllib.error.HTTPError as e:
            print('  fout bij aanmaken:', e.code, e.read().decode('utf-8')[:300])
            continue

        # Prefer: wait geeft meestal direct succeeded; anders pollen
        pogingen = 0
        while pred.get('status') not in ('succeeded', 'failed', 'canceled') and pogingen < 60:
            time.sleep(2)
            pred = api_request(API + '/predictions/' + pred['id'])
            pogingen += 1

        if pred.get('status') != 'succeeded':
            print('  mislukt:', pred.get('status'), str(pred.get('error'))[:200])
            continue

        url = pred['output'][0] if isinstance(pred['output'], list) else pred['output']
        doel = OUT / naam
        download(url, doel)
        print('  opgeslagen:', doel, doel.stat().st_size, 'bytes')
        ok += 1

    print('== klaar:', ok, 'van', len(BEELDEN), 'beelden ==')
    return 0 if ok == len(BEELDEN) else 2


if __name__ == '__main__':
    raise SystemExit(main())
