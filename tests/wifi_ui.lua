local app=...
local S=require('wifi_server');local old=S.address;S.address=function()return '127.0.0.1'end
local W=require('wifi_receive');local books=require('books'):new{owner=app}
local BB=require('ffi/blitbuffer');local canvas=BB.new(app.w,app.h,BB.TYPE_BB8);books:paintTo(canvas);canvas:writePNG(app.root..'/import-menu.png');canvas:free()
local entry;for _,hit in ipairs(books.hits)do assert(hit.y+hit.h<=app.h);if hit.id=='import' then entry=hit end end
assert(entry,'PDF import entry missing');entry.fn();assert(books.closed,'Source menu must close after receiver opens')
local w=assert(app.wifi_receiver);assert(w.pid and w.url:find(w.token,1,true))
local BB=require('ffi/blitbuffer');local bb=BB.new(app.w,app.h,BB.TYPE_BB8);w:paintTo(bb);bb:writePNG(app.root..'/wifi-050.png');bb:free()
local f=assert(io.open(app.root..'/wifi-url.txt','w'));f:write(w.url);f:close()
local pid=w.pid;w:onCloseWidget();assert(not w.pid and not app.wifi_receiver);S.address=old
print('PASS QR rendering, temporary server start and shutdown')

local F=require('wifi_firewall');local Device=require('device');local kindle=Device.isKindle;local execute=os.execute
Device.isKindle=function()return true end
local calls={};os.execute=function(cmd)calls[#calls+1]=cmd;return 0 end
local close=F.open(12345);assert(#calls==2);close();assert(#calls==4);close();assert(#calls==4)
assert(calls[1]=='iptables -I INPUT -p tcp --dport 12345 -j ACCEPT')
assert(calls[3]=='iptables -D INPUT -p tcp --dport 12345 -j ACCEPT')
calls={};os.execute=function(cmd)calls[#calls+1]=cmd;return #calls==2 and 1 or 0 end
assert(not pcall(F.open,12345));assert(#calls==3 and calls[3]:find('iptables -D INPUT',1,true))
os.execute=execute;Device.isKindle=kindle
print('PASS import entry, return flow, scoped firewall cleanup and partial failure rollback')
