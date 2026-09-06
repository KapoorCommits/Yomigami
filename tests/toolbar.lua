local app=...
local BB=require('ffi/blitbuffer')
local function paint(name)
 local bb=BB.new(app.w,app.h,BB.TYPE_BB8);app:paintTo(bb,0,0)
 bb:writePNG(os.getenv('YOMIGAMI_HOME')..'/'..name..'.png');bb:free()
end
local book
for _,b in ipairs(app.books) do if b.format=='CBZ' then book=b;break end end
app:openBook(book);app.nav:jump(1);app:renderPage();paint('toolbar-visible')
local function tap(x,y) app:onTap(nil,{pos={x=app:s(x),y=app:s(y)}}) end
tap(440,20);assert(app.chrome_hidden and app:readerHeight()==app.h);paint('toolbar-hidden')
app:turn(1);assert(app.nav.page==2 and app.book.path==book.path);paint('toolbar-page-2')
tap(300,200);assert(not app.chrome_hidden);paint('toolbar-restored')
tap(30,20);assert(app.screen_name=='library' and not app.doc)
app:openBook(book);assert(app.nav.page==2);paint('toolbar-resume')
local called=false;app.quit=function() called=true end;tap(550,20);assert(called)
print('PASS toolbar hide/show, fullscreen turn, Library, saved resume and Quit')
