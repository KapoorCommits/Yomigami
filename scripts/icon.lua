-- Original vector-style cover: a growing branch above the leaves of an open book.
local app=...
local BB=require('ffi/blitbuffer')
local b=BB.new(600,916,BB.TYPE_BB8)
local paper=BB.Color8(244);local ink=BB.Color8(25);b:fill(paper)
b:paintBorder(22,22,556,872,2,ink);b:paintBorder(30,30,540,856,1,BB.Color8(170))
app:centerLabel(b,'Y O M I G A M I',40,82,520,70,34,true)
app:centerLabel(b,'A quiet place to read',40,158,520,36,15,false)
-- A stem and symmetric leaves: growth through reading.
for y=253,489 do b:paintRect(298,y,3,1,ink)end
for level=0,3 do
    local base=475-level*52
    for x=0,86 do
        local thickness=math.floor(17*math.sin(x/86*math.pi))
        local y=math.floor(base-x*.57)
        b:paintRect(300+x,y-thickness,1,math.max(1,thickness*2),ink)
        b:paintRect(298-x,y-thickness,1,math.max(1,thickness*2),ink)
    end
end
-- Fine page contours, mirrored around the spine.
for line=0,8 do
    for x=0,222 do
        local y=math.floor(536+line*14-48*math.sin(x/222*math.pi*.85))
        b:paintRect(300+x,y,1,2,ink);b:paintRect(299-x,y,1,2,ink)
    end
end
b:paintRect(298,535,3,146,ink)
-- A small ribbon emerges from the center of the pages.
b:paintRect(287,636,24,83,ink)
for i=0,12 do b:paintRect(299-i,707+i,math.max(1,i*2),1,paper)end
b:paintRect(260,777,80,1,ink)
app:centerLabel(b,'M A N G A   ·   B O O K S',40,801,520,28,12,false)
b:writePNG(os.getenv('YOMIGAMI_APP')..'/../assets/icon.png');b:free()
