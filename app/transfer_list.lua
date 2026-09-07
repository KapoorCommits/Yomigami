-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager');local BB=require('ffi/blitbuffer');local T=require('book_transfer');local Store=require('storage')
local V=require('discover'):extend{}
function V:init()
    self.per=6;self.page=1;require('discover').init(self)
    self.tick=function()if self.closed then return end
        local key={};for _,j in ipairs(self.owner.state.book_queue)do local _,p=T.paths(self.owner.root,j.id);local m=Store.load(p,{});key[#key+1]=j.status..':'..math.floor((m.bytes or 0)/1048576)..':'..tostring(m.total)end
        key=table.concat(key,'|');if key~=self.previous then self.previous=key;if UI:getTopmostVisibleWidget()==self then UI:setDirty(self,'fast')endend;UI:scheduleIn(2,self.tick)
    end;UI:scheduleIn(2,self.tick)
end
function V:onCloseWidget()self.closed=true;UI:unschedule(self.tick)end
function V:onClose()self:onCloseWidget();UI:close(self);self.owner:refresh();return true end
function V:onNext()self.page=math.min(math.max(1,math.ceil(#self.owner.state.book_queue/self.per)),self.page+1);UI:setDirty(self,'partial');return true end
function V:paintTo(bb)
    local a=self.owner;local s=function(n)return a:s(n)end;local p=s(28);local w=a.w-2*p;self.hits={};bb:fill(BB.COLOR_WHITE)
    a:label(bb,'Book downloads',p,s(32),26,true,w-s(60));self:button(bb,'close','×',a.w-p-s(46),s(26),s(46),s(42),function()self:onClose()end)
    a:label(bb,T.format(T.free(a.root))..' free · Partial files survive restarts',p,s(92),12,false,w)
    if #a.state.book_queue==0 then a:centerLabel(bb,'Your next book starts in PDFs.',p,s(210),w,s(60),18,false)end
    for slot=1,self.per do local j=a.state.book_queue[(self.page-1)*self.per+slot]
        if j then local y=s(155)+(slot-1)*s(76);local _,mp=T.paths(a.root,j.id);local m=Store.load(mp,{});local total=m.total or j.total;local bytes=j.status=='complete' and total or m.bytes or 0
            bb:paintRect(p,y,w,s(67),BB.Color8(246));a:centerLabel(bb,j.book.title,p,y+s(3),w,s(29),16,true)
            local label=j.status..' · '..T.format(bytes)..' / '..T.format(total)
            a:centerLabel(bb,label,p,y+s(33),w,s(24),11,false)
            if total and total>0 then bb:paintRect(p,y+s(64),w,s(2),BB.Color8(210));bb:paintRect(p,y+s(64),math.floor(w*math.min(1,bytes/total)),s(2),BB.COLOR_BLACK)end
            self:hit('job-'..j.id,p,y,w,s(67),function()
                local entries={{text=(j.error or 'Downloaded bytes are kept until the book is complete.'),callback=function()end}}
                if j.status~='complete' then
                    if j.status~='active' then entries[#entries+1]={text='Resume / Retry',callback=function()j.status='queued';j.next_try=0;j.attempts=0;a:save();a:pumpBookDownloads()end}end
                    entries[#entries+1]={text=j.status=='paused' and 'Keep paused' or 'Pause',callback=function()a:pauseBookDownload(j)end}
                    entries[#entries+1]={text='Cancel and remove partial file',callback=function()a:pauseBookDownload(j,true)end}
                end
                a:menu(j.book.title,entries)
            end)
        end
    end
    self:button(bb,'previous','‹',p,a.h-s(65),s(48),s(40),function()self:onPrevious()end)
    a:centerLabel(bb,tostring(self.page),p+s(60),a.h-s(65),w-s(120),s(40),13,false)
    self:button(bb,'next','›',a.w-p-s(48),a.h-s(65),s(48),s(40),function()self:onNext()end)
end
return V
