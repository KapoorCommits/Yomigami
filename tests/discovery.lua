local app=...
local UI=require('ui/uimanager');local BB=require('ffi/blitbuffer');local R=require('requests')
local function draw(widget,name)
 local bb=BB.new(app.w,app.h,BB.TYPE_BB8);widget:paintTo(bb,0,0);bb:writePNG(app.root..'/'..name..'.png');bb:free()
 for _,h in ipairs(widget.hits or {})do assert(h.x>=0 and h.y>=0 and h.x+h.w<=app.w and h.y+h.h<=app.h,'Hit outside screen: '..h.id)end
end
local D=require('discover');local home=D:new{owner=app};draw(home,'mangas-home')
local results={};for i=1,20 do results[i]={id='m'..i,title='Sample Manga '..i,source={id='en.test',name='Test source'}}end
local list=D:new{owner=app,query='Sample manga',results=results};draw(list,'mangas-results');list:onNext();assert(list.page==2)
local send=R.send
R.send=function(_,root,path,method,body,done)
 if path:match('/chapters$')then done(true,{{id='c1',title='Chapter 1',chapter_number=1},{id='c2',title='Chapter 2',chapter_number=2}})else done(true,{})end
end
local chapter=D:new{owner=app,manga=results[1]};assert(#chapter.chapters==2);draw(chapter,'mangas-chapters');R.send=send
local queue=app.state.queue
app.state.queue={{status='complete',manga=results[1]},{status='active',manga=results[1],progress={data={processed=5,total=10}}},{status='queued',manga=results[1]}}
local progress=require('download_progress'):new{owner=app,title='Sample Manga'};assert(progress:stats().ratio==.5);draw(progress,'download-progress');progress:onCloseWidget();app.state.queue=queue
local blank=BB.new(200,300,BB.TYPE_BB8);blank:fill(BB.COLOR_WHITE)
local crop=require('crop');assert(crop.bounds(blank).w==1)
blank:paintRect(30,40,140,220,BB.COLOR_BLACK);local bounds=crop.bounds(blank)
assert(bounds.x<.15 and bounds.x>.1 and bounds.w<1 and bounds.y<40/300)
blank:paintRect(0,0,2,2,BB.COLOR_BLACK);assert(crop.bounds(blank).x==0 and crop.bounds(blank).y==0);blank:free()
local book;for _,b in ipairs(app.books)do if b.format=='CBZ'then book=b;break end end
app:openBook(book);app.nav:jump(1);app.state.prefetch=true;app:renderPage()
local tick=app.prefetch_tick;for i=1,5 do tick()end
local size=0;for _,v in pairs(app.page_cache)do size=size+v.image:getWidth()*v.image:getHeight()*v.image:getBpp()/8 end
assert(size<=6*app.w*app.h*4)
local hits=app.cache_hits or 0;app:turn(1);assert(app.cache_hits==hits+1 and app.nav.page==2)
app.state.autocrop=true;app:renderPage();assert(app.page_cache[3]==nil,'Crop must invalidate previously prefetched pages');app.state.autocrop=false;app:closeBook();assert(not next(app.page_cache))
print('PASS discovery, chapter fetch, honest progress, conservative crop bounds and cached page turns; cache bytes '..size)
