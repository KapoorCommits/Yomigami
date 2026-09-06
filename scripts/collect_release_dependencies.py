from pathlib import Path
import urllib.request,urllib.parse,hashlib,json,re,tomllib,concurrent.futures
root=Path(__file__).resolve().parents[1]/'build/release-sources'
out=root/'dependency-archives';out.mkdir(exist_ok=True)
jobs=[]
for p in (root/'koreader/base/thirdparty').glob('*/CMakeLists.txt'):
 s=p.read_text();m=re.search(r'DOWNLOAD\s+(URL|GIT)\s+(\S+)\s+((?:https?://\S+\s*)+)',s)
 if not m:continue
 kind,ref,urls=m.groups();urls=urls.split();name='koreader-'+p.parent.name
 if kind=='GIT':
  u=urls[0].rstrip('/').removesuffix('.git')
  if u.startswith('https://github.com/'):urls=['https://codeload.github.com/'+u.split('github.com/')[1]+'/tar.gz/'+ref]
  else: urls=[u+'/-/archive/'+ref+'/'+u.split('/')[-1]+'-'+ref+'.tar.gz']
 jobs.append({'name':name,'urls':urls,'recipe':str(p.relative_to(root)),'upstream_ref':ref})
lock=tomllib.loads((root/'rakuyomi/backend/Cargo.lock').read_text())
for p in lock['package']:
 src=p.get('source','')
 if src.startswith('registry+'):
  jobs.append({'name':f"crate-{p['name']}-{p['version']}",'urls':[f"https://static.crates.io/crates/{p['name']}/{p['name']}-{p['version']}.crate"],'expected_sha256':p['checksum']})
 elif src.startswith('git+'):
  url,rev=src[4:].split('#');url=url.split('?')[0].removesuffix('.git')
  if url.startswith('https://github.com/'):
   jobs.append({'name':'rust-git-'+url.split('/')[-1]+'-'+rev[:12],'urls':['https://codeload.github.com/'+url.split('github.com/')[1]+'/tar.gz/'+rev],'upstream_ref':rev})
jobs=list({j['name']:j for j in jobs}.values())
def download(j):
 p=out/(j['name']+'.source')
 for url in j['urls']:
  try:
   data=p.read_bytes() if p.exists() else urllib.request.urlopen(url,timeout=90).read()
   digest=hashlib.sha256(data).hexdigest()
   if j.get('expected_sha256'):assert digest==j['expected_sha256'],'checksum mismatch'
   p.write_bytes(data);j.update(file=str(p.relative_to(root)),sha256=digest,download_url=url,size=len(data));return j
  except Exception as e:j['last_error']=str(e)
 print('FAILED',j['name'],j['last_error'],flush=True);return j
with concurrent.futures.ThreadPoolExecutor(max_workers=10) as ex:
 result=list(ex.map(download,jobs))
(root/'DEPENDENCY-SOURCES.json').write_text(json.dumps(result,indent=2))
failed=[j['name'] for j in result if 'file' not in j]
print('DONE',len(result),'dependencies; failed:',failed,flush=True)
