-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager');local Store=require('storage')
return function(App)
function App:addAnnotation(quote,note)
    self.state.annotations=self.state.annotations or {}
    local list=self.state.annotations[self.book.path] or {};self.state.annotations[self.book.path]=list
    list[#list+1]={quote=quote or '',note=note or '',page=self.nav.page,count=self.nav.count,created=os.time(),font_size=self.state.font_size}
    local ok=self:save();if ok then self:message('Saved to this book’s highlights & notes.')end
    return list[#list]
end
function App:pageTextNotes()
    if not self.doc then return end
    local ok,text=pcall(self.doc.pageText,self.doc,self.nav.page)
    if not ok then return self:message('Could not extract text from this page.')end
    if text:match('^%s*$') then return self:input('Page note · No selectable text on this scan',function(note)self:addAnnotation('',note)end)end
    UI:show(require('ui/widget/textviewer'):new{title='Page '..self.nav.page..' · Hold and drag to select',text=text,
        text_selection_callback=function(quote)
            self:menu('Selected passage',{
                {text='Save highlight',callback=function()self:addAnnotation(quote,'')end},
                {text='Add note to highlight',callback=function()self:input('Note for selected passage',function(note)self:addAnnotation(quote,note)end)end},
            })
        end})
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
                {text='Go to location (approximate after reflow)',callback=function()
                    local page=e.page;if self.doc.reflowable and e.count~=self.nav.count then page=math.floor((e.page-1)/math.max(1,e.count-1)*(self.nav.count-1))+1 end
                    self.navigation_direction=page<self.nav.page and -1 or 1;self.nav:jump(page);self:renderPage();self:saveProgress();self:refresh()
                end},
                {text='Delete entry',callback=function()UI:show(require('ui/widget/confirmbox'):new{text='Delete this highlight and note?',ok_callback=function()table.remove(entries,n);self:save()end})end},
            })
        end}
    end
    self:menu('Highlights & notes',items)
end
end
