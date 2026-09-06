local app=...
local UI=require('ui/uimanager');local R=require('requests')
local done=false
R:send(app.root,'/installed-sources',nil,nil,function(ok,data)
 assert(ok,tostring(data));assert(#data>=10);done=true;UI:quit()
end)
UI:scheduleIn(10,function()assert(done,'Async request failed to complete');UI:quit()end)
UI:run();assert(done);assert(not next(R.active));print('PASS live source request runs in subprocess and returns through UI event loop')
