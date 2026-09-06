-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager')
local BB=require('ffi/blitbuffer')
local Gesture=require('ui/gesturerange')
local C=require('catalog')
local P=require('chapters'):extend{}
function P:init()
    self.dimen=self.owner.dimen;self.hits={}
    self.ges_events={Tap={Gesture:new{ges='tap',range=self.dimen}}};self.key_events={Close={{'Back'},{'Esc'}}}
    self.tick=function()
        if self.closed then return end
        local c=self:stats();local key=table.concat({math.floor(c.ratio*100),c.total,c.complete,c.active,c.failed,tostring(self.owner.state.queue_paused)},':')
        if key~=self.last_stats then
            self.last_stats=key
            UI:setDirty(self,'fast',require('ui/geometry'):new{x=0,y=self.owner:s(250),w=self.owner.w,h=self.owner:s(260)})
        end
        UI:scheduleIn(2,self.tick)
    end
    UI:scheduleIn(1,self.tick)
end
function P:onCloseWidget()self.closed=true;UI:unschedule(self.tick)end
function P:onClose()self:onCloseWidget();UI:close(self);self.owner:refresh();return true end
function P:stats()
    local c={total=0,complete=0,active=0,failed=0,fraction=0}
    for _,j in ipairs(self.owner.state.queue)do
        if j.status~='cancelled' and (not self.series_key or C.seriesKey(j.manga)==self.series_key)then
            c.total=c.total+1
            if j.status=='complete'then c.complete=c.complete+1;c.fraction=c.fraction+1
            elseif j.status=='active'then
                c.active=c.active+1;local data=j.progress and j.progress.data
                if type(data)=='table' and type(data.processed)=='number' and type(data.total)=='number' and data.total>0 then c.fraction=c.fraction+math.min(.99,data.processed/data.total)end
            elseif j.status=='failed'then c.failed=c.failed+1 end
        end
    end
    c.ratio=c.total>0 and c.fraction/c.total or 0;return c
end
function P:paintTo(bb)
    local a=self.owner;local s=function(n)return a:s(n)end;local p=s(28);local width=a.w-p*2;local c=self:stats()
    self.hits={};bb:paintRect(0,0,a.w,a.h,BB.COLOR_WHITE)
    a:label(bb,'Your downloads',p,s(34),28,true,width)
    a:centerLabel(bb,self.title or 'Building your offline library',p,s(155),width,s(65),22,true)
    a:centerLabel(bb,math.floor(c.ratio*100)..'%',p,s(256),width,s(90),54,true)
    bb:paintRect(p,s(367),width,s(13),BB.Color8(223));bb:paintRect(p,s(367),math.floor(width*c.ratio),s(13),BB.COLOR_BLACK)
    a:centerLabel(bb,c.complete..' of '..c.total..' chapters ready',p,s(408),width,s(35),17,true)
    a:centerLabel(bb,c.failed>0 and (c.failed..' need retry') or c.total>0 and c.complete==c.total and 'Your library is ready.' or a.state.queue_paused and 'Paused' or c.total==0 and 'No downloads in the queue.' or (c.active..' downloading · You can keep reading'),p,s(455),width,s(32),13,false)
    self:button(bb,'background',c.total>0 and c.complete==c.total and 'Done' or 'Run in background',p,s(538),width,s(48),function()self:onClose()end,true)
    self:button(bb,'pause',a.state.queue_paused and 'Resume downloads' or 'Pause new downloads',p,s(605),width,s(44),function()a.state.queue_paused=not a.state.queue_paused;a:save();UI:setDirty(self,'partial')end)
    self:button(bb,'details','Manage queue / Retry / Cancel',p,s(667),width,s(44),function()self:onClose();a:manageDownloads()end)
end
return P
