from pathlib import Path
import tempfile,subprocess,json,tarfile,os,shutil
r=Path(__file__).resolve().parents[1]
with tempfile.TemporaryDirectory() as t:
 root=Path(t)/'yomigami';stage=Path(t)/'stage';stage.mkdir();(root/'data/sources').mkdir(parents=True);(root/'data/library').mkdir()
 sample=root/'data/library/Sakamoto Days - Chapter 1.cbz';sample.write_bytes(b'preserve sample')
 settings={'languages':['en'],'source_settings':{'custom':{'keep':True}},'concurrent_requests_pages':5}
 state={'progress':{str(sample):{'page':17,'count':58}},'aliases':{'existing':'Original title'},'book_settings':{'sample':{'contrast':1.4}},'book_queue':[{'id':'retained','status':'queued'}]}
 (root/'data/state.json').write_text(json.dumps(state));(root/'data/sources/settings.json').write_text(json.dumps(settings))
 shutil.copyfile(r/'scripts/upgrade_data.lua',stage/'upgrade_data.lua')
 shutil.copytree(r/'assets/sources',stage/'sources')
 runtime=r/'build/macos/KOReader.app/Contents/koreader'
 subprocess.run([str(runtime/'luajit'),str(stage/'upgrade_data.lua'),str(root),str(stage)],cwd=runtime,check=True,stdout=subprocess.DEVNULL)
 new=json.loads((stage/'state.json').read_text());cfg=json.loads((stage/'settings.json').read_text())
 assert new['progress'][str(sample)]['page']==17 and new['aliases']==state['aliases']
 assert new['book_settings']==state['book_settings'] and new['book_queue']==state['book_queue']
 assert cfg['source_settings']==settings['source_settings'] and cfg['concurrent_requests_pages']==8
 assert (root/'data/state.json').read_text()==json.dumps(state)
 assert len(list((stage/'sources').glob('*.aix')))==20
 (root/'data/state.json').write_text('{broken')
 result=subprocess.run([str(runtime/'luajit'),str(stage/'upgrade_data.lua'),str(root),str(stage)],cwd=runtime,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
 assert result.returncode!=0 and (root/'data/state.json').read_text()=='{broken'
 print('PASS upgrade prepares settings, preserves bookmarks/aliases/source preferences, bundles 20 adapters and refuses corrupt state')
