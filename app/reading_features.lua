-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager')
local BB=require('ffi/blitbuffer')
local Store=require('storage')
local lfs=require('libs/libkoreader-lfs')
return function(App)
function App:groupLocalChapters()
    local groups,books={},{}
    for _,b in ipairs(self.books) do
        local name,num=b.title:match('^(.-) %- [Cc]hapter ([%d%.]+)')
        if b.chapters then
            local existing=groups[b.series_key]
            if existing then for _,c in ipairs(b.chapters) do existing.chapters[#existing.chapters+1]=c end else groups[b.series_key]=b end
        elseif b.format=='CBZ' and name and tonumber(num) then
            local stored=self.state.downloads[b.path]
            local key=stored and stored.series_key or 'local:'..b.path:match('(.+)/')..'/'..name
            b.series_key=key;b.chapter_num=tonumber(num)
            groups[key]=groups[key] or {path='series:'..key,series_key=key,title=name,format='CBZ',chapters={}}
            table.insert(groups[key].chapters,b)
        else books[#books+1]=b end
    end
    for key,b in pairs(groups) do
        table.sort(b.chapters,function(a,c)
            if type(a.chapter_num)=='number' and type(c.chapter_num)=='number' and a.chapter_num~=c.chapter_num then return a.chapter_num<c.chapter_num end
            return Store.natural(a.title,c.title)
        end)
        b.cover_path=b.chapters[1].path
        local meta=self.state.series[key] or {title=b.title}
        if not meta.last_path then
            local latest=0
            for _,c in ipairs(b.chapters) do local p=self.state.progress[c.path];if p and (p.last_read or 0)>=latest then latest=p.last_read or 0;meta.last_path=c.path end end
        end
        self.state.series[key]=meta;books[#books+1]=b
    end
    self.books=books
end
function App:paintBookmark(bb,x,y,w,h)
    bb:paintRect(x,y,w,h,BB.COLOR_BLACK)
    for row=0,math.floor(w/2) do
        bb:paintRect(x+math.floor(w/2)-row,y+h-math.floor(w/2)+row,math.max(1,row*2),1,BB.COLOR_WHITE)
    end
end
function App:bookmarkFor(book)
    if book.series_key and book.chapters then
        local meta=self.state.series[book.series_key] or {}
        return meta.last_path and self.state.progress[meta.last_path]
    end
    return self.state.progress[book.path]
end
function App:chapterMenu(series)
    UI:show(require('chapters'):new{owner=self,series=series})
end
function App:onlineChapters(m) self:mangaDetails(m) end
function App:chapterDropdown()
    for _,b in ipairs(self.books) do
        if b.chapters and b.series_key==self.book.series_key then return self:chapterMenu(b) end
    end
    self:chapterMenu{title=self.book.title,path=self.book.path,chapters={self.book},cover_path=self.book.path}
end
function App:onHold(_,g)
    if self.screen_name~='library' then return true end
    for _,h in ipairs(self.book_hits or {}) do
        if g.pos.x>=h.x and g.pos.x<h.x+h.w and g.pos.y>=h.y and g.pos.y<h.y+h.h then self:bookActions(h.book);break end
    end
    return true
end
function App:renameBook(book,value)
    value=value:match('^%s*(.-)%s*$')
    if value=='' or #value>180 or value:find('[%c]') then return self:message('Use a title of 1–180 characters.') end
    self.state.aliases[book.path]=value;self:save();self:scan()
end
function App:bookActions(book)
    self:menu(book.title,{
        {text='Open / Resume bookmark',callback=function() self:openBook(book) end},
        {text='Rename',callback=function() self:input('New book title',function(v) self:renameBook(book,v) end) end},
        {text='Delete book',callback=function()
            UI:show(require('ui/widget/confirmbox'):new{text='Move '..book.title..' to Recently deleted?',ok_text='Delete',ok_callback=function() self:deleteBook(book) end})
        end},
    })
end
function App:deleteBook(book)
    if self.state_error then return self:message(self.state_error) end
    local trash=self.root..'/.trash';lfs.mkdir(trash)
    local files=book.chapters or {book};local moves={}
    local token=tostring(os.time())..'-'..tostring(math.random(100000,999999))
    for i,b in ipairs(files) do
        -- Only books indexed inside this app may be moved. Never follow symlinks.
        if b.path:sub(1,#self.root+1)~=self.root..'/' or lfs.symlinkattributes(b.path,'mode')~='file' then
            for _,m in ipairs(moves) do os.rename(m.trash,m.path) end
            return self:message('Book could not be moved. Original files retained.')
        end
        local dest=trash..'/'..token..'-'..i
        if lfs.attributes(dest) then for _,m in ipairs(moves) do os.rename(m.trash,m.path) end;return self:message('Please try deleting again.') end
        local ok,err=os.rename(b.path,dest)
        if not ok then for _,m in ipairs(moves) do os.rename(m.trash,m.path) end;return self:message(err) end
        moves[#moves+1]={path=b.path,trash=dest}
    end
    self.state.trash[#self.state.trash+1]={title=book.title,moves=moves}
    if not self:save() then
        table.remove(self.state.trash)
        for _,m in ipairs(moves) do os.rename(m.trash,m.path) end
        return
    end
    self:clearCovers();self:scan()
end
function App:restoreBook(index)
    local entry=self.state.trash[index];if not entry then return end
    for _,m in ipairs(entry.moves) do if lfs.attributes(m.path) then return self:message('A file already exists at the original location.') end end
    local restored={}
    for _,m in ipairs(entry.moves) do
        local ok,err=os.rename(m.trash,m.path)
        if not ok then for _,v in ipairs(restored) do os.rename(v.path,v.trash) end;return self:message(err) end
        restored[#restored+1]=m
    end
    table.remove(self.state.trash,index);self:save();self:scan()
end
function App:trashMenu()
    local items={}
    for i,entry in ipairs(self.state.trash) do
        local n=i;local e=entry
        items[#items+1]={text=e.title,callback=function()
            self:menu(e.title,{
                {text='Restore book',callback=function()self:restoreBook(n)end},
                {text='Delete permanently / Free space',callback=function()
                    UI:show(require('ui/widget/confirmbox'):new{text='Permanently delete '..e.title..'? This cannot be undone.',ok_text='Delete permanently',ok_callback=function()
                        for _,m in ipairs(e.moves) do
                            if m.trash:sub(1,#self.root+8)~=self.root..'/.trash/' then return self:message('Invalid trash path.') end
                            local ok,err=os.remove(m.trash);if not ok then return self:message(err) end
                        end
                        table.remove(self.state.trash,n);self:save();self:refresh()
                    end})
                end},
            })
        end}
    end
    if #items==0 then items={{text='No deleted books'}} end
    self:menu('Recently deleted',items)
end
function App:setZoom(value)
    if not self.doc then return end
    self.zoom=math.max(1,math.min(4,value));self.nav.offset=0;self.pan_x=0
    self:renderPage();self:refresh()
end
function App:onSpread(_,g)
    if self.doc then self:setZoom((self.zoom or 1)*(g.start_span and g.start_span>0 and g.span/g.start_span or 1.5)) end
    return true
end
function App:onPinch(_,g)
    if self.doc then self:setZoom((self.zoom or 1)*(g.start_span and g.start_span>0 and g.span/g.start_span or 1/1.5)) end
    return true
end
function App:panZoom(direction,distance)
    local step=math.min(self.w*.8,math.max(self:s(60),distance or self.w*.4))
    if direction=='west' then self.pan_x=self.pan_x+step elseif direction=='east' then self.pan_x=self.pan_x-step
    elseif direction=='north' then self.nav.offset=self.nav.offset+step elseif direction=='south' then self.nav.offset=self.nav.offset-step end
    self.pan_x=math.max(0,math.min(self.pan_x,math.max(0,(self.content_width or self.w)-self.w)))
    self.nav.offset=math.max(0,math.min(self.nav.offset,math.max(0,self.content_height-self:readerHeight())))
    self:renderPage();UI:setDirty(self,'partial');return true
end
function App:zoomMenu()
    local items={}
    for _,v in ipairs({1,1.5,2,3,4}) do local value=v;items[#items+1]={text=(v==1 and 'Reset zoom / ' or '')..v..'×',callback=function() self:setZoom(value) end} end
    self:menu('Zoom / Swipe to pan when enlarged',items)
end
end
