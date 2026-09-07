-- SPDX-License-Identifier: AGPL-3.0-or-later
local Store=require('storage');local lfs=require('libs/libkoreader-lfs');local H=require('book_http')
local T={limit=512*1024*1024,reserve=64*1024*1024}
function T.format(n)
    if type(n)~='number' then return 'Size unknown' end
    if n>=1024^3 then return string.format('%.2f GB',n/1024^3)end
    if n>=1024^2 then return string.format('%.1f MB',n/1024^2)end
    return string.format('%.0f KB',n/1024)
end
function T.name(name,format)
    name=tostring(name or 'Book'):gsub('[/%c\\:*?"<>|]',' '):gsub('^%s*%.+',''):match('^%s*(.-)%s*$'):sub(1,140)
    if name=='' then name='Book'end
    return name..(format=='EPUB' and '.epub' or format=='CBZ' and '.cbz' or '.pdf')
end
function T.free(root)return require('disk_space').free(root)end
function T.paths(root,id)
    assert(tostring(id):match('^[%w%-]+$'),'Invalid transfer ID')
    local dir=root..'/.book-transfers';lfs.mkdir(dir)
    return dir..'/'..id..'.part',dir..'/'..id..'.json'
end
local function request(url,headers,method,onheaders,sink)
    return H.stream({url=url,method=method,headers=headers,verify='peer',cafile='data/ca-bundle.crt'},onheaders,sink)
end
local function headersFor(url,original,cookies)
    local h={['user-agent']='Yomigami/0.5.0'}
    if require('socket.url').parse(url).host==original then for k,v in pairs(cookies or {})do h[k]=v end end
    return h
end
function T.probe(root,book)
    local url,cookies=require('book_sources').resolve(book,root);local original=require('socket.url').parse(url).host
    local size
    for i=1,6 do
        local code,reply=request(url,headersFor(url,original,cookies),'HEAD',function()return false end)
        if code>=300 and code<400 and reply.location then url=require('socket.url').absolute(url,reply.location)
        elseif code==405 or code==501 then
            code,reply=request(url,headersFor(url,original,cookies),'GET',function()return false end)
            size=code==200 and tonumber(reply['content-length']) or nil;break
        else size=code==200 and tonumber(reply['content-length']) or nil;break end
    end
    return {total=size,free=T.free(root),limit=T.limit}
end
function T.transfer(root,job)
    local part,meta_path=T.paths(root,job.id);local meta=Store.load(meta_path,{})
    local dest=root..'/library/'..T.name(job.book.title,job.book.format)
    if lfs.attributes(dest) then
        if meta.ready then return {path=dest,total=lfs.attributes(dest,'size')}end
        error('A book with this filename already exists. Rename it or cancel this download.')
    end
    local file;local received=lfs.attributes(part,'size') or 0;local last=0
    local function save()
        if file then assert(file:flush(),'Could not write book data.')end
        meta.bytes=received;assert(Store.save(meta_path,meta),'Could not save download progress.')
    end
    local ok,result=pcall(function()
        local url,cookies=require('book_sources').resolve(job.book,root);local original=require('socket.url').parse(url).host
        for hop=1,6 do
            local offset=meta.validator and received or 0
            local headers=headersFor(url,original,cookies)
            if offset>0 then headers.range='bytes='..offset..'-';headers['if-range']=meta.validator end
            local code,reply=request(url,headers,'GET',function(code,h)
                if code>=300 and code<400 then return false end
                if code==416 then meta.validator=nil;save();error('The remote file changed. Retry to restart safely.')end
                if code==401 or code==403 then error('Access denied. Sign in again or check your account/download limit.')end
                if code==404 then error('This download is no longer available from the source.')end
                if code==429 then error('The source is rate limiting downloads. Try again later.')end
                assert(code==200 or code==206,'Source returned HTTP '..tostring(code)..'. Retry or choose another source.')
                local total=tonumber(h['content-length'])
                if code==206 and offset>0 and h.etag and meta.validator~=h.etag then meta.validator=nil;save();error('Remote file changed. Retry to restart safely.')end
                if code==206 then
                    local first,lastbyte,full=(h['content-range'] or ''):match('^bytes (%d+)%-(%d+)/(%d+)$')
                    assert(offset>0 and first and tonumber(first)==offset and tonumber(lastbyte)>=offset and tonumber(full)>tonumber(lastbyte),'Invalid resume response. Partial file preserved.')
                    assert(not meta.total or meta.total==tonumber(full),'Remote file size changed. Restart this download.')
                    total=tonumber(full)
                else offset=0;received=0 end
                assert(not total or total<=T.limit,'Book exceeds the 512 MB download limit.')
                assert(T.free(root)>math.max(0,(total or 0)-offset)+T.reserve,'Not enough storage. Free space in + → Storage, then retry.')
                meta.total=total;meta.validator=(h.etag and not h.etag:match('^W/')) and h.etag or h['last-modified'];meta.ready=nil
                file=assert(io.open(part,offset>0 and 'ab' or 'wb'),'Cannot create the download file. Check storage.')
                received=offset;save();return true
            end,function(chunk,err)
                if err then return nil,err end
                if chunk then
                    if received+#chunk>T.limit then return nil,'Book exceeds the 512 MB download limit.'end
                    if T.free(root)<#chunk+T.reserve then return nil,'Not enough storage. Partial download saved.'end
                    local wrote=file:write(chunk);if not wrote then return nil,'Unable to write book data.'end
                    received=received+#chunk
                    if os.time()>last then save();last=os.time()end
                end
                return 1
            end)
            if code>=300 and code<400 then
                assert(reply.location,'Source redirect is missing an address.')
                url=require('socket.url').absolute(url,reply.location)
            else
                assert(file,'No book data was received.');save();file:close();file=nil
                assert(not meta.total or received==meta.total,'Transfer interrupted. Your downloaded bytes are saved.')
                local valid,doc=pcall(require('document').open,part)
                if not valid then meta.validator=nil;save();error('Downloaded file is not a readable book. Retry to restart or choose another source.')end
                doc:close();meta.ready=true;save()
                assert(not lfs.attributes(dest),'A book with this filename already exists.')
                assert(os.rename(part,dest),'Could not finish saving the book.')
                return {path=dest,total=received}
            end
        end
        error('Too many source redirects.')
    end)
    if file then pcall(save);file:close()end
    if not ok then
        local err=tostring(result)
        if err:find('timeout') or err:find('closed') or err:find('connect') or err:find('resolve') then err='Connection interrupted. Partial download saved; waiting to retry.'end
        error(err)
    end
    return result
end
return T
