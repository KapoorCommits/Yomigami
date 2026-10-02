-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager')
local BB=require('ffi/blitbuffer')
local R=require('requests')
local B=require('discover'):extend{}
function B:init()
    self.book_mode=true;self.owner.downloaded_books=self.owner.downloaded_books or {}
    require('discover').init(self)
end
function B:search()
    if not self.query or self.query=='' then return end
    self:fetch('@books/search','POST',{root=self.owner.root,source=self.source or 'gutenberg',query=self.query,page=self.remote_page},function(data)self.results=data.books;self.has_more=data.more;self.page=1 end)
end
function B:chooseSource(source)
    self.request_generation=(self.request_generation or 0)+1;self.source=source;self.query=nil;self.results=nil;self.error=nil;self.page=1;UI:setDirty(self,'full')
    self.owner:input('Search '..(source=='gutenberg' and 'Gutenberg ebooks' or source=='zlib' and 'Z-Library' or source=='textbooks' and 'Open Textbook Library' or 'Internet Archive PDFs'),function(q)if not self.closed then self.query=q;self.remote_page=1;self:search()end end)
end
function B:download(book)
    local a=self.owner;local T=require('book_transfer');a:message('Checking download size…')
    R:send(a.root,'@books/probe','POST',{root=a.root,book=book},function(ok,info)
        if self.closed then return end
        if not ok then return a:message('Could not check the source: '..tostring(info))end
        if info.total and (info.total>info.limit or info.total+T.reserve>info.free)then return a:message('This book needs '..T.format(info.total)..'. Available: '..T.format(info.free)..'. Open + → Storage to free space. File limit: '..T.format(info.limit))end
        UI:show(require('ui/widget/confirmbox'):new{text=book.title..'\n'..(info.total and 'Download size: '..T.format(info.total) or 'The source does not report a total size. Usage will appear as it downloads.')..'\nFree storage: '..T.format(info.free),ok_text='Download',ok_callback=function()a:queueBook(book,info)end})
    end)
end
function B:zlibrary()
    local a=self.owner
    local function signin()
        a:input('Your Z-Library HTTPS server address',function(base)
            a:input('Z-Library email',function(email)
                a:input('Z-Library password',function(password)
                    a:message('Signing in…')
                    R:send(a.root,'@books/login','POST',{root=a.root,base=base,email=email,password=password},function(ok,result)
                        if ok and not self.closed then self:chooseSource('zlib')else a:message(ok and 'Signed in.' or result)end
                    end)
                end,true)
            end)
        end)
    end
    a:menu('Z-Library',{
        {text='Search PDF & EPUB',callback=function()local ok=pcall(require('zlibrary').session,a.root);if ok then self:chooseSource('zlib')else signin()end end},
        {text='Sign in / change server',callback=signin},
        {text='Sign out',callback=function()os.remove(a.root..'/zlibrary-session.json');a:message('Signed out.')end},
    })
end
function B:annas()
    local a=self.owner;local A=require('annas')
    a:menu('Anna’s Archive',{
        {text='Search on phone / computer, then import',callback=function()
            a:input('Search Anna’s Archive',function(q)
                require('wifi_receive').show(a,function()self:onClose()end,A.searchURL(q))
            end)
        end},
        {text='Download book link (membership required)',callback=function()
            a:input('Anna’s Archive .gl book URL or MD5',function(value)
                local ok,id=pcall(A.md5,value);if not ok then return a:message(id)end
                a:input('Book title',function(title)
                    a:menu('Choose the file’s format',{
                        {text='PDF',callback=function()self:download{source='annas',id=id,title=title,format='PDF'}end},
                        {text='EPUB',callback=function()self:download{source='annas',id=id,title=title,format='EPUB'}end},
                    })
                end)
            end)
        end},
        {text='Set membership secret key',callback=function()
            a:input('Anna’s Archive membership secret key',function(key)
                local ok,err=pcall(A.setKey,a.root,key);a:message(ok and 'Membership key saved on this device.' or err)
            end,true)
        end},
        {text='Remove membership key',callback=function()os.remove(a.root..'/annas-session.json');a:message('Membership key removed.')end},
    })
end
function B:paintTo(bb)
    local a=self.owner;local s=function(n)return a:s(n)end;local p=s(28);local w=a.w-2*p
    self.hits={};bb:paintRect(0,0,a.w,a.h,BB.COLOR_WHITE)
    a:label(bb,'PDFs & ebooks',p,s(32),28,true,w-s(70));self:button(bb,'close','×',a.w-s(74),s(26),s(46),s(42),function()self:onClose()end)
    a:label(bb,'Stories, ideas and entire worlds.',p,s(82),13,false,w)
    if not self.query then
        local rows={
            {'import','Import PDF From Anywhere','Phone or computer · Scan QR or use Wi-Fi',function()
                require('wifi_receive').show(a,function()self:onClose()end)
            end},
            {'gutenberg','Project Gutenberg','EPUB classics · Free downloads',function()self:chooseSource('gutenberg')end},
            {'textbooks','Open Textbook Library','Open-access textbooks · Direct PDFs',function()self:chooseSource('textbooks')end},
            {'archive','Internet Archive','Publicly downloadable PDFs',function()self:chooseSource('archive')end},
            {'url','Download from a link','Direct HTTPS links to PDF or EPUB files',function()
                a:input('Direct PDF or EPUB HTTPS link',function(url)
                    local ext=url:lower():match('%.(epub)') and 'EPUB' or 'PDF'
                    a:input('Book title',function(title)self:download{title=title,url=url,format=ext}end)
                end)
            end},
            {'zlib','Z-Library','PDF & EPUB · Sign in with your account',function()self:zlibrary()end},
            {'annas','Anna’s Archive','Browser search & import · Member downloads',function()self:annas()end},
        }
        for i,row in ipairs(rows)do local y=s(130)+(i-1)*s(88)
            bb:paintRect(p,y,w,s(76),BB.Color8(247));bb:paintBorder(p,y,w,s(76),1,BB.Color8(210))
            a:centerLabel(bb,row[2],p,y+s(9),w,s(30),17,true);a:centerLabel(bb,row[3],p,y+s(42),w,s(25),12,false)
            self:hit(row[1],p,y,w,s(76),row[4])
        end
        return
    end
    self:button(bb,'search',self.query,p,s(118),w-s(56),s(48),function()self:chooseSource(self.source)end)
    self:button(bb,'clear','×',a.w-p-s(46),s(118),s(46),s(48),function()self.query=nil;self.results=nil;self.request_generation=(self.request_generation or 0)+1;self.loading=false;UI:setDirty(self,'full')end)
    a:label(bb,self.loading and 'Searching…' or self.error and 'Unavailable · Try again' or (#(self.results or {})==0 and 'No matching files on this page · Try next page' or 'Tap a book to download'),p,s(190),12,false,w)
    if self.error then self:button(bb,'error-details','Why did this fail?',p,s(230),w,s(44),function()a:message(self.error)end)end
    local items=self.error and {} or self.results or {}
    for slot=1,self.per do local index=(self.page-1)*self.per+slot;local book=items[index]
        if book then local y=s(230)+(slot-1)*s(76)
            bb:paintRect(p,y,w,s(66),BB.Color8(247));a:centerLabel(bb,book.title,p,y+s(5),w,s(30),16,true)
            a:centerLabel(bb,book.format..' · '..(book.author or 'Internet Archive'),p,y+s(36),w,s(24),11,false)
            self:hit('book-'..index,p,y,w,s(66),function()self:download(book)end)
        end
    end
    local foot=a.h-s(68);self:button(bb,'previous','‹',p,foot,s(48),s(40),function()self:onPrevious()end)
    a:centerLabel(bb,self.page..' / '..math.max(1,math.ceil(#items/self.per)),p+s(70),foot,w-s(140),s(40),13,false)
    self:button(bb,'next',self.error and 'Retry' or '›',a.w-p-s(60),foot,s(60),s(40),function()if self.error then self:search()else self:onNext()end end)
end
return B
