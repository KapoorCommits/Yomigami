local app=...
local UI=require('ui/uimanager');local D=require('discover')
local view=D:new{owner=app,query='Sakamoto Days',autosearch=true};UI:show(view)
local phase=1;local ticks=0
local function check()
 ticks=ticks+1;assert(ticks<180,'Live discovery timed out');assert(not view.error,view.error)
 if phase==1 and view.results then
    local found;for _,m in ipairs(view.results)do if m.title=='Sakamoto Days' and m.source.id=='en.weebcentral'then found=m;break end end
    assert(found,'Expected manga missing from live multi-source results');view:onClose();view=D:new{owner=app,manga=found};UI:show(view);phase=2
 elseif phase==2 and view.chapters then assert(#view.chapters>200);view:onClose();UI:quit();print('PASS live discovery search → source selection → '..#view.chapters..' chapters');return end
 UI:scheduleIn(.5,check)
end
UI:scheduleIn(.5,check);UI:run()
