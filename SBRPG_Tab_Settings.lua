-- Settings tab: grouped configuration with staged Apply/Revert/Defaults.
SBRPG = SBRPG or {}
local defaults={enable="1",debug="0",minchance="1.0",bagreserve="0",attempts="3",failedblacklist="120",emptyblacklist="120",zone="1",settledelay="1000",actiondelay="1000",bobbers="35591",uselures="1",prioritizepools="0",openwateronly="1",searchdistance="500.0",castdistance="12.0"}
local definitions={
 {section="General"},{key="enable",label="Module enabled",kind="bool",tip="Enable mod-selfbot-rpg."},{key="debug",label="Debug logging",kind="bool",tip="Show additional server diagnostics and retain DEBUG History entries."},{key="zone",label="Stay in starting zone",kind="bool",tip="Restrict local farming routes to the starting zone."},
 {section="Activity timing"},{key="actiondelay",label="Action delay",kind="number",min=100,max=10000,unit="ms",tip="Delay between SBRPG action checks."},{key="settledelay",label="Gather settle delay",kind="number",min=0,max=10000,unit="ms",tip="Wait after stock gather claims before evaluating completion."},
 {section="Failure handling"},{key="attempts",label="Attempts before blacklist",kind="number",min=1,max=10,tip="Bounded retries before a failed source cooldown."},{key="failedblacklist",label="Failed-node cooldown",kind="number",min=0,max=3600,unit="seconds",tip="Temporary cooldown after repeated node failure."},{key="emptyblacklist",label="Empty-node cooldown",kind="number",min=0,max=3600,unit="seconds",tip="Temporary cooldown after a confirmed empty node."},
 {section="Material and bags"},{key="minchance",label="Minimum loot chance",kind="decimal",min=0,max=100,unit="%",tip="Minimum indexed chance for material sources."},{key="bagreserve",label="Reserved bag space",kind="number",min=0,max=100,unit="%",tip="Stop before consuming this percentage of bag capacity."},
 {section="Fishing"},{key="bobbers",label="Fishing bobber entries",kind="text",tip="Comma-separated gameobject entries recognized as fishing bobbers."},{key="uselures",label="Use fishing lures",kind="bool",tip="Use an available lure when practical; lures remain optional."},{key="prioritizepools",label="Prioritize pools",kind="bool",tip="Prefer known fishing pools."},{key="openwateronly",label="Open water only",kind="bool",tip="Avoid routing between fishing pools."},{key="searchdistance",label="Fishing search distance",kind="decimal",min=60,max=2000,unit="yards",tip="Bound water/pool discovery."},{key="castdistance",label="Fishing cast distance",kind="decimal",min=5,max=25,unit="yards",tip="Bound shoreline cast-position selection."},
}
for key,value in pairs(defaults)do if SelfBotRPGDB.Settings[key]==nil then SelfBotRPGDB.Settings[key]=value end end
local controls,staged={},{}
local function LoadStaged(source)for key,value in pairs(source)do staged[key]=tostring(value)end end
LoadStaged(SelfBotRPGDB.Settings)
local function BoolValue(control)return control:GetChecked()and"1"or"0"end
local function Validate()
 for _,def in ipairs(definitions)do if def.key then local value=staged[def.key]or"";if def.kind=="number"or def.kind=="decimal"then local n=tonumber(value);if not n or n<def.min or n>def.max then return false,def.label.." must be "..def.min.."–"..def.max..(def.unit and(" "..def.unit)or"").."."end elseif def.kind=="text"and value==""then return false,def.label.." cannot be empty."end end end;return true
end
function SBRPG.ApplySavedSettings()
 if not SBRPG.State.bridgeReady or not SBRPG.HasCapability("SET_CONFIG")then return end
 for _,def in ipairs(definitions)do if def.key then SBRPG.Send("SET_CONFIG",{def.key,tostring(SelfBotRPGDB.Settings[def.key]or defaults[def.key])})end end
end
SBRPG.RegisterTab("settings","Settings",4,function(panel)
 SBRPG.CreateSectionHeader(panel,"Settings",-16);local hint=SBRPG.CreateLabel(panel,"Changes are staged locally. Apply sends validated values to the current server session.",16,-44,650);hint:SetTextColor(unpack(SBRPG.Theme.gray))
 local scroll,child=SBRPG.CreateScrollList(panel,16,-72,655,295,30);local y=0
 local dirty=SBRPG.CreateLabel(panel,"No unsaved changes",16,-378,130);dirty:SetTextColor(unpack(SBRPG.Theme.gray))
 local function UpdateDirty()local changed=false;for key,value in pairs(staged)do if tostring(value)~=tostring(SelfBotRPGDB.Settings[key]or defaults[key])then changed=true;break end end;dirty:SetText(changed and "Unsaved changes"or"No unsaved changes");dirty:SetTextColor(unpack(changed and SBRPG.Theme.amber or SBRPG.Theme.gray))end
 local function SyncControls()for _,def in ipairs(definitions)do if def.key then local c=controls[def.key];if def.kind=="bool"then c:SetChecked(staged[def.key]=="1")else c:SetText(staged[def.key]or defaults[def.key])end end end;UpdateDirty()end
 for _,def in ipairs(definitions)do
  if def.section then local h=child:CreateFontString(nil,"OVERLAY","GameFontNormal");h:SetPoint("TOPLEFT",4,-y);h:SetText(def.section);h:SetTextColor(unpack(SBRPG.Theme.gold));y=y+25
  elseif def.kind=="bool"then local c=SBRPG.CreateCheck(child,def.label,8,-y,staged[def.key]=="1",def.tip.." Default: "..defaults[def.key]);controls[def.key]=c;c:SetScript("OnClick",function(self)staged[def.key]=BoolValue(self);UpdateDirty()end);y=y+28
  else local label=SBRPG.CreateLabel(child,def.label,8,-y,300);local unit=child:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");unit:SetPoint("LEFT",label,"RIGHT",6,0);unit:SetText(def.unit or "");unit:SetTextColor(unpack(SBRPG.Theme.dim));local c=CreateFrame("EditBox",nil,child);c:SetSize(160,22);c:SetPoint("TOPRIGHT",-18,-y+4);c:SetAutoFocus(false);c:SetText(staged[def.key]or defaults[def.key]);if def.kind=="number"then c:SetNumeric(true)end;SBRPG.StyleInput(c);controls[def.key]=c;SBRPG.Tooltip(c,def.label,{def.tip,"Default: "..defaults[def.key],def.min and("Range: "..def.min.."–"..def.max..(def.unit and(" "..def.unit)or""))or""});c:SetScript("OnTextChanged",function(self)staged[def.key]=self:GetText();UpdateDirty()end);c:SetScript("OnEscapePressed",function(self)self:ClearFocus()end);y=y+30 end
 end;child:SetHeight(y+8)
 local apply=SBRPG.CreateButton(panel,"Apply",120,155,-375,function()local ok,err=Validate();if not ok then SBRPG.SetStatus("error",err,{category="errors"});return end;if not SBRPG.State.bridgeReady then SBRPG.Connect();return end;if not SBRPG.HasCapability("SET_CONFIG")then SBRPG.SetStatus("warning","Server does not support settings.",{category="protocol"});return end;local changed={};for key,value in pairs(staged)do if tostring(value)~=tostring(SelfBotRPGDB.Settings[key])then changed[key]=value end end;for key,value in pairs(changed)do SelfBotRPGDB.Settings[key]=value;SBRPG.Send("SET_CONFIG",{key,value})end;for _,key in ipairs({"attempts","failedblacklist","emptyblacklist","zone","settledelay"})do if changed[key]then SBRPG.Send("SET",{key,changed[key]})end end;UpdateDirty();SBRPG.SetStatus("success","Settings applied.",{category="settings"})end)
 local revert=SBRPG.CreateButton(panel,"Revert Unsaved",130,283,-375,function()LoadStaged(SelfBotRPGDB.Settings);SyncControls();SBRPG.SetStatus("info","Unsaved settings reverted.",{category="settings"})end)
 local reset=SBRPG.CreateButton(panel,"Reset Defaults",120,421,-375,function()LoadStaged(defaults);SyncControls();SBRPG.SetStatus("warning","Defaults loaded; press Apply to send them.",{category="settings"})end)
 SBRPG.Tooltip(apply,"Apply settings",function()return apply.disabledReason or"Validate and send changed settings."end);SBRPG.Tooltip(revert,"Revert unsaved","Restore the last applied values.");SBRPG.Tooltip(reset,"Reset defaults","Stage documented defaults without sending them yet.")
 function panel:OnSettingUpdated(_,key,value)SelfBotRPGDB.Settings[key]=value;staged[key]=value;SyncControls()end
 function panel:OnCapabilitiesUpdated()SBRPG.SetEnabled(apply,SBRPG.State.bridgeReady and SBRPG.HasCapability("SET_CONFIG"),"Server does not advertise SET_CONFIG.")end
 function panel:OnShowTab()LoadStaged(SelfBotRPGDB.Settings);SyncControls();panel:OnCapabilitiesUpdated()end
 panel:OnCapabilitiesUpdated();SyncControls()
end)
