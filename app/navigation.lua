-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Page state belongs to Yomigami. No ReaderUI events are consumed.
local N = {}
N.__index = N
function N.new(count, saved)
    assert(type(count) == 'number' and count >= 1 and count == math.floor(count), 'Invalid page count')
    return setmetatable({count=count, page=math.max(1, math.min(count, math.floor(tonumber(saved) or 1))), offset=0}, N)
end
function N:turn(delta, viewport, content)
    assert(delta == 1 or delta == -1, 'Expected a single page turn')
    local limit = math.max(0, (content or 0) - (viewport or 0))
    if delta > 0 and self.offset < limit then
        self.offset = math.min(limit, self.offset + math.max(1, math.floor(viewport * .88)))
        return 'pan'
    elseif delta < 0 and self.offset > 0 then
        self.offset = math.max(0, self.offset - math.max(1, math.floor(viewport * .88)))
        return 'pan'
    end
    local target = self.page + delta
    if target > self.count then return 'end' end
    if target < 1 then return 'start' end
    self.page, self.offset = target, 0
    return 'page'
end
function N:jump(page)
    page = tonumber(page)
    if not page or page % 1 ~= 0 or page < 1 or page > self.count then return false end
    self.page, self.offset = page, 0
    return true
end
return N
