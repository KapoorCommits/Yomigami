local app=...
local H=require('book_http');local original=H.request;local Z=require('zlibrary');local Store=require('storage');local A=require('annas');local S=require('wifi_server')
local root=app.root..'/source-adapters';require('libs/libkoreader-lfs').mkdir(root)
local calls=0
H.request=function(o)
 calls=calls+1;assert(o.redirect==false and o.verify=='peer')
 if calls==1 then o.sink('<html>not found</html>');return 1,404,{} end
 assert(o.url=='https://example.org/eapi/user/login');o.sink(' {"success":1,"user":{"id":1,"remix_userkey":"test-key"}}');return 1,200,{}
end
assert(Z.login(root,'https://example.org','sample@example.org','test'));assert(calls==2)
H.request=function(o)o.sink('{"success":false,"errors":[{"message":"Please login"}]}');return 1,200,{} end
assert(not pcall(Z.search,root,'algebra',1),'API error must not appear as empty results')
calls=0;H.request=function(o)calls=calls+1;o.sink('{"errors":[{"message":"Too many logins"}]}');return 1,200,{} end
assert(not pcall(Z.login,root,'https://example.org','sample@example.org','test'));assert(calls==1,'No login retry on lockout')
calls=0;H.request=function(o)calls=calls+1;o.sink('blocked');return 1,403,{}end
local ok,err=pcall(Z.search,root,'algebra',1);assert(not ok and err:find('blocked',1,true))
assert(not pcall(Z.login,root,'https://example.org','sample@example.org','test'));assert(calls==2)
H.request=function(o)o.sink('{"books":[null,{"id":2,"hash":"abc","title":"Book","extension":"pdf"}],"pagination":{"total_items":1}}');return 1,200,{}end
assert(#Z.search(root,'book',1).books==1)
local hash=string.rep('a',32);assert(A.md5(A.base..'/md5/'..hash)==hash);assert(not pcall(A.md5,'https://evil.example/md5/'..hash))
A.setKey(root,'test-secret')
H.request=function(o)assert(o.url:find('/dyn/api/fast_download.json?',1,true));assert(o.redirect==false);o.sink('{"download_url":"https://files.example.org/book.pdf"}');return 1,200,{}end
assert(A.resolve(root,{id=hash})=='https://files.example.org/book.pdf')
H.request=function(o)o.sink('{"download_url":null,"error":"bad key"}');return 1,403,{}end
assert(not pcall(A.resolve,root,{id=hash}))
local page=S.page('test',A.searchURL('math & science'));assert(page:find('math%%20%%26%%20science'));assert(page:find('Search Anna’s Archive',1,true))
assert(not pcall(S.page,'test','https://evil.example/'))
local B=require('book_sources');local get=B.get
B.get=function(url)assert(url:find('q=algebra',1,true));return '{"data":[{"id":1,"title":"Algebra","formats":[{"type":"PDF","url":"https://example.org/landing"},{"type":"PDF","url":"https://example.org/book.pdf"}]}],"links":{"next":"page2"}}'end
local results=B.search('textbooks','algebra',1,root);assert(#results.books==1 and results.more and results.books[1].url=='https://example.org/book.pdf')
B.get=get;H.request=original
os.remove(root..'/zlibrary-session.json');os.remove(root..'/annas-session.json')
local books=require('books'):new{owner=app};local bb=require('ffi/blitbuffer').new(app.w,app.h,require('ffi/blitbuffer').TYPE_BB8);books:paintTo(bb);bb:writePNG(app.root..'/sources-oct.png');bb:free()
local found={};for _,h in ipairs(books.hits)do assert(h.y+h.h<=app.h);found[h.id]=true end
assert(found.textbooks and found.annas and found.import and not found.pdfdrive)
print('PASS source errors, bounded login fallback, Anna API contract, safe handoff, textbook filtering and source layout')
