-- SPDX-License-Identifier: AGPL-3.0-or-later
-- Only the temporary receiver port is opened. Never flush Kindle firewall rules.
local F={}
function F.open(port)
    if not require('device'):isKindle() then return function()end end
    port=assert(tonumber(port));assert(port%1==0 and port>0 and port<65536)
    local rules={'INPUT -p tcp --dport '..port,'OUTPUT -p tcp --sport '..port}
    local installed={}
    local function close()
        for _,rule in ipairs(installed)do os.execute('iptables -D '..rule..' -j ACCEPT')end
        installed={}
    end
    for _,rule in ipairs(rules)do
        if os.execute('iptables -I '..rule..' -j ACCEPT')~=0 then
            close();error('Could not allow Wi-Fi imports through the Kindle firewall. Close and try again.')
        end
        installed[#installed+1]=rule
    end
    return close
end
return F
