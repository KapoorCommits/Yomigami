-- SPDX-License-Identifier: AGPL-3.0-or-later
-- A small, shared e-ink design system. Icons do not depend on font glyph coverage.
local BB=require('ffi/blitbuffer')
local A={}
local icons={['×']='close',['+']='plus',['‹']='back',['›']='next',['−']='minus'}
function A.icon(bb,name,cx,cy,size,color,stroke)
    color=color or BB.COLOR_BLACK;stroke=math.max(1,stroke or 2)
    local function line(x0,y0,x1,y1)
        local dx,dy=x1-x0,y1-y0;local steps=math.max(1,math.ceil(math.max(math.abs(dx),math.abs(dy))*size))
        for i=0,steps do local t=i/steps;bb:paintRect(math.floor(cx+(x0+dx*t)*size-stroke/2),math.floor(cy+(y0+dy*t)*size-stroke/2),stroke,stroke,color)end
    end
    if name=='close' then line(-.28,-.28,.28,.28);line(-.28,.28,.28,-.28)
    elseif name=='plus' then line(-.32,0,.32,0);line(0,-.32,0,.32)
    elseif name=='minus' then line(-.32,0,.32,0)
    elseif name=='next' then line(-.15,-.3,.15,0);line(.15,0,-.15,.3)
    elseif name=='back' then line(.15,-.3,-.15,0);line(-.15,0,.15,.3)
    elseif name=='download' then line(0,-.35,0,.13);line(-.2,-.04,0,.16);line(0,.16,.2,-.04);line(-.32,.17,-.32,.35);line(-.32,.35,.32,.35);line(.32,.35,.32,.17)
    elseif name=='book' then line(-.33,-.3,-.33,.3);line(-.33,-.3,-.08,-.24);line(-.08,-.24,0,-.16);line(0,-.16,.08,-.24);line(.08,-.24,.33,-.3);line(.33,-.3,.33,.3);line(-.33,.3,0,.37);line(0,.37,.33,.3);line(0,-.16,0,.37)
    elseif name=='check' then line(-.3,0,-.08,.22);line(-.08,.22,.32,-.25)
    elseif name=='search' then bb:paintCircle(math.floor(cx-size*.08),math.floor(cy-size*.08),math.floor(size*.25),color,stroke);line(.12,.12,.36,.36)
    end
end
function A.card(bb,a,x,y,w,h,selected)
    local radius=a:s(7)
    bb:paintRoundedRect(x,y,w,h,BB.Color8(selected and 235 or 248),radius)
    bb:paintBorder(x,y,w,h,math.max(1,a:s(.65)),BB.Color8(selected and 165 or 223),radius,true)
    if selected then bb:paintRoundedRect(x+a:s(1),y+a:s(12),a:s(3),h-a:s(24),BB.COLOR_BLACK,a:s(1))end
end
function A.button(bb,a,text,x,y,w,h,active,disabled)
    local icon=icons[text];local radius=a:s(8)
    bb:paintRoundedRect(x,y,w,h,active and BB.COLOR_BLACK or BB.Color8(248),radius)
    if not active then bb:paintBorder(x,y,w,h,math.max(1,a:s(.7)),BB.Color8(disabled and 225 or 175),radius,true)end
    if icon then A.icon(bb,icon,x+w/2,y+h/2,a:s(21),disabled and BB.Color8(170) or active and BB.COLOR_WHITE or BB.COLOR_BLACK,a:s(1.6))
    else a:centerLabel(bb,text,x,y,w,h,13,true,active)end
end
return A
