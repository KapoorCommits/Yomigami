-- SPDX-License-Identifier: AGPL-3.0-or-later
local socket=require('socket');local Store=require('storage');local T=require('book_transfer');local lfs=require('libs/libkoreader-lfs')
local S={}
function S.token()
    local f=assert(io.open('/dev/urandom','rb'));local bytes=f:read(16);f:close();assert(bytes and #bytes==16)
    return (bytes:gsub('.',function(c)return string.format('%02x',c:byte())end))
end
function S.address()
    local udp=assert(socket.udp());udp:setpeername('192.0.2.1',9);local ip=udp:getsockname();udp:close()
    if not ip or not ip:match('^%d+%.%d+%.%d+%.%d+$') or ip=='0.0.0.0' or ip:match('^127%.')then return nil end
    return ip
end
function S.page(token)
    return [[<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Send to Yomigami</title>
<style>body{margin:0;background:#f4f1e8;color:#233c30;font:17px system-ui,sans-serif}main{max-width:620px;margin:8vh auto;padding:28px}small{letter-spacing:.15em}h1{font:48px Georgia,serif;line-height:1.12}p{line-height:1.6}label{display:block;padding:30px;border:1px dashed #697d6b;border-radius:18px;background:#fffdf6}input{max-width:100%;margin-top:16px}button{width:100%;padding:18px;border:0;border-radius:12px;background:#233c30;color:white;font:inherit;margin-top:22px;cursor:pointer}button:disabled{opacity:.5}progress{width:100%;accent-color:#233c30;height:14px;margin-top:28px}#status{white-space:pre-line}footer{font-size:13px;color:#546457;margin-top:36px}</style>
<main><small>A READER OF YOUR OWN</small><h1>Your next book.<br>Now on your Kindle.</h1><p>Choose PDF, EPUB or CBZ files. They travel directly over your local Wi-Fi and appear in your Yomigami library.</p><label>Choose your books<input id="files" type="file" multiple accept=".pdf,.epub,.cbz"></label><button id="send">Send to Yomigami</button><progress id="progress" max="100" value="0"></progress><p id="status" role="status" aria-live="polite">Keep the transfer screen open on your Kindle.</p><footer>Local transfer · No cloud account · Up to 512 MB per file<br>Use a trusted Wi-Fi network. This local connection is HTTP.</footer></main>
<script>const files=document.querySelector('#files'),send=document.querySelector('#send'),bar=document.querySelector('#progress'),status=document.querySelector('#status');
send.onclick=async()=>{if(!files.files.length){status.textContent='Choose a book first.';return}send.disabled=true;files.disabled=true;let done=0;try{for(const file of files.files){if(file.size>512*1024*1024)throw Error(file.name+' exceeds 512 MB.');status.textContent='Sending '+file.name;await new Promise((resolve,reject)=>{const x=new XMLHttpRequest();x.open('POST',location.pathname.replace(/\/$/,'')+'/upload');x.setRequestHeader('Content-Type','application/octet-stream');x.setRequestHeader('X-Filename',encodeURIComponent(file.name));x.upload.onprogress=e=>{if(e.lengthComputable)bar.value=e.loaded/e.total*100};x.onload=()=>{let r;try{r=JSON.parse(x.responseText)}catch{reject(Error('The Kindle returned an unexpected response.'));return}x.status===201?resolve():reject(Error(r.error||'Upload failed.'))};x.onerror=()=>reject(Error('Connection lost. Keep both devices on the same Wi-Fi and try again.'));x.send(file)});done++;}status.textContent=done+' book'+(done===1?'':'s')+' added to your Kindle.';bar.value=100}catch(e){status.textContent=e.message+'\n'+done+' added successfully.'}finally{send.disabled=false;files.disabled=false}};
</script></html>]]
end
local function respond(c,code,body,content_type)
    local labels={[200]='OK',[201]='Created',[400]='Bad Request',[403]='Forbidden',[404]='Not Found',[409]='Conflict',[413]='Too Large',[507]='Insufficient Storage',[422]='Unprocessable Content'}
    local header='HTTP/1.1 '..code..' '..(labels[code] or 'Error')..'\r\nContent-Type: '..(content_type or 'application/json')..'\r\nContent-Length: '..#body..'\r\nConnection: close\r\nCache-Control: no-store\r\nReferrer-Policy: no-referrer\r\nX-Content-Type-Options: nosniff\r\nContent-Security-Policy: default-src \'none\'; script-src \'unsafe-inline\'; style-src \'unsafe-inline\'; connect-src \'self\'; frame-ancestors \'none\'; base-uri \'none\'\r\n\r\n'
    c:send(header..body)
end
local function line(c)
    local chars={}
    for i=1,4096 do local ch=assert(c:receive(1));if ch=='\n' then return table.concat(chars):gsub('\r$','')end;chars[#chars+1]=ch end
    error('Header line too long')
end
function S.handle(c,root,token,host)
    c:settimeout(15);local part=root..'/.wifi-upload.part';local file
    local ok,err=pcall(function()
        local first=line(c)
        local method,path=first:match('^(%u+) (%S+) HTTP/1%.[01]$');local h={};local count=0
        while true do local l=line(c);count=count+#l;assert(count<16384,'Headers too large');if l=='' then break end;local k,v=l:match('^([^:]+):%s*(.-)%s*$');assert(k and not h[k:lower()],'Invalid headers');h[k:lower()]=v end
        if h.host~=host or (h.origin and h.origin~='http://'..host) or (path~='/'..token and path~='/'..token..'/upload')then respond(c,403,'{"error":"This transfer session is not available."}');return end
        if method=='GET' and path=='/'..token then respond(c,200,S.page(token),'text/html; charset=utf-8');return end
        if method~='POST' or path~='/'..token..'/upload' then respond(c,404,'{"error":"Not found."}');return end
        local n=tonumber(h['content-length']);if h['transfer-encoding'] or not n or n<1 or n%1~=0 or n>T.limit then respond(c,413,'{"error":"Choose a file between 1 byte and 512 MB."}');return end
        local name=(h['x-filename'] or ''):gsub('%%(%x%x)',function(hex)return string.char(tonumber(hex,16))end)
        local ext=name:lower():match('%.(epub)$') or name:lower():match('%.(pdf)$') or name:lower():match('%.(cbz)$')
        if not ext or #name>180 or name:find('[/\\%c]') or name:sub(1,1)=='.'then respond(c,400,'{"error":"Use a PDF, EPUB or CBZ filename without folders."}');return end
        local dest=root..'/library/'..name
        if lfs.symlinkattributes(dest)then respond(c,409,'{"error":"A book with this filename already exists. Rename your file first."}');return end
        if T.free(root)<n+T.reserve then respond(c,507,'{"error":"Not enough free Kindle storage."}');return end
        if h.expect and h.expect:lower()=='100-continue' then c:send('HTTP/1.1 100 Continue\r\n\r\n')end
        file=assert(io.open(part,'wb'));local received=0
        while received<n do
            local chunk,why,partial=c:receive(math.min(65536,n-received));chunk=chunk or partial
            if chunk and #chunk>0 then assert(T.free(root)>#chunk+T.reserve,'Not enough storage');assert(file:write(chunk));received=received+#chunk end
            assert(not why, 'Connection interrupted. Please send the file again.')
        end
        assert(file:close());file=nil
        local valid,doc=pcall(require('document').open,part)
        if not valid then respond(c,422,'{"error":"This file is not a readable, unlocked book."}');return end
        doc:close();assert(not lfs.symlinkattributes(dest),'Filename already exists');assert(os.rename(part,dest))
        local old=Store.load(root..'/.wifi-status.json',{});Store.save(root..'/.wifi-status.json',{count=(old.count or 0)+1,title=name,bytes=n})
        respond(c,201,'{"ok":true}')
    end)
    if file then file:close()end;os.remove(part)
    if not ok then pcall(respond,c,400,'{"error":"Transfer interrupted or invalid request. Your library was not replaced. Try again."}')end
    c:close()
end
function S.run(server,root,token,host)
    server:settimeout(1)
    while true do local c=server:accept();if c then S.handle(c,root,token,host)end end
end
return S
