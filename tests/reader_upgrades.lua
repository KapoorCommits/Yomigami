local app=...
local UI=require('ui/uimanager');local BB=require('ffi/blitbuffer');local Store=require('storage');local T=require('book_transfer');local lfs=require('libs/libkoreader-lfs')
local books={};for _,b in ipairs(app.books)do if not b.chapters then books[#books+1]=b end end;assert(#books>=2)
app.state.book_settings={};app:restoreReadingDefaults();local defaults=app.state.reading_defaults.contrast
app:openBook(books[1]);app.state.contrast=1.7;app.state.autocrop=true;app.state.direction='ltr';app:setZoom(2);app:closeBook()
app:openBook(books[2]);assert(app.state.contrast==defaults and app.zoom==1);app.state.contrast=.8;app:save();app:closeBook()
app:openBook(books[1]);assert(app.state.contrast==1.7 and app.state.autocrop and app.state.direction=='ltr' and app.zoom==2);app:closeBook()
app:initBookPreferences();assert(app.state.contrast==defaults)
app:showStorage();local v=UI:getTopmostVisibleWidget();local total=0;for _,b in ipairs(app.books)do for _,c in ipairs(b.chapters or {b})do total=total+(lfs.attributes(c.path,'size') or 0)end end;assert(v.library_bytes==total)
local bb=BB.new(app.w,app.h,BB.TYPE_BB8);v:paintTo(bb);bb:writePNG(app.root..'/storage-050.png');bb:free();v:onClose()
local root=app.root..'/transfer-tests';lfs.mkdir(root);lfs.mkdir(root..'/library')
local f=assert(io.open(books[1].path,'rb'));local data=f:read('*a');f:close();local count=math.floor(#data/2)
local H=require('book_http');local stream=H.stream;local free=T.free;T.free=function()return 2^32 end
local job={id='resume-test',book={title='Resumed',format=books[1].format,url='https://example.org/book'}}
local dest=root..'/library/'..T.name(job.book.title,job.book.format);os.remove(dest);local part,mp=T.paths(root,job.id);os.remove(part);os.remove(mp)
H.stream=function(opts,onheaders,sink)
 assert(not opts.headers.range);onheaders(200,{['content-length']=tostring(#data),etag='"v1"'});sink(data:sub(1,count));error('timeout')
end
assert(not pcall(T.transfer,root,job));assert(lfs.attributes(part,'size')==count)
H.stream=function(opts,onheaders,sink)
 assert(opts.headers.range=='bytes='..count..'-' and opts.headers['if-range']=='"v1"')
 onheaders(206,{['content-range']='bytes '..count..'-'..(#data-1)..'/'..#data,['content-length']=tostring(#data-count),etag='"v1"'})
 sink(data:sub(count+1));return 206,{}
end
assert(T.transfer(root,job).total==#data);f=assert(io.open(dest,'rb'));assert(f:read('*a')==data);f:close()
-- A server ignoring Range must restart rather than append a second full book.
os.remove(dest);f=assert(io.open(part,'wb'));f:write(data:sub(1,count));f:close();Store.save(mp,{validator='"v1"',bytes=count,total=#data})
H.stream=function(opts,onheaders,sink)assert(opts.headers.range);onheaders(200,{['content-length']=tostring(#data),etag='"v2"'});sink(data);return 200,{}end
assert(T.transfer(root,job).total==#data);assert(lfs.attributes(dest,'size')==#data)
-- Invalid ranges never append to the saved prefix.
os.remove(dest);f=assert(io.open(part,'wb'));f:write(data:sub(1,count));f:close();Store.save(mp,{validator='"v1"',bytes=count,total=#data})
H.stream=function(opts,onheaders,sink)onheaders(206,{['content-range']='bytes 1-4/5',etag='"v1"'});sink('wrong');return 206,{}end
assert(not pcall(T.transfer,root,job));assert(lfs.attributes(part,'size')==count)
T.free=function()return 1 end;H.stream=function(opts,onheaders)onheaders(200,{['content-length']=tostring(#data)});return 200,{}end
assert(not pcall(T.transfer,root,job));assert(lfs.attributes(part,'size')==count)
H.stream=stream;T.free=free;os.remove(part);os.remove(mp)
app.state.book_settings={};app:restoreReadingDefaults();app:save()
print('PASS per-book isolation/reopen, storage sums, partial resume, ignored Range restart, invalid Range and low-space protection')

app.state.book_queue={{id='ui-test',status='paused',book={title='Test transfer'},total=1048576}}
app:bookDownloadsMenu();local list=UI:getTopmostVisibleWidget()
local canvas=BB.new(app.w,app.h,BB.TYPE_BB8);list:paintTo(canvas);canvas:writePNG(app.root..'/downloads-050.png');canvas:free();list.tick();list:onClose()
print('PASS download list opens, paints, polls and closes')
