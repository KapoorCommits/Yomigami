local app=...
local doc=require('document').open(os.getenv('YOMIGAMI_APP')..'/../build/crop-fixture.cbz')
local a=doc:render(1,400,600,'page',0,1,0,1,false)
local b=doc:render(1,400,600,'page',0,1,0,1,true)
local function ink(bb)local n=0;for y=0,bb:getHeight()-1 do for x=0,bb:getWidth()-1 do if bb:getPixel(x,y):getColor8().a<128 then n=n+1 end end end;return n end
assert(b:getWidth()>=399,'Auto-crop must fill the viewport width')
assert(ink(b)>ink(a)*1.2,'Auto-crop must enlarge content')
assert(b:getPixel(0,0):getColor8().a>240,'Preserve white safety margin')
a:free();b:free();doc:close();print('PASS actual cropped MuPDF rendering enlarges content and preserves safety margin')
