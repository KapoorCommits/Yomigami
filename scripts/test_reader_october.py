"""Run reader regression suites with isolated original fixtures, no source network access."""
from pathlib import Path
import os, subprocess, tempfile
r=Path(__file__).resolve().parents[1]
tests=['ui','features','toolbar','design','discovery','reader_upgrades','books','book_sources_202610','wifi_ui','reader_october']
for name in tests:
    with tempfile.TemporaryDirectory(prefix='yomigami-reader-') as home:
        env=dict(os.environ,YOMIGAMI_HOME=home,YOMIGAMI_NO_ENGINE='1',SDL_VIDEODRIVER='dummy',YOMIGAMI_TEST=str(r/'tests'/f'{name}.lua'))
        if name=='reader_october':env.update(EMULATE_READER_W='1272',EMULATE_READER_H='1696')
        subprocess.run(['python3',str(r/'scripts/make_fixtures.py')],env=env,check=True,stdout=subprocess.DEVNULL)
        result=subprocess.run([str(r/'scripts/run_macos.sh')],env=env,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
        if result.returncode:
            print(result.stdout);raise SystemExit(f'FAILED {name}')
        print(name+': '+next((line for line in reversed(result.stdout.splitlines()) if 'PASS' in line),'completed'))
print('PASS isolated reader regression suites')
