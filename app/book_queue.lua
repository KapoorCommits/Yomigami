-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager');local R=require('requests');local Store=require('storage');local T=require('book_transfer')
return function(App)
function App:startBookDownloads()
    self.state.book_queue=self.state.book_queue or {}
    for _,j in ipairs(self.state.book_queue)do if j.status=='active' then j.status='queued';j.next_try=0 end end
    self.book_download_tick=function()if self.book_download_stopped then return end;self:pumpBookDownloads();UI:scheduleIn(1,self.book_download_tick)end
    if not os.getenv('YOMIGAMI_TEST') then UI:scheduleIn(1,self.book_download_tick)end
end
function App:stopBookDownloads()
    self.book_download_stopped=true;if self.book_download_tick then UI:unschedule(self.book_download_tick)end
    for _,j in ipairs(self.state.book_queue or {})do if j.status=='active' then j.status='queued';j.next_try=0 end end
    self:save()
end
function App:queueBook(book,info)
    local key=(book.source or '')..':'..tostring(book.url or book.id)
    for _,j in ipairs(self.state.book_queue)do if j.key==key and j.status~='cancelled' and j.status~='complete' then return self:bookDownloadsMenu()end end
    self.state.book_job_counter=(self.state.book_job_counter or 0)+1
    self.state.book_queue[#self.state.book_queue+1]={id='book-'..self.state.book_job_counter,key=key,book=book,status='queued',total=info and info.total,attempts=0}
    self:save();self:bookDownloadsMenu();self:pumpBookDownloads()
end
function App:pumpBookDownloads()
    if self.book_worker or self.state_error or self.book_download_stopped then return end
    for _,j in ipairs(self.state.book_queue)do
        if (j.status=='queued' or j.status=='waiting') and (j.next_try or 0)<=os.time() then
            self.book_worker=j;j.status='active';j.attempts=(j.attempts or 0)+1;self:save()
            j.pid=R:send(self.root,'@books/transfer','POST',{root=self.root,job=j},function(ok,result)
                self.book_worker=nil;j.pid=nil
                if self.book_download_stopped then return end
                if ok then j.status='complete';j.path=result.path;j.total=result.total;j.error=nil;self:scan()
                else j.error=tostring(result):gsub('^.-:%d+: ','');local retry=j.error:find('Connection') or j.error:find('Transfer interrupted') or j.error:find('HTTP 5') or j.error:find('rate limit') or j.error:find('timed out');j.status=retry and j.attempts<6 and 'waiting' or 'failed';j.next_try=os.time()+math.min(300,15*2^(j.attempts-1))end
                self:save()
            end)
            return
        end
    end
end
function App:pauseBookDownload(j,cancel)
    if self.book_worker==j then R:cancel(j.pid);self.book_worker=nil end
    j.pid=nil;j.status=cancel and 'cancelled' or 'paused'
    if cancel then local part,meta=T.paths(self.root,j.id);os.remove(part);os.remove(meta)end
    self:save()
end
function App:bookDownloadsMenu()UI:show(require('transfer_list'):new{owner=self})end
end
