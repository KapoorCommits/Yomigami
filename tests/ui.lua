
local app=...
app.state.fit='page'
local UI=require('ui/uimanager')
local BB=require('ffi/blitbuffer')
local root=assert(os.getenv('YOMIGAMI_HOME'))
local function draw(name)
    local bb=BB.new(app.w,app.h,BB.TYPE_BB8);app:paintTo(bb,0,0)
    bb:writePNG(root..'/'..name..'.png');bb:free()
end
assert(#app.books==6)
draw('library')
local book
for _,b in ipairs(app.books) do if b.format=='CBZ' then book=b;break end end
app:openBook(book);assert(app.nav.count==12);app.nav:jump(1);app:renderPage()
draw('reader-page-1')
for i=2,12 do app:turn(1);assert(app.nav.page==i);assert(app.book.path==book.path) end
app:turn(1);assert(app.boundary and app.nav.page==12 and app.book.path==book.path)
-- Dismiss the boundary dialog without selecting the next chapter.
local top=UI._window_stack[#UI._window_stack].widget;top.cancel_callback();UI:close(top)
assert(not app.boundary)
app.nav:jump(2);app:renderPage();draw('reader-page-2');app:closeBook()
app:openBook(book);assert(app.nav.page==2)
app:readerOptions();assert(#UI._window_stack==2)
local menu=UI._window_stack[#UI._window_stack].widget
local bb=BB.new(app.w,app.h,BB.TYPE_BB8);menu:paintTo(bb);bb:free()
for _,hit in ipairs(menu.hits) do if hit.id=='fit-page' then hit.fn();break end end
menu:onClose();assert(#UI._window_stack==1)
assert(app.state.fit=='page')
app:closeBook();app.filter='PDFs';assert(#app:items()==5);app.filter='Manga';assert(#app:items()==1);app.filter='All'
app:input('Test input',function() end)
local dialog=UI._window_stack[#UI._window_stack].widget;UI:close(dialog)
app:mangaResults({{id='test',title='Test series',source={id='en.test'}}},'Test results')
menu=UI._window_stack[#UI._window_stack].widget;assert(menu.results[1].source.id=='en.test');UI:close(menu)
for _,b in ipairs(app.books) do if b.title=='Long Horizons' then app:openBook(b);app.nav:jump(2);app.state.fit='width';app:renderPage();local p=app.nav.page;app:turn(1);assert(app.nav.page==p and app.nav.offset>0);draw('pdf-fit-width');app:closeBook() end end
require('sleep'):setup();require('sleep'):show();assert(require('device').screen_saver_mode);require('sleep'):close();assert(not require('device').screen_saver_mode)
for name in pairs(package.loaded) do assert(not name:match('^apps/reader/') and not name:match('^pluginloader'),name) end
app.state.fit='page';app:save()
print('PASS UI: native layout, 12-page chapter boundary, resume, menus, filters, input dialog, source schema, tall PDF pan, module isolation')
