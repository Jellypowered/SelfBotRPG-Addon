-- Dark/gold visual language inspired by PlayerbotManager and PBAltManager.
SBRPG = SBRPG or {}
SBRPG.Theme = {
    bg={0.04,0.05,0.08,0.97}, panel={0.075,0.075,0.10,0.96}, row={0.11,0.11,0.14,0.90},
    gold={0.83,0.69,0.22,1}, goldLight={0.94,0.82,0.42,1}, border={0.32,0.32,0.36,1},
    white={0.92,0.92,0.92,1}, gray={0.62,0.62,0.65,1}, dim={0.40,0.40,0.43,1},
    green={0.27,1.00,0.53,1}, amber={1.00,0.62,0.12,1}, red={1.00,0.25,0.25,1}, blue={0.40,0.75,1.00,1},
}
local T=SBRPG.Theme
function SBRPG.ApplyBackdrop(frame, panel)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8x8",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",tile=true,tileSize=8,edgeSize=12,insets={left=3,right=3,top=3,bottom=3}})
    local c=panel and T.panel or T.bg;frame:SetBackdropColor(c[1],c[2],c[3],c[4]);frame:SetBackdropBorderColor(unpack(T.border))
end
function SBRPG.CreateGoldLine(parent, y)
    local line=parent:CreateTexture(nil,"OVERLAY");line:SetPoint("TOPLEFT",12,y);line:SetPoint("TOPRIGHT",-12,y);line:SetHeight(1);line:SetTexture("Interface\\Buttons\\WHITE8x8");line:SetVertexColor(T.gold[1],T.gold[2],T.gold[3],.6);return line
end
function SBRPG.CreateSectionHeader(parent,text,y)
    local fs=parent:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");fs:SetPoint("TOPLEFT",16,y);fs:SetText(text);fs:SetTextColor(unpack(T.gold));SBRPG.CreateGoldLine(parent,y-18);return fs
end
function SBRPG.ColorForStatus(kind)
    if kind=="success" then return T.green elseif kind=="error" then return T.red elseif kind=="warning" then return T.amber elseif kind=="debug" then return T.blue end
    return T.white
end
