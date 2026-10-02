-- SPDX-License-Identifier: AGPL-3.0-or-later
local Device=require('device')
local UI=require('ui/uimanager')
local Input=require('ui/widget/container/inputcontainer')
local Gesture=require('ui/gesturerange')
local BB=require('ffi/blitbuffer')
local O=Input:extend{}
function O:init()
    self.dimen=self.owner.dimen;self.power=self.power or Device:getPowerDevice();self.hits={}
    self.ges_events={Tap={Gesture:new{ges='tap',range=self.dimen}}}
    self.key_events={Close={{'Back'},{'Esc'}}}
end
function O:onClose() UI:close(self);self.owner:refresh();return true end
function O:hit(id,x,y,w,h,fn) self.hits[#self.hits+1]={id=id,x=x,y=y,w=w,h=h,fn=fn} end
function O:button(bb,id,text,x,y,w,h,fn,active)
    local a=self.owner
    bb:paintRect(x,y,w,h,active and BB.COLOR_BLACK or BB.Color8(245))
    if not active then bb:paintBorder(x,y,w,h,a:s(1),BB.Color8(175)) end
    a:centerLabel(bb,text,x,y,w,h,13,true,active);self:hit(id,x,y,w,h,fn)
end
function O:paintTo(bb)
    local a=self.owner;local s=function(n)return a:s(n)end;local p=self.power
    self.hits={};bb:paintRect(0,0,a.w,a.h,BB.COLOR_WHITE)
    a:label(bb,'Reading options',s(28),s(30),28,true,a.w-s(125))
    self:button(bb,'close','×',a.w-s(74),s(28),s(46),s(42),function()self:onClose()end)
    a:label(bb,a.doc and 'Saved for this book · Light and theme stay global.' or 'Defaults for books without saved settings.',s(28),s(77),13,false,a.w-s(56))
    bb:paintRect(s(28),s(110),a.w-s(56),1,BB.Color8(175))
    local function row(id,label,y,value,min,max,enabled,set,toggle)
        a:label(bb,label,s(28),y,18,true,s(240))
        if not enabled then a:label(bb,'Unavailable',s(28),y+s(42),13,false,s(350));return end
        a:centerLabel(bb,tostring(value),s(260),y,s(80),s(30),15,true)
        self:button(bb,id..'-toggle',id=='contrast' and 'Reset' or value>0 and 'On' or 'Off',a.w-s(104),y-s(3),s(76),s(34),toggle,id~='contrast' and value>0)
        local x=s(88);local w=a.w-s(176);local sy=y+s(57)
        self:button(bb,id..'-minus','−',s(28),sy-s(21),s(42),s(42),function()set(math.max(min,value-1))end)
        self:button(bb,id..'-plus','+',a.w-s(70),sy-s(21),s(42),s(42),function()set(math.min(max,value+1))end)
        bb:paintRect(x,sy,w,s(2),BB.Color8(180));local filled=math.floor(w*(value-min)/(max-min))
        bb:paintRect(x,sy,filled,s(3),BB.COLOR_BLACK)
        bb:paintCircle(x+filled,sy,s(10),BB.COLOR_WHITE);bb:paintCircle(x+filled,sy,s(10),BB.COLOR_BLACK,s(1))
        self:hit(id..'-slider',x,sy-s(24),w,s(48),function(px)set(math.floor(min+(px-x)/w*(max-min)+.5))end)
    end
    local dirty=function()UI:setDirty(self,'partial')end
    row('brightness','Brightness',s(140),p:frontlightIntensity(),0,p.fl_max or 24,Device:hasFrontlight(),function(v)p:setIntensity(v);dirty()end,function()p:toggleFrontlight();dirty()end)
    row('warmth','Warmth',s(246),p:frontlightWarmth(),0,100,Device:hasNaturalLight(),function(v)p:setWarmth(v);dirty()end,function()
        local v=p:frontlightWarmth();if v>0 then a.state.last_warmth=v;p:setWarmth(0) else p:setWarmth(a.state.last_warmth or 50) end;a:save();dirty()
    end)
    local function contrast(v)a.state.contrast=v/100;a:save();if a.doc then a:renderPage()end;dirty()end
    row('contrast','Contrast',s(352),math.floor((a.state.contrast or 1)*100+.5),50,200,true,contrast,function()contrast(100)end)
    a:label(bb,'100 is the original page tone.',s(28),s(438),11,false,a.w-s(56))
    local y=s(464);local gap=s(12);local w=math.floor((a.w-s(56)-gap)/2);local h=s(40)
    local function choice(id,text,col,row,fn,active)
        self:button(bb,id,text,s(28)+(col-1)*(w+gap),y+(row-1)*s(48),w,h,fn,active)
    end
    if a.doc then
        local function fit(mode)a.state.fit=mode;a.zoom=1;a.pan_x=0;a.nav.offset=0;a:renderPage();a:save();dirty()end
        choice('fit-page','Fit page',1,1,function()fit('page')end,a.state.fit=='page')
        choice('fit-width','Fit width',2,1,function()fit('width')end,a.state.fit=='width')
        choice('rtl','Right to left',1,2,function()a.state.direction='rtl';a:save();dirty()end,a.state.direction=='rtl')
        choice('ltr','Left to right',2,2,function()a.state.direction='ltr';a:save();dirty()end,a.state.direction=='ltr')
        choice('zoom','Zoom',1,3,function()self:onClose();a:zoomMenu()end)
        choice('jump','Go to page',2,3,function()self:onClose();a:jumpDialog()end)
        choice('animation','Page animation: '..(a.state.animation==false and 'Off' or 'On'),1,4,function()a.state.animation=a.state.animation==false;a:save();dirty()end)
        choice('crop','Auto-crop: '..(a.state.autocrop and 'On' or 'Off'),2,4,function()a.state.autocrop=not a.state.autocrop;a:renderPage();a:save();dirty()end,a.state.autocrop)
        choice('prefetch','Pre-render: '..(a.state.prefetch==false and 'Off' or 'On'),1,5,function()a.state.prefetch=a.state.prefetch==false;a:clearPageCache();a:renderPage();a:save();dirty()end,a.state.prefetch~=false)
        choice('more','Text, notes & controls',2,5,function()self:onClose();a:extraReaderOptions()end)
        choice('theme',a.state.dark_mode and 'Dark mode' or 'Light mode',1,6,function()a.state.dark_mode=not a.state.dark_mode;require('device').screen:toggleNightMode();a:save();UI:setDirty(self,'full')end,a.state.dark_mode)
        choice('done','Done',2,6,function()self:onClose()end,true)
    else
        self:button(bb,'theme',a.state.dark_mode and 'Dark mode' or 'Light mode',s(28),y,a.w-s(56),h,function()a.state.dark_mode=not a.state.dark_mode;require('device').screen:toggleNightMode();a:save();UI:setDirty(self,'full')end)
        self:button(bb,'more','Refresh & sleep settings',s(28),y+s(56),a.w-s(56),h,function()self:onClose();a:extraReaderOptions()end)
        self:button(bb,'done','Done',s(28),y+s(112),a.w-s(56),h,function()self:onClose()end,true)
    end
end
function O:onTap(_,g)
    for _,h in ipairs(self.hits) do if g.pos.x>=h.x and g.pos.x<h.x+h.w and g.pos.y>=h.y and g.pos.y<h.y+h.h then h.fn(g.pos.x);break end end
    return true
end
function O.show(owner) UI:show(O:new{owner=owner}) end
return O
