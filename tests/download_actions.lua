local app=...
local UI=require('ui/uimanager');local R=require('requests');local T=require('book_transfer');local lfs=require('libs/libkoreader-lfs')
local send,cancel=R.send,R.cancel;local callbacks={};local deletes={};local killed={}
R.send=function(_,root,path,method,body,done)
 if method=='DELETE' then deletes[#deletes+1]=path;done(true,{})else callbacks[#callbacks+1]=done end
 return 900+#callbacks
end
R.cancel=function(_,pid)killed[#killed+1]=pid end
local completed={id='done',status='complete',book={title='Kept'}}
local active={id='active-test',status='queued',book={title='Active',url='https://example.org/file'},attempts=0}
app.state.book_queue={completed,active};app:pumpBookDownloads();assert(app.book_worker==active)
local part,meta=T.paths(app.root,active.id);local f=assert(io.open(part,'w'));f:write('partial');f:close()
assert(app:bulkDownloads('books',false)==1);assert(not lfs.attributes(part));assert(#killed==1 and not app.book_worker)
callbacks[1](true,{path='must-not-be-added',total=99});assert(active.status=='cancelled' and completed.status=='complete')
app.state.book_queue[#app.state.book_queue+1]={id='failed-test',status='failed'}
assert(app:bulkDownloads('books',true)==2 and #app.state.book_queue==1 and app.state.book_queue[1]==completed)
local manga={id='m',source_id='test',title='Fixture'}
local pending={status='queued',manga=manga,chapter={id='c'},title='Pending'}
app.state.queue={pending,{status='complete',manga=manga,title='Keep',path='kept.cbz'}};app.state.queue_paused=false
app:pumpDownloads();assert(app.queue_busy)
assert(app:bulkDownloads('manga',true)==1 and #app.state.queue==1)
callbacks[#callbacks](true,'late-engine-job');assert(pending.status=='cancelled' and not app.queue_busy and deletes[#deletes]=='/jobs/late-engine-job')
lfs.mkdir(app.root..'/sources');lfs.mkdir(app.root..'/sources/downloads')
local file=app.root..'/sources/downloads/incomplete.cbz';local f=assert(io.open(file,'w'));f:write('partial');f:close()
app.state.incomplete[file]=true;app.state.queue[#app.state.queue+1]={status='failed',partial_path=file}
app:bulkDownloads('manga',true);assert(not lfs.attributes(file) and app.state.incomplete[file]==nil)
local show=UI.show;local refresh
UI.show=function(self,widget,mode,...)refresh=mode;return show(self,widget,mode,...)end
app:downloadsMenu();local view=UI:getTopmostVisibleWidget();assert(refresh=='full' and view.covers_fullscreen)
local bb=require('ffi/blitbuffer').new(app.w,app.h,require('ffi/blitbuffer').TYPE_BB8);view:paintTo(bb)
local buttons={};for _,h in ipairs(view.hits)do buttons[h.id]=true;assert(h.y+h.h<=app.h)end
assert(buttons['cancel-all'] and buttons['clear-failed']);bb:free();view:onClose()
app:bookDownloadsMenu();view=UI:getTopmostVisibleWidget();assert(refresh=='full');view:onClose()
UI.show=show;R.send=send;R.cancel=cancel
print('PASS bulk cancellation, partial cleanup, completed retention, late callbacks, full initial repaint and button bounds')
