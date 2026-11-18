-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Calendar arithmetic is UTC-based, independent of the Kindle's timezone setting.
local S={}
S.defaults={offset=19800,slots={{day=0,hour=22,minute=0},{day=1,hour=18,minute=0}}}
function S.latest(now,config)
    config=config or S.defaults
    local offset=config.offset or 19800
    local day=math.floor((now+offset)/86400)
    local weekday=(day+4)%7 -- Unix epoch was Thursday.
    local latest
    for _,slot in ipairs(config.slots or S.defaults.slots)do
        local candidate=(day-(weekday-slot.day)%7)*86400+slot.hour*3600+(slot.minute or 0)*60-offset
        if candidate>now then candidate=candidate-7*86400 end
        latest=math.max(latest or candidate,candidate)
    end
    return latest
end
function S.due(meta,now,config)
    if config and config.mode=='weekly' then
        local slot=S.latest(now,config)
        return slot and (meta.schedule_completed or 0)<slot and now-(meta.auto_attempt or 0)>=900,slot
    end
    return now-(meta.auto_attempt or 0)>=21600,nil
end
return S
