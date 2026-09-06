package.path=assert(os.getenv('YOMIGAMI_APP'))..'/?.lua;'..package.path
require('setupkoenv')
local N=require('navigation');local S=require('storage');local D=require('document')
local count=0
local function test(name,fn) fn();count=count+1;print('PASS '..name) end
local root=assert(os.getenv('YOMIGAMI_HOME'))
test('page 2 never implies chapter completion',function()
    local n=N.new(12)
    for p=2,12 do assert(n:turn(1)=='page');assert(n.page==p) end
    for i=1,20 do assert(n:turn(1)=='end');assert(n.page==12) end
end)
test('reverse, resume and jumps stay inside document',function()
    local n=N.new(4,900);assert(n.page==4);assert(n:turn(-1)=='page');assert(n.page==3)
    assert(not n:jump(0));assert(not n:jump(1.5));assert(not n:jump('bad'));assert(n:jump(1));assert(n:turn(-1)=='start')
end)
test('one-page chapter requires a forward request to end',function()
    local n=N.new(1);assert(n.page==1);assert(n:turn(-1)=='start');assert(n:turn(1)=='end')
end)
test('tall page pans before changing page',function()
    local n=N.new(2);assert(n:turn(1,700,2100)=='pan');assert(n.page==1)
    while n.offset<1400 do assert(n:turn(1,700,2100)=='pan') end
    assert(n:turn(1,700,2100)=='page');assert(n.page==2)
end)
test('natural chapter order',function() assert(S.natural('Chapter 2','Chapter 10'));assert(not S.natural('Chapter 20','Chapter 3')) end)
test('progress round trip and corrupt input preserved',function()
    local path=root..'/test-state.json';assert(S.save(path,{page=8}));assert(S.load(path,{}).page==8)
    local f=assert(io.open(path,'w'));f:write('invalid');f:close()
    local state,err=S.load(path,{page=1});assert(state.page==1 and err)
    f=assert(io.open(path));assert(f:read('*a')=='invalid');f:close();os.remove(path)
end)
test('PDF and CBZ native rendering of every page',function()
    for _,b in ipairs(S.scan(root..'/library')) do
        local d=D.open(b.path)
        assert(d.count==(b.format=='CBZ' and 12 or 4))
        for page=1,d.count do
            local image=d:render(page,600,700,'page',0)
            assert(image:getWidth()>0 and image:getHeight()>0);image:free()
        end
        d:close()
    end
end)
test('import protects originals and refuses overwrite',function()
    local source=root..'/library/Moon Atlas.pdf'
    local dest,err=S.import(source,root);assert(dest,err)
    assert(not S.import(source,root));assert(io.open(source)):close();os.remove(dest)
end)
test('no KOReader application or plugin module loaded',function()
    for name in pairs(package.loaded) do assert(not name:match('^apps/reader/') and not name:match('^pluginloader'),name) end
end)
print(count..' core tests passed')
