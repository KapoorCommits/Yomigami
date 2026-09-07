local app=...
local lfs=require('libs/libkoreader-lfs');local T=require('book_transfer')
local root=app.root..'/live-transfer';lfs.mkdir(root);lfs.mkdir(root..'/library')
local book={title='W3C transfer '..os.time(),format='PDF',url='https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf'}
local info=T.probe(root,book);assert(info.free>1024*1024);assert(not info.total or info.total>100)
local result=T.transfer(root,{id='test-'..os.time(),book=book});assert(result.total>100)
local doc=require('document').open(result.path);assert(doc.count==1);doc:close()
print('PASS live verified HTTPS header probe, transfer, size check and PDF validation: '..T.format(result.total))
