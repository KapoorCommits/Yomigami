
"""Exercise the real generated installer in a temporary fake USB root."""
from pathlib import Path
import tempfile,subprocess,os,shutil
ROOT=Path(__file__).resolve().parents[1]
script=(ROOT/'dist/installer/Yomigami.sh').read_text()
with tempfile.TemporaryDirectory(prefix='yomigami-installer-test-') as tmp:
    base=Path(tmp);usb=base/'usb';usb.mkdir();bin=base/'bin';bin.mkdir()
    (bin/'eips').write_text('#!/bin/sh\nexit 0\n');(bin/'eips').chmod(0o755)
    (bin/'sha256sum').write_text('#!/bin/sh\nexec shasum -a 256 "$@"\n');(bin/'sha256sum').chmod(0o755)
    installer=base/'install.sh'
    installer.write_text(script.replace('/mnt/us',str(usb)).replace('exec "$ROOT/launch.sh" --kual --asap','echo LAUNCH_READY'))
    env={**os.environ,'PATH':str(bin)+':'+os.environ['PATH']}
    def run():return subprocess.run(['sh',str(installer)],env=env,capture_output=True,text=True)
    assert run().returncode==1 and not (usb/'yomigami').exists()
    print('PASS missing payload refuses installation')
    (usb/'yomigami-0.5.0.tar.gz').write_bytes(b'bad archive')
    assert run().returncode==1 and not (usb/'yomigami').exists()
    print('PASS checksum rejects incomplete transfer')
    (usb/'yomigami').mkdir();(usb/'yomigami/sentinel').write_text('preserve')
    assert run().returncode==1 and (usb/'yomigami/sentinel').read_text()=='preserve'
    print('PASS existing folder protected')
    shutil.rmtree(usb/'yomigami')
    shutil.copyfile(ROOT/'dist/yomigami-0.5.0.tar.gz',usb/'yomigami-0.5.0.tar.gz')
    assert run().returncode==0
    assert (usb/'yomigami/runtime/yomigami.lua').exists()
    assert (usb/'yomigami/data/library/Reader Test.cbz').exists()
    assert 'LAUNCH_READY' in (usb/'yomigami-install.log').read_text()
    assert run().returncode==0
    print('PASS verified extraction, sample books and subsequent launch')
