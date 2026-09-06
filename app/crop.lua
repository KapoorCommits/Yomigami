-- SPDX-License-Identifier: AGPL-3.0-or-later
local C={}
function C.bounds(bb)
    local w,h=bb:getWidth(),bb:getHeight();local x0,y0,x1,y1=w,h,-1,-1
    for y=0,h-1 do for x=0,w-1 do
        if bb:getPixel(x,y):getColor8().a<246 then
            x0=math.min(x0,x);y0=math.min(y0,y);x1=math.max(x1,x);y1=math.max(y1,y)
        end
    end end
    if x1<0 then return {x=0,y=0,w=1,h=1} end
    local px=math.max(2,math.ceil(w*.015));local py=math.max(2,math.ceil(h*.015))
    x0=math.max(0,math.min(math.floor(w*.2),x0-px));y0=math.max(0,math.min(math.floor(h*.2),y0-py))
    x1=math.min(w,math.max(math.ceil(w*.8),x1+px+1));y1=math.min(h,math.max(math.ceil(h*.8),y1+py+1))
    return {x=x0/w,y=y0/h,w=(x1-x0)/w,h=(y1-y0)/h}
end
return C
