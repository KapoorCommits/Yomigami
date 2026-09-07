local app=...
local S=require('wifi_server');local old=S.address;S.address=function()return '127.0.0.1'end
local W=require('wifi_receive');local w=W:new{owner=app};assert(w.pid and w.url:find(w.token,1,true))
local BB=require('ffi/blitbuffer');local bb=BB.new(app.w,app.h,BB.TYPE_BB8);w:paintTo(bb);bb:writePNG(app.root..'/wifi-050.png');bb:free()
local pid=w.pid;w:onCloseWidget();assert(not w.pid and not app.wifi_receiver);S.address=old
print('PASS QR rendering, temporary server start and shutdown')
