-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager')
local Device=require('device')
local Input=require('ui/widget/container/inputcontainer')
local Geom=require('ui/geometry')
local Gesture=require('ui/gesturerange')
local BB=require('ffi/blitbuffer')
local Text=require('ui/widget/textwidget')
local Font=require('ui/font')
local P=require('passcode')
local Pad=Input:extend{modal=true}
function Pad:init()
 self.w=Device.screen:getWidth();self.h=Device.screen:getHeight();self.scale=self.w/600
 self.dimen=Geom:new{x=0,y=0,w=self.w,h=self.h};self.pin='';self.hits={}
 self.ges_events={Tap={Gesture:new{ges='tap',range=self.dimen}}}
 self.key_events={Back={{'Back'},{'Esc'}}}
end
function Pad:onBack()UI:close(self);self.cancel();return true end
function Pad:label(bb,text,y,size)
 local t=Text:new{text=text,face=Font:getFace('cfont',math.floor(size*self.scale)),max_width=self.w-40}
 t:paintTo(bb,math.floor((self.w-t:getSize().w)/2),y);t:free()
end
function Pad:paintTo(bb)
 local s=function(n)return math.floor(n*self.scale)end
 bb:paintRect(0,0,self.w,self.h,BB.COLOR_WHITE);self.hits={}
 self:label(bb,'Y O M I G A M I',s(48),24)
 self:label(bb,self.title,s(108),20)
 self:label(bb,string.rep('● ',#self.pin),s(166),24)
 self:label(bb,self.error or '4–8 digits',s(215),13)
 local top=math.max(s(265),math.floor((self.h-s(360))/2));local width=s(130);local height=s(60)
 local labels={'1','2','3','4','5','6','7','8','9','⌫','0','OK'}
 for i,label in ipairs(labels)do
  local x=math.floor((self.w-s(420))/2)+((i-1)%3)*s(145);local y=top+math.floor((i-1)/3)*s(72)
  bb:paintBorder(x,y,width,height,s(1),BB.Color8(150))
  local t=Text:new{text=label,face=Font:getFace('cfont',s(24))};local z=t:getSize();t:paintTo(bb,x+(width-z.w)/2,y+(height-z.h)/2);t:free()
  self.hits[#self.hits+1]={x=x,y=y,w=width,h=height,key=label}
 end
 local y=top+s(302);self:label(bb,self.exit_label or 'Cancel',y,16)
 self.hits[#self.hits+1]={x=0,y=y-s(10),w=self.w,h=s(48),key='cancel'}
end
function Pad:press(key)
 if key=='cancel'then return self:onBack()
 elseif key=='⌫'then self.pin=self.pin:sub(1,-2)
 elseif key=='OK'then
  if not P.valid(self.pin)then self.error='Use 4 to 8 digits.'
  else local value=self.pin;self.pin='';self.submit(self,value);value=nil end
 elseif #self.pin<8 and key:match('^%d$')then self.pin=self.pin..key;self.error=nil end
 UI:setDirty(self,'partial');return true
end
function Pad:onTap(_,g)
 for _,h in ipairs(self.hits)do if g.pos.x>=h.x and g.pos.x<h.x+h.w and g.pos.y>=h.y and g.pos.y<h.y+h.h then return self:press(h.key)end end
 return true
end
local M={Pad=Pad}
function M.unlock(root,done,cancel)
 local settings,err=P.load(root)
 if settings and not settings.enabled then done();return end
 local pad=Pad:new{title='Enter your passcode',exit_label='Exit to Kindle',cancel=cancel,error=err,submit=function(self,pin)
  local ok,e=P.verify(root,pin)
  if ok then UI:close(self);done()else self.error=e end
 end};UI:show(pad)
end
function M.settings(app)
 local cfg,err=P.load(app.root);if not cfg then app:message(err);return end
 local function setup()
  local first
  UI:show(Pad:new{title='Choose a passcode',cancel=function()first=nil;app:refresh()end,submit=function(self,pin)
   if not first then first=pin;self.title='Confirm your passcode';self.error=nil
   elseif first~=pin then first=nil;self.title='Choose a passcode';self.error='Codes did not match. Try again.'
   else local ok,e=P.set(app.root,pin);first=nil;if ok then UI:close(self);app:refresh();app:message('Passcode enabled. Required each time Yomigami opens.')else self.title='Choose a passcode';self.error=e end end
  end})
 end
 local function auth(fn)M.unlock(app.root,fn,function()app:refresh()end)end
 local items
 if cfg.enabled then items={{text='Change passcode',callback=function()auth(setup)end},{text='Disable passcode',callback=function()auth(function()local ok,e=P.disable(app.root);app:message(ok and 'Passcode disabled.' or e)end)end}}
 else items={{text='Enable numeric passcode',callback=setup}}end
 app:menu('Passcode · '..(cfg.enabled and 'On' or 'Off'),items)
end
return M
