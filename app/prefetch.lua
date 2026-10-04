-- SPDX-License-Identifier: AGPL-3.0-or-later
local UI=require('ui/uimanager')
return function(App)
function App:clearPageCache()
    if self.prefetch_tick then UI:unschedule(self.prefetch_tick);self.prefetch_tick=nil end
    for _,v in pairs(self.page_cache or {})do v.image:free()end
    self.page_cache={};self.cache_signature=nil
end
function App:renderSignature()
    return table.concat({self.book.path,self.w,self:readerHeight(),self.state.direction,self.state.font_size or 24,self.state.fit,self.zoom or 1,self.state.contrast or 1,tostring(self.state.autocrop)},':')
end
function App:renderPage()
    self:ensureTextLayout()
    if self.last_render_path==self.book.path and self.last_render_page and self.nav.page~=self.last_render_page then
        self.navigation_direction=self.nav.page<self.last_render_page and -1 or 1
    end
    self.last_render_path=self.book.path;self.last_render_page=self.nav.page
    local signature=self:renderSignature()
    if signature~=self.cache_signature then self:clearPageCache();self.cache_signature=signature end
    local key=self.nav.page..'/'..self.nav.offset..'/'..(self.pan_x or 0)
    local cached=self.page_cache[key]
    if cached then
        if self.page_image then self.page_image:free()end
        self.page_transform=cached.transform;self.page_image=cached.image:copy();self.content_height=cached.h;self.content_width=cached.w;self.render_error=nil;self.cache_hits=(self.cache_hits or 0)+1
    else
        self:renderPageUncached()
        if self.page_image and self.state.prefetch~=false then
            if self.page_cache[key] then self.page_cache[key].image:free()end
            self.page_cache[key]={page=self.nav.page,image=self.page_image:copy(),h=self.content_height,w=self.content_width,transform=self.page_transform}
        end
    end
    self:schedulePrefetch()
end
function App:trimPageCache()
    local total=0;local entries={}
    for n,v in pairs(self.page_cache)do
        local bytes=v.image:getWidth()*v.image:getHeight()*v.image:getBpp()/8
        total=total+bytes;entries[#entries+1]={key=n,page=v.page,bytes=bytes}
    end
    table.sort(entries,function(a,b)return math.abs(a.page-self.nav.page)>math.abs(b.page-self.nav.page)end)
    for _,entry in ipairs(entries)do
        if total<=32*1024*1024 then break end
        self.page_cache[entry.key].image:free();self.page_cache[entry.key]=nil;total=total-entry.bytes
    end
end
function App:schedulePrefetch()
    if self.prefetch_tick then UI:unschedule(self.prefetch_tick)end
    if self.state.prefetch==false then return end
    local signature=self.cache_signature;local page=self.nav.page;local targets={}
    local direction=self.navigation_direction or 1
    for _,delta in ipairs({direction,2*direction,3*direction,4*direction,-direction})do local n=page+delta;if n>=1 and n<=self.nav.count then targets[#targets+1]=n end end
    local keep={[page]=true};for _,n in ipairs(targets)do keep[n]=true end
    for n,v in pairs(self.page_cache)do if not keep[v.page]then v.image:free();self.page_cache[n]=nil end end
    self:trimPageCache()
    local i=0
    local limit=math.max(0,(self.content_height or 0)-self:readerHeight())
    local pan=math.max(0,math.min(limit,self.nav.offset+direction*math.floor(self:readerHeight()*.88)))
    local pan_x=self.pan_x or 0
    local warmPan=pan~=self.nav.offset
    self.prefetch_tick=function()
        if not self.doc or self.cache_signature~=signature then return end
        if warmPan then
            warmPan=false
            local key=page..'/'..pan..'/'..pan_x
            if not self.page_cache[key]then
                local ok,image,h,w,transform=pcall(self.doc.render,self.doc,page,self.w,self:readerHeight(),self.state.fit,pan,self.zoom,pan_x,self.state.contrast,self.state.autocrop)
                if ok then self.page_cache[key]={page=page,image=image,h=h,w=w,transform=transform};self:trimPageCache()end
            end
            UI:scheduleIn(.02,self.prefetch_tick);return
        end
        i=i+1;local n=targets[i];if not n then return end
        local key=n..'/0/0'
        if not self.page_cache[key]then
            local ok,image,h,w,transform=pcall(self.doc.render,self.doc,n,self.w,self:readerHeight(),self.state.fit,0,self.zoom,0,self.state.contrast,self.state.autocrop)
            if ok then self.page_cache[key]={page=n,image=image,h=h,w=w,transform=transform};self:trimPageCache()end
        end
        UI:scheduleIn(.02,self.prefetch_tick)
    end
    UI:scheduleIn(.05,self.prefetch_tick)
end
end
