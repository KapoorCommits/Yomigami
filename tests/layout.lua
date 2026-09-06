
local app=...
local Font=require('ui/font');local BB=require('ffi/blitbuffer')
for _,size in ipairs({11,13,15,20,34}) do
    local face=Font:getFace('cfont',size)
    assert(math.abs(face.size-app:s(size))<=1,'Font scaled twice at '..app.w..' px')
end
local bb=BB.new(app.w,app.h,BB.TYPE_BB8)
local original=Font.getFace;local actual
Font.getFace=function(self,...) local face=original(self,...);actual=face.size;return face end
app:label(bb,'Scale check',0,0,13,false,app.w);Font.getFace=original
assert(math.abs(actual-app:s(13))<=1,'Application double-scaled its label font')
app:paintTo(bb,0,0);bb:writePNG(os.getenv('YOMIGAMI_HOME')..'/layout-'..app.w..'.png');bb:free()
local exit_hit
for _,h in ipairs(app.hits) do if h.x==app.w-app:s(78) then exit_hit=h end end
assert(exit_hit,'Missing exit control')
local oldquit=app.quit;local called=false;app.quit=function()called=true end
exit_hit.fn();assert(called);app.quit=oldquit
local modes={};local oldDirty=require('ui/uimanager').setDirty
require('ui/uimanager').setDirty=function(_,_,mode) modes[#modes+1]=mode end
for i=1,6 do app:refreshPage(1,'page') end
require('ui/uimanager').setDirty=oldDirty
assert(modes[1]=='partial' and modes[5]=='partial' and modes[6]=='full')
print('PASS layout '..app.w..'x'..app.h..', exit button and partial/full refresh cadence')
