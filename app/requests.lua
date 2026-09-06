-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager')
local util=require('ffi/util')
local Store=require('storage')
local Catalog=require('catalog')
local R={active={},counter=0}
function R:send(root,path,method,body,callback)
    self.counter=self.counter+1
    local file=root..'/.request-'..self.counter..'.json';os.remove(file)
    local pid=util.runInSubProcess(function()
        local ok,data=pcall(Catalog.request,path,method,body)
        Store.save(file,{ok=ok,data=ok and data or tostring(data)})
    end)
    if not pid then return callback(false,'Could not start source request.') end
    local job={pid=pid,file=file,started=os.time(),timeout=path=='@books/download' and 1200 or 95};self.active[pid]=job
    local function poll()
        if not self.active[pid] then return end
        if util.isSubProcessDone(pid) then
            self.active[pid]=nil
            local result=Store.load(file,{ok=false,data='Source request ended unexpectedly.'});os.remove(file)
            callback(result.ok,result.data)
        elseif os.time()-job.started>job.timeout then
            util.terminateSubProcess(pid);util.isSubProcessDone(pid,true);self.active[pid]=nil;os.remove(file)
            callback(false,'Source request timed out. Please try another source.')
        else UI:scheduleIn(.2,poll) end
    end
    UI:scheduleIn(.1,poll)
end
function R:close()
    for pid,job in pairs(self.active) do util.terminateSubProcess(pid);util.isSubProcessDone(pid,true);os.remove(job.file) end
    self.active={}
end
return R
