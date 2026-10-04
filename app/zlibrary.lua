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
    code=tonumber(code)
    local ok,data=pcall(json.decode,table.concat(parts))
    local errors=ok and type(data)=='table' and data.errors
    local first=type(errors)=='table' and errors[1]
    local reason=type(first)=='table' and first.message or type(first)=='string' and first or ''
    if code==429 or tostring(reason):lower():find('too many',1,true) then error('Too many Z-Library requests. Wait before signing in again.')end
    if code==301 or code==302 or code==307 or code==308 then error('Z-Library moved this endpoint. Enter your current HTTPS server under Sign in / change server. Your credentials were not forwarded.')end
    if code==401 then error('Your Z-Library session expired. Sign in again.')end
    if code==403 then error('Z-Library blocked this request. Check your server in a browser, then sign in with that server.')end
    if code==404 or code==405 then error('Z-Library API endpoint unavailable.')end
    assert(code==200,'Z-Library connection failed (HTTP '..tostring(code or 'unavailable')..'). Check Wi-Fi and your server.')
    assert(ok and type(data)=='table','Z-Library API endpoint unavailable: this server returned a browser page. Try your current server.')
    local response=type(data.response)=='table' and data.response or {}
    assert(not data.error and data.success~=false and data.success~=0 and not first and not response.validationError,
        'Z-Library rejected the request. Sign in again and check your account limits.')
    return data
end
function Z.session(root)
    local s=Store.load(root..'/zlibrary-session.json',{})
    assert(type(s.id)=='string' and s.id:match('^%d+$') and type(s.key)=='string' and s.key:match('^[%w%-_]+$'),'Sign in to Z-Library first.')
    Z.base(s.base);return s
end
function Z.login(root,base,email,password)
    base=Z.base(base)
    local ok,d=pcall(function() return Z.request(base,'/rpc.php','isModal=true&site_mode=books&action=login&gg_json_mode=1&redirectUrl='..E(base..'/')..'&email='..E(email)..'&password='..E(password)) end)
    if not ok then
        if not tostring(d):find('API endpoint unavailable',1,true) then error(d)end
        d=Z.request(base,'/eapi/user/login','email='..E(email)..'&password='..E(password))
    end
    local s=type(d.response)=='table' and d.response or type(d.user)=='table' and d.user or {}
    local id=tostring(s.user_id or s.id or '');local key=s.user_key or s.remix_userkey
    assert(id:match('^%d+$') and type(key)=='string' and key:match('^[%w%-_]+$'),'Sign-in was not accepted. Check your email, password and server address.')
    assert(Store.save(root..'/zlibrary-session.json',{base=base,id=id,key=key}),'Could not save the sign-in session.')
    return true
end
function Z.search(root,query,page)
    local s=Z.session(root)
    local d=Z.request(s.base,'/eapi/book/search','message='..E(query)..'&page='..page..'&limit=20&languages[0]=english&extensions[0]=pdf&extensions[1]=epub',s)
    local books={};local items=type(d.books)=='table' and d.books or (type(d.exactMatch)=='table' and d.exactMatch.books)
    assert(type(items)=='table','Z-Library returned no search data. Sign in again or change server.')
    for _,b in ipairs(items)do
        local ext=type(b)=='table' and type(b.extension)=='string' and b.extension:upper() or ''
        if type(b)=='table' and b.id and b.hash and (ext=='PDF' or ext=='EPUB')then books[#books+1]={id=tostring(b.id),hash=tostring(b.hash),title=b.title or 'Untitled',author=b.author or '',format=ext,source='zlib'}end
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
