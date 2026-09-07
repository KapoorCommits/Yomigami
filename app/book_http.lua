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
function H.configure(options)
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
    return options
end
function H.request(options)return require('socket.http').request(H.configure(options))end
-- Receive headers before opening a destination, so 200 can safely reset a Range retry.
function H.stream(options,onheaders,sink)
    local u=require('socket.url').parse(options.url)
    assert(u and u.scheme=='https' and u.host and not u.userinfo,'Use an HTTPS download URL.')
    local conn
    local ok,result=pcall(function()
        H.configure(options);conn=require('socket.http').open(u.host,tonumber(u.port) or 443,options.create)
        conn:sendrequestline(options.method or 'GET',(u.path or '/')..(u.query and '?'..u.query or ''))
        local headers=options.headers or {};headers.host=u.host..(u.port and ':'..u.port or '');headers.connection='close';headers['accept-encoding']='identity'
        conn:sendheaders(headers)
        local code=conn:receivestatusline();local reply=conn:receiveheaders()
        while code==100 do code=conn:receivestatusline();reply=conn:receiveheaders()end
        local body=onheaders(code,reply)
        if body and options.method~='HEAD' then conn:receivebody(reply,sink)end
        return {code=code,headers=reply}
    end)
    if conn then pcall(conn.close,conn)end
    if not ok then error(type(result)=='table' and ('Connection interrupted: '..tostring(result[1])) or result)end
    return result.code,result.headers
end
return H
