-- SPDX-License-Identifier: AGPL-3.0-or-later
local json=require('rapidjson')
local C={}
function C.encode(s) return tostring(s):gsub('([^%w%-_%.~])',function(c) return string.format('%%%02X',c:byte()) end) end
function C.request(path, method, body)
    if path=='@books/login' then return require('zlibrary').login(body.root,body.base,body.email,body.password)end
    if path=='@books/search' then return require('book_sources').search(body.source,body.query,body.page or 1,body.root) end
    if path=='@books/download' then return require('book_sources').download(body.root,body.book) end
    local http=require('socket.http')
    local ltn12=require('ltn12')
    http.TIMEOUT=75
    local parts={}
    local payload=body~=nil and json.encode(body) or ''
    local _,code=http.request{
        url='http://127.0.0.1:'..(os.getenv('YOMIGAMI_SOURCE_PORT') or '18787')..path,
        method=method or 'GET',
        headers={['content-type']='application/json',['content-length']=tostring(#payload)},
        source=ltn12.source.string(payload), sink=ltn12.sink.table(parts),
    }
    if not tonumber(code) then error('Source engine unavailable: '..tostring(code)) end
    local text=table.concat(parts)
    if tonumber(code)<200 or tonumber(code)>=300 then error('Source request failed ('..code..'): '..text:sub(1,250)) end
    if text=='' or text=='null' then return {} end
    return json.decode(text)
end
function C.sourceId(m) return m.source_id or (m.source and m.source.id) end
function C.mangaPath(m) return '/mangas/'..C.encode(assert(C.sourceId(m),'Missing source ID'))..'/'..C.encode(m.id) end
function C.seriesKey(m) return C.sourceId(m)..':'..m.id end
return C
