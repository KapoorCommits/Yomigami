-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager')
local C=require('catalog')
local R=require('requests')
local lfs=require('libs/libkoreader-lfs')
return function(App)
function App:startDownloads()
    self.state.queue=self.state.queue or {}
    -- A new launcher starts a new engine. Re-submit interrupted jobs; the engine reuses cached pages.
    for _,job in ipairs(self.state.queue) do if job.status=='active' then job.status='queued';job.id=nil end end
    self.download_tick=function()
        if self.download_stopped then return end
        self:pumpDownloads();UI:scheduleIn(.2,self.download_tick)
    end
    if not os.getenv('YOMIGAMI_TEST') then UI:scheduleIn(.2,self.download_tick) end
end
function App:stopDownloads()
    self.download_stopped=true
    if self.download_tick then UI:unschedule(self.download_tick) end
    self:save()
end
function App:download(m,c)
    self:enqueueChapters(m,{c});self:message('Chapter queued. You can continue reading.')
end
function App:downloadAll(m,chapters)
    UI:show(require('ui/widget/confirmbox'):new{text='Queue '..#chapters..' chapters of '..m.title..'? Existing complete chapters will be skipped. Downloads continue while Yomigami is open and resume next time.',ok_text='Download all',ok_callback=function()
        local n=self:enqueueChapters(m,chapters);self:downloadsMenu(C.seriesKey(m),m.title)
    end})
end
function App:enqueueChapters(m,chapters)
    local known={}
    for _,job in ipairs(self.state.queue) do if job.status~='cancelled' then known[job.key]=job end end
    local key=C.seriesKey(m);local meta=self.state.series[key] or {};meta.title=m.title;meta.manga=m;self.state.series[key]=meta
    local offline={}
    for path,info in pairs(self.state.downloads) do if info.chapter_id and lfs.attributes(path) then offline[info.series_key..':'..info.chapter_id]=true end end
    local count=0
    for _,c in ipairs(chapters) do
        local id=key..':'..c.id;local old=known[id]
        if not offline[id] and (not old or old.status=='failed' or old.status=='complete' and (not old.path or not lfs.attributes(old.path))) then
            if old then old.status='cancelled' end
            self.state.queue[#self.state.queue+1]={key=id,manga=m,chapter=c,title=m.title..' / '..(c.title or c.id),status='queued'}
            known[id]=self.state.queue[#self.state.queue];count=count+1
        end
    end
    self:save();return count
end
function App:pumpDownloads()
    if self.queue_busy or self.state_error then return end
    local active=0;local poll
    for _,job in ipairs(self.state.queue) do if job.status=='active' then active=active+1;if not poll or (job.polled or 0)<(poll.polled or 0) then poll=job end end end
    local pending
    if active<3 and not self.state.queue_paused then for _,job in ipairs(self.state.queue) do if job.status=='queued' then pending=job;break end end end
    if pending then
        local free=require('disk_space').free(self.root)
        if not free or free<512*1024*1024 then
            self.state.queue_paused=true;self:save();self:message('Downloads paused: less than 512 MB free. Free space, then resume Downloads.')
            pending=nil
        end
    end
    local job=pending or poll;if not job then return end
    self.queue_busy=true
    local path,method,body
    if pending then
        path='/jobs/download-chapter';method='POST';body={source_id=C.sourceId(job.manga),manga_id=job.manga.id,chapter_id=job.chapter.id}
    else path='/jobs/'..C.encode(job.id);job.polled=os.time() end
    R:send(self.root,path,method,body,function(ok,result)
        self.queue_busy=false
        if job.status=='cancelled' then
            if pending and ok then R:send(self.root,'/jobs/'..C.encode(result),'DELETE',nil,function()end) end
            return
        end
        if not ok then
            job.status='failed';job.error=tostring(result)
        elseif pending then job.id=result;job.status='active'
        elseif result.type=='COMPLETED' then
            local data=result.data;local file=type(data)=='table' and data[1];local errors=type(data)=='table' and data[2]
            if type(file)~='string' or type(errors)=='table' and #errors>0 then job.status='failed';job.error='Some pages did not download. Retry this chapter.'
                if type(file)=='string' then self.state.incomplete[file]=true end
            else
                job.status='complete';job.path=file;self.state.incomplete[file]=nil
                self.state.downloads[file]={title=job.chapter.title or job.chapter.id,series_key=C.seriesKey(job.manga),chapter_num=job.chapter.chapter_number or job.chapter.chapter_num,chapter_id=job.chapter.id}
                self:scan()
            end
        elseif result.type=='ERROR' then job.status='failed';job.error=require('rapidjson').encode(result.data)
        else job.progress=result end
        self:save()
        if pending or result and result.type=='COMPLETED' then UI:scheduleIn(.01,function()if not self.download_stopped then self:pumpDownloads()end end)end
    end)
end
function App:cancelDownload(job)
    job.status='cancelled';self:save()
    if job.id then R:send(self.root,'/jobs/'..C.encode(job.id),'DELETE',nil,function()end) end
end
function App:manageDownloads()
    local counts={queued=0,active=0,complete=0,failed=0}
    for _,j in ipairs(self.state.queue) do if counts[j.status] then counts[j.status]=counts[j.status]+1 end end
    local items={
        {text=counts.queued..' waiting / '..counts.active..' downloading / '..counts.complete..' complete'},
        {text=self.state.queue_paused and 'Resume queue' or 'Pause new downloads',callback=function()self.state.queue_paused=not self.state.queue_paused;self:save()end},
        {text='Refresh',callback=function()self:manageDownloads()end},
        {text='Retry failed chapters ('..counts.failed..')',callback=function()for _,j in ipairs(self.state.queue) do if j.status=='failed' then j.status='queued';j.id=nil;j.error=nil end end;self:save()end},
    }
    for _,j in ipairs(self.state.queue) do
        local job=j
        if job.status~='cancelled' and job.status~='complete' then items[#items+1]={text=job.status..' / '..job.title,callback=function()
            self:menu(job.title,{{text=job.error or job.status},{text='Cancel download',callback=function()self:cancelDownload(job)end}})
        end} end
    end
    self:menu('Downloads',items)
end
function App:downloadsMenu(key,title) UI:show(require('download_progress'):new{owner=self,series_key=key,title=title}) end
function App:pollDownloads() self:pumpDownloads();self:downloadsMenu() end
end
