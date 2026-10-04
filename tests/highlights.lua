-- SPDX-License-Identifier: AGPL-3.0-or-later
local app=...;local H=require('highlight_anchor');local D=require('document');local BB=require('ffi/blitbuffer');local Store=require('storage')
local path=os.getenv('YOMIGAMI_SAMPLE_PDF') or app.root..'/library/Long Horizons.pdf'
local sample=D.open(path)
print('Bible PDF pages: '..sample.count)
local found
for _,n in ipairs({2,10,30,100,200,500})do if n<=sample.count then local m=sample:textMap(n);print('Bible page '..n..': '..#m.words..' selectable words');if #m.words>=16 then found=n;break end end end
assert(found,'Bible text layer unavailable')
local map=sample:textMap(found);local quote=map.text:sub(map.words[10].first,map.words[15].last)
local anchor=assert(H.capture(sample,found,quote));assert(#H.boxes(sample,found,{{anchor=anchor}})==6);sample:close()
app:openBook{path=path,title='Orthodox Study Bible',format='PDF'}
app.nav:jump(found);app:renderPage();local entry=app:addAnnotation(quote,'Test note',anchor)
local clean=BB.new(app.w,app.h,BB.TYPE_BB8);local marked=BB.new(app.w,app.h,BB.TYPE_BB8)
local actual=app.state.annotations[app.book.path];app.state.annotations[app.book.path]={};app.highlight_overlay=nil;app:paintReader(clean)
app.state.annotations[app.book.path]=actual;app.highlight_overlay=nil;app:paintReader(marked)
local changed,black=0,0
for y=0,app.h-1 do for x=0,app.w-1 do local a=clean:getPixel(x,y):getColor8().a;local b=marked:getPixel(x,y):getColor8().a;if a~=b then changed=changed+1;assert(b<a)end;if a==0 then assert(b==0);black=black+1 end end end
assert(changed>0 and black>0);marked:writePNG('/tmp/yomigami-bible-highlight.png');clean:free();marked:free()
assert(Store.load(app.root..'/state.json',{}).annotations[app.book.path][1].anchor)
app.state.fit='width';app.zoom=2;app.pan_x=80;app.nav.offset=120;app:renderPage();assert(app.page_transform.zoom>1 and app.page_transform.y>=120)
app:closeBook();app:openBook{path=path,title='Orthodox Study Bible',format='PDF'};app.nav:jump(found);app:renderPage();assert(#H.boxes(app.doc,found,app.state.annotations[app.book.path])==6)
app:closeBook()
local epub=D.open(app.root..'/Reader-layout.epub',nil,{width=600,height=706,font_size=24});local m=epub:textMap(2)
local q=m.text:sub(m.words[2].first,m.words[math.min(7,#m.words)].last);local a=assert(H.capture(epub,2,q));local old_count=epub.count
epub:relayout(600,706,36);assert(epub.count~=old_count)
local idx=H.index(epub,1);local first,last=H.resolve(idx,a);assert(first and last,'Anchor must survive reflow')
assert(#H.boxes(epub,idx.words[first].page,{{anchor=a}})>0);epub:close()
-- Exact duplicate contexts must never cause highlighting the wrong passage.
local fake={words={}};for i=1,40 do fake.words[i]={text='same'}end
assert(not H.resolve(fake,{version=1,first=10,last=10,text='same',before=string.rep('same ',7)..'same',after=string.rep('same ',7)..'same'}))
print('PASS real Bible text layer, visible grey overlay, preserved black text, save/reopen, zoom/pan, EPUB reflow and ambiguous anchors')
