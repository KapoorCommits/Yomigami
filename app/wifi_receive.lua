-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager');local BB=require('ffi/blitbuffer');local util=require('ffi/util');local Store=require('storage')
local W=require('discover'):extend{}
function W:init()
    require('discover').init(self)
    local S=require('wifi_server');self.token=S.token();self.ip=S.address()
    assert(self.ip,'Connect the Kindle to Wi-Fi first, then open Send to Yomigami.')
    local server,err=require('socket').bind(self.ip,0);assert(server,err)
    local _,port=server:getsockname();self.host=self.ip..':'..port;self.url='http://'..self.host..'/'..self.token
    os.remove(self.owner.root..'/.wifi-status.json');os.remove(self.owner.root..'/.wifi-upload.part')
    local ok,qr=pcall(function()return require('ui/widget/qrwidget'):new{text=self.url,width=self.owner:s(250),height=self.owner:s(250)}end)
    if not ok then server:close();error('Could not create the transfer QR code.')end
    self.qr=qr
    self.pid=util.runInSubProcess(function()S.run(server,self.owner.root,self.token,self.host,self.browse_url)end)
    server:close();if not self.pid then self.qr:free();error('Could not start Wi-Fi transfer.')end
    local allowed,cleanup=pcall(require('wifi_firewall').open,port)
    if not allowed then util.terminateSubProcess(self.pid);util.isSubProcessDone(self.pid,true);self.pid=nil;self.qr:free();error(cleanup)end
    self.firewall=cleanup
    self.owner.wifi_receiver=self;self.started=os.time()
    self.tick=function()
        if self.closed then return end
        if os.time()-self.started>1800 then self:onClose();return end
        if util.isSubProcessDone(self.pid)then self.pid=nil;self:onClose();self.owner:message('Wi-Fi transfer stopped. Reopen it to try again.');return end
        local status=Store.load(self.owner.root..'/.wifi-status.json',{})
        if status.count~=self.count then self.count=status.count;UI:setDirty(self,'partial')end
        UI:scheduleIn(2,self.tick)
    end;UI:scheduleIn(2,self.tick)
end
function W:onCloseWidget()
    if self.closed then return end;self.closed=true;UI:unschedule(self.tick)
    if self.pid then util.terminateSubProcess(self.pid);util.isSubProcessDone(self.pid,true);self.pid=nil end
    if self.firewall then self.firewall();self.firewall=nil end
    if self.qr then self.qr:free();self.qr=nil end
    os.remove(self.owner.root..'/.wifi-upload.part');os.remove(self.owner.root..'/.wifi-status.json')
    self.owner.wifi_receiver=nil;self.owner:scan()
end
function W:onClose()self:onCloseWidget();UI:close(self);self.owner:refresh();return true end
function W:paintTo(bb)
    local a=self.owner;local s=function(n)return a:s(n)end;local p=s(28);local w=a.w-2*p;self.hits={};bb:fill(BB.COLOR_WHITE)
    a:label(bb,'Send to Yomigami',p,s(32),26,true,w-s(60));self:button(bb,'close','×',a.w-p-s(46),s(26),s(46),s(42),function()self:onClose()end)
    a:centerLabel(bb,self.browse_url and 'Anna’s Archive → Your library' or 'Import PDF From Anywhere',p,s(110),w,s(40),17,true)
    a:centerLabel(bb,'1. Connect both devices to the same Wi-Fi.',p,s(166),w,s(35),13,false)
    local qx=math.floor((a.w-self.qr:getSize().w)/2);local qy=s(225)
    self.qr:paintTo(bb,qx,qy)
    if require('device').screen.night_mode then bb:invertRect(qx-s(16),qy-s(16),self.qr:getSize().w+s(32),self.qr:getSize().h+s(32))end
    a:centerLabel(bb,'2. Scan the QR, or type this address in a browser.',p,s(492),w,s(25),11,false)
    a:centerLabel(bb,self.url,p,s(523),w,s(30),10,true)
    a:centerLabel(bb,(self.count or 0)..' books received · PDF / EPUB / CBZ',p,s(573),w,s(35),14,false)
    a:centerLabel(bb,self.browse_url and '3. Search, download, then send the file from that browser tab.' or '3. Choose files on your device. Keep this screen open.',p,s(631),w,s(35),11,false)
    a:centerLabel(bb,'Local HTTP · Use trusted Wi-Fi · Session expires in 30 minutes',p,s(674),w,s(30),10,false)
    self:button(bb,'stop','Done · Return to library',p,a.h-s(70),w,s(42),function()self:onClose()end,true)
end
function W.show(owner,on_ready,browse_url)
    if owner.wifi_receiver then return UI:show(owner.wifi_receiver)end
    local ok,widget=pcall(W.new,W,{owner=owner,browse_url=browse_url})
    if ok then if on_ready then on_ready()end;UI:show(widget)else owner:message(tostring(widget))end
end
return W
