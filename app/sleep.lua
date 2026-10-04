
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
    local app=self.app;local cover
    if app and app.book and app.state.sleep_cover~=false then
        local ok,image=pcall(app.cover,app,app.book,app.w,app.h)
        if ok and image then cover=image:copy()end
    end
    if cover then
        local Widget=require('ui/widget/widget');local BB=require('ffi/blitbuffer')
        self.widget=Widget:new{dimen=app.dimen,image=cover}
        function self.widget:paintTo(bb)
            bb:fill(BB.COLOR_WHITE)
            bb:blitFrom(self.image,math.floor((app.w-self.image:getWidth())/2),math.floor((app.h-self.image:getHeight())/2),0,0,self.image:getWidth(),self.image:getHeight())
        end
        function self.widget:onCloseWidget()if self.image then self.image:free();self.image=nil end end
    else self.widget=Info:new{text=self.message,dismissable=false}end
    UI:show(self.widget);UI:setDirty('all','full')
end
function S:close()
    local UI=require('ui/uimanager');local Device=require('device')
    if self.widget then UI:close(self.widget);self.widget=nil end
    Device.screen_saver_mode=false;Device.screen_saver_lock=false
    UI:setDirty('all','full');return true
end
return S
