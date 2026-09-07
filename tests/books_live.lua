local app=...
local B=require('book_sources');local S=require('storage')
local results=B.search('gutenberg','Alice in Wonderland',1)
assert(#results.books>0);local book=results.books[1];assert(book.format=='EPUB')
local dest=require('book_transfer').transfer(app.root,{id='gutenberg-live',book=book}).path;local doc=require('document').open(dest)
assert(doc.count>0)
local bb=doc:render(1,600,800,'page',0,1,0,1,false);bb:writePNG(app.root..'/epub-page.png');bb:free();doc:close()
print('PASS live Gutenberg search, EPUB download and native rendering')
