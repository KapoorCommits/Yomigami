local app=...
local UI=require('ui/uimanager');local Store=require('storage');local util=require('ffi/util');local lfs=require('libs/libkoreader-lfs');local R=require('requests')
local dir=app.root..'/durability-'..os.time();assert(lfs.mkdir(dir));local path=dir..'/state.json'
assert(Store.save(path,{generation=1}));assert(Store.save(path,{generation=2}));assert(Store.load(path..'.bak',{}).generation==1)
local f=assert(io.open(path,'w'));f:write('{broken');f:close()
local value,err,recovered=Store.load(path,{});assert(value.generation==1 and not err and recovered)
assert(Store.save(path,{generation=3}));assert(Store.load(path..'.bak',{}).generation==1,'Do not back up corruption')
local sync=util.fsyncOpenedFile;util.fsyncOpenedFile=function()return false,'injected disk failure'end
assert(not Store.save(path,{generation=4}));assert(Store.load(path,{}).generation==3);util.fsyncOpenedFile=sync
local rename=os.rename;os.rename=function(a,b)if b==path then return nil,'injected rename failure'end;return rename(a,b)end
assert(not Store.save(path,{generation=5}));assert(Store.load(path,{}).generation==3);os.rename=rename
os.remove(path);assert(Store.load(path,{}).generation==3,'Missing main restores backup')
local epub={path=app.root..'/Reader-layout.epub',title='Layout Test',format='EPUB'}
app.state.book_settings[epub.path]=nil;app:openBook(epub);assert(app.doc.reflowable)
assert(app.doc.layout.width==app.w and app.doc.layout.height==app:readerHeight());assert(app.doc.layout.font_size==app:s(24))
local old_count=app.nav.count;app.nav:jump(math.floor(old_count/2));local fraction=(app.nav.page-1)/math.max(1,old_count-1)
app.state.font_size=36;app:renderPage();assert(app.nav.count>old_count);assert(math.abs((app.nav.page-1)/(app.nav.count-1)-fraction)<.1)
app:saveProgress();app:closeBook();app:openBook(epub);assert(app.state.font_size==36 and app.doc.layout.font_size==app:s(36))
local dirty=UI.setDirty;local modes={};UI.setDirty=function(_,widget,mode)modes[#modes+1]=mode end
app.state.animation=false;app.state.refresh_text=12;app.turns_since_full=0
for i=1,12 do app:refreshPage(1,'page')end;assert(modes[11]=='partial' and modes[12]=='full')
app.state.refresh_text=0;app:refreshPage(1,'page');assert(modes[#modes]=='partial');UI.setDirty=dirty
app.state.tap_zones='forward';app:onDoubleTap();assert(app.chrome_hidden);app:onDoubleTap();assert(not app.chrome_hidden)
local text=app.doc:pageText(app.nav.page);assert(text:find('Passage',1,true))
app:pageTextNotes();local viewer=UI:getTopmostVisibleWidget();assert(viewer.text_selection_callback);viewer:handleTextSelection(viewer.text:match('[^\n]+'),1);local selection=UI:getTopmostVisibleWidget();assert(selection.item_table[1].text=='Save highlight');selection.item_table[1].callback();UI:close(viewer)
local entry=app:addAnnotation('An exact excerpt','A meaningful note');assert(entry.page==app.nav.page)
local export=assert(app:exportAnnotations());local f=assert(io.open(export));local markdown=f:read('*a');f:close();assert(markdown:find('> An exact excerpt',1,true) and markdown:find('A meaningful note',1,true))
assert(Store.load(app.root..'/state.json',{}).annotations[epub.path][1])
app:closeBook()
local comic;for _,b in ipairs(app.books)do if b.format=='CBZ' then comic=b;break end end
app:openBook(comic);app.state.prefetch=true;app.nav:jump(7);app:renderPage();app.nav:jump(6);app:renderPage();assert(app.navigation_direction==-1)
app.prefetch_tick();assert(app.page_cache['5/0/0'],'Backward target should be prepared first')
local signature=app:renderSignature();app.state.direction=app.state.direction=='rtl' and 'ltr' or 'rtl';assert(signature~=app:renderSignature())
app:closeBook()
for _,b in ipairs(app.books)do if b.title=='Long Horizons' then app:openBook(b);break end end
app.state.fit='width';app.nav:jump(2);app:renderPage();app.navigation_direction=1;app:schedulePrefetch();app.prefetch_tick()
local target=math.min(app.content_height-app:readerHeight(),math.floor(app:readerHeight()*.88));assert(app.page_cache['2/'..target..'/0'])
local hits=app.cache_hits or 0;app:turn(1);assert((app.cache_hits or 0)>hits,'Tall pan should hit pre-rendered viewport')
local sleep=require('sleep');sleep.app=app;sleep:setup();sleep:show();assert(sleep.widget.image);sleep:close();app:closeBook()
local manga={id='m',title='Follow Test',source_id='en.test'};app:toggleFollow(manga)
local meta=app.state.series['en.test:m'];assert(meta.followed)
local send=R.send;R.send=function(_,root,path,method,body,callback)
 if path:find('/refresh-chapters',1,true) then callback(true,{})else callback(true,{{id='1',title='Chapter 1'},{id='2',title='Chapter 2'}})end
end
local done=false;app:checkSeriesUpdate(meta,function()done=true end);assert(done and #meta.available==2)
assert(app:enqueueChapters(manga,{meta.available[1]})==1);assert(app:enqueueChapters(manga,{meta.available[1]})==0)
app:checkSeriesUpdate(meta,function()end);assert(#meta.available==1)
R.send=function(_,root,path,method,body,callback)callback(false,'Source unavailable')end
app:checkSeriesUpdate(meta,function()end);assert(meta.update_error and #meta.available==1,'Failure must preserve results')
R.send=send
print('PASS durable save failures and recovery, real EPUB relayout, annotations/export, backward and pan prefetch, sleep cover, series updates and duplicate avoidance')
