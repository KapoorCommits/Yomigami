-- SPDX-License-Identifier: AGPL-3.0-or-later
local P={}
function P.at(map,x,y)
    local lines={};local order={}
    for _,w in ipairs(map.words)do
        local id=w.line or w.y0
        local line=lines[id]
        if not line then line={x0=w.x0,y0=w.y0,x1=w.x1,y1=w.y1,first=w.first,last=w.last};lines[id]=line;order[#order+1]=line
        else line.x0=math.min(line.x0,w.x0);line.x1=math.max(line.x1,w.x1);line.y0=math.min(line.y0,w.y0);line.y1=math.max(line.y1,w.y1);line.last=w.last end
    end
    local hit
    for i,line in ipairs(order)do if x>=line.x0 and x<=line.x1 and y>=line.y0 and y<=line.y1 then hit=i;break end end
    if not hit then return end
    local function joins(a,b)
        local h=math.max(1,a.y1-a.y0,b.y1-b.y0)
        return b.y0>a.y0 and b.y0-a.y1<h*.65 and b.x0<=a.x1 and b.x1>=a.x0
            and b.x0-a.x0<h*.7 and math.abs((b.y1-b.y0)-(a.y1-a.y0))<h*.35
    end
    local a,b=hit,hit
    while a>1 and b-a<11 and joins(order[a-1],order[a])do a=a-1 end
    while b<#order and b-a<11 and joins(order[b],order[b+1])do b=b+1 end
    local first,last=order[a].first,order[b].last
    local function chars(s)local n=0;for _ in s:gmatch('[%z\1-\127\194-\244][\128-\191]*')do n=n+1 end;return n end
    return map.text:sub(first,last),chars(map.text:sub(1,first-1))+1,chars(map.text:sub(1,last))
end
return P
