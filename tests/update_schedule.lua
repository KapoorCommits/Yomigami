local S=require('update_schedule')
local config={mode='weekly',offset=19800,slots={{day=0,hour=22,minute=0},{day=1,hour=18,minute=0}}}
-- 2026-11-15 22:00 IST = Sunday 16:30 UTC.
local sunday=1794760200
assert(os.date('!%Y-%m-%d %H:%M',sunday)=='2026-11-15 16:30')
assert(S.latest(sunday,config)==sunday)
assert(S.latest(sunday-1,config)<sunday)
local monday=sunday+20*3600
assert(S.latest(monday,config)==monday)
assert(S.latest(monday+2*86400,config)==monday,'Missed run catches up')
local meta={schedule_completed=sunday,auto_attempt=sunday}
assert(not S.due(meta,sunday+3600,config))
assert(S.due(meta,monday,config))
meta.auto_attempt=monday;assert(not S.due(meta,monday+899,config));assert(S.due(meta,monday+900,config),'Retry unsuccessful checks')
meta.schedule_completed=monday;assert(not S.due(meta,monday+3600,config))
assert(S.due(meta,monday+7*86400,config))
print('PASS India-time weekly schedule, boundaries, catch-up, retry and duplicate suppression')
