-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Protocol reference: ZlibraryKO/zlibrary.koplugin (AGPL-3.0), zlibrary/api.lua.
local json=require('rapidjson')
local Store=require('storage')
local E=require('catalog').encode
local Z={}
function Z.base(value)
    value=tostring(value or ''):gsub('/+$','')
    assert(value:match('^https://[%w%.%-]+$'),'Enter an HTTPS server address without a path.')
    return value
end
function Z.request(base,path,body,session)
    local parts={};local headers={['user-agent']='Yomigami/0.4.0',['accept']='application/json'}
    if session then headers.cookie='remix_userid='..session.id..'; remix_userkey='..session.key end
    if body then headers['content-type']='application/x-www-form-urlencoded';headers['content-length']=tostring(#body)end
    local https=require('book_http');https.TIMEOUT=45
    local _,code=https.request{url=Z.base(base)..path,method=body and 'POST' or 'GET',redirect=false,
        verify='peer',cafile='data/ca-bundle.crt',headers=headers,
        source=body and require('ltn12').source.string(body),sink=require('ltn12').sink.table(parts)}
    assert(tonumber(code)==200,'Z-Library did not accept the request. Check your server address and connection.')
    local ok,data=pcall(json.decode,table.concat(parts))
    assert(ok and type(data)=='table','This server returned a browser challenge or an invalid API response. Try your current Z-Library server.')
    assert(not data.error,'Z-Library rejected the request. Check your sign-in and account limits.')
    return data
end
function Z.session(root)
    local s=Store.load(root..'/zlibrary-session.json',{})
    assert(type(s.id)=='string' and s.id:match('^%d+$') and type(s.key)=='string' and s.key:match('^[%w%-_]+$'),'Sign in to Z-Library first.')
    Z.base(s.base);return s
end
function Z.login(root,base,email,password)
    base=Z.base(base)
    local d=Z.request(base,'/rpc.php','isModal=true&site_mode=books&action=login&gg_json_mode=1&redirectUrl='..E(base..'/')..'&email='..E(email)..'&password='..E(password))
    local s=type(d.response)=='table' and d.response or type(d.user)=='table' and d.user or {}
    local id=tostring(s.user_id or s.id or '');local key=s.user_key or s.remix_userkey
    assert(id:match('^%d+$') and type(key)=='string' and key:match('^[%w%-_]+$'),'Sign-in was not accepted. Check your email, password and server address.')
    assert(Store.save(root..'/zlibrary-session.json',{base=base,id=id,key=key}),'Could not save the sign-in session.')
    return true
end
function Z.search(root,query,page)
    local s=Z.session(root)
    local d=Z.request(s.base,'/eapi/book/search','message='..E(query)..'&page='..page..'&limit=20&languages[0]=english&extensions[0]=pdf&extensions[1]=epub',s)
    local books={};local items=d.books or (type(d.exactMatch)=='table' and d.exactMatch.books) or {}
    for _,b in ipairs(items)do
        local ext=type(b.extension)=='string' and b.extension:upper() or ''
        if b.id and b.hash and (ext=='PDF' or ext=='EPUB')then books[#books+1]={id=tostring(b.id),hash=tostring(b.hash),title=b.title or 'Untitled',author=b.author or '',format=ext,source='zlib'}end
    end
    local total=type(d.pagination)=='table' and tonumber(d.pagination.total_items) or tonumber(d.exactBooksCount)
    return {books=books,more=total and page*20<total or not total and #items==20}
end
function Z.resolve(root,book)
    local s=Z.session(root)
    local d=Z.request(s.base,'/eapi/book/'..E(book.id)..'/'..E(book.hash)..'/file',nil,s)
    assert(type(d.file)=='table' and d.file.allowDownload~=false and type(d.file.downloadLink)=='string','Download unavailable. Your account may have reached its daily limit.')
    local url=require('socket.url').absolute(s.base..'/',d.file.downloadLink)
    local headers
    if require('socket.url').parse(url).host==require('socket.url').parse(s.base).host then headers={cookie='remix_userid='..s.id..'; remix_userkey='..s.key}end
    return url,headers
end
return Z
