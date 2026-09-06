-- SPDX-License-Identifier: AGPL-3.0-or-later
local json=require('rapidjson')
local E=require('catalog').encode
local B={}
function B.get(url,sink,reset,headers)
    local https=require('book_http');https.TIMEOUT=60
    local original=require('socket.url').parse(url).host
    for redirects=1,6 do
        assert(type(url)=='string' and url:match('^https://[^/@]+/'),'Use a direct HTTPS link.')
        local parts={};local request_headers={['user-agent']='Yomigami/0.4.0'}
        if require('socket.url').parse(url).host==original then
            for k,v in pairs(headers or {})do request_headers[k]=v end
        end
        local _,code,response=https.request{url=url,redirect=false,verify='peer',cafile='data/ca-bundle.crt',sink=sink or require('ltn12').sink.table(parts),headers=request_headers}
        code=tonumber(code)
        if code and code>=300 and code<400 and response.location then
            if sink then assert(reset,'Cannot reset redirected download.');reset()end
            url=require('socket.url').absolute(url,response.location)
        else assert(code==200,'Download unavailable. Check the source or connection.');return sink and true or table.concat(parts)end
    end
    error('Too many redirects.')
end
function B.search(source,q,page,root)
    if source=='zlib' then return require('zlibrary').search(root,q,page)end
    if source=='gutenberg' then
        local data=json.decode(B.get('https://gutendex.com/books/?languages=en&search='..E(q)..'&page='..page))
        local books={}
        for _,b in ipairs(data.results or {})do
            local url=b.formats['application/epub+zip'];local pdf=b.formats['application/pdf']
            if url or pdf then books[#books+1]={title=b.title,author=b.authors[1] and b.authors[1].name or '',url=pdf or url,format=pdf and 'PDF' or 'EPUB',id=tostring(b.id)}end
        end
        return {books=books,more=type(data.next)=='string'}
    elseif source=='archive' then
        local query='mediatype:texts AND (format:"Text PDF" OR format:"Image Container PDF") AND NOT access-restricted-item:true AND ('..q..')'
        local data=json.decode(B.get('https://archive.org/advancedsearch.php?q='..E(query)..'&fl%5B%5D=identifier&fl%5B%5D=title&rows=20&page='..page..'&output=json'))
        local books={};for _,b in ipairs(data.response.docs or {})do books[#books+1]={title=type(b.title)=='string' and b.title or b.identifier,id=b.identifier,format='PDF',source='archive'}end
        return {books=books,more=page*20<(data.response.numFound or 0)}
    end
    error('This source does not currently expose a verified search integration.')
end
function B.resolve(book,root)
    if book.source=='zlib' then return require('zlibrary').resolve(root,book)end
    if book.url then return book.url end
    local data=json.decode(B.get('https://archive.org/metadata/'..E(book.id)))
    assert(not data.is_dark and not (data.metadata and (data.metadata['access-restricted-item']=='true' or data.metadata['access-restricted-item']==true)),'This item requires borrowing or is restricted.')
    local selected
    for _,f in ipairs(data.files or {})do
        if not f.private and f.name:lower():match('%.pdf$') and (not selected or (tonumber(f.size) or math.huge)<(tonumber(selected.size) or math.huge))then selected=f end
    end
    assert(selected,'No publicly downloadable PDF is available.')
    return 'https://archive.org/download/'..E(book.id)..'/'..E(selected.name)
end
function B.download(root,book)
    local name=(book.title or 'Book'):gsub('[/%c\\:*?"<>|]',' '):sub(1,120)
    local ext=book.format=='EPUB' and '.epub' or '.pdf';local dest=root..'/library/'..name..ext
    local lfs=require('libs/libkoreader-lfs');assert(not lfs.attributes(dest),'This book is already in the library.')
    local _,free=require('ffi/util').df(root);assert(free>256*1024*1024,'Not enough free space.')
    local part=dest..'.part';local file=assert(io.open(part,'wb'));local bytes=0
    local ok,err=pcall(function()
        local url,headers=B.resolve(book,root)
        B.get(url,function(chunk,error)
            if error then return nil,error end
            if chunk then
                bytes=bytes+#chunk;if bytes>128*1024*1024 then return nil,'Book exceeds 128 MB download limit.'end
                return file:write(chunk) and 1
            end
            return 1
        end,function()file:close();file=assert(io.open(part,'wb'));bytes=0 end,headers)
    end)
    file:close()
    if not ok then os.remove(part);error(err)end
    local valid,doc=pcall(require('document').open,part)
    if not valid then os.remove(part);error('The link did not return a readable book.')end
    doc:close();assert(os.rename(part,dest));return dest
end
return B
