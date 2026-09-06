-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager')
local Input=require('ui/widget/container/inputcontainer')
local Gesture=require('ui/gesturerange')
local BB=require('ffi/blitbuffer')
local Doc=require('document')
local C=Input:extend{}
function C:init()
    local a=self.owner;self.dimen=a.dimen;self.hits={}
    self.ges_events={Tap={Gesture:new{ges='tap',range=self.dimen}},Swipe={Gesture:new{ges='swipe',range=self.dimen}}}
    self.key_events={Close={{'Back'},{'Esc'}},Next={{'Right'},{'PgFwd'}},Previous={{'Left'},{'PgBack'}}}
    self.per=math.max(1,math.floor((a.h-a:s(310))/a:s(66)))
    self.meta=a.state.series[self.series.series_key] or {}
    self.last=self.meta.last_path
    local index=1
    for i,b in ipairs(self.series.chapters) do if b.path==self.last then index=i end end
    self.page=math.floor((index-1)/self.per)+1
    local doc
    local ok,image=pcall(function()doc=Doc.open(self.series.cover_path or self.series.chapters[1].path);return doc:render(1,a:s(68),a:s(102),'page',0)end)
    if doc then doc:close()end;if ok then self.cover=image end
end
function C:onCloseWidget()if self.cover then self.cover:free();self.cover=nil end end
function C:onClose()UI:close(self);self.owner:refresh();return true end
function C:hit(id,x,y,w,h,fn)self.hits[#self.hits+1]={id=id,x=x,y=y,w=w,h=h,fn=fn}end
function C:button(bb,id,text,x,y,w,h,fn,active)
    local a=self.owner
    bb:paintRect(x,y,w,h,active and BB.COLOR_BLACK or BB.COLOR_WHITE)
    if not active then bb:paintBorder(x,y,w,h,a:s(1),BB.Color8(175))end
    a:centerLabel(bb,text,x,y,w,h,13,true,active);self:hit(id,x,y,w,h,fn)
end
function C:paintTo(bb)
    local a=self.owner;local s=function(n)return a:s(n)end;local p=s(28)
    self.hits={};bb:paintRect(0,0,a.w,a.h,BB.COLOR_WHITE)
    a:label(bb,'YOUR LIBRARY',p,s(34),12,true,a.w-s(120))
    self:button(bb,'close','×',a.w-s(74),s(24),s(46),s(42),function()self:onClose()end)
    if self.cover then bb:blitFrom(self.cover,p,s(87),0,0,self.cover:getWidth(),self.cover:getHeight())end
    a:label(bb,self.series.title,s(116),s(96),23,true,a.w-s(145))
    a:label(bb,#self.series.chapters..' chapters · Available offline',s(116),s(135),12,false,a.w-s(145))
    local last=self.last and a.state.progress[self.last]
    a:label(bb,last and ('Your bookmark · Page '..last.page..' of '..last.count) or 'Choose a chapter to begin.',s(116),s(163),12,false,a.w-s(145))
    local y=s(220);local rh=s(58);local gap=s(8);local width=a.w-p*2
    for slot=1,self.per do
        local index=(self.page-1)*self.per+slot;local b=self.series.chapters[index]
        if b then
            local chapter=b;local yy=y+(slot-1)*(rh+gap);local marked=b.path==self.last
            bb:paintRect(p,yy,width,rh,marked and BB.Color8(236) or BB.Color8(248))
            bb:paintBorder(p,yy,width,rh,1,BB.Color8(marked and 100 or 218))
            local number=type(b.chapter_num)=='number' and b.chapter_num or index
            a:centerLabel(bb,number%1==0 and string.format('%02d',number) or tostring(number),p,yy,s(55),rh,17,true)
            local saved=a.state.progress[b.path]
            local label=saved and ('Page '..saved.page..' of '..saved.count) or 'Unread'
            a:centerLabel(bb,b.title,p+s(58),yy+s(4),width-s(112),s(27),14,true)
            a:centerLabel(bb,label,p+s(58),yy+s(30),width-s(112),s(20),11,false)
            if marked then a:paintBookmark(bb,a.w-p-s(35),yy,s(19),s(31))end
            self:hit('chapter-'..index,p,yy,width,rh,function()self:onClose();a:openBook(chapter)end)
        end
    end
    local pages=math.max(1,math.ceil(#self.series.chapters/self.per));local foot=a.h-s(68)
    self:button(bb,'previous','‹',p,foot,s(48),s(40),function()self:onPrevious()end)
    a:centerLabel(bb,self.page..' / '..pages,p+s(58),foot,s(70),s(40),12,false)
    local remote=self.meta.manga
    if remote then self:button(bb,'online','All online chapters',a.w/2-s(80),foot,s(180),s(40),function()self:onClose();a:onlineChapters(remote)end)end
    self:button(bb,'next','›',a.w-p-s(48),foot,s(48),s(40),function()self:onNext()end)
end
function C:move(delta)
    self.page=math.max(1,math.min(math.max(1,math.ceil(#self.series.chapters/self.per)),self.page+delta));UI:setDirty(self,'partial');return true
end
function C:onNext()return self:move(1)end
function C:onPrevious()return self:move(-1)end
function C:onSwipe(_,g)if g.direction=='west' then self:onNext()elseif g.direction=='east' then self:onPrevious()end;return true end
function C:onTap(_,g)
    for _,h in ipairs(self.hits) do if g.pos.x>=h.x and g.pos.x<h.x+h.w and g.pos.y>=h.y and g.pos.y<h.y+h.h then h.fn();break end end;return true
end
return C
