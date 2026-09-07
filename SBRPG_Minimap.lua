-- Dependency-free persistent minimap launcher.
SBRPG = SBRPG or {}
local db=SelfBotRPGDB.Minimap
local button=CreateFrame("Button","SelfBotRPGMinimapButton",Minimap);button:SetSize(32,32);button:SetMovable(true);button:EnableMouse(true);button:SetFrameStrata("MEDIUM");button:SetFrameLevel(Minimap:GetFrameLevel()+8);button:RegisterForClicks("LeftButtonUp","RightButtonUp");button:RegisterForDrag("LeftButton")
local bg=button:CreateTexture(nil,"BACKGROUND");bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background");bg:SetSize(20,20);bg:SetPoint("CENTER",0,1)
local icon=button:CreateTexture(nil,"ARTWORK");icon:SetTexture("Interface\\Icons\\INV_Pick_02");icon:SetSize(18,18);icon:SetPoint("CENTER",0,1);icon:SetTexCoord(.08,.92,.08,.92)
local border=button:CreateTexture(nil,"OVERLAY");border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder");border:SetSize(54,54);border:SetPoint("TOPLEFT")
local highlight=button:CreateTexture(nil,"HIGHLIGHT");highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight");highlight:SetBlendMode("ADD");highlight:SetAllPoints()
local function Place()local angle=math.rad(tonumber(db.angle) or 225);button:ClearAllPoints();button:SetPoint("CENTER",Minimap,"CENTER",math.cos(angle)*80,math.sin(angle)*80);if db.hidden then button:Hide() else button:Show() end end
local moved=false;button:SetScript("OnMouseDown",function()moved=false end);button:SetScript("OnDragStart",function(self)moved=true;self:SetScript("OnUpdate",function()local mx,my=Minimap:GetCenter();local x,y=GetCursorPosition();local scale=Minimap:GetEffectiveScale();db.angle=math.deg(math.atan2(y/scale-my,x/scale-mx));Place()end)end);button:SetScript("OnDragStop",function(self)self:SetScript("OnUpdate",nil);Place()end)
button:SetScript("OnClick",function(_,mouse)if moved then return end;if mouse=="RightButton" then SBRPG.ToggleWindow("settings") else SBRPG.ToggleWindow() end end)
SBRPG.Tooltip(button,"SelfBot RPG",{"Left-click: toggle control window","Right-click: open Settings","Drag: reposition"})
function SBRPG.SetMinimapHidden(hidden)db.hidden=hidden and true or false;Place()end
Place()
