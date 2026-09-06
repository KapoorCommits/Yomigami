-- SPDX-License-Identifier: AGPL-3.0-or-later
local Device=require('device')
local UI=require('ui/uimanager')
local Input=require('ui/widget/container/inputcontainer')
local Gesture=require('ui/gesturerange')
local BB=require('ffi/blitbuffer')
local L=Input:extend{}
function L:init()
    self.dimen=self.owner.dimen;self.power=self.power or Device:getPowerDevice()
    self.ges_events={Tap={Gesture:new{ges='tap',range=self.dimen}}}
    self.key_events={Close={{'Back'},{'Esc'}}}
end
function L:onClose() UI:close(self);self.owner:refresh();return true end
function L:paintTo(bb)
    local a=self.owner;local s=function(n)return a:s(n)end
    local top=math.floor((a.h-s(310))/2);self.hits={}
    bb:paintRect(0,0,a.w,a.h,BB.COLOR_WHITE)
    a:label(bb,'Reading light',s(28),top,26,true,a.w-s(100))
    a:label(bb,'×',a.w-s(52),top,26,true,s(40))
    self.hits[#self.hits+1]={x=a.w-s(75),y=top,w=s(75),h=s(50),fn=function()self:onClose()end}
    local function row(label,y,value,max,enabled,set,toggle)
        a:label(bb,label,s(28),y,19,true,s(230))
        if not enabled then a:label(bb,'Unavailable on this device',s(28),y+s(42),14,false,a.w-s(56));return end
        a:label(bb,value..' / '..max,s(270),y,15,false,s(120))
        a:label(bb,value>0 and 'On' or 'Off',a.w-s(78),y,16,true,s(65))
        self.hits[#self.hits+1]={x=a.w-s(110),y=y,w=s(100),h=s(38),fn=toggle}
        local x=s(80);local w=a.w-s(160);local sy=y+s(59)
        a:label(bb,'−',s(28),sy-s(13),24,true,s(40));a:label(bb,'+',a.w-s(52),sy-s(13),24,true,s(40))
        bb:paintRect(x,sy,w,s(3),BB.Color8(160));bb:paintRect(x,sy,math.floor(w*value/max),s(4),BB.COLOR_BLACK)
        local knob=x+math.floor(w*value/max);bb:paintCircle(knob,sy,s(11),BB.COLOR_WHITE)
        bb:paintCircle(knob,sy,s(11),BB.COLOR_BLACK,s(1))
        self.hits[#self.hits+1]={x=0,y=sy-s(25),w=s(75),h=s(50),fn=function()set(math.max(0,value-1))end}
        self.hits[#self.hits+1]={x=a.w-s(75),y=sy-s(25),w=s(75),h=s(50),fn=function()set(math.min(max,value+1))end}
        self.hits[#self.hits+1]={x=x,y=sy-s(25),w=w,h=s(50),fn=function(px)set(math.floor((px-x)/w*max+.5))end}
    end
    local p=self.power
    row('Brightness',top+s(75),p:frontlightIntensity(),p.fl_max or 24,Device:hasFrontlight(),function(v)p:setIntensity(v);UI:setDirty(self,'partial')end,function()p:toggleFrontlight();UI:setDirty(self,'partial')end)
    row('Warmth',top+s(205),p:frontlightWarmth(),100,Device:hasNaturalLight(),function(v)p:setWarmth(v);UI:setDirty(self,'partial')end,function()
        local v=p:frontlightWarmth();if v>0 then self.last_warmth=v;p:setWarmth(0) else p:setWarmth(self.last_warmth or 50) end;UI:setDirty(self,'partial')
    end)
end
function L:onTap(_,g)
    for _,h in ipairs(self.hits) do if g.pos.x>=h.x and g.pos.x<h.x+h.w and g.pos.y>=h.y and g.pos.y<h.y+h.h then h.fn(g.pos.x);break end end
    return true
end
function L.show(owner) UI:show(L:new{owner=owner}) end
return L
