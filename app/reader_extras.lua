-- SPDX-License-Identifier: AGPL-3.0-or-later
return function(App)
function App:onDoubleTap(_,g)
    if not self.doc then return true end
    if not g or not g.pos then self:toggleChrome();return true end
    if self.book.format=='CBZ' then self:toggleChrome();return true end
    local image,t=self.page_image,self.page_transform;if not image or not t then return true end
    local ox=math.floor((self.w-image:getWidth())/2)
    local oy=(self.chrome_hidden and 0 or self:s(47))+math.floor((self:readerHeight()-image:getHeight())/2)
    if g.pos.x<ox or g.pos.x>=ox+image:getWidth() or g.pos.y<oy or g.pos.y>=oy+image:getHeight()then return true end
    local ok,map=pcall(self.doc.textMap,self.doc,self.nav.page)
    if not ok or #map.words==0 then self:message('This page has no selectable text. Hold the page to add a note.');return true end
    local quote,first,last=require('paragraph').at(map,(g.pos.x-ox+t.x)/t.zoom,(g.pos.y-oy+t.y)/t.zoom)
    if not quote then return true end
    local captured,anchor=pcall(require('highlight_anchor').capture,self.doc,self.nav.page,quote,first,last)
    if not captured or not anchor then self:message('Could not locate this paragraph. Use Select text for a precise highlight.');return true end
    for _,e in ipairs((self.state.annotations or {})[self.book.path] or {})do
        if e.anchor and e.anchor.first==anchor.first and e.anchor.last==anchor.last and e.anchor.text==anchor.text and e.anchor.page==anchor.page then return true end
    end
    self:addAnnotation(quote,'',anchor);return true
end
function App:ensureTextLayout()
    if not self.doc or not self.doc.reflowable then return end
    local width,height,font=self.w,self:readerHeight(),self:s(self.state.font_size or 24)
    local old=self.doc.layout or {}
    if old.width==width and old.height==height and old.font_size==font then return end
    local fraction=(self.nav.page-1)/math.max(1,self.nav.count-1)
    self.doc:relayout(width,height,font)
    self.nav.count=self.doc.count;self.nav.page=math.min(self.doc.count,math.floor(fraction*(self.doc.count-1))+1)
    self.nav.offset=0;self.pan_x=0;self:clearPageCache()
end
function App:extraReaderOptions()
    local items={}
    if self.doc then
        items[#items+1]={text='Highlights & notes',callback=function()self:annotationsMenu()end}
        items[#items+1]={text='Select text on this page',callback=function()self:pageTextNotes()end}
        if self.doc.reflowable then items[#items+1]={text='EPUB font size: '..(self.state.font_size or 24),callback=function()
            local sizes={};for _,n in ipairs({16,18,20,22,24,28,32,36,40})do local size=n;sizes[#sizes+1]={text=tostring(size),callback=function()self.state.font_size=size;self:renderPage();self:saveProgress();self:refresh()end}end
            self:menu('Font size · position is kept approximately',sizes)
        end}end
        items[#items+1]={text='Tap zones: '..(self.state.tap_zones=='forward' and 'Whole page forward' or 'Left / right'),callback=function()
            self.state.tap_zones=self.state.tap_zones=='forward' and 'sides' or 'forward';self:save();self:refresh()
        end}
        items[#items+1]={text='Show / hide reading toolbar',callback=function()self:toggleChrome()end}
    end
    for _,kind in ipairs({'manga','text'})do local category=kind
        items[#items+1]={text='Full refresh · '..category..': '..tostring(self.state['refresh_'..category] or 6),callback=function()
            local choices={};for _,n in ipairs({1,6,12,0})do local interval=n;choices[#choices+1]={text=interval==0 and 'Never (manual refresh still available)' or 'Every '..interval..' turns',callback=function()self.state['refresh_'..category]=interval;self.turns_since_full=0;self:save();self:refresh()end}end
            self:menu('Full refresh · '..category,choices)
        end}
    end
    items[#items+1]={text='Sleep cover: '..(self.state.sleep_cover==false and 'Off' or 'On'),callback=function()self.state.sleep_cover=self.state.sleep_cover==false;self:save()end}
    self:menu('Reading preferences',items)
end
end
