-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Protocol: https://annas-archive.gl/dyn/api/fast_download.json
local A={base='https://annas-archive.gl'}
local Store=require('storage');local E=require('catalog').encode
function A.md5(value)
    value=tostring(value or ''):match('^%s*(.-)%s*$')
    local hash=value:match('^https://annas%-archive%.gl/md5/(%x+)$') or value:match('^https://annas%-archive%.gl/md5/(%x+)[/?#]') or value:match('^(%x+)$')
    assert(hash and #hash==32,'Enter an Anna’s Archive .gl book link or its 32-character MD5.')
    return hash:lower()
end
function A.searchURL(query)return A.base..'/search?q='..E(query)end
function A.setKey(root,key)
    assert(type(key)=='string' and key:match('^[%w_-]+$'),'Enter your membership secret key without spaces.')
    assert(Store.save(root..'/annas-session.json',{key=key}),'Could not save membership key.')
end
function A.resolve(root,book)
    local session=Store.load(root..'/annas-session.json',{})
    assert(type(session.key)=='string' and session.key:match('^[%w_-]+$'),'Set your Anna’s Archive membership key, or use Search on phone / computer and import the file.')
    local parts={};local _,code=require('book_http').request{
        url=A.base..'/dyn/api/fast_download.json?md5='..A.md5(book.id)..'&key='..E(session.key),
        redirect=false,verify='peer',cafile='data/ca-bundle.crt',headers={accept='application/json'},
        sink=require('ltn12').sink.table(parts)}
    local ok,data=pcall(require('rapidjson').decode,table.concat(parts))
    assert((tonumber(code)==200 or tonumber(code)==204) and ok and type(data)=='table' and type(data.download_url)=='string',
        'Anna’s Archive could not provide a download. Check membership, key and quota, or use browser download and Wi-Fi import.')
    assert(data.download_url:match('^https://[^/@]+/'),'Anna’s Archive returned no secure download URL.')
    return data.download_url
end
return A
