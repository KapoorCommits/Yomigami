
"""Build a private KindleHF runtime. Never install over /mnt/us/koreader."""
from pathlib import Path
import shutil,re,json,hashlib,zipfile,tarfile,subprocess,difflib
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'dist/kindle'
APP=OUT/'yomigami'
RUNTIME=APP/'runtime'
if OUT.exists():shutil.rmtree(OUT)
RUNTIME.parent.mkdir(parents=True)
shutil.copytree(ROOT/'build/kindle/koreader',RUNTIME)
for name in ('plugins','ota'):
    p=RUNTIME/name
    if p.exists():shutil.rmtree(p)
(RUNTIME/'plugins').mkdir()
shutil.copytree(ROOT/'app',APP/'app')
(APP/'engine').mkdir()
shutil.copy2(ROOT/'build/source-kindle/rakuyomi.koplugin/server',APP/'engine/server')
(APP/'engine/server').chmod(0o755)
shutil.copy2(ROOT/'launcher/launch.sh',APP/'launch.sh')
shutil.copy2(ROOT/'LICENSE',APP/'LICENSE')
shutil.copy2(ROOT/'THIRD_PARTY_NOTICES.md',APP/'THIRD_PARTY_NOTICES.md')
shutil.copytree(ROOT/'licenses',APP/'licenses')
# Namespaced temp files and LIPC client IDs avoid clashing with an installed KOReader.
changes=[]
for relative in ['koreader.sh','libkohelper.sh','frontend/device/kindle/device.lua','frontend/device/kindle/powerd.lua']:
    path=RUNTIME/relative
    original=path.read_text();text=original
    if relative=='koreader.sh':
        text,n=re.subn(r'ko_update_check\(\) \{.*?\n\}', 'ko_update_check() { :; }',text,flags=re.S)
        assert n==1,'Upstream update hook changed; review required'
        text=text.replace('./reader.lua','./yomigami.lua').replace('pidof reader.lua','pidof yomigami.lua').replace('killall -TERM reader.lua','killall -TERM yomigami.lua')
        text=text.replace('Starting KOReader','Starting Yomigami').replace('KOreader processes','Yomigami processes')
    text=text.replace('/var/tmp/koreader.sh','/var/tmp/yomigami-runtime.sh')
    text=text.replace('"koreader.sh"','"yomigami-runtime.sh"').replace('./koreader.sh','./yomigami-runtime.sh')
    text=text.replace('/var/tmp/fbink','/var/tmp/yomigami-fbink').replace('/var/tmp/koreader-fb.dump','/var/tmp/yomigami-fb.dump')
    text=text.replace('com.github.koreader.device','org.yomigami.device').replace('com.github.koreader.networkmgr','org.yomigami.networkmgr').replace('com.github.koreader.screen','org.yomigami.screen').replace('com.github.koreader.ambientbrightness','org.yomigami.ambientbrightness').replace('com.github.koreader.powerd','org.yomigami.powerd')
    path.write_text(text)
    changes.extend(difflib.unified_diff(original.splitlines(True),text.splitlines(True),fromfile='runtime/'+relative,tofile='runtime/'+relative))
(RUNTIME/'koreader.sh').rename(RUNTIME/'yomigami-runtime.sh')
(RUNTIME/'reader.lua').unlink()
(RUNTIME/'yomigami.lua').write_text('#!./luajit\ndofile(assert(os.getenv("YOMIGAMI_APP")).."/boot.lua")\n')
(RUNTIME/'yomigami.lua').chmod(0o755)
for file in (RUNTIME/'yomigami-runtime.sh',APP/'launch.sh'):file.chmod(0o755)
for name in ('library','runtime','sources'):(APP/'data'/name).mkdir(parents=True,exist_ok=True)
shutil.copy2(ROOT/'build/package-fixtures/library/Ink Journey.cbz',APP/'data/library/Reader Test.cbz')
shutil.copy2(ROOT/'assets/Welcome.pdf',APP/'data/library/Welcome.pdf')
# Do not seed user data in upgrades. Initial source defaults keep downloads persistent.
(APP/'data/sources/settings.json').write_text(json.dumps({'source_lists':[
    {'url':'https://aidoku-community.github.io/sources/index.min.json','type':'aidoku'},
    {'url':'https://tachibana-shin.github.io/aidoku-sources-next/index.min.json','type':'aidoku'}],
    'languages':['en'],'concurrent_requests_pages':8,'optimize_image':False,'storage_size_limit':'100 GB','search_view_mode':'base','ram_storage_enabled':False,'enabled_cron_check_mangas_update':False,
    'delete_downloaded_after_read':False,'delete_downloaded_on_remove':False},indent=2))
shutil.copytree(ROOT/'assets/sources',APP/'data/sources/sources',dirs_exist_ok=True)
(APP/'app/version.txt').write_text('0.4.0-alpha\n')
(OUT/'documents').mkdir();shutil.copy2(ROOT/'launcher/Yomigami.sh',OUT/'documents/Yomigami.sh')
EXT=OUT/'extensions/yomigami';EXT.mkdir(parents=True)
for name in ('config.xml','menu.json'):shutil.copy2(ROOT/'launcher'/name,EXT/name)
if (ROOT/'assets/icon.png').exists():shutil.copy2(ROOT/'assets/icon.png',APP/'icon.png')
if (ROOT/'docs/INSTALL.md').exists():shutil.copy2(ROOT/'docs/INSTALL.md',OUT/'INSTALL.md')
(ROOT/'docs/runtime.patch').write_text(''.join(changes))
lock=json.loads((ROOT/'runtime-lock.json').read_text())
(APP/'runtime-lock.json').write_text(json.dumps(lock,indent=2))
(ROOT/'runtime-lock.json').write_text(json.dumps(lock,indent=2))
files={str(f.relative_to(OUT)):hashlib.sha256(f.read_bytes()).hexdigest() for f in OUT.rglob('*') if f.is_file()}
(ROOT/'dist/manifest.json').write_text(json.dumps(files,indent=2))
zip_path=ROOT/'dist/Yomigami-0.4.0-kindlehf.zip'
with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED) as z:
    for f in OUT.rglob('*'):
        if f.is_file():z.write(f,f.relative_to(OUT))
with tarfile.open(ROOT/'dist/yomigami-0.4.0.tar.gz','w:gz') as t:
    t.add(APP,arcname='yomigami')
print(f'Packaged {len(files)} files; {zip_path.stat().st_size/1024/1024:.1f} MiB zip')
