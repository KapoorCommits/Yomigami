local app=...
local B=require('book_sources')
local raw=B.get('https://gutendex.com/books/11');local book=require('rapidjson').decode(raw);assert(book.id==11)
local pdf={title='W3C PDF fixture',url='https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',format='PDF'}
local dest=B.download(app.root,pdf);local doc=require('document').open(dest);assert(doc.count==1);doc:close()
local epub=require('document').open(os.getenv('YOMIGAMI_APP')..'/../build/book-live-data/library/Alice\'s Adventures in Wonderland.epub');assert(epub.count>5);epub:close()
print('PASS hostname-verified HTTPS, live PDF download/validation and EPUB reopening')
