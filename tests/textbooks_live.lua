local app=...
local B=require('book_sources');local T=require('book_transfer');local lfs=require('libs/libkoreader-lfs')
local found=B.search('textbooks','algebra',1,app.root);assert(#found.books>0)
local book=found.books[1];print('LIVE catalog: '..book.title)
local root=app.root..'/textbooks-live-'..os.time();lfs.mkdir(root);lfs.mkdir(root..'/library')
local result=T.transfer(root,{id='open-textbook',book=book})
local doc=require('document').open(result.path);assert(doc.count>0);print('PASS live textbook search, HTTPS PDF download, readable pages: '..doc.count..', bytes: '..result.total);doc:close()
