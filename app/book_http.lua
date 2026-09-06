-- SPDX-License-Identifier: AGPL-3.0-or-later
local H={}
function H.matches(host,name)
    host=host:lower();name=name:lower()
    if host==name then return true end
    if name:sub(1,2)=='*.' then
        local suffix=name:sub(2)
        return host:sub(-#suffix)==suffix and host:sub(1,-#suffix-1):match('^[^.]+$')~=nil
    end
    return false
end
function H.request(options)
    local https=require('ssl.https');https.TIMEOUT=45
    options.create=function()
        local conn=https.tcp(options)();local connect=conn.connect
        function conn:connect(host,port)
            local result=connect(self,host,port)
            local cert=self.sock:getpeercertificate()
            local ext=cert and cert:extensions();local san=ext and ext['2.5.29.17']
            local valid=false
            for _,name in ipairs(san and san.dNSName or {})do if H.matches(host,name)then valid=true;break end end
            if not valid then self:close();error('Server certificate does not match its address.')end
            return result
        end
        return conn
    end
    return require('socket.http').request(options)
end
return H
