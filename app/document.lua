-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Private low-level MuPDF adapter. Does not load KOReader's document registry.
local mupdf = require('ffi/mupdf')
local DC = require('ffi/drawcontext')
local D = {}; D.__index=D
function D.open(path, password, layout)
    local raw = mupdf.openDocument(path)
    if raw:needsPassword() and not raw:authenticatePassword(password or '') then
        raw:close(); error('This PDF needs a password.')
    end
    local reflow=raw:isDocumentReflowable()
    if reflow then
        layout=layout or {width=600,height=800,font_size=24}
        raw:layoutDocument(layout.width,layout.height,layout.font_size)
    end
    local count = raw:getPages()
    if count < 1 then raw:close(); error('This document has no readable pages.') end
    return setmetatable({raw=raw, count=count, path=path,reflowable=reflow,layout=layout}, D)
end
function D:relayout(width,height,font_size)
    if not self.reflowable then return end
    self.raw:layoutDocument(width,height,font_size);self.count=self.raw:getPages()
    self.layout={width=width,height=height,font_size=font_size};self.crop_bounds=nil;self.highlight_index=nil
end
function D:textMap(number)
    local page=self.raw:openPage(number)
    local ok,lines=pcall(page.getPageText,page);page:close();if not ok then error(lines)end
    local parts,words={},{};local pos=1
    for line_index,line in ipairs(lines or {})do
        for i,word in ipairs(line)do
            if i>1 then parts[#parts+1]=' ';pos=pos+1 end
            local w={line=line_index,text=word.word,x0=word.x0,y0=word.y0,x1=word.x1,y1=word.y1,first=pos,last=pos+#word.word-1}
            words[#words+1]=w;parts[#parts+1]=word.word;pos=pos+#word.word
        end
        parts[#parts+1]='\n';pos=pos+1
    end
    return {text=table.concat(parts):gsub('\n$',''),words=words}
end
function D:pageText(number)return self:textMap(number).text end
function D:render(number, width, height, mode, offset, magnification, horizontal, contrast, autocrop)
    assert(number >= 1 and number <= self.count, 'Page outside document')
    local page=self.raw:openPage(number)
    local ok, result, content_height, content_width, transform = pcall(function()
        local dc=DC.new()
        local w,h=page:getSize(dc)
        assert(w>0 and h>0, 'Invalid page size')
        local crop={x=0,y=0,w=1,h=1}
        if autocrop or mode=='edge' then
            self.crop_bounds=self.crop_bounds or {}
            local crop_key=number..(mode=='edge' and '/tight' or '/safe')
            crop=self.crop_bounds[crop_key]
            if not crop then
                local preview=DC.new();preview:setZoom(math.min(768/w,768/h))
                local bw=math.max(1,math.floor(w*preview:getZoom()));local bh=math.max(1,math.floor(h*preview:getZoom()))
                local thumb=page:draw_new(preview,bw,bh,0,0)
                crop=require('crop').bounds(thumb,mode=='edge');thumb:free()
                if mode=='edge' then
                    -- Preserve selectable text even when preview antialiasing makes it faint.
                    local text_ok,lines=pcall(page.getPageText,page)
                    if text_ok then
                        local x0,y0,x1,y1=crop.x*w,crop.y*h,(crop.x+crop.w)*w,(crop.y+crop.h)*h
                        for _,line in ipairs(lines or {})do for _,word in ipairs(line)do
                            if word.x0 and word.y0 and word.x1 and word.y1 then
                                x0=math.max(0,math.min(x0,word.x0-1));y0=math.max(0,math.min(y0,word.y0-1))
                                x1=math.min(w,math.max(x1,word.x1+1));y1=math.min(h,math.max(y1,word.y1+1))
                            end
                        end end
                        crop={x=x0/w,y=y0/h,w=(x1-x0)/w,h=(y1-y0)/h}
                    end
                end
                self.crop_bounds[crop_key]=crop
            end
        end
        local original_w,original_h=w,h
        w=w*crop.w;h=h*crop.h
        local zoom=(mode=='width' or mode=='edge' or autocrop) and width/w or math.min(width/w,height/h)
        zoom=zoom*math.max(1,math.min(magnification or 1,4))
        dc:setZoom(zoom)
        if contrast and contrast~=1 then dc:setGamma(math.max(.5,math.min(2,contrast))) end
        local pw,ph=math.max(1,math.floor(w*zoom)),math.max(1,math.floor(h*zoom))
        local tx=math.floor(original_w*crop.x*zoom+math.max(0,math.min(horizontal or 0,pw-width)))
        local ty=math.floor(original_h*crop.y*zoom+math.max(0,math.min(offset or 0,ph-height)))
        local buffer=page:draw_new(dc, math.min(width,pw), math.min(height,ph), math.floor(original_w*crop.x*zoom+math.max(0,math.min(horizontal or 0,pw-width))),
            math.floor(original_h*crop.y*zoom+math.max(0,math.min(offset or 0,ph-height))))
        return buffer,ph,pw,{zoom=zoom,x=tx,y=ty}
    end)
    page:close()
    if not ok then error(result) end
    return result,content_height,content_width,transform
end
function D:close() if self.raw then self.raw:close(); self.raw=nil end end
return D
