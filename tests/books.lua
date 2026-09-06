local app=...
local BB=require('ffi/blitbuffer');local UI=require('ui/uimanager');local R=require('requests')
local b=require('books'):new{owner=app};local bb=BB.new(app.w,app.h,BB.TYPE_BB8);b:paintTo(bb);bb:writePNG(app.root..'/books-home.png');bb:free()
for _,h in ipairs(b.hits)do assert(h.x>=0 and h.y>=0 and h.x+h.w<=app.w and h.y+h.h<=app.h,h.id)end
local https=require('book_http');local request=https.request;local count=0
https.request=function(o)
 count=count+1
 if count==1 then o.sink('redirect body');return 1,302,{location='/final'}end
 o.sink('final book');return 1,200,{}
end
local B=require('book_sources');assert(B.get('https://example.org/first')=='final book')
count=0;local data='';B.get('https://example.org/first',function(c)data=data..(c or '');return 1 end,function()data=''end);assert(data=='final book')
count=0;https.request=function(o)
 count=count+1
 if count==1 then assert(o.headers.cookie=='secret');return 1,302,{location='https://other.example/file'}end
 assert(not o.headers.cookie);o.sink('ok');return 1,200,{}
end
assert(B.get('https://example.org/first',nil,nil,{cookie='secret'})=='ok')
local Z=require('zlibrary');assert(not pcall(Z.base,'https://example.org/path'));assert(not pcall(Z.base,'http://example.org'));assert(not pcall(Z.base,'https://name@example.org'))
https.request=function(o)
 assert(o.redirect==false and o.verify=='peer')
 o.sink('{"errors":[],"response":{"user_id":123,"user_key":"test-session"}}');return 1,200,{}
end
assert(Z.login(app.root,'https://example.org','test@example.org','not-a-real-password'))
assert(Z.session(app.root).key=='test-session');os.remove(app.root..'/zlibrary-session.json')
https.request=function(o)o.sink('{"response":{"validationError":true}}');return 1,200,{} end
assert(not pcall(Z.login,app.root,'https://example.org','test@example.org','bad'))
https.request=function(o)o.sink('<html>challenge</html>');return 1,200,{} end
assert(not pcall(Z.login,app.root,'https://example.org','test@example.org','bad'))
https.request=request
local send=R.send;local callback
R.send=function(_,root,path,method,body,done)callback=done end
local d=require('discover'):new{owner=app,query='Test',autosearch=true}
local canvas=BB.new(app.w,app.h,BB.TYPE_BB8);d:paintTo(canvas);canvas:free()
local cleared=false;for _,h in ipairs(d.hits)do if h.id=='clear-search' or h.id=='clear' then h.fn();cleared=true end end
assert(cleared,'clear hit missing');callback(true,{mangas={{title='stale'}},errors={}});assert(not d.results or #d.results==0)
R.send=send
local H=require('book_http');assert(H.matches('a.example.org','*.example.org'));assert(not H.matches('a.b.example.org','*.example.org'));assert(not H.matches('badexample.org','*.example.org'))
local P=require('download_progress'):new{owner=app};local dirty=UI.setDirty;local updates=0
UI.setDirty=function(_,widget,mode,region)assert(mode=='fast' and region);updates=updates+1 end
P.tick();P.tick();assert(updates==1,'Idle progress must not refresh');P:onCloseWidget();UI.setDirty=dirty
print('PASS book screen, redirect body reset, cookie scoping, Z-Library session and cleared stale results')
