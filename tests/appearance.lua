-- SPDX-License-Identifier: AGPL-3.0-or-later
local app=...
local BB=require('ffi/blitbuffer');local A=require('appearance')
-- Every geometric stroke must remain connected at both UI scales.
for _,scale in ipairs({1,2.12})do
 local size=math.floor(24*scale);local bb=BB.new(100,100,BB.TYPE_BB8)
 bb:fill(BB.COLOR_WHITE);A.icon(bb,'plus',50,50,size,BB.COLOR_BLACK,math.max(1,math.floor(2*scale)))
 for x=math.ceil(50-size*.30),math.floor(50+size*.30)do assert(bb:getPixel(x,50):getColor8().a<100,'Broken horizontal icon stroke')end
 for y=math.ceil(50-size*.30),math.floor(50+size*.30)do assert(bb:getPixel(50,y):getColor8().a<100,'Broken vertical icon stroke')end
 bb:free()
end
-- Close uses exactly the same pad and border as its neighboring plus control.
do
 local a={s=function(_,n)return n end};local close=BB.new(60,60,BB.TYPE_BB8);local plus=BB.new(60,60,BB.TYPE_BB8)
 close:fill(BB.COLOR_WHITE);plus:fill(BB.COLOR_WHITE)
 A.button(close,a,'×',5,5,44,44);A.button(plus,a,'+',5,5,44,44)
 for y=5,48 do for x=5,48 do if x<15 or x>38 or y<15 or y>38 then
  assert(close:getPixel(x,y):getColor8().a==plus:getPixel(x,y):getColor8().a,'Inconsistent close pad')
 end end end
 assert(close:getPixel(5,25):getColor8().a<220,'Close outline missing');close:free();plus:free()
end
local function check(widget)
 local bb=BB.new(app.w,app.h,BB.TYPE_BB8);widget:paintTo(bb,0,0);bb:free()
 for i,a in ipairs(widget.hits or {})do
  assert(a.x>=0 and a.y>=0 and a.x+a.w<=app.w and a.y+a.h<=app.h,'Offscreen '..tostring(a.id))
  for j=i+1,#widget.hits do local b=widget.hits[j]
   assert(a.x+a.w<=b.x or b.x+b.w<=a.x or a.y+a.h<=b.y or b.y+b.h<=a.y,'Overlapping controls '..tostring(a.id)..' / '..tostring(b.id))
  end
 end
end
check(app)
local search=require('discover'):new{owner=app,query='Sample',results={}};check(search)
local progress=require('download_progress'):new{owner=app};check(progress);progress:onCloseWidget()
print('PASS continuous icons at two scales and non-overlapping library, search and download controls')
