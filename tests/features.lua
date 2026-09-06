local app=...
local Store=require('storage');local UI=require('ui/uimanager');local BB=require('ffi/blitbuffer');local Device=require('device')
local function draw(name,widget)
 local bb=BB.new(app.w,app.h,BB.TYPE_BB8);(widget or app):paintTo(bb,0,0);bb:writePNG(app.root..'/'..name..'.png');bb:free()
end
local book;for _,b in ipairs(app.books) do if b.format=='CBZ' then book=b;break end end
app:openBook(book);app.nav:jump(2);app:renderPage();app:onSpread(nil,{span=200,start_span=100});assert(app.zoom==2)
assert(app.page_image:getWidth()<=app.w and app.page_image:getHeight()<=app.h)
app:panZoom('west',100);assert(app.pan_x>0);app:panZoom('north',100);assert(app.nav.offset>0);assert(app.nav.page==2)
draw('zoom-2x');app:onPinch(nil,{span=100,start_span=200});assert(app.zoom==1 and app.pan_x==0)
app:closeBook();draw('bookmark-library');assert(app:bookmarkFor(book).page==2)
local temp=app.root..'/Feature Test.cbz'
local f=assert(io.open(book.path,'rb'));local bytes=f:read('*a');f:close();f=assert(io.open(temp,'wb'));f:write(bytes);f:close()
local copied=assert(Store.import(temp,app.root..'/library'));os.remove(temp)
app:scan();local b;for _,v in ipairs(app.books) do if v.path==copied then b=v end end;assert(b)
app:renameBook(b,'Renamed book');assert(app.state.aliases[b.path]=='Renamed book')
app:deleteBook(b);assert(not io.open(copied,'rb'));app:restoreBook(#app.state.trash);f=assert(io.open(copied,'rb'));f:close();os.remove(copied)
app.state.aliases[copied]=nil;app:scan()
local hasFL,hasNL=Device.hasFrontlight,Device.hasNaturalLight;Device.hasFrontlight=function()return true end;Device.hasNaturalLight=function()return true end
local power={fl_max=24,intensity=12,warmth=50,frontlightIntensity=function(p)return p.intensity end,frontlightWarmth=function(p)return p.warmth end,setIntensity=function(p,v)p.intensity=v end,setWarmth=function(p,v)p.warmth=v end,toggleFrontlight=function(p)p.intensity=p.intensity>0 and 0 or 12 end}
local light=require('options'):new{owner=app,power=power};draw('lighting',light)
for _,h in ipairs(light.hits) do if h.id=='brightness-toggle' then h.fn() end end;assert(power.intensity==0)
for _,h in ipairs(light.hits) do if h.id=='brightness-plus' then h.fn() end end;assert(power.intensity==13)
for _,h in ipairs(light.hits) do if h.id=='warmth-toggle' then h.fn() end end;assert(power.warmth==0)
Device.hasFrontlight=hasFL;Device.hasNaturalLight=hasNL
local R=require('requests');local send=R.send
R.send=function(_,root,path,method,body,done)
 if method=='POST' then done(true,'job-123') else done(true,{type='COMPLETED',data={book.path,{ },false}}) end
end
app.state.queue={};local manga={id='m1',title='Test Manga',source={id='en.test'}};local chapter={id='c1',title='Chapter 1',chapter_num=1}
assert(app:enqueueChapters(manga,{chapter,chapter})==1);app:pumpDownloads();assert(app.state.queue[1].status=='active');app:pumpDownloads();assert(app.state.queue[1].status=='complete')
assert(app.state.downloads[book.path].series_key=='en.test:m1');app.state.downloads[book.path]=nil
app.state.queue={};app.state.series['en.test:m1']=nil;R.send=send
app:save();print('PASS zoom bounds/pan, bookmark, rename/delete/restore, lighting controls, queue deduplication/completion')
