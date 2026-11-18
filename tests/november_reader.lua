local app=...
local rank=require('search_rank')
local results=rank.rank({{title='Amon Saga'},{title='Vinland Saga Official'},{title='VINLAND SAGA'},{title='Saga of Vinland'},{title='Vinland Saga'}},'vinland saga')
assert(results[1].title=='VINLAND SAGA' and results[2].title=='Vinland Saga' and results[3].title=='Vinland Saga Official')
local UI=require('ui/uimanager');local BB=require('ffi/blitbuffer')
local view=require('discover'):new{owner=app,query='Vinland Saga',results=results}
local bb=BB.new(app.w,app.h,BB.TYPE_BB8);view:paintTo(bb)
if os.getenv('YOMIGAMI_SEARCH_PREVIEW')then bb:writePNG(os.getenv('YOMIGAMI_SEARCH_PREVIEW'))end
local clear;for _,h in ipairs(view.hits)do if h.id=='clear'then clear=h end end
assert(clear and math.abs(clear.y+clear.h/2-app:s(149))<=1)
assert(bb:getPixel(clear.x,clear.y):getColor8().a>240,'Clear hit must not have a square border')
clear.fn();assert(not view.results and not view.query and view.remote_page==1);bb:free();view:onCloseWidget()
local manga={source_id='en.fixture',id='series',title='Automatic series'};local key=require('catalog').seriesKey(manga)
local file=app.root..'/library/owned.cbz';local f=assert(io.open(file,'w'));f:write('fixture');f:close()
app.state.downloads[file]={series_key=key,chapter_id='ten',chapter_num=10};app.state.series[key]={manga=manga,title=manga.title}
local chapters={{id='old',chapter_number=1},{id='ten',chapter_number=10},{id='new',chapter_number=11}}
assert(app:applySeriesChapters(manga,chapters)==1);assert(app.state.queue[#app.state.queue].chapter.id=='new')
assert(app:applySeriesChapters(manga,chapters)==0,'Do not duplicate queued chapters')
chapters[#chapters+1]={id='special',title='New special'};assert(app:applySeriesChapters(manga,chapters)==1)
app.state.series[key].auto_updates=false;chapters[#chapters+1]={id='later',chapter_number=12};assert(app:applySeriesChapters(manga,chapters)==0)
local epub={path=app.root..'/Reader-layout.epub',title='Paragraph fixture',format='EPUB'}
app:openBook(epub);assert(require('device').input.disable_double_tap==false)
local map=app.doc:textMap(app.nav.page);local word=map.words[1];assert(word and word.line)
local t=app.page_transform;local image=app.page_image
local ox=math.floor((app.w-image:getWidth())/2);local oy=app:s(47)+math.floor((app:readerHeight()-image:getHeight())/2)
local gesture={pos={x=ox+(word.x0+word.x1)/2*t.zoom-t.x,y=oy+(word.y0+word.y1)/2*t.zoom-t.y}}
app:onDoubleTap(nil,gesture)
local entries=app.state.annotations[epub.path];assert(#entries==1 and entries[1].anchor)
local toast=UI:getTopmostVisibleWidget();if toast~=app then UI:close(toast)end
app:onDoubleTap(nil,gesture);assert(#entries==1,'Repeated double tap must not duplicate the highlight')
local boxes=require('highlight_anchor').boxes(app.doc,app.nav.page,entries);assert(#boxes>0)
app:closeBook();assert(require('device').input.disable_double_tap==true)
print('PASS exact-title ranking, borderless clear control, new-chapter baseline/dedup/opt-out, real EPUB double-tap highlight and gesture reset')
