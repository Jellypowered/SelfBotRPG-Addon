-- Main browser-like frame, tab registry, footer, and shared confirmation dialog.
SBRPG = SBRPG or {}
local T=SBRPG.Theme
local db=SelfBotRPGDB.Window
local frame=CreateFrame("Frame","SelfBotRPGFrame",UIParent)
SBRPG.MainWindow=frame;frame:SetSize(720,540);frame:SetFrameStrata("HIGH");frame:SetMovable(true);frame:EnableMouse(true);frame:RegisterForDrag("LeftButton");SBRPG.ApplyBackdrop(frame,false)
if db.x and db.y then frame:SetPoint("CENTER",UIParent,"BOTTOMLEFT",db.x,db.y) else frame:SetPoint("CENTER") end
frame:SetScript("OnDragStart",function(self)self:StartMoving()end)
frame:SetScript("OnDragStop",function(self)self:StopMovingOrSizing();local x,y=self:GetCenter();local scale=UIParent:GetEffectiveScale() or 1;db.x=x*scale;db.y=y*scale end)
frame:Hide()

local title=frame:CreateFontString(nil,"OVERLAY","GameFontNormalLarge");title:SetPoint("TOPLEFT",18,-14);title:SetText("SelfBot RPG");title:SetTextColor(unpack(T.goldLight))
local version=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");version:SetPoint("LEFT",title,"RIGHT",8,0);version:SetText("v"..SBRPG.Version);version:SetTextColor(unpack(T.dim))
local close=CreateFrame("Button",nil,frame,"UIPanelCloseButton");close:SetPoint("TOPRIGHT",1,1)
local connection=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");connection:SetPoint("RIGHT",close,"LEFT",-8,0);connection:SetText("Disconnected")
local dot=frame:CreateTexture(nil,"OVERLAY");dot:SetSize(8,8);dot:SetPoint("RIGHT",connection,"LEFT",-5,0);dot:SetTexture("Interface\\Buttons\\WHITE8x8")

local tabBar=CreateFrame("Frame",nil,frame);tabBar:SetPoint("TOPLEFT",12,-42);tabBar:SetPoint("TOPRIGHT",-12,-42);tabBar:SetHeight(30)
local content=CreateFrame("Frame",nil,frame);content:SetPoint("TOPLEFT",12,-72);content:SetPoint("BOTTOMRIGHT",-12,54);SBRPG.ApplyBackdrop(content,true)
local footerLine=frame:CreateTexture(nil,"OVERLAY");footerLine:SetPoint("BOTTOMLEFT",12,48);footerLine:SetPoint("BOTTOMRIGHT",-12,48);footerLine:SetHeight(1);footerLine:SetTexture("Interface\\Buttons\\WHITE8x8");footerLine:SetVertexColor(T.gold[1],T.gold[2],T.gold[3],.45)
local footer=frame:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");footer:SetPoint("BOTTOMLEFT",18,18);footer:SetPoint("BOTTOMRIGHT",-150,18);footer:SetHeight(24);footer:SetJustifyH("LEFT");footer:SetJustifyV("MIDDLE");footer:SetText("Waiting for status…")
local stop=SBRPG.CreateButton(frame,"Stop Current",120,582,-497,function()
    if not SBRPG.State.bridgeReady then SBRPG.Connect();return end
    if not SBRPG.HasCapability("STOP") then SBRPG.SetStatus("warning","Stop is not supported by this server.",{category="protocol"});return end
    SBRPG.Send("STOP",{})
end)
stop:ClearAllPoints();stop:SetPoint("BOTTOMRIGHT",-18,14);SBRPG.Tooltip(stop,"Stop current activity",function()return stop.disabledReason or "Stop the active run and let the server restore normal playerbot strategies." end)
SBRPG.StatusFooter=footer;SBRPG.StopButton=stop

function SBRPG.UpdateStatusUI()
    local ready=SBRPG.State.bridgeReady;connection:SetText(ready and "Connected" or "Disconnected");local c=ready and T.green or T.red;connection:SetTextColor(unpack(c));dot:SetVertexColor(unpack(c))
    local state=SBRPG.State.status or {kind="info",text="Waiting for status…"};footer:SetText(state.text);footer:SetTextColor(unpack(SBRPG.ColorForStatus(state.kind)))
    SBRPG.SetEnabled(stop,ready and SBRPG.HasCapability("STOP"),ready and "Server does not advertise STOP." or "Protocol is disconnected.")
end
function SBRPG.NotifyTabs(method,...)
    for _,tab in pairs(SBRPG.Tabs) do if tab.panel and tab.panel[method] then tab.panel[method](tab.panel,...) end end
end
local function LayoutTabs()
    local ordered={};for _,tab in pairs(SBRPG.Tabs) do if not tab.hidden then table.insert(ordered,tab) end end;table.sort(ordered,function(a,b)return a.order<b.order end)
    local width=math.floor((tabBar:GetWidth()>0 and tabBar:GetWidth() or 696)/math.max(7,#ordered));width=math.max(82,math.min(112,width))
    for i,tab in ipairs(ordered) do tab.button:ClearAllPoints();tab.button:SetPoint("TOPLEFT",(i-1)*(width+2),0);tab.button:SetSize(width,28) end
end
function SBRPG.UpdateTabHighlights()
    for id,tab in pairs(SBRPG.Tabs) do local active=id==SBRPG.ActiveTab;tab.button:SetAlpha(active and 1 or .62);tab.line:SetVertexColor(T.gold[1],T.gold[2],T.gold[3],active and 1 or 0);tab.bg:SetVertexColor(active and .17 or .06,active and .14 or .07,active and .07 or .10,1) end
end
function SBRPG.RegisterTab(id,label,order,buildFunc,options)
    if SBRPG.Tabs[id] then return SBRPG.Tabs[id] end
    local tab={id=id,label=label,order=order,hidden=options and options.hidden};SBRPG.Tabs[id]=tab
    local button=CreateFrame("Button",nil,tabBar);tab.button=button;button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight","ADD")
    tab.bg=button:CreateTexture(nil,"BACKGROUND");tab.bg:SetAllPoints();tab.bg:SetTexture("Interface\\Buttons\\WHITE8x8")
    tab.line=button:CreateTexture(nil,"OVERLAY");tab.line:SetPoint("BOTTOMLEFT",1,1);tab.line:SetPoint("BOTTOMRIGHT",-1,1);tab.line:SetHeight(3);tab.line:SetTexture("Interface\\Buttons\\WHITE8x8")
    local text=button:CreateFontString(nil,"OVERLAY","GameFontNormalSmall");text:SetAllPoints();text:SetText(label);text:SetTextColor(unpack(T.goldLight))
    button:SetScript("OnClick",function()SBRPG.SelectTab(id)end)
    local panel=CreateFrame("Frame",nil,content);panel:SetAllPoints();panel:Hide();tab.panel=panel
    buildFunc(panel);LayoutTabs();return tab
end
function SBRPG.SelectTab(id)
    local tab=SBRPG.Tabs[id];if not tab or tab.hidden then return end
    for _,entry in pairs(SBRPG.Tabs) do if entry.panel then entry.panel:Hide() end end
    SBRPG.ActiveTab=id;db.activeTab=id;tab.panel:Show();SBRPG.UpdateTabHighlights();if tab.panel.OnShowTab then tab.panel:OnShowTab() end
end
function SBRPG.ShowConfirm(message,callback)
    if not SBRPG.ConfirmFrame then
        local f=CreateFrame("Frame",nil,UIParent);f:SetSize(370,130);f:SetPoint("CENTER");f:SetFrameStrata("DIALOG");SBRPG.ApplyBackdrop(f,false)
        local text=f:CreateFontString(nil,"OVERLAY","GameFontHighlight");text:SetPoint("TOPLEFT",18,-24);text:SetPoint("TOPRIGHT",-18,-24);text:SetHeight(48);text:SetJustifyH("CENTER");text:SetWordWrap(true);f.text=text
        local yes=SBRPG.CreateButton(f,YES,105,52,-88,function()local cb=f.callback;f.callback=nil;f:Hide();if cb then cb() end end);yes:ClearAllPoints();yes:SetPoint("BOTTOMLEFT",58,14)
        local no=SBRPG.CreateButton(f,NO,105,200,-88,function()f.callback=nil;f:Hide()end);no:ClearAllPoints();no:SetPoint("BOTTOMRIGHT",-58,14);SBRPG.ConfirmFrame=f;f:Hide()
    end
    SBRPG.ConfirmFrame.text:SetText(message);SBRPG.ConfirmFrame.callback=callback;SBRPG.ConfirmFrame:Show();SBRPG.ConfirmFrame:Raise()
end
frame:SetScript("OnShow",function()if not SBRPG.ActiveTab then SBRPG.SelectTab(db.activeTab or "gathering") end;SBRPG.RequestStatus(false);SBRPG.UpdateStatusUI()end)
frame:SetScript("OnHide",function()for _,tab in pairs(SBRPG.Tabs) do if tab.panel and tab.panel.OnHideTab then tab.panel:OnHideTab() end end end)
frame:EnableKeyboard(true);frame:SetScript("OnKeyDown",function(self,key)if key=="ESCAPE" then self:Hide();if self.SetPropagateKeyboardInput then self:SetPropagateKeyboardInput(false) end end end)
SBRPG.UpdateStatusUI()
