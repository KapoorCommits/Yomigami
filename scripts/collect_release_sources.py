from pathlib import Path
import urllib.request,tarfile,io,configparser,re,json
root=Path(__file__).resolve().parents[1]/'build/release-sources';root.mkdir(parents=True,exist_ok=True)
entries=[]
def fetch(repo,rev,dest):
 url=f'https://codeload.github.com/{repo}/tar.gz/{rev}'
 print('Fetching',repo,rev,flush=True)
 data=urllib.request.urlopen(url,timeout=120).read()
 dest.mkdir(parents=True,exist_ok=True)
 with tarfile.open(fileobj=io.BytesIO(data),mode='r:gz') as t:
  prefix=t.getmembers()[0].name.split('/')[0]+'/'
  for m in t.getmembers():
   if not m.name.startswith(prefix):continue
   m.name=m.name[len(prefix):]
   if m.name:t.extract(m,dest,filter='data')
 entries.append({'repository':repo,'commit':rev,'source_url':url,'directory':str(dest.relative_to(root))})
 gm=dest/'.gitmodules'
 if gm.exists():
  cfg=configparser.ConfigParser();cfg.read(gm)
  tree=json.load(urllib.request.urlopen(f'https://api.github.com/repos/{repo}/git/trees/{rev}?recursive=1',timeout=90))
  hashes={x['path']:x['sha'] for x in tree['tree'] if x['mode']=='160000'}
  for section in cfg.sections():
   path=cfg[section]['path'];remote=cfg[section]['url'];name=remote.removeprefix('https://github.com/').removesuffix('.git')
   if path not in hashes:continue
   assert remote.startswith('https://github.com/'),remote
   fetch(name,hashes[path],dest/path)
lock=json.loads((root.parents[1]/'runtime-lock.json').read_text())
fetch('koreader/koreader',lock['koreader_commit'],root/'koreader')
# Original upstream URL is unavailable; this fork retains the identical commit.
fetch('kravenos/krakuyomi',lock['rakuyomi_commit'],root/'rakuyomi')
(root/'UPSTREAM-SOURCES.json').write_text(json.dumps(entries,indent=2))
print('DONE',len(entries),'pinned repositories',flush=True)
