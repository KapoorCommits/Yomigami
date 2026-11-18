-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager');local R=require('requests');local C=require('catalog');local T=require('book_transfer')
return function(App)
function App:bulkDownloads(kind,clear)
    local queue=kind=='books' and self.state.book_queue or self.state.queue
    local keep={};local count=0;local errors=0
    for _,j in ipairs(queue or {})do
        local remove=clear and (j.status=='failed' or j.status=='queued' or j.status=='waiting' or j.status=='paused' or j.status=='cancelled')
        local cancel=not clear and j.status~='complete' and j.status~='cancelled'
        if remove or cancel then
            count=count+1;j.status='cancelled' -- Invalidate in-flight callbacks before touching files.
            if kind=='books' then
                if self.book_worker==j then if j.pid then R:cancel(j.pid)end;self.book_worker=nil end
                j.pid=nil
                local part,meta=T.paths(self.root,j.id)
                for _,path in ipairs({part,meta})do
                    if require('libs/libkoreader-lfs').attributes(path) and not os.remove(path)then errors=errors+1 end
                end
            else
                if j.id then R:send(self.root,'/jobs/'..C.encode(j.id),'DELETE',nil,function(ok)
                    if not ok then self:message('A source did not confirm cancellation. Close Yomigami to stop its engine.')end
                end)end
                local path=j.partial_path
                if path and self.state.incomplete[path] and not self.state.downloads[path]
                    and path:sub(1,#self.root+19)==self.root..'/sources/downloads/' and not path:find('/../',1,true) then
                    if not require('libs/libkoreader-lfs').attributes(path) or os.remove(path)then self.state.incomplete[path]=nil
                    else errors=errors+1 end
                end
            end
        end
        if not remove then keep[#keep+1]=j end
    end
    if kind=='books' then self.state.book_queue=keep else self.state.queue=keep end
    self:save()
    if errors>0 then self:message('Queue updated, but '..errors..' partial files could not be removed.')end
    return count
end
function App:confirmBulkDownloads(kind,clear,done)
    UI:show(require('ui/widget/confirmbox'):new{
        text=clear and 'Remove failed and waiting downloads, cancelled entries and their known partial files? Completed books and active downloads are kept.'
            or 'Cancel all active and waiting downloads? Completed books are kept. PDF/EPUB partial files will be removed.',
        ok_text=clear and 'Clear failed & queued' or 'Cancel all',
        ok_callback=function()self:bulkDownloads(kind,clear);if done then done()end end})
end
function App:bookDownloadActions(done)
    self:menu('Manage book downloads',{
        {text='Cancel all downloads',callback=function()self:confirmBulkDownloads('books',false,done)end},
        {text='Clear failed & queued',callback=function()self:confirmBulkDownloads('books',true,done)end},
    })
end
end
