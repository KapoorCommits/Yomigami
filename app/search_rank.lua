-- SPDX-License-Identifier: AGPL-3.0-or-later
local M={}
local function norm(s)return tostring(s or ''):lower():gsub('[%p%s]+',' '):match('^%s*(.-)%s*$')end
function M.rank(items,query)
    local q=norm(query);local ranked={}
    local function score(title)
        local t=norm(title);if q=='' then return 0 end
        if t==q then return 10000 end
        if t:sub(1,#q+1)==q..' ' then return 9000 end
        if (' '..t..' '):find(' '..q..' ',1,true) then return 8000 end
        local matched,total=0,0
        for token in q:gmatch('%S+')do total=total+1;if (' '..t..' '):find(' '..token..' ',1,true)then matched=matched+1 end end
        return matched==total and 7000 or matched/math.max(1,total)*1000
    end
    for i,item in ipairs(items)do ranked[#ranked+1]={item=item,score=score(item.title),index=i}end
    table.sort(ranked,function(a,b)if a.score~=b.score then return a.score>b.score end;return a.index<b.index end)
    local result={};for _,v in ipairs(ranked)do result[#result+1]=v.item end;return result
end
return M
