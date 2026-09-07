local app=...
local R=require('requests');local oldsend,oldcancel=R.send,R.cancel;local previous=app.state.book_queue
local callback;local calls=0
R.send=function(_,root,path,method,body,done)calls=calls+1;callback=done;return 999 end
local cancelled;R.cancel=function(_,pid)cancelled=pid end
app.state.book_queue={{id='queue-fixture',book={title='Queue test',format='PDF',url='https://example.org/book'},status='queued',attempts=0}}
local j=app.state.book_queue[1]
app:pumpBookDownloads();assert(j.status=='active' and calls==1)
callback(false,'Connection interrupted.');assert(j.status=='waiting' and j.next_try>os.time())
app:pumpBookDownloads();assert(calls==1,'Backoff must prevent immediate retries')
j.next_try=0;app:pumpBookDownloads();assert(calls==2)
app:pauseBookDownload(j);assert(cancelled==999 and j.status=='paused' and not app.book_worker)
app:pumpBookDownloads();assert(calls==2)
j.status='queued';app:pumpBookDownloads();callback(false,'Access denied. Sign in again.');assert(j.status=='failed')
j.status='active';app:stopBookDownloads();assert(j.status=='queued');app.book_download_stopped=false;app.book_worker=nil
app.state.book_queue=previous;R.send=oldsend;R.cancel=oldcancel;app:save()
print('PASS retry backoff, active pause, permanent error and restart persistence')
