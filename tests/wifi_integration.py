from pathlib import Path
import os,subprocess,http.client,time,json,hashlib
root=Path(__file__).resolve().parents[1];home=root/'build/wifi-integration';(home/'library').mkdir(parents=True,exist_ok=True)
for p in (home/'library').glob('*'):p.unlink()
env=dict(os.environ,YOMIGAMI_HOME=str(home),YOMIGAMI_NO_ENGINE='1',SDL_VIDEODRIVER='dummy',YOMIGAMI_TEST=str(root/'tests/wifi_integration.lua'))
with (root/'build/wifi-integration.log').open('w') as log:
 proc=subprocess.Popen([str(root/'scripts/run_macos.sh')],env=env,stdout=log,stderr=subprocess.STDOUT)
 try:
  for _ in range(100):
   if 'WIFI_TEST_READY' in (root/'build/wifi-integration.log').read_text():break
   if proc.poll() is not None:raise AssertionError('Server did not start')
   time.sleep(.1)
  def request(method,path,body=None,headers={}):
   c=http.client.HTTPConnection('127.0.0.1',18789,timeout=10);c.request(method,path,body,headers);r=c.getresponse();data=r.read();code=r.status;c.close();return code,data
  code,page=request('GET','/test-session');assert code==200 and b'Send to Yomigami' in page
  assert request('GET','/wrong')[0]==403
  assert request('POST','/test-session/upload',b'no',{'X-Filename':'../bad.pdf'})[0]==400
  assert request('POST','/test-session/upload',b'no',{'X-Filename':'bad.pdf','Origin':'http://evil.example'})[0]==403
  assert request('POST','/test-session/upload',b'not a pdf',{'X-Filename':'bad.pdf'})[0]==422
  fixture=(root/'assets/Welcome.pdf').read_bytes()
  assert request('POST','/test-session/upload',fixture,{'X-Filename':'Welcome.pdf'})[0]==201
  assert (home/'library/Welcome.pdf').read_bytes()==fixture
  assert request('POST','/test-session/upload',fixture,{'X-Filename':'Welcome.pdf'})[0]==409
  assert not (home/'.wifi-upload.part').exists()
  assert proc.wait(timeout=10)==0
  print('PASS real HTTP upload, byte equality, token/origin/path checks, invalid-file rejection and overwrite protection')
 finally:
  if proc.poll() is None:proc.terminate();proc.wait(timeout=10)
