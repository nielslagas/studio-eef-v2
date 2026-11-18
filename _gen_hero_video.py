"""Genereer de hero-video voor Studio EEF via Replicate — variant "Fries huis".

Route (gekozen door de eigenaar, sept. 2026): de clip begint op een Friese
gevel en eindigt in de verf. Eén rustige beweging, geen voor/na.

    stap 1  flux-schnell  -> close-up van een geschilderd muurvlak (het eindbeeld)
    stap 2  p-video       -> beginbeeld (gevel) + eindbeeld (verf), 5 s, 720p

Gebruik:
    python _gen_hero_video.py verfstil   # alleen het eindbeeld genereren
    python _gen_hero_video.py video      # de clip maken (beide beelden moeten bestaan)

Het beginbeeld komt uit img-gen/fries-huis-4x3.jpg (uitsnede van de door de
eigenaar aangeleverde foto). Ruwe output blijft in img-gen/; alleen gecureerde
assets gaan naar site-v3/assets/video/. Het token wordt nooit geprint.

Eerdere variant "roller" (flux-seed + p-video, $0,10) is vervallen: in het
midden van die clip viel de roller uit elkaar (zie _vision/clip1-frames-roller.png).
"""
import json
import sys
import time
import uuid
import urllib.request
import urllib.error
from pathlib import Path

TOKEN = Path('.replicate_token').read_text(encoding='utf-8').strip()
API = 'https://api.replicate.com/v1'
OUT = Path('img-gen')
SEED = OUT / 'fries-huis-4x3.jpg'          # beginbeeld (door eigenaar aangeleverd)
EIND = OUT / 'hero-verf-eind-4x3.jpg'      # eindbeeld (AI, close-up verf)
VIDEO = OUT / 'hero-video-huis-1.mp4'
DUUR = 5                                    # seconden -> $0,10 bij $0,02/s

VERF_PROMPT = (
    'Low key macro photograph of a razor-sharp straight edge between two freshly '
    'painted matte olive green wall surfaces. The left surface is a deeper olive '
    'green (#424631), the right surface a slightly lighter olive green (#6A7150). '
    'The edge between them is perfectly crisp and straight, as if masking tape '
    'was just pulled off. Subtle paint texture, faint satin sheen on the fresh '
    'paint, very dark and moody with deep shadows. No paint blobs, no thick '
    'paint, no palette knife, no tools, no tape, no hands, no people, no text, '
    'no letters, no logo, no watermark. Photorealistic, shallow depth of field.'
)

MOTION_PROMPT = (
    'Slow steady dolly push-in toward the brick facade of the Frisian house. '
    'The camera moves forward at a constant, calm speed; the brickwork, white '
    'window frames and roof tiles glide closer and fill the frame, and the '
    'surfaces gradually dissolve into a freshly painted olive green wall with a '
    'razor-sharp straight edge between two olive tones, as if masking tape was '
    'just pulled off. Continuous single shot, no jump cuts, no camera shake, no '
    'zoom snap, no people, no hands. '
    'Absolutely no text of any kind: no letters, no words, no subtitles, '
    'no captions, no signage, no shop signs, no watermarks, no writing at all. '
    'Quiet room tone only, no music, no dialogue.'
)


def api_request(url, data=None):
    headers = {'Authorization': 'Bearer ' + TOKEN,
               'User-Agent': 'StudioEEF-site-builder/1.0'}
    if data is not None:
        headers['Content-Type'] = 'application/json'
        data = json.dumps(data).encode('utf-8')
    req = urllib.request.Request(url, data=data, headers=headers)
    with urllib.request.urlopen(req, timeout=180) as resp:
        return json.loads(resp.read().decode('utf-8'))


def upload(path):
    """Zet een lokaal bestand op Replicate en geef de HTTPS-URL terug."""
    grens = '----StudioEEF' + uuid.uuid4().hex
    body = b''
    body += ('--%s\r\n' % grens).encode()
    body += ('Content-Disposition: form-data; name="content"; filename="%s"\r\n' % path.name).encode()
    body += b'Content-Type: application/octet-stream\r\n\r\n'
    body += path.read_bytes() + b'\r\n'
    body += ('--%s--\r\n' % grens).encode()
    req = urllib.request.Request(API + '/files', data=body, headers={
        'Authorization': 'Bearer ' + TOKEN,
        'Content-Type': 'multipart/form-data; boundary=' + grens,
        'User-Agent': 'StudioEEF-site-builder/1.0'})
    with urllib.request.urlopen(req, timeout=300) as resp:
        return json.loads(resp.read().decode('utf-8'))['urls']['get']


def wacht(pred, max_pogingen=90, stap=5):
    pogingen = 0
    while pred.get('status') not in ('succeeded', 'failed', 'canceled') and pogingen < max_pogingen:
        time.sleep(stap)
        pred = api_request(API + '/predictions/' + pred['id'])
        pogingen += 1
        print('   ...', pred.get('status'), flush=True)
    return pred


def download(url, doel):
    req = urllib.request.Request(url, headers={'User-Agent': 'StudioEEF-site-builder/1.0'})
    with urllib.request.urlopen(req, timeout=300) as resp:
        Path(doel).write_bytes(resp.read())


def check_account():
    try:
        account = api_request(API + '/account')
        print('token geldig voor:', account.get('username'), '/', account.get('type'))
    except urllib.error.HTTPError as e:
        print('ONGELDIGE TOKEN of fout:', e.code, e.read().decode('utf-8')[:300])
        raise SystemExit(1)


def maak_verfstil():
    """close-up van geschilderd muurvlak (1:1; daarna lokaal naar 4:3 gesneden)."""
    print('== eindbeeld: verfclose-up (flux-schnell) ==')
    pred = api_request(
        API + '/models/black-forest-labs/flux-schnell/predictions',
        data={'input': {'prompt': VERF_PROMPT, 'aspect_ratio': '1:1',
                        'num_outputs': 1, 'output_format': 'jpg', 'output_quality': 92}})
    pred = wacht(pred, max_pogingen=30, stap=2)
    if pred.get('status') != 'succeeded':
        print('  mislukt:', pred.get('status'), str(pred.get('error'))[:300])
        return 1
    url = pred['output'][0] if isinstance(pred['output'], list) else pred['output']
    doel = OUT / 'hero-verf-eind-1x1.jpg'
    download(url, doel)
    print('  opgeslagen:', doel, doel.stat().st_size, 'bytes')
    print('  -> snijd dit lokaal naar 4:3 als', EIND.name)
    return 0


def maak_video():
    for pad in (SEED, EIND):
        if not pad.exists():
            print('ONTBREEKT:', pad)
            return 1

    print(f'== clip: gevel -> verf (prunaai/p-video, {DUUR}s = ${0.02 * DUUR:.2f}) ==')
    seed_url = upload(SEED)
    eind_url = upload(EIND)
    print('  beginbeeld en eindbeeld geüpload')

    pred = api_request(
        API + '/models/prunaai/p-video/predictions',
        data={'input': {'prompt': MOTION_PROMPT, 'image': seed_url,
                        'last_frame_image': eind_url, 'duration': DUUR,
                        'resolution': '720p', 'draft': False,
                        'save_audio': False, 'prompt_upsampling': False}})
    pred = wacht(pred)
    if pred.get('status') != 'succeeded':
        print('  mislukt:', pred.get('status'), str(pred.get('error'))[:300])
        return 1

    out = pred['output']
    download(out[0] if isinstance(out, list) else out, VIDEO)
    print('  opgeslagen:', VIDEO, VIDEO.stat().st_size, 'bytes')
    print('  reken  :', pred.get('metrics'))
    print(f'  kosten : ${0.02 * DUUR:.2f} (schatting)')
    return 0


if __name__ == '__main__':
    modus = sys.argv[1] if len(sys.argv) > 1 else 'video'
    check_account()
    if modus == 'verfstil':
        raise SystemExit(maak_verfstil())
    if modus == 'video':
        raise SystemExit(maak_video())
    print('onbekende modus:', modus)
    raise SystemExit(2)
