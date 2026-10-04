local app=...
local S=require('wifi_server');local socket=require('socket')
local server=assert(socket.bind('127.0.0.1',18789));server:settimeout(20)
print('WIFI_TEST_READY')
for i=1,7 do local c=assert(server:accept());S.handle(c,app.root,'test-session','127.0.0.1:18789')end
server:close();print('PASS Wi-Fi request loop')
