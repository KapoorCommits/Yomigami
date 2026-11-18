local app=...
local BB=require('ffi/blitbuffer');local C=require('crop');local UI=require('ui/uimanager');local Device=require('device')
local b=BB.new(400,600,BB.TYPE_BB8);b:fill(BB.COLOR_WHITE)
b:paintRect(130,90,150,400,BB.COLOR_BLACK)
b:paintRect(115,85,2,3,BB.Color8(210)) -- Small, faint edge text must remain.
local safe=C.bounds(b);local tight=C.bounds(b,true)
assert(tight.w<safe.w and tight.x*400<=114 and (tight.x+tight.w)*400>=280)
b:fill(BB.COLOR_WHITE);local blank=C.bounds(b,true);assert(blank.w==1 and blank.h==1);b:free()
local doc=require('document').open(os.getenv('YOMIGAMI_APP')..'/../build/crop-fixture.cbz')
local image,h,w=doc:render(1,400,600,'edge',0,1,0,1,false)
assert(image:getWidth()>=399 and h>=image:getHeight());image:free();doc:close()
local book;for _,v in ipairs(app.books)do if v.format=='CBZ' then book=v;break end end
app:openBook(book);app.state.fit='edge';app:renderPage();app:saveProgress();app:closeBook();app:openBook(book);assert(app.state.fit=='edge')
app.state.fit='page';app.state.autocrop=false;app.zoom=1;app.nav:jump(1);app:renderPage()
local save=app.save;local saves=0;app.save=function(self,...)saves=saves+1;return save(self,...)end
app:turn(1);assert(saves==0 and app.progress_save_tick,'No disk save before page refresh')
app:turn(1);assert(saves==0)
local Store=require('storage');app.progress_save_tick();assert(saves==0,'Checkpoint must not rewrite the full library')
local checkpoint=Store.load(app.root..'/reading-position.json',{});assert(checkpoint.progress.page==app.nav.page)
local recovered={};assert(Store.restoreProgress(recovered,checkpoint));assert(recovered.progress[book.path].page==app.nav.page)
assert(not Store.restoreProgress(recovered,checkpoint),'Do not replay stale checkpoint')
assert(not Store.restoreProgress({}, {generation=1,path='x',progress={page=0,count=2}}))
app:closeBook();assert(saves==1 and not app.progress_save_tick,'Exit flushes the latest position')
app.save=save;app:openBook(book);app.nav:jump(1);app:renderPage();app:clearPageCache()
local render=app.doc.render;app.doc.render=function(self,n,...)if n==2 then error('injected failure')end;return render(self,n,...)end
app:turn(1);assert(app.nav.page==1 and app.page_image and not app.render_error,'Failed turn must not advance or lose current image')
local notice=UI:getTopmostVisibleWidget();if notice~=app then UI:close(notice)end
app.doc.render=render
local turn=app.turn;local turned;app.turn=function(_,delta)turned=delta;return true end
app.state.direction='rtl';app:onSwipe(nil,{direction='northeast'});assert(turned==1)
app.state.direction='ltr';app:onSwipe(nil,{direction='southwest'});assert(turned==1);app.turn=turn
local can=Device.canDoSwipeAnimation;local animation=Device.screen.setSwipeAnimations;local direction=Device.screen.setSwipeDirection
local flags={};Device.canDoSwipeAnimation=function()return true end;Device.screen.setSwipeAnimations=function(_,v)flags[#flags+1]=v end;Device.screen.setSwipeDirection=function()end
app.state.animation=true;app.state.refresh_manga=0;app:refreshPage(1,'pan');assert(flags[#flags])
app.state.animation=false;app:refreshPage(1,'page');assert(flags[#flags]==false)
Device.canDoSwipeAnimation=can;Device.screen.setSwipeAnimations=animation;Device.screen.setSwipeDirection=direction
app:closeBook();print('PASS tight crop protects faint edge marks, real render fills width, per-book fit persists, deferred save flushes on exit, failed turn rolls back, animation resets')
