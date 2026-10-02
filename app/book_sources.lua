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
    if source=='textbooks' then
        local data=json.decode(B.get('https://open.umn.edu/opentextbooks/textbooks.json?language=eng&formats%5B%5D=PDF&q='..E(q)..'&page='..page))
        assert(type(data.data)=='table','Textbook catalog returned an invalid response.')
        local books={}
        for _,book in ipairs(data.data)do
            for _,f in ipairs(book.formats or {})do
                -- Some PDF entries are publisher landing pages, not files.
                if f.type=='PDF' and type(f.url)=='string' and f.url:match('^https://') and f.url:lower():match('%.pdf[%?#]?') then
                    books[#books+1]={id=tostring(book.id),title=book.title,author='Open Textbook Library',url=f.url,format='PDF',source='textbooks'};break
                end
            end
        end
        return {books=books,more=type(data.links)=='table' and type(data.links.next)=='string'}
    end
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
    if book.source=='annas' then return require('annas').resolve(root,book)end
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
return B
