-- SPDX-License-Identifier: AGPL-3.0-or-later
io.stdout:setvbuf('line')
os.setlocale('C','numeric')
require('setupkoenv')
package.path=assert(os.getenv('YOMIGAMI_APP'))..'/?.lua;'..package.path
package.loaded['ui/screensaver']=require('sleep')
G_defaults=require('luadefaults'):open()
G_reader_settings=require('luasettings'):open(assert(os.getenv('KO_HOME'))..'/settings.reader.lua')
local Device=require('device')
require('document/canvascontext'):init(Device)
require('ui/bidi').setup()
local UI=require('ui/uimanager')
local App=require('main')
local app=App:new{}
require('sleep').app=app
UI:show(app)
if os.getenv('YOMIGAMI_TEST') then
    assert(loadfile(os.getenv('YOMIGAMI_TEST')))(app)
    app:clearCovers();Device:exit();os.exit(0)
end
if os.getenv('YOMIGAMI_SCREENSHOT') then
    local bb=require('ffi/blitbuffer').new(Device.screen:getWidth(),Device.screen:getHeight(),require('ffi/blitbuffer').TYPE_BB8)
    app:paintTo(bb,0,0)
    bb:writePNG(os.getenv('YOMIGAMI_SCREENSHOT'))
    bb:free();app:clearCovers();Device:exit();os.exit(0)
end
if app.state_error then app:message(app.state_error) elseif app.recovery_notice then app:message(app.recovery_notice)end
UI:run()
Device:exit()
