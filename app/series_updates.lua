-- SPDX-License-Identifier: AGPL-3.0-or-later
local C=require('catalog');local R=require('requests');local UI=require('ui/uimanager')
return function(App)
function App:toggleFollow(m)
    local key=C.seriesKey(m);local meta=self.state.series[key] or {};self.state.series[key]=meta
    meta.manga=m;meta.title=m.title;meta.followed=not meta.followed
    self:save();self:message(meta.followed and 'Following. Check updates from Library → +.' or 'Series unfollowed.')
end
function App:checkSeriesUpdate(meta,done)
    local path=C.mangaPath(meta.manga)
    R:send(self.root,path..'/refresh-chapters','POST',1,function(ok,error)
        if not ok then meta.update_error=tostring(error);self:save();return done()end
        R:send(self.root,path..'/chapters',nil,nil,function(success,chapters)
            if not success or type(chapters)~='table' then meta.update_error=tostring(chapters);self:save();return done()end
            local offline={};local key=C.seriesKey(meta.manga)
            for file,info in pairs(self.state.downloads)do if info.series_key==key and require('libs/libkoreader-lfs').attributes(file) then offline[tostring(info.chapter_id)]=true end end
            for _,job in ipairs(self.state.queue)do if C.seriesKey(job.manga)==key and (job.status=='queued' or job.status=='active') then offline[tostring(job.chapter.id)]=true end end
            meta.available={};for _,chapter in ipairs(chapters)do if chapter.id and not offline[tostring(chapter.id)]then meta.available[#meta.available+1]=chapter end end
            table.sort(meta.available,function(a,b)return require('storage').natural(a.title or tostring(a.id),b.title or tostring(b.id))end)
            meta.checked=os.time();meta.update_error=nil;self:save();done()
        end)
    end)
end
function App:checkFollowedUpdates()
    if self.series_check_busy then return self:message('Series update check is already running.')end
    local followed={};for _,meta in pairs(self.state.series)do if meta.followed and meta.manga then followed[#followed+1]=meta end end
    self.series_check_busy=true
    local i=0;local function nextSeries()
        i=i+1;if not followed[i]then self.series_check_busy=false;self:followedSeries();return end
        self:checkSeriesUpdate(followed[i],nextSeries)
    end
    nextSeries()
end
function App:followedSeries()
    local items={{text=self.series_check_busy and 'Checking sources…' or 'Check all followed series now',callback=function()self:checkFollowedUpdates()end}}
    local count=0
    for _,meta in pairs(self.state.series)do if meta.manga then local m=meta;count=count+1
        items[#items+1]={text=(m.followed and 'Following · ' or 'Not followed · ')..m.title..(m.update_error and ' · Check failed' or ' · '..#(m.available or {})..' available'),callback=function()
            local choices={
                {text=m.followed and 'Unfollow' or 'Follow series',callback=function()self:toggleFollow(m.manga)end},
                {text='Check this series',callback=function()self:checkSeriesUpdate(m,function()self:followedSeries()end)end},
                {text='Choose from all chapters',callback=function()self:mangaDetails(m.manga)end},
            }
            if m.update_error then choices[#choices+1]={text='Show source error',callback=function()self:message(m.update_error)end}end
            if #(m.available or {})>0 then
                choices[#choices+1]={text='Download all '..#m.available..' missing chapters',callback=function()self:downloadAll(m.manga,m.available)end}
                for _,c in ipairs(m.available)do local chapter=c;choices[#choices+1]={text='Download · '..(chapter.title or tostring(chapter.id)),callback=function()self:download(m.manga,chapter)end}end
            end
            self:menu(m.title,choices)
        end}
    end end
    if count==0 then items[#items+1]={text='Search Mangas, open a series, then tap Follow.'}end
    self:menu('Series updates',items)
end
end
