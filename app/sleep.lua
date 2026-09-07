
-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Kindle powerd still controls suspend; Yomigami owns the visible sleep overlay.
local S={}
function S:setup(_,message)
    self.message=message or 'Yomigami\nResting. Your place is saved.'
    if self.app then if self.app.wifi_receiver then self.app.wifi_receiver:onClose()end;self.app:saveProgress() end
end
function S:show()
    local Device=require('device');Device.screen_saver_mode=true
    local Info=require('ui/widget/infomessage');local UI=require('ui/uimanager')
    self.widget=Info:new{text=self.message,dismissable=false}
    UI:show(self.widget);UI:setDirty('all','full')
end
function S:close()
    local UI=require('ui/uimanager');local Device=require('device')
    if self.widget then UI:close(self.widget);self.widget=nil end
    Device.screen_saver_mode=false;Device.screen_saver_lock=false
    UI:setDirty('all','full');return true
end
return S
