-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager')
local BB=require('ffi/blitbuffer')
local Gesture=require('ui/gesturerange')
local C=require('catalog')
local R=require('requests')
local D=require('chapters'):extend{}
function D:init()
    local a=self.owner;self.dimen=a.dimen;self.hits={};self.page=1;self.remote_page=self.remote_page or 1
    self.per=math.max(1,math.floor((a.h-a:s(300))/a:s(76)))
    self.ges_events={Tap={Gesture:new{ges='tap',range=self.dimen}},Swipe={Gesture:new{ges='swipe',range=self.dimen}}}
    self.key_events={Close={{'Back'},{'Esc'}},Next={{'Right'},{'PgFwd'}},Previous={{'Left'},{'PgBack'}}}
    if self.manga then self:loadChapters()elseif self.autosearch then self:search()end
end
function D:onClose()self.closed=true;UI:close(self);self.owner:refresh();return true end
function D:onCloseWidget()self.closed=true end
function D:fetch(path,method,body,done)
    self.request_generation=(self.request_generation or 0)+1
    local generation=self.request_generation
    self.loading=true;self.error=nil;UI:setDirty(self,'partial')
    R:send(self.owner.root,path,method,body,function(ok,data)
        if self.closed or generation~=(self.request_generation or 0) then return end
        self.loading=false
        if ok then done(data)else self.error=tostring(data)end
        UI:setDirty(self,'full')
    end)
end
function D:search()
    self.query=(self.query or ''):match('^%s*(.-)%s*$');if self.query=='' then return end
    self:fetch('/mangas?q='..C.encode(self.query)..'&page='..self.remote_page..'&cancel_id=3030',nil,nil,function(data)
        self.results=data[1] or {};self.errors=data[2] or {};self.has_more=data[3];self.page=1
    end)
end
function D:loadChapters()
    local path=C.mangaPath(self.manga)
    -- The sample may be linked without having been discovered by a search yet.
    self:fetch(path..'/refresh-details','POST',1,function()
        self:fetch(path..'/refresh-chapters','POST',1,function()
            self:fetch(path..'/chapters',nil,nil,function(data)
                self.chapters=data
                table.sort(data,function(a,b)
                    local an=a.chapter_number or a.chapter_num;local bn=b.chapter_number or b.chapter_num
                    if type(an)=='number' and type(bn)=='number' and an~=bn then return an<bn end
                    return require('storage').natural(a.title or a.id,b.title or b.id)
                end)
            end)
        end)
    end)
end
function D:findOffline(chapter)
    local key=C.seriesKey(self.manga)
    for _,series in ipairs(self.owner.books)do for _,book in ipairs(series.chapters or {})do
        local meta=self.owner.state.downloads[book.path]
        if meta and meta.series_key==key and meta.chapter_id==chapter.id then return book end
    end end
end
function D:paintTo(bb)
    local a=self.owner;local s=function(n)return a:s(n)end;local p=s(28);local width=a.w-p*2
    self.hits={};bb:paintRect(0,0,a.w,a.h,BB.COLOR_WHITE)
    a:label(bb,self.manga and self.manga.title or 'Mangas',p,s(32),28,true,width-s(70))
    self:button(bb,'close','×',a.w-s(74),s(26),s(46),s(42),function()self:onClose()end)
    if self.manga then
        a:label(bb,C.sourceId(self.manga),p,s(80),12,false,width)
        self:button(bb,'all','Download All at once',p,s(116),width,s(48),function()
            if self.chapters then self:onClose();a:downloadAll(self.manga,self.chapters)end
        end,true)
    else
        a:label(bb,'Find your next story across every installed source.',p,s(82),13,false,width)
        bb:paintBorder(p,s(122),width,s(54),s(1),BB.Color8(160),s(27),true)
        bb:paintCircle(p+s(25),s(149),s(7),BB.COLOR_BLACK,s(1))
        for i=0,s(6) do bb:paintRect(p+s(30)+i,s(154)+i,s(1),s(1),BB.COLOR_BLACK) end
        a:centerLabel(bb,self.query or 'Search manga you want to read',p+s(45),s(122),width-s(106),s(54),14,false)
        if self.query then self:button(bb,'clear','×',a.w-p-s(48),s(127),s(40),s(44),function()self.query=nil;self.results=nil;self.errors=nil;self.error=nil;self.has_more=false;self.page=1;self.request_generation=(self.request_generation or 0)+1;self.loading=false;UI:setDirty(self,'full')end) end
        self:hit('search',p,s(122),width-s(55),s(54),function()
            a:input('Search manga you want to read',function(q)if not self.closed then self.query=q;self.remote_page=1;self:search()end end)
        end)
    end
    local entries=self.chapters or self.results or {}
    local caption=self.loading and 'Searching… You can go back and keep reading.' or self.error and 'Unable to load. Tap Retry below.' or (#entries>0 and (#entries..(self.manga and ' chapters' or ' results')..(self.errors and #self.errors>0 and ' · Some sources unavailable' or '')) or self.query and 'No results. Try another title.' or 'One search. All your manga sources.')
    a:label(bb,caption,p,s(191),12,false,width)
    for slot=1,self.per do
        local index=(self.page-1)*self.per+slot;local entry=entries[index]
        if entry then
            local y=s(229)+(slot-1)*s(76);local h=s(66)
            bb:paintRect(p,y,width,h,BB.Color8(247));bb:paintBorder(p,y,width,h,1,BB.Color8(210))
            local offline=self.manga and self:findOffline(entry)
            local saved=offline and a.state.progress[offline.path]
            a:centerLabel(bb,entry.title or entry.id,p+s(20),y+s(5),width-s(40),s(30),16,true)
            local sub=self.manga and (offline and (saved and 'Bookmark · Page '..saved.page or 'Ready to read') or 'Tap to download') or ((entry.source and entry.source.name) or C.sourceId(entry))
            a:centerLabel(bb,sub,p+s(20),y+s(36),width-s(40),s(22),11,false)
            if saved then a:paintBookmark(bb,a.w-p-s(28),y,s(17),s(27))end
            local selected=entry
            self:hit('item-'..index,p,y,width,h,function()
                if self.manga then
                    if offline then self:onClose();a:openBook(offline)else a:download(self.manga,selected)end
                else self:onClose();a:mangaDetails(selected)end
            end)
        end
    end
    if #entries==0 and not self.query and not self.manga then
        a:centerLabel(bb,'A whole library is waiting.',p,s(305),width,s(60),24,true)
        a:centerLabel(bb,'Search a title, choose a source, make it yours.',p,s(370),width,s(40),13,false)
        self:button(bb,'downloads','Downloads',p,s(450),width,s(48),function()self:onClose();a:downloadsMenu()end,true)
        self:button(bb,'manage','Manage sources',p,s(516),width,s(44),function()self:onClose();a:sourceSettings()end)
    end
    if #entries==0 and not self.query and not self.manga then return end
    local foot=a.h-s(68)
    self:button(bb,'previous','‹',p,foot,s(48),s(40),function()self:onPrevious()end)
    a:centerLabel(bb,self.page..' / '..math.max(1,math.ceil(#entries/self.per)),p+s(56),foot,s(80),s(40),12,false)
    self:button(bb,'downloads','Downloads',a.w/2-s(65),foot,s(130),s(40),function()self:onClose();a:downloadsMenu()end)
    self:button(bb,'next',self.error and 'Retry' or '›',a.w-p-s(65),foot,s(65),s(40),function()
        if self.error then if self.manga then self:loadChapters()else self:search()end else self:onNext()end
    end)
end
function D:move(delta)
    local n=math.max(1,math.ceil(#(self.chapters or self.results or {})/self.per))
    if delta>0 and self.page==n and self.has_more and not self.loading then self.remote_page=self.remote_page+1;self:search()
    else self.page=math.max(1,math.min(n,self.page+delta));UI:setDirty(self,'partial')end
    return true
end
return D
