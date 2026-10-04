-- SPDX-License-Identifier: AGPL-3.0-or-later
local ffi=require('ffi');require('ffi/posix_h')
local D={}
function D.free(path)
    if ffi.os=='OSX' then
        -- The older macOS emulator ships a Linux statvfs layout. Use the host utility.
        local now=os.time();if D.path==path and D.time==now then return D.value end
        local quoted="'"..path:gsub("'","'\\''").."'"
        local f=io.popen('df -Pk '..quoted..' 2>/dev/null');local value=0
        if f then for line in f:lines()do local n=line:match('^%S+%s+%d+%s+%d+%s+(%d+)');if n then value=tonumber(n)*1024 end end;f:close()end
        D.path=path;D.time=now;D.value=value;return value
    end
    local st=ffi.new('struct statvfs')
    if ffi.C.statvfs(path,st)~=0 then return 0 end
    local block=tonumber(st.f_frsize);if block==0 then block=tonumber(st.f_bsize)end
    return tonumber(st.f_bavail)*block
end
return D
