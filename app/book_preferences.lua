-- SPDX-License-Identifier: AGPL-3.0-or-later
local keys={fit='page',direction='rtl',contrast=1,autocrop=false}
return function(App)
function App:initBookPreferences()
    self.state.book_settings=self.state.book_settings or {}
    if not self.state.reading_defaults then
        self.state.reading_defaults={}
        for k,v in pairs(keys)do local x=self.state[k];if x==nil then x=v end;self.state.reading_defaults[k]=x end
    end
    self:restoreReadingDefaults()
end
function App:readingKey()return self.book and (self.book.series_key or self.book.path)end
function App:rememberReadingSettings()
    if not self.state.reading_defaults then return end
    local target
    if self.doc and self.book then
        local key=self:readingKey();target=self.state.book_settings[key] or {};self.state.book_settings[key]=target
        target.zoom=self.zoom or 1
    else target=self.state.reading_defaults end
    for k,v in pairs(keys)do local x=self.state[k];if x==nil then x=v end;target[k]=x end
end
function App:loadBookSettings()
    local saved=self.state.book_settings[self:readingKey()] or {}
    for k,v in pairs(keys)do local x=saved[k];if x==nil then x=self.state.reading_defaults[k]end;if x==nil then x=v end;self.state[k]=x end
    return math.max(1,math.min(4,tonumber(saved.zoom) or 1))
end
function App:restoreReadingDefaults()
    for k,v in pairs(keys)do local x=self.state.reading_defaults[k];if x==nil then x=v end;self.state[k]=x end
    self.zoom=1
end
end
