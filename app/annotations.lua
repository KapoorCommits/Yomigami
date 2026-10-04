-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager');local Store=require('storage')
return function(App)
function App:addAnnotation(quote,note,anchor)
    self.state.annotations=self.state.annotations or {}
    local list=self.state.annotations[self.book.path] or {};self.state.annotations[self.book.path]=list
    list[#list+1]={quote=quote or '',note=note or '',page=self.nav.page,count=self.nav.count,created=os.time(),font_size=self.state.font_size,anchor=anchor}
    self.highlight_overlay=nil
    local ok=self:save();self:refresh();if ok then self:message('Saved to this book’s highlights & notes.')end
    return list[#list]
end
function App:pageTextNotes()
    if not self.doc then return end
    local ok,text=pcall(self.doc.pageText,self.doc,self.nav.page)
    if not ok then return self:message('Could not extract text from this page.')end
    if text:match('^%s*$') then return self:input('Page note · No selectable text on this scan',function(note)self:addAnnotation('',note)end)end
    local viewer
    viewer=require('ui/widget/textviewer'):new{title='Page '..self.nav.page..' · Hold and drag to select',text=text,
        text_selection_callback=function(quote,_,start_idx,end_idx)
            local ok,anchor=pcall(require('highlight_anchor').capture,self.doc,self.nav.page,quote,start_idx,end_idx)
            if not ok or not anchor then return self:message('Could not locate this selection reliably. Select a longer passage.')end
            local function save(note)self:addAnnotation(quote,note,anchor);UI:close(viewer);self:refresh()end
            self:menu('Selected passage',{
                {text='Save highlight',callback=function()save('')end},
                {text='Add note to highlight',callback=function()self:input('Note for selected passage',function(note)save(note)end)end},
            })
        end}
    UI:show(viewer)
end
function App:paintHighlights(bb)
    local t=self.page_transform;if not t or not self.page_image then return end
    local entries=(self.state.annotations or {})[self.book.path] or {}
    local key=self:renderSignature()..':'..self.nav.page..':'..#entries
    if not self.highlight_overlay or self.highlight_overlay.key~=key then
        local ok,boxes=pcall(require('highlight_anchor').boxes,self.doc,self.nav.page,entries)
        self.highlight_overlay={key=key,boxes=ok and boxes or {}}
    end
    local image=self.page_image;local ox=math.floor((self.w-image:getWidth())/2)
    local oy=(self.chrome_hidden and 0 or self:s(47))+math.floor((self:readerHeight()-image:getHeight())/2)
    for _,b in ipairs(self.highlight_overlay.boxes)do
        local x=math.max(0,math.floor(b.x0*t.zoom-t.x));local y=math.max(0,math.floor(b.y0*t.zoom-t.y))
        local right=math.min(image:getWidth(),math.ceil(b.x1*t.zoom-t.x));local bottom=math.min(image:getHeight(),math.ceil(b.y1*t.zoom-t.y))
        if right>x and bottom>y then bb:darkenRect(ox+x,oy+y,right-x,bottom-y,.20)end
    end
end
function App:exportAnnotations()
    local dir=self.root..'/exports';require('libs/libkoreader-lfs').mkdir(dir)
    local path=dir..'/'..require('book_transfer').name(self.book.title,'PDF'):gsub('%.pdf$','')..'-notes.md'
    local out={'# '..self.book.title:gsub('[\r\n]',' '),'','Highlights and notes exported from Yomigami. Page numbers refer to the layout at capture.',''}
    for _,entry in ipairs((self.state.annotations or {})[self.book.path] or {})do
        out[#out+1]='## Page '..entry.page;out[#out+1]=''
        if entry.quote~='' then out[#out+1]='> '..entry.quote:gsub('\n','\n> ');out[#out+1]=''end
        if entry.note~='' then out[#out+1]=entry.note;out[#out+1]=''end
    end
    local ok,err=Store.writeDurable(path..'.tmp',table.concat(out,'\n'))
    if ok then ok,err=os.rename(path..'.tmp',path)end
    if ok then ok,err=require('ffi/util').fsyncDirectory(path)end
    if not ok then self:message('Export failed: '..tostring(err));return end
    self:message('Markdown saved to '..path);return path
end
function App:annotationsMenu()
    local entries=(self.state.annotations or {})[self.book.path] or {}
    local items={
        {text='Select text / Highlight this page',callback=function()self:pageTextNotes()end},
        {text='Add page note',callback=function()self:input('Page note',function(note)self:addAnnotation('',note)end)end},
        {text='Export '..#entries..' entries as Markdown',callback=function()self:exportAnnotations()end},
    }
    for index,entry in ipairs(entries)do local n=index;local e=entry
        items[#items+1]={text='Page '..e.page..' · '..(e.quote~='' and e.quote or e.note):sub(1,100),callback=function()
            self:menu('Highlight / Page '..e.page,{
                {text='Read full highlight and note',callback=function()UI:show(require('ui/widget/textviewer'):new{title='Page '..e.page,text=e.quote..'\n\n'..e.note})end},
                {text='Edit note',callback=function()self:input('Replace note',function(note)e.note=note;self:save()end)end},
                {text=e.anchor and 'Go to highlighted passage' or 'Go to location (approximate after reflow)',callback=function()
                    local page=e.page
                    if e.anchor then
                        local H=require('highlight_anchor');local idx=H.index(self.doc,page);local first=H.resolve(idx,e.anchor)
                        if not first then return self:message('This passage could not be located unambiguously in the current layout.')end
                        page=idx.words[first].page
                    elseif self.doc.reflowable and e.count~=self.nav.count then page=math.floor((e.page-1)/math.max(1,e.count-1)*(self.nav.count-1))+1 end
                    self.navigation_direction=page<self.nav.page and -1 or 1;self.nav:jump(page);self:renderPage();self:saveProgress();self:refresh()
                end},
                {text='Delete entry',callback=function()UI:show(require('ui/widget/confirmbox'):new{text='Delete this highlight and note?',ok_callback=function()table.remove(entries,n);self.highlight_overlay=nil;self:save();self:refresh()end})end},
            })
        end}
    end
    self:menu('Highlights & notes',items)
end
end
