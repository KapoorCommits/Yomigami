local app=...
local UI=require('ui/uimanager');local BB=require('ffi/blitbuffer');local Device=require('device')
local function draw(widget,name)
 local bb=BB.new(app.w,app.h,BB.TYPE_BB8);widget:paintTo(bb,0,0);bb:writePNG(app.root..'/'..name..'.png');return bb
end
local book;for _,b in ipairs(app.books)do if b.format=='CBZ' then book=b;break end end
app:openBook(book);app.nav:jump(2);app:renderPage()
local original=app.page_image:copy();app.state.contrast=1.8;app:renderPage()
local different=false
for y=0,math.min(original:getHeight(),app.page_image:getHeight())-1,11 do
 for x=0,math.min(original:getWidth(),app.page_image:getWidth())-1,11 do if original:getPixel(x,y):getColor8().a~=app.page_image:getPixel(x,y):getColor8().a then different=true end end
end
original:free();assert(different,'Contrast must alter grayscale pixels');app.state.contrast=1;app:renderPage()
local hfl,hnl=Device.hasFrontlight,Device.hasNaturalLight;Device.hasFrontlight=function()return true end;Device.hasNaturalLight=function()return true end
local power={fl_max=24,frontlightIntensity=function()return 12 end,frontlightWarmth=function()return 50 end}
local options=require('options'):new{owner=app,power=power};draw(options,'options-021'):free()
local found={};for _,h in ipairs(options.hits)do found[h.id]=true;assert(h.x>=0 and h.y>=0 and h.x+h.w<=app.w and h.y+h.h<=app.h,'Control outside screen: '..h.id)end
local night=not not Device.screen.night_mode
for _,h in ipairs(options.hits)do if h.id=='theme' then h.fn();assert((not not Device.screen.night_mode)~=night);h.fn();assert((not not Device.screen.night_mode)==night)end end
assert(found['theme'])
assert(found['brightness-slider'] and found['warmth-slider'] and found['contrast-slider'])
Device.hasFrontlight=hfl;Device.hasNaturalLight=hnl
local series={title='Sakamoto Days',series_key='design-fixture',chapters={},cover_path=book.path}
for i=1,23 do series.chapters[i]={path=book.path..'-'..i,title='Days '..i,chapter_num=i,format='CBZ'}end
app.state.series['design-fixture']={last_path=series.chapters[10].path}
app.state.progress[series.chapters[10].path]={page=17,count=58}
local chapters=require('chapters'):new{owner=app,series=series};assert(chapters.page==2)
draw(chapters,'chapters-021'):free();assert(chapters.last==series.chapters[10].path)
chapters:onNext();assert(chapters.page==3);chapters:onPrevious();assert(chapters.page==2)
chapters:onCloseWidget();app.state.series['design-fixture']=nil;app.state.progress[series.chapters[10].path]=nil
app:closeBook();draw(app,'library-021'):free();app:save()
print('PASS contrast changes pixels, direct sliders stay on screen, chapter menu opens at bookmark and paginates')
