-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager');local BB=require('ffi/blitbuffer');local lfs=require('libs/libkoreader-lfs');local T=require('book_transfer')
local V=require('discover'):extend{}
local function size(path,depth)
    if (depth or 0)>12 then return 0 end
    local attr=lfs.symlinkattributes(path);if not attr then return 0 end
    if attr.mode=='file' then return attr.size end
    if attr.mode~='directory' then return 0 end
    local n=0;for name in lfs.dir(path)do if name~='.' and name~='..' then n=n+size(path..'/'..name,(depth or 0)+1)end end;return n
end
function V:init()
    require('discover').init(self);self.rows={};self.library_bytes=0
    for _,b in ipairs(self.owner.books)do
        local n=0;for _,c in ipairs(b.chapters or {b})do n=n+size(c.path)end
        self.rows[#self.rows+1]={book=b,bytes=n};self.library_bytes=self.library_bytes+n
    end
    table.sort(self.rows,function(a,b)return a.bytes>b.bytes end)
    self.per=math.max(1,math.floor((self.owner.h-self.owner:s(340))/self.owner:s(72)))
    self.partial=size(self.owner.root..'/.book-transfers');self.trash=size(self.owner.root..'/.trash')
end
function V:onNext()self.page=math.min(math.max(1,math.ceil(#self.rows/self.per)),self.page+1);UI:setDirty(self,'partial');return true end
function V:paintTo(bb)
    local a=self.owner;local s=function(n)return a:s(n)end;local p=s(28);local w=a.w-2*p;self.hits={};bb:fill(BB.COLOR_WHITE)
    a:label(bb,'Your storage',p,s(32),28,true,w-s(60));self:button(bb,'close','×',a.w-p-s(46),s(26),s(46),s(42),function()self:onClose()end)
    a:centerLabel(bb,T.format(T.free(a.root))..' free',p,s(98),w,s(45),24,true)
    a:centerLabel(bb,'Books '..T.format(self.library_bytes)..' · Downloads '..T.format(self.partial)..' · Trash '..T.format(self.trash),p,s(152),w,s(32),11,false)
    a:label(bb,'Largest first · Tap a book for actions',p,s(208),12,false,w)
    for slot=1,self.per do local row=self.rows[(self.page-1)*self.per+slot]
        if row then local y=s(247)+(slot-1)*s(72);local b=row.book
            bb:paintRect(p,y,w,s(62),BB.Color8(246));a:centerLabel(bb,b.title,p,y+s(3),w,s(28),15,true)
            a:centerLabel(bb,T.format(row.bytes)..' · '..(b.chapters and #b.chapters..' chapters' or b.format),p,y+s(32),w,s(24),11,false)
            self:hit('storage-'..slot,p,y,w,s(62),function()self:onClose();a:bookActions(b)end)
        end
    end
    self:button(bb,'previous','‹',p,a.h-s(65),s(48),s(40),function()self:onPrevious()end)
    a:centerLabel(bb,self.page..' / '..math.max(1,math.ceil(#self.rows/self.per)),p+s(60),a.h-s(65),w-s(120),s(40),13,false)
    self:button(bb,'next','›',a.w-p-s(48),a.h-s(65),s(48),s(40),function()self:onNext()end)
end
return function(App)function App:showStorage()UI:show(V:new{owner=self})end end
