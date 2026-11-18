local app=...
local R=require('requests');local Doc=require('document');local BB=require('ffi/blitbuffer')
local send,save=R.send,app.save;local writes=0
app.save=function()writes=writes+1;return true end
local job={status='active',id='fixture',manga={source_id='test',id='m'},chapter={id='c'}}
app.state.queue={job};app.state.queue_paused=false
local progress=0
R.send=function(_,root,path,method,body,done)progress=progress+1;done(true,{type='RUNNING',data={processed=progress,total=100}})end
for i=1,20 do app:pumpDownloads()end
assert(writes==0 and job.progress.data.processed==20,'Progress polling must update UI without full-state writes')
R.send=function(_,root,path,method,body,done)done(false,'connection lost')end
app:pumpDownloads();assert(writes==1 and job.status=='failed','Failure transition must be saved')
job.status='queued';R.send=function(_,root,path,method,body,done)done(true,'new-job')end
app:pumpDownloads();assert(writes==2 and job.status=='active','New job must be saved')
R.send=send;app.save=save;app.state.queue={}
app:clearCovers();local open=Doc.open;local renders=0
Doc.open=function()return {render=function()renders=renders+1;return BB.new(1024,1024,BB.TYPE_BB8)end,close=function()end}end
local book={path='cache-fixture'};local first=app:cover(book,100,100)
app:changeShelf(1);assert(app:cover(book,100,100)==first and renders==1,'Shelf navigation must retain covers')
for i=1,20 do app:cover({path='cache-'..i},100,100)end
local bytes=0;for _,v in pairs(app.covers)do bytes=bytes+v:getWidth()*v:getHeight()*v:getBpp()/8 end
assert(bytes<=8*1024*1024,'Cover cache exceeds memory budget')
app:cover(book,100,100);assert(renders==22,'Evicted covers must be rendered again')
app:clearCovers();Doc.open=open
local menu=app.menu;app.menu=function()end
app.state.trash={{title='Removed over USB',moves={{trash=app.root..'/.trash/missing'}}}}
app:trashMenu();assert(#app.state.trash==0,'Externally removed trash must not leave restore actions');app.menu=menu
print('PASS 20 progress polls: zero full-state writes; failures/new jobs saved; repeat cover: one render; cache <=8 MiB')
