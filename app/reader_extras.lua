-- SPDX-License-Identifier: AGPL-3.0-or-later
return function(App)
function App:onDoubleTap()if self.doc then self:toggleChrome()end;return true end
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
