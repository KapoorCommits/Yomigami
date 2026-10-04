-- SPDX-License-Identifier: AGPL-3.0-or-later
local H={}
local function norm(s)return (s:gsub('%s+',' '):gsub('^ ',''):gsub(' $',''))end
local function utf8byte(s,n)
 local i=0;for pos in s:gmatch('()[%z\1-\127\194-\244][\128-\191]*')do i=i+1;if i==n then return pos end end
 return #s+1
end
function H.selection(map,quote,start_idx,end_idx)
 local first,last
 if start_idx and end_idx then
  local a,b=utf8byte(map.text,start_idx),utf8byte(map.text,end_idx+1)-1
  if norm(map.text:sub(a,b))==norm(quote)then first,last=a,b end
 end
 if not first then
  first,last=map.text:find(quote,1,true)
  if not first or map.text:find(quote,last+1,true)then return nil end
 end
 local a,b
 for i,w in ipairs(map.words)do if w.last>=first and w.first<=last then a=a or i;b=i end end
 return a,b
end
local function join(words,a,b)local t={};for i=a,b do t[#t+1]=words[i].text end;return table.concat(t,' ')end
function H.index(doc,page)
 if doc.reflowable and doc.highlight_index then return doc.highlight_index end
 local idx={words={},pages={}}
 local first,last=page,page;if doc.reflowable then first,last=1,doc.count end
 for n=first,last do
  local map=doc:textMap(n);idx.pages[n]={start=#idx.words+1,map=map}
  for _,w in ipairs(map.words)do idx.words[#idx.words+1]={text=w.text,page=n,box=w}end
 end
 if doc.reflowable then doc.highlight_index=idx end
 return idx
end
function H.capture(doc,page,quote,start_idx,end_idx)
 local idx=H.index(doc,page);local info=idx.pages[page]
 local a,b=H.selection(info.map,quote,start_idx,end_idx);if not a then return nil end
 a=a+info.start-1;b=b+info.start-1
 return {version=1,first=a,last=b,text=join(idx.words,a,b),before=join(idx.words,math.max(1,a-8),a-1),after=join(idx.words,b+1,math.min(#idx.words,b+8)),page=page,reflowable=doc.reflowable}
end
function H.resolve(idx,anchor)
 if not anchor or anchor.version~=1 then return end
 local length=anchor.last-anchor.first+1;local hits={}
 for a=1,#idx.words-length+1 do
  local b=a+length-1
  if idx.words[a].text==anchor.text:match('^%S+') and join(idx.words,a,b)==anchor.text
   and join(idx.words,math.max(1,a-8),a-1)==anchor.before
   and join(idx.words,b+1,math.min(#idx.words,b+8))==anchor.after then hits[#hits+1]={a,b}end
 end
 if #hits==1 then return hits[1][1],hits[1][2]end
 -- Ambiguous passages are intentionally not shaded on a potentially wrong location.
end
function H.boxes(doc,page,entries)
 local relevant={};for _,e in ipairs(entries)do if e.anchor and (doc.reflowable or e.anchor.page==page)then relevant[#relevant+1]=e end end
 if #relevant==0 then return {}end
 local idx=H.index(doc,page);local out={};local seen={}
 for _,e in ipairs(relevant)do
  local a,b=H.resolve(idx,e.anchor)
  if a then for i=a,b do local w=idx.words[i];if w.page==page and not seen[i]then out[#out+1]=w.box;seen[i]=true end end end
 end
 return out
end
return H
