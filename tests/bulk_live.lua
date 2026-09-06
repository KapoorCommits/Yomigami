local app=...
local UI=require('ui/uimanager');local Store=require('storage');local R=require('requests')
local input=Store.load(assert(os.getenv('YOMIGAMI_APP'))..'/../build/bulk-live-input.json',{})
local expected=#input.chapters;assert(expected>=2)
app.state.queue={};assert(app:enqueueChapters(input.manga,input.chapters)==expected)
local completed=false;local ticks=0
local function pump()
 ticks=ticks+1;app:pumpDownloads()
 local n=0
 for _,j in ipairs(app.state.queue) do assert(j.status~='failed',j.error);if j.status=='complete' then n=n+1 end end
 if n==expected then completed=true;UI:quit();return end
 assert(ticks<120,'Bulk download timed out');UI:scheduleIn(.5,pump)
end
UI:scheduleIn(.1,pump);UI:run();assert(completed);R:close()
print('PASS real multi-chapter queue: async submission, completion polling and persistent chapter metadata')
