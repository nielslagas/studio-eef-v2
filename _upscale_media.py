"""Verbeter (upscalen) van de door de eigenaar aangeleverde foto en video.

Foto  : 1600x1200 uit WhatsApp (gecomprimeerd) -> 2x upscale, twee modellen om te
        vergelijken: prunaai/p-image-upscale (goedkoop, detail/realism-optie) en
        topazlabs/image-upscale (fotografie-specialist).
Video : 368x368 uit WhatsApp -> 1080p via topazlabs/video-upscale.

Ruwe output blijft in img-gen/. Het token wordt nooit geprint.

Gebruik: python _upscale_media.py foto | video
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

FOTO = OUT / 'eef-bus-bron.jpg'
VIDEO = OUT / 'werk-kwast-bron.mp4'


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


def wacht(pred, max_pogingen=120, stap=5):
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


def run(model, inputs, doel, label):
    print('== %s ==' % label, flush=True)
    try:
        pred = api_request(API + '/models/%s/predictions' % model, data={'input': inputs})
    except urllib.error.HTTPError as e:
        print('  aanmaken mislukt:', e.code, e.read().decode('utf-8')[:300])
        return
    pred = wacht(pred)
    if pred.get('status') != 'succeeded':
        print('  mislukt:', pred.get('status'), str(pred.get('error'))[:300])
        return
    out = pred['output']
    url = out[0] if isinstance(out, list) else out
    if isinstance(url, dict):
        url = url.get('url') or url.get('video') or url.get('image')
    download(url, doel)
    print('  opgeslagen:', doel, '%d KB' % (doel.stat().st_size // 1024))
    print('  reken  :', pred.get('metrics'))


def main():
    modus = sys.argv[1] if len(sys.argv) > 1 else 'foto'
    account = api_request(API + '/account')
    print('token geldig voor:', account.get('username'))

    if modus == 'foto':
        if not FOTO.exists():
            print('ONTBREEKT:', FOTO)
            return 1
        url = upload(FOTO)
        run('prunaai/p-image-upscale',
            {'image': url, 'factor': 2, 'enhance_details': True,
             'enhance_realism': True, 'output_format': 'jpg', 'output_quality': 92},
            OUT / 'eef-bus-pruna-2x.jpg', 'prunaai p-image-upscale 2x')
        run('topazlabs/image-upscale',
            {'image': url, 'output_format': 'jpg', 'face_enhancement': False},
            OUT / 'eef-bus-topaz-2x.jpg', 'topazlabs image-upscale')
        return 0

    if modus == 'video':
        if not VIDEO.exists():
            print('ONTBREEKT:', VIDEO)
            return 1
        url = upload(VIDEO)
        # topazlabs/video-upscale faalt met een interne fout ("source.container
        # is required"), dus pruna als alternatief.
        run('prunaai/p-video-upscale',
            {'video': url, 'target': '1080p'},
            OUT / 'werk-kwast-pruna-1080.mp4', 'prunaai p-video-upscale 1080p')
        return 0

    print('onbekende modus:', modus)
    return 2


if __name__ == '__main__':
    raise SystemExit(main())
