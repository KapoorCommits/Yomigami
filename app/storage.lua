-- SPDX-License-Identifier: AGPL-3.0-or-later
local json = require('rapidjson')
local lfs = require('libs/libkoreader-lfs')
local S = {}
function S.load(path, fallback)
    local f = io.open(path, 'rb')
    if not f then return fallback end
    local data = f:read('*a'); f:close()
    local ok, value = pcall(json.decode, data)
    if not ok or type(value) ~= 'table' then
        return fallback, 'Could not read '..path..'. Original file preserved.'
    end
    return value
end
function S.save(path, value)
    local tmp = path..'.tmp'
    local f, err = io.open(tmp, 'wb'); if not f then return nil, err end
    local ok, msg = f:write(json.encode(value))
    local closed, close_err = f:close()
    if not ok or not closed then os.remove(tmp); return nil, msg or close_err end
    return os.rename(tmp, path)
end
function S.natural(a, b)
    local function key(s)
        return s:lower():gsub('%d+', function(n) return string.format('%012d', tonumber(n)) end)
    end
    return key(a) < key(b)
end
function S.scan(dir, results, depth)
    results, depth = results or {}, depth or 0
    if depth > 12 or lfs.attributes(dir, 'mode') ~= 'directory' then return results end
    for name in lfs.dir(dir) do
        if name:sub(1,1) ~= '.' then
            local path = dir..'/'..name
            local mode = lfs.symlinkattributes(path, 'mode')
            if mode == 'directory' then S.scan(path, results, depth+1)
            elseif mode == 'file' then
                local ext = name:match('%.([^%.]+)$')
                ext = ext and ext:lower()
                if ext == 'pdf' or ext == 'cbz' or ext == 'epub' then
                    results[#results+1] = {path=path, title=name:gsub('%.[^.]+$', ''), format=ext:upper()}
                end
            end
        end
    end
    table.sort(results, function(a,b) return S.natural(a.path,b.path) end)
    return results
end
-- Copy only into Yomigami. Never change a user's source file.
function S.import(source, directory)
    local name = source:match('([^/]+)$')
    if not name or not name:lower():match('%.pdf$') and not name:lower():match('%.cbz$') and not name:lower():match('%.epub$') then
        return nil, 'Choose a PDF, EPUB or CBZ file.'
    end
    local dest = directory..'/'..name
    if lfs.attributes(dest) then return nil, 'A book with this filename already exists.' end
    local input, err = io.open(source, 'rb'); if not input then return nil, err end
    local output; output,err = io.open(dest..'.part','wb')
    if not output then input:close(); return nil,err end
    while true do
        local block=input:read(65536); if not block then break end
        local ok; ok,err=output:write(block)
        if not ok then input:close(); output:close(); os.remove(dest..'.part'); return nil,err end
    end
    input:close()
    local ok; ok,err=output:close()
    if not ok then os.remove(dest..'.part'); return nil,err end
    ok,err=os.rename(dest..'.part',dest)
    if not ok then return nil,err end
    return dest
end
return S
