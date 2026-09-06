-- SPDX-License-Identifier: AGPL-3.0-or-later
require('setupkoenv')
local json=require('rapidjson');local root=assert(arg[1]);local staging=assert(arg[2])
local function load(path)
    local f=io.open(path,'rb');if not f then return {} end
    local text=f:read('*a');f:close();local value=json.decode(text);assert(type(value)=='table','Invalid existing settings: '..path);return value
end
local function write(path,value)
    local f=assert(io.open(path,'wb'));assert(f:write(json.encode(value)));assert(f:close())
end
local settings=load(root..'/data/sources/settings.json')
settings.languages={'en'};settings.concurrent_requests_pages=8;settings.optimize_image=false
settings.storage_size_limit='100 GB' -- Above this device's capacity; never evict a user's books as a cache.
settings.ram_storage_enabled=false;settings.enabled_cron_check_mangas_update=false
settings.delete_downloaded_after_read=false;settings.delete_downloaded_on_remove=false
settings.search_view_mode='base'
write(staging..'/settings.json',settings)
local state=load(root..'/data/state.json')
write(staging..'/state.json',state)
