local app=...
local clock=require('socket').gettime
local book;for _,b in ipairs(app.books)do if b.format=='CBZ'then book=b.chapters and b.chapters[1] or b;break end end
app:openBook(book);app.nav:jump(1);app:renderPage();app.prefetch_tick();app.nav:jump(2)
local start=clock();for i=1,15 do app:renderPageUncached()end;local cold=(clock()-start)/15
start=clock();for i=1,15 do app:renderPage()end;local warm=(clock()-start)/15
print(string.format('Render average: uncached %.2f ms; cached %.2f ms; %d cache hits',cold*1000,warm*1000,app.cache_hits or 0))
app:closeBook()
