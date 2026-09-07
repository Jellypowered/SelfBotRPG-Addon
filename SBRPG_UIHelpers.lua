-- Reusable WotLK-safe widgets and validation helpers.
SBRPG = SBRPG or {}
local T=SBRPG.Theme
function SBRPG.Tooltip(frame,title,lines)
    frame:SetScript("OnEnter",function(self)
        GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText(title or "SelfBot RPG",T.goldLight[1],T.goldLight[2],T.goldLight[3])
        if type(lines)=="function" then lines=lines() end
        if type(lines)=="string" then GameTooltip:AddLine(lines,.8,.8,.8,true) else for _,line in ipairs(lines or {}) do GameTooltip:AddLine(line,.8,.8,.8,true) end end
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave",function()GameTooltip:Hide()end)
end
function SBRPG.StyleInput(box)
    box:SetFontObject(GameFontHighlightSmall);box:SetBackdrop({bgFile="Interface\\Tooltips\\UI-Tooltip-Background",edgeFile="Interface\\Tooltips\\UI-Tooltip-Border",edgeSize=8,insets={left=3,right=3,top=3,bottom=3}});box:SetBackdropColor(0,0,0,.9);box:SetBackdropBorderColor(.35,.35,.38,1);box:SetTextInsets(5,5,0,0)
end
function SBRPG.CreateLabel(parent,text,x,y,width)
    local fs=parent:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");fs:SetPoint("TOPLEFT",x,y);if width then fs:SetWidth(width) end;fs:SetJustifyH("LEFT");fs:SetText(text);fs:SetTextColor(unpack(T.white));return fs
end
function SBRPG.CreateInput(parent,label,x,y,width,value,numeric,tooltip)
    local caption=SBRPG.CreateLabel(parent,label,x,y,width)
    local box=CreateFrame("EditBox",nil,parent);box:SetSize(width,22);box:SetPoint("TOPLEFT",x,y-18);box:SetAutoFocus(false);if numeric then box:SetNumeric(true) end;box:SetText(tostring(value or ""));SBRPG.StyleInput(box)
    if tooltip then SBRPG.Tooltip(box,label,tooltip) end
    box:SetScript("OnEscapePressed",function(self)self:ClearFocus()end);box:SetScript("OnEnterPressed",function(self)self:ClearFocus()end)
    return box,caption
end
function SBRPG.CreateButton(parent,text,width,x,y,callback)
    local b=CreateFrame("Button",nil,parent,"UIPanelButtonTemplate");b:SetSize(width or 120,24);b:SetPoint("TOPLEFT",x,y);b:SetText(text);b:SetScript("OnClick",callback);return b
end
function SBRPG.SetEnabled(button,enabled,reason)
    button.disabledReason=reason
    if enabled then button:Enable();button:SetAlpha(1) else button:Disable();button:SetAlpha(.45) end
end
function SBRPG.CreateCheck(parent,text,x,y,checked,tooltip)
    local c=CreateFrame("CheckButton",nil,parent,"UICheckButtonTemplate");c:SetPoint("TOPLEFT",x,y);c:SetChecked(checked and true or false)
    c.text=c:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");c.text:SetPoint("LEFT",c,"RIGHT",2,1);c.text:SetText(text);if tooltip then SBRPG.Tooltip(c,text,tooltip) end;return c
end
function SBRPG.Number(text,min,max,label)
    local value=tonumber(text);if not value or value<min or value>max then return nil,(label or "Value").." must be "..min.."–"..max.."." end;return value
end
function SBRPG.ShowItemTooltip(owner,row,extra)
    GameTooltip:SetOwner(owner,"ANCHOR_RIGHT")
    if row and row.itemId and row.itemId>0 and GameTooltip.SetHyperlink then GameTooltip:SetHyperlink("item:"..row.itemId..":0:0:0:0:0:0:0") else GameTooltip:SetText(row and row.name or "Unknown item",1,.82,.22) end
    if extra then GameTooltip:AddLine(extra,.72,.82,.95,true) end;GameTooltip:Show()
end
SBRPG._scrollListSerial=SBRPG._scrollListSerial or 0
function SBRPG.CreateScrollList(parent,x,y,width,height,rowHeight)
    -- UIPanelScrollFrameTemplate's WotLK OnLoad looks up named scrollbar
    -- children from the scroll frame's global name; anonymous frames error.
    SBRPG._scrollListSerial=SBRPG._scrollListSerial+1
    local name="SBRPGScrollList"..SBRPG._scrollListSerial
    local scroll=CreateFrame("ScrollFrame",name,parent,"UIPanelScrollFrameTemplate");scroll:SetPoint("TOPLEFT",x,y);scroll:SetSize(width,height);scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel",function(self,delta)self:SetVerticalScroll(math.max(0,math.min(self:GetVerticalScrollRange(),self:GetVerticalScroll()-delta*(rowHeight or 24)*3)))end)
    local child=CreateFrame("Frame",name.."Child",scroll);child:SetWidth(width-28);child:SetHeight(1);scroll:SetScrollChild(child);return scroll,child
end
function SBRPG.CreateDropdown(parent,name,x,y,width,items,onSelect)
    local frame=CreateFrame("Frame",name,parent,"UIDropDownMenuTemplate");frame:SetPoint("TOPLEFT",x-16,y+8);UIDropDownMenu_SetWidth(frame,width)
    frame.items=items or {};frame.onSelect=onSelect
    UIDropDownMenu_Initialize(frame,function()
        for _,entry in ipairs(frame.items or {}) do local info=UIDropDownMenu_CreateInfo();info.text=entry.label or entry.value;info.value=entry.value;info.checked=frame.value==entry.value;info.func=function()frame.value=entry.value;UIDropDownMenu_SetText(frame,entry.label or entry.value);if frame.onSelect then frame.onSelect(entry.value) end end;UIDropDownMenu_AddButton(info) end
    end)
    function frame:SetValue(value,label) self.value=value;UIDropDownMenu_SetText(self,label or value) end
    function frame:SetItems(items2) self.items=items2 or {} end
    return frame
end
