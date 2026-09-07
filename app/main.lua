-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager')
local Device=require('device')
local Input=require('ui/widget/container/inputcontainer')
local GestureRange=require('ui/gesturerange')
local Geom=require('ui/geometry')
local BB=require('ffi/blitbuffer')
local Text=require('ui/widget/textwidget')
local Font=require('ui/font')
local Info=require('ui/widget/infomessage')
local Store=require('storage')
local Doc=require('document')
local Nav=require('navigation')
local Catalog=require('catalog')
local App=Input:extend{name='Yomigami',is_always_active=true}
function App:init()
    self.root=assert(os.getenv('YOMIGAMI_HOME'))
    self.w,self.h=Device.screen:getWidth(),Device.screen:getHeight()
    self.scale=self.w/600
    self.dimen=Geom:new{x=0,y=0,w=self.w,h=self.h}
    self.ges_events={Tap={GestureRange:new{ges='tap',range=self.dimen}},Swipe={GestureRange:new{ges='swipe',range=self.dimen}}}
    for event,ges in pairs({Hold='hold',Pinch='pinch',Spread='spread'}) do
        self.ges_events[event]={GestureRange:new{ges=ges,range=self.dimen}}
    end
    self.key_events={Back={{'Back'},{'Esc'}},Forward={{'Right'},{'PgFwd'},{'Space'}},Backward={{'Left'},{'PgBack'}}}
    self.state,self.state_error=Store.load(self.root..'/state.json',{progress={},direction='rtl',fit='page'})
    self.state.progress=self.state.progress or {}
    self.state.downloads=self.state.downloads or {}
    self.state.series=self.state.series or {}
    self:initBookPreferences()
    self.jobs={}
    self.state.aliases=self.state.aliases or {}
    self.state.trash=self.state.trash or {}
    self.state.incomplete=self.state.incomplete or {}
    self.screen_name='library'; self.shelf=1; self.filter='All'; self.hits={}; self.covers={}
    self:scan()
    if (Device.screen.night_mode or false)~=(self.state.dark_mode or false) then Device.screen:toggleNightMode() end
    self:startDownloads()
    self:startBookDownloads()
end
function App:s(n) return math.floor(n*self.scale+.5) end
function App:save()
    if self.state_error then return nil,self.state_error end -- Never overwrite an unreadable original.
    self:rememberReadingSettings()
    local ok,err=Store.save(self.root..'/state.json',self.state)
    if not ok then self:message('Progress could not be saved: '..tostring(err)) end
    return ok,err
end
function App:message(text) UI:show(Info:new{text=tostring(text),timeout=5}) end
function App:refresh() UI:setDirty(self,'full') end
function App:refreshPage(delta,result)
    self.turns_since_full=(self.turns_since_full or 0)+1
    local full=self.turns_since_full>=6
    if full then self.turns_since_full=0 end
    if result=='page' and not full and Device:canDoSwipeAnimation() and self.state.animation~=false then
        Device.screen:setSwipeAnimations(true)
        Device.screen:setSwipeDirection((delta>0)~=(self.state.direction=='rtl'))
    end
    local top=self.chrome_hidden and 0 or self:s(47)
    local region=Geom:new{x=0,y=top,w=self.w,h=self.h-top}
    UI:setDirty(self,full and 'full' or 'partial',region)
end
function App:scan()
    self.books=Store.scan(self.root..'/library')
    local downloaded=Store.scan(self.root..'/sources/downloads')
    local groups={}
    for _,book in ipairs(downloaded) do
        local meta=self.state.downloads[book.path]
        if meta then
            book.title=meta.title;book.series_key=meta.series_key;book.chapter_num=meta.chapter_num
            local key=meta.series_key
            groups[key]=groups[key] or {};table.insert(groups[key],book)
        elseif not self.state.incomplete[book.path] then self.books[#self.books+1]=book end
    end
    for key,chapters in pairs(groups) do
        table.sort(chapters,function(a,b)
            if type(a.chapter_num)=='number' and type(b.chapter_num)=='number' and a.chapter_num~=b.chapter_num then return a.chapter_num<b.chapter_num end
            return Store.natural(a.title,b.title)
        end)
        local meta=self.state.series[key] or {}
        self.books[#self.books+1]={path='series:'..key,title=meta.title or chapters[1].title,format='CBZ',
            chapters=chapters,cover_path=meta.cover_path or chapters[1].path,series_key=key}
    end
    self:groupLocalChapters()
    for _,b in ipairs(self.books) do b.title=self.state.aliases[b.path] or b.title end
    table.sort(self.books,function(a,b) return Store.natural(a.title,b.title) end)
    if self.screen_name=='library' and UI:getTopmostVisibleWidget()==self then self:refresh() end
end
function App:items()
    local out={}
    for _,b in ipairs(self.books) do
        local p=self:bookmarkFor(b)
        if self.filter=='All' or self.filter=='PDFs' and b.format=='PDF'
            or self.filter=='EPUBs' and b.format=='EPUB'
            or self.filter=='Manga' and b.format=='CBZ'
            or self.filter=='Reading' and p and p.page<p.count then out[#out+1]=b end
    end
    return out
end
function App:label(bb,text,x,y,size,bold,width,white)
    local t=Text:new{text=tostring(text),face=Font:getFace(bold and 'tfont' or 'cfont',size),
        bold=bold or false,max_width=width,padding=0,fgcolor=white and BB.COLOR_WHITE or BB.COLOR_BLACK}
    t:paintTo(bb,x,y); t:free()
end
function App:centerLabel(bb,text,x,y,w,h,size,bold,white)
    local t=Text:new{text=tostring(text),face=Font:getFace(bold and 'tfont' or 'cfont',size),
        bold=bold or false,max_width=w-self:s(12),padding=0,fgcolor=white and BB.COLOR_WHITE or BB.COLOR_BLACK}
    local d=t:getSize()
    t:paintTo(bb,x+math.floor((w-d.w)/2),y+math.floor((h-d.h)/2));t:free()
end
function App:hit(x,y,w,h,fn) self.hits[#self.hits+1]={x=x,y=y,w=w,h=h,fn=fn} end
function App:button(bb,title,x,y,w,fn,active)
    local h=self:s(34)
    if active then bb:paintRect(x,y,w,h,BB.COLOR_BLACK) else bb:paintBorder(x,y,w,h,self:s(1),BB.COLOR_BLACK) end
    self:centerLabel(bb,title,x,y,w,h,13,false,active)
    self:hit(x,y,w,h,fn)
end
function App:cover(book,w,h)
    local key=book.path..':'..w..':'..h
    if self.covers[key] then return self.covers[key] end
    local doc
    local ok,result=pcall(function() doc=Doc.open(book.cover_path or book.path); return doc:render(1,w,h,'page',0) end)
    if doc then doc:close() end
    if not ok then return nil end
    self.covers[key]=result
    return result
end
function App:clearCovers() for _,b in pairs(self.covers) do b:free() end; self.covers={} end
function App:paintTo(bb,x,y)
    self.hits={};self.book_hits={}; bb:paintRect(0,0,self.w,self.h,BB.COLOR_WHITE)
    if self.screen_name=='reader' then return self:paintReader(bb) end
    local p=self:s(28)
    self:label(bb,'Yomigami',p,self:s(25),34,true,self.w-p*2)
    self:label(bb,'A quiet place to read.',p,self:s(72),13,false,self.w-p*2)
    self:button(bb,'Mangas',self.w-self:s(310),self:s(30),self:s(82),function() self:showSources() end)
    self:button(bb,'PDFs',self.w-self:s(218),self:s(30),self:s(76),function() self:showBooks() end)
    self:button(bb,'+',self.w-self:s(132),self:s(30),self:s(44),function() self:libraryActions() end)
    self:button(bb,'×',self.w-self:s(78),self:s(30),self:s(48),function() self:quit() end)
    local filters={'All','Reading','Manga','PDFs','EPUBs'}
    for i,f in ipairs(filters) do
        self:button(bb,f,p+(i-1)*self:s(91),self:s(108),self:s(82),function() self.filter=f;self.shelf=1;self:clearCovers();self:refresh() end,self.filter==f)
    end
    local books=self:items()
    local rows=2; local cols=3; local per=rows*cols
    local pages=math.max(1,math.ceil(#books/per)); self.shelf=math.min(self.shelf,pages)
    local gap=self:s(18); local cw=math.floor((self.w-2*p-2*gap)/3)
    local top=self:s(169); local foot=self.h-self:s(76)
    local ch=math.floor((foot-top-self:s(24))/2)
    if #books==0 then
        self:label(bb,'Your next story starts here.',p,self:s(230),24,true,self.w-p*2)
        self:label(bb,'Add PDFs, EPUBs and CBZs with +, or discover Mangas.',p,self:s(276),16,false,self.w-p*2)
        self:label(bb,'Books stay on your Kindle for offline reading.',p,self:s(308),14,false,self.w-p*2)
    end
    for slot=1,per do
        local book=books[(self.shelf-1)*per+slot]
        if book then
            local cx=p+((slot-1)%3)*(cw+gap);local cy=top+math.floor((slot-1)/3)*(ch+self:s(12))
            local coverh=ch-self:s(62)
            bb:paintRect(cx+self:s(3),cy+self:s(4),cw,coverh,BB.Color8(210))
            bb:paintRect(cx,cy,cw,coverh,BB.Color8(244))
            local image=self:cover(book,cw,coverh)
            if image then bb:blitFrom(image,cx+math.floor((cw-image:getWidth())/2),cy+math.floor((coverh-image:getHeight())/2),0,0,image:getWidth(),image:getHeight())
            else self:label(bb,book.format,cx+self:s(14),cy+self:s(25),22,true,cw-self:s(20)) end
            bb:paintBorder(cx,cy,cw,coverh,1,BB.Color8(150))
            self:label(bb,book.title,cx,cy+coverh+self:s(10),15,true,cw)
            local saved=self:bookmarkFor(book)
            local caption=book.chapters and (#book.chapters..' chapters / Offline') or book.format..'  /  '..(saved and (saved.page..' of '..saved.count) or 'Not started')
            if not saved then self:label(bb,caption,cx,cy+coverh+self:s(34),11,false,cw) end
            if saved then
                bb:paintRect(cx,cy+coverh-3,math.floor(cw*saved.page/saved.count),3,BB.COLOR_BLACK)
                self:paintBookmark(bb,cx+cw-self:s(34),cy,self:s(24),self:s(42))
                caption=book.chapters and ('Ch '..tostring(saved.chapter_num or '?')..' / Page '..saved.page) or ('Bookmark / '..saved.page..' of '..saved.count)
                self:label(bb,caption,cx,cy+coverh+self:s(34),11,false,cw)
            end
            self:hit(cx,cy,cw,ch,function() self:openBook(book) end)
            self.book_hits[#self.book_hits+1]={x=cx,y=cy,w=cw,h=ch,book=book}
        end
    end
    bb:paintRect(p,foot,self.w-2*p,1,BB.Color8(160))
    self:label(bb,#books..' books  /  '..self.shelf..' of '..pages,p,foot+self:s(19),12,false,self:s(230))
    self:button(bb,'Back',self.w-self:s(198),foot+self:s(12),self:s(74),function() self:changeShelf(-1) end)
    self:button(bb,'Next',self.w-self:s(112),foot+self:s(12),self:s(82),function() self:changeShelf(1) end)
end
function App:changeShelf(delta)
    self.shelf=math.max(1,math.min(math.max(1,math.ceil(#self:items()/6)),self.shelf+delta))
    self:clearCovers();self:refresh()
end
function App:openBook(book,password)
    if book.chapters then return self:chapterMenu(book) end
    local ok,document=pcall(Doc.open,book.path,password)
    if not ok then
        if tostring(document):find('needs a password',1,true) then
            return self:input('PDF password',function(value) self:openBook(book,value) end,true)
        end
        return self:message('Unable to open '..book.title..'\n'..tostring(document))
    end
    self:clearPageCache()
    if self.doc then self:saveProgress();self.doc:close() end
    self:clearCovers();self.doc=document;self.book=book
    local saved=self.state.progress[book.path]
    self.nav=Nav.new(document.count,saved and saved.page)
    self.screen_name='reader';self.boundary=false;self.chrome_hidden=false;self.zoom=self:loadBookSettings();self.pan_x=0
    self:renderPage();self:saveProgress();self:refresh()
end
function App:renderPageUncached()
    if self.page_image then self.page_image:free();self.page_image=nil end
    local vh=self:readerHeight()
    local ok,image,content,content_width=pcall(self.doc.render,self.doc,self.nav.page,self.w,vh,self.state.fit,self.nav.offset,self.zoom,self.pan_x,self.state.contrast,self.state.autocrop)
    if ok then self.page_image=image;self.content_height=content;self.content_width=content_width;self.render_error=nil
    else self.render_error=tostring(image);self.content_height=vh end
end
function App:saveProgress()
    if not self.book or self.render_error then return end
    self.state.progress[self.book.path]={page=self.nav.page,count=self.nav.count,last_read=os.time(),chapter_title=self.book.title,chapter_num=self.book.chapter_num}
    if self.book.series_key then
        local meta=self.state.series[self.book.series_key] or {};meta.last_path=self.book.path
        self.state.series[self.book.series_key]=meta
    end
    self:save()
end
function App:readerHeight()
    return self.chrome_hidden and self.h or self.h-self:s(94)
end
function App:toggleChrome()
    self.chrome_hidden=not self.chrome_hidden
    self.nav.offset=0
    self:renderPage();self:refresh()
end
function App:paintReader(bb)
    local margin=self:s(18)
    if not self.chrome_hidden then
        local controls={
            {text='Library',x=0,w=100,fn=function() self:closeBook() end},
            {text='Options',x=300,w=100,fn=function() self:readerOptions() end},
            {text='Hide',x=400,w=90,fn=function() self:toggleChrome() end},
            {text='Quit ×',x=490,w=110,fn=function() self:quit() end},
        }
        for _,c in ipairs(controls) do
            self:centerLabel(bb,c.text,self:s(c.x),0,self:s(c.w),self:s(47),14,true)
            self:hit(self:s(c.x),0,self:s(c.w),self:s(47),c.fn)
        end
        self:label(bb,self.book.title,self:s(108),self:s(13),13,false,self:s(162))
        self:label(bb,'▾',self:s(278),self:s(13),13,true,self:s(20))
        self:hit(self:s(100),0,self:s(200),self:s(47),function() self:chapterDropdown() end)
    end
    local top=self.chrome_hidden and 0 or self:s(47);local vh=self:readerHeight()
    if self.page_image then
        local image=self.page_image
        bb:blitFrom(image,math.floor((self.w-image:getWidth())/2),top+math.floor((vh-image:getHeight())/2),0,0,image:getWidth(),image:getHeight())
    elseif self.render_error then self:label(bb,'Page could not be rendered. Try another page.',margin,top+self:s(30),14,false,self.w-2*margin) end
    local foot=self.h-self:s(40)
    if not self.chrome_hidden then
    bb:paintRect(margin,foot-self:s(6),self.w-2*margin,1,BB.Color8(160))
    self:label(bb,self.nav.page..' / '..self.nav.count,margin,foot+self:s(7),13,true,self:s(130))
    self:label(bb,self.state.fit=='width' and 'Fit width' or 'Fit page',self:s(240),foot+self:s(7),12,false,self:s(120))
    self:label(bb,self.state.direction:upper(),self.w-self:s(60),foot+self:s(7),12,true,self:s(50))
    self:hit(0,foot,self.w,self:s(40),function() self:jumpDialog() end)
    end
    self:hit(0,top,self.w*.34,vh,function() self:turn(self.state.direction=='rtl' and 1 or -1) end)
    self:hit(self.w*.66,top,self.w*.34,vh,function() self:turn(self.state.direction=='rtl' and -1 or 1) end)
    self:hit(self.w*.34,top,self.w*.32,vh,function() self:toggleChrome() end)
end
function App:turn(delta)
    if self.screen_name~='reader' then return self:changeShelf(delta) end
    if self.boundary then return true end
    local oldpage=self.nav.page
    local result=self.nav:turn(delta,self:readerHeight(),self.content_height)
    if result=='end' or result=='start' then
        if result=='start' then return self:message('First page') end
        self.boundary=true
        local Confirm=require('ui/widget/confirmbox')
        local nextbook
        if self.book.series_key then
            for _,series in ipairs(self.books) do
                if series.series_key==self.book.series_key and series.chapters then
                    for i,b in ipairs(series.chapters) do if b.path==self.book.path then nextbook=series.chapters[i+1];break end end
                end
            end
        end
        -- Only an adjacent CBZ in the same folder can be offered as the next chapter.
        if nextbook and (self.book.format~='CBZ' or nextbook.format~='CBZ' or nextbook.path:match('(.+)/')~=self.book.path:match('(.+)/')) then nextbook=nil end
        UI:show(Confirm:new{text=nextbook and ('Chapter finished.\nOpen '..nextbook.title..'?') or 'You have reached the last page.',
            ok_text=nextbook and 'Next chapter' or 'Library',cancel_text='Stay here',
            ok_callback=function() self.boundary=false;if nextbook then self:openBook(nextbook) else self:closeBook() end end,
            cancel_callback=function() self.boundary=false end})
        return true
    end
    if oldpage~=self.nav.page then self.pan_x=0 end
    self:renderPage();self:saveProgress();self:refreshPage(delta,result);return true
end
function App:closeBook()
    self:clearPageCache()
    self:saveProgress()
    if self.page_image then self.page_image:free();self.page_image=nil end
    if self.doc then self.doc:close();self.doc=nil end
    self.book=nil;self:restoreReadingDefaults();self.screen_name='library';self:refresh()
end
function App:onTap(_,g)
    for _,hit in ipairs(self.hits) do
        if g.pos.x>=hit.x and g.pos.x<hit.x+hit.w and g.pos.y>=hit.y and g.pos.y<hit.y+hit.h then hit.fn();return true end
    end
    return true
end
function App:onSwipe(_,g)
    local d=g.direction
    if self.screen_name=='reader' then
        if (self.zoom or 1)>1 then return self:panZoom(d,g.distance) end
        if d=='north' then self:turn(1) elseif d=='south' then self:turn(-1)
        elseif d=='west' or d=='east' then self:turn((d=='east')==(self.state.direction=='rtl') and 1 or -1) end
    elseif d=='west' then self:changeShelf(1) elseif d=='east' then self:changeShelf(-1) end
    return true
end
function App:onForward() return self:turn(1) end
function App:onBackward() return self:turn(-1) end
function App:onBack() if self.doc then self:closeBook() else self:quit() end;return true end
function App:quit() if self.wifi_receiver then self.wifi_receiver:onCloseWidget()end;self:stopBookDownloads();self:clearPageCache();self:stopDownloads();require('requests'):close();self:saveProgress();self:clearCovers();if self.doc then self.doc:close();self.doc=nil end;UI:quit() end
function App:onSuspend() if self.wifi_receiver then self.wifi_receiver:onClose()end;self:saveProgress() end
function App:onCloseWidget() self:saveProgress() end
function App:input(title,callback,password)
    local Dialog=require('ui/widget/inputdialog');local dialog
    dialog=Dialog:new{title=title,input='',text_type=password and 'password' or nil,buttons={{
        {text='Cancel',callback=function() UI:close(dialog) end},
        {text='OK',is_enter_default=true,callback=function() local value=dialog:getInputText();UI:close(dialog);callback(value) end}
    }}}
    UI:show(dialog);dialog:onShowKeyboard()
end
function App:menu(title,items)
    local Menu=require('ui/widget/menu');local menu
    for _,item in ipairs(items) do
        if item.callback then local callback=item.callback;item.callback=function() UI:close(menu);callback() end end
    end
    menu=Menu:new{title=title,item_table=items,width=self.w,height=self.h,is_popout=false,is_borderless=true,
        onCloseWidget=function() self:refresh() end,
        close_callback=function() self:refresh() end}
    UI:show(menu);return menu
end
function App:jumpDialog()
    self:input('Go to page (1-'..self.nav.count..')',function(value)
        if self.nav:jump(value) then self:renderPage();self:saveProgress();self:refresh() else self:message('Enter a valid page number.') end
    end)
end
function App:readerOptions() require('options').show(self) end
function App:libraryActions()
    self:menu('Your library',{
        {text='Import PDF, EPUB or CBZ',callback=function() self:chooseFile('/mnt/us/documents') end},
        {text='Storage',callback=function()self:showStorage()end},
        {text='Book downloads',callback=function()self:bookDownloadsMenu()end},
        {text='Send to Yomigami',callback=function()require('wifi_receive').show(self)end},
        {text='Recently deleted',callback=function() self:trashMenu() end},
        {text='Options',callback=function() self:readerOptions() end},
        {text='Rescan library',callback=function() self:scan() end},
        {text='About Yomigami',callback=function() self:message('Yomigami 0.5.0 alpha\nIndependent reader and library.\nPrivate KOReader-derived runtime and MuPDF; Rakuyomi source engine.\nAGPL-3.0. Device validation pending.') end},
        {text='Exit to Kindle',callback=function() self:quit() end},
    })
end
function App:chooseFile(path)
    local lfs=require('libs/libkoreader-lfs');local entries={}
    if lfs.attributes(path,'mode')~='directory' then path=self.root..'/library' end
    local parent=path:match('(.+)/[^/]+$')
    if parent then entries[#entries+1]={text='..',callback=function() self:chooseFile(parent) end} end
    for name in lfs.dir(path) do
        if name:sub(1,1)~='.' then
            local full=path..'/'..name;local mode=lfs.symlinkattributes(full,'mode')
            if mode=='directory' then entries[#entries+1]={text=name..'/',callback=function() self:chooseFile(full) end}
            elseif name:lower():match('%.pdf$') or name:lower():match('%.cbz$') or name:lower():match('%.epub$') then
                entries[#entries+1]={text=name,callback=function()
                    local dest,err=Store.import(full,self.root..'/library');if dest then self:scan();self:message('Added to your library.') else self:message(err) end
                end}
            end
        end
    end
    self:menu('Import / '..path,entries)
end
-- Requests are bounded. Downloads use server jobs, so page rendering stays local.
function App:request(path,method,body,done,failed)
    local notice=Info:new{text='Loading… You can continue reading.',timeout=2};UI:show(notice)
    require('requests'):send(self.root,path,method,body,function(ok,data)
        UI:close(notice)
        if ok then done(data) elseif failed then failed(data) else self:message(data) end
    end)
end
function App:sourceSettings()
    self:menu('Discover',{
        {text='Search installed sources',callback=function() self:input('Search manga',function(q) self:searchManga(q,1) end) end},
        {text='Install a source',callback=function() self:availableSources() end},
        {text='Installed sources',callback=function() self:request('/installed-sources',nil,nil,function(data)
            local items={};for _,s in ipairs(data) do items[#items+1]={text=s.name or s.id} end;self:menu('Installed sources',items)
        end) end},
        {text='Saved manga',callback=function() self:request('/library',nil,nil,function(data) self:mangaResults(data,'Saved manga') end) end},
        {text='Downloads',callback=function() self:downloadsMenu() end},
    })
end
function App:availableSources(filter)
    if not filter then return self:input('Find a source by name or language',function(value) self:availableSources(value) end) end
    self:request('/available-sources',nil,nil,function(data)
        local items={}
        for _,s in ipairs(data) do
        if ((s.name or s.id)..' '..table.concat(s.languages or {},' ')):lower():find(filter:lower(),1,true) then
        items[#items+1]={text=(s.name or s.id)..' / '..table.concat(s.languages or {},', '),callback=function()
            self:request('/available-sources/'..Catalog.encode(s.id)..'/install','POST',{source_of_source=s.source_of_source},function(result)
                self:message(result.type=='selection_required' and 'This source needs language selection; use an individual-language source in this alpha.' or 'Source installed.')
            end)
        end} end end
        self:menu('Available sources',items)
    end)
end
function App:showBooks() UI:show(require('books'):new{owner=self}) end
function App:showSources() UI:show(require('discover'):new{owner=self}) end
function App:searchManga(query,page) UI:show(require('discover'):new{owner=self,query=query,remote_page=page or 1,autosearch=true}) end
function App:mangaResults(data,title,more) UI:show(require('discover'):new{owner=self,results=data,query=title,more_callback=more}) end
function App:mangaDetails(m) UI:show(require('discover'):new{owner=self,manga=m}) end
require('book_preferences')(App)
require('book_queue')(App)
require('storage_view')(App)
require('reading_features')(App)
require('downloads')(App)
require('prefetch')(App)
return App
