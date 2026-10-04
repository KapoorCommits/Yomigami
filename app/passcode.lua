-- SPDX-License-Identifier: AGPL-3.0-or-later
local Store=require('storage')
local sha=require('ffi/sha2')
local bit=require('bit')
local P={}
local function raw(hex)return (hex:gsub('..',function(s)return string.char(tonumber(s,16))end))end
function P.derive(pin,salt,rounds)
    local u=raw(sha.hmac(sha.sha256,pin,salt..'\0\0\0\1'));local out={u:byte(1,32)}
    for _=2,rounds do u=raw(sha.hmac(sha.sha256,pin,u));for i=1,32 do out[i]=bit.bxor(out[i],u:byte(i))end end
    for i=1,32 do out[i]=string.format('%02x',out[i])end
    return table.concat(out)
end
function P.valid(pin)return type(pin)=='string' and #pin>=4 and #pin<=8 and pin:match('^%d+$')~=nil end
function P.load(root)
    local v,e=Store.load(root..'/passcode.json',{enabled=false})
    if e then return nil,'Passcode settings could not be read. Restore passcode.json from your backup.' end
    if type(v.enabled)~='boolean' then return nil,'Invalid passcode settings.' end
    if v.enabled and (type(v.salt)~='string' or #v.salt~=32 or not v.salt:match('^%x+$') or type(v.hash)~='string' or #v.hash~=64 or not v.hash:match('^%x+$') or v.rounds~=10000 or type(v.failures)~='number' or type(v.until_time)~='number') then return nil,'Invalid passcode settings.' end
    return v
end
function P.set(root,pin)
    if not P.valid(pin)then return nil,'Use 4 to 8 digits.' end
    local f=io.open('/dev/urandom','rb');if not f then return nil,'Random generator unavailable.' end
    local bytes=f:read(16);f:close();if not bytes or #bytes~=16 then return nil,'Random generator unavailable.' end
    local salt=bytes:gsub('.',function(c)return string.format('%02x',c:byte())end)
    return Store.save(root..'/passcode.json',{enabled=true,salt=salt,rounds=10000,hash=P.derive(pin,salt,10000),failures=0,until_time=0})
end
function P.verify(root,pin)
    local v,e=P.load(root);if not v then return nil,e end
    if not v.enabled then return true end
    if os.time()<v.until_time then return nil,'Please wait '..(v.until_time-os.time())..' seconds.' end
    if not P.valid(pin)then return nil,'Use 4 to 8 digits.' end
    v.failures=v.failures+1
    if v.failures>=5 then v.until_time=os.time()+30 end
    local ok,err=Store.save(root..'/passcode.json',v);if not ok then return nil,'Could not save passcode attempts: '..tostring(err)end
    local hash=P.derive(pin,v.salt,v.rounds);local diff=0
    for i=1,64 do diff=bit.bor(diff,bit.bxor(hash:byte(i),v.hash:byte(i)))end
    if diff~=0 then return nil,'Incorrect passcode.' end
    v.failures=0;v.until_time=0
    return Store.save(root..'/passcode.json',v)
end
function P.disable(root)return Store.save(root..'/passcode.json',{enabled=false})end
return P
