-- JLYRPG2 transport, correlation, capability negotiation, and typed state updates.
SBRPG = SBRPG or {}
local State=SBRPG.State
local Data=SBRPG.Data
local PREFIX="JLYRPG2"
local nextRequestId=0
local lastStatusRequest=0
State.pending=State.pending or {}

function SBRPG.HasCapability(name) return State.capabilities[name]==true end
local function Split(message)
    local fields={};for field in string.gmatch(tostring(message or "").."\t","(.-)\t") do table.insert(fields,field) end;return fields
end
function SBRPG.Send(opcode,fields,callback)
    nextRequestId=(nextRequestId%999999999)+1
    local requestId=nextRequestId;local payload="1\t"..opcode.."\t"..requestId
    for _,field in ipairs(fields or {}) do payload=payload.."\t"..tostring(field) end
    local channel,target="WHISPER",UnitName("player")
    if GetNumRaidMembers and GetNumRaidMembers()>0 then channel,target="RAID",nil elseif GetNumPartyMembers and GetNumPartyMembers()>0 then channel,target="PARTY",nil end
    if callback then State.pending[tostring(requestId)]={callback=callback,started=GetTime and GetTime() or 0} end
    SendAddonMessage(PREFIX,payload,channel,target);return requestId
end
function SBRPG.Connect()
    State.bridgeReady=false;SBRPG.SetStatus("warning","Connecting to SelfBot RPG server…",{category="protocol"});SBRPG.Send("HELLO",{})
end
function SBRPG.RequestStatus(force)
    local now=GetTime and GetTime() or 0;if not force and now-lastStatusRequest<2 then return end;lastStatusRequest=now
    if not State.bridgeReady then SBRPG.Connect();return end
    if SBRPG.HasCapability("STATUS") then SBRPG.Send("STATUS",{}) else SBRPG.Send("STATUS",{}) end
    if SBRPG.HasCapability("MATERIAL_STATUS") then SBRPG.Send("MATERIAL_STATUS",{}) end
end
function SBRPG.RequestMaterialStatus(force) if not State.bridgeReady then SBRPG.Connect() elseif SBRPG.HasCapability("MATERIAL_STATUS") then SBRPG.Send("MATERIAL_STATUS",{}) elseif force then SBRPG.SetStatus("warning","Material status is not supported by this server.",{category="protocol"}) end end
function SBRPG.RequestMaterialSources(row)
    if not row or not State.bridgeReady or not SBRPG.HasCapability("MATERIAL_SOURCES") then return end
    local key=tostring(row.name);Data.SourceCounts[key]={received=0,total=0,pending=true}
    State.sourceRequest=SBRPG.Send("MATERIAL_SOURCES",{"material",row.name});State.sourceName=key
end
function SBRPG.RefreshCapabilityControls() SBRPG.NotifyTabs("OnCapabilitiesUpdated",State.capabilities);if SBRPG.UpdateStatusUI then SBRPG.UpdateStatusUI() end end

local function ParseCapabilities(parts)
    State.bridgeReady=true;State.capabilities={}
    for capability in string.gmatch(parts[5] or "","[^,]+") do State.capabilities[capability]=true end
    SBRPG.SetStatus("success","Protocol connected.",{category="protocol"});SBRPG.RefreshCapabilityControls()
    if SBRPG.ApplySavedSettings then SBRPG.ApplySavedSettings() end
    if SBRPG.HasCapability("MATERIAL_CATALOG") then SBRPG.Send("MATERIAL_CATALOG",{}) end
    SBRPG.RequestStatus(true)
end
local function ParseCatalog(parts)
    local requestId,index,total,itemId,key,displayName,family,methods=unpack(parts,3);index=tonumber(index) or 0;total=tonumber(total) or 0
    if index==0 then Data.ResetCatalog() end
    if tonumber(itemId) and tonumber(itemId)>0 then Data.AddMaterial({itemId=itemId,key=key,name=displayName or key,family=family,methods=methods}) end
    if total>0 and index+1>=total then Data.CatalogComplete=true;SBRPG.NotifyTabs("OnCatalogUpdated",Data.Materials) end
end
local function FormatDuration(seconds)
    seconds=math.max(0,tonumber(seconds) or 0);local h=math.floor(seconds/3600);local m=math.floor((seconds%3600)/60);local s=seconds%60
    if h>0 then return string.format("%dh %dm %ds",h,m,s) elseif m>0 then return string.format("%dm %ds",m,s) end;return string.format("%ds",s)
end
local function ParseStatus(parts)
    local active,phase,reason,profession,nodes,gathers,items,perMin,perSec,target,durationSec,remainingSec=unpack(parts,3)
    State.activity={mode="gathering",active=active=="1",phase=phase,reason=reason,profession=profession,nodes=nodes,gathers=gathers,items=items,perMin=perMin,perSec=perSec,target=target,duration=durationSec,remaining=remainingSec}
    if active~="1" then SBRPG.SetStatus("info","SelfBot RPG: "..((reason and reason~="") and reason or "idle"),{category="activity"});return end
    local timer=(tonumber(durationSec) or 0)>0 and (" | "..FormatDuration(remainingSec).." left") or "";local why=(reason and reason~="") and (" — "..reason) or "";local targetText=(target and target~="0") and (" | target "..target) or ""
    SBRPG.SetStatus("info",tostring(phase or "Farming")..why.." | "..tostring(profession or "")..": "..tostring(nodes or 0).." nodes | "..tostring(gathers or 0).." gathers / "..tostring(items or 0).." items | "..tostring(perMin or 0).."/min "..tostring(perSec or 0).."/sec"..timer..targetText,{category="activity"})
end
local function ParseMaterialStatus(parts)
    local requestId,active,itemId,gathered,goal,kills,remaining,harvest,phase=unpack(parts,3)
    State.material={active=active=="1",itemId=tonumber(itemId) or 0,gathered=tonumber(gathered) or 0,goal=tonumber(goal) or 0,kills=tonumber(kills) or 0,remaining=tonumber(remaining) or 0,harvest=harvest,phase=phase}
    if active~="1" then return end
    local goalText=State.material.goal>0 and (" / "..State.material.goal) or ""
    SBRPG.SetStatus("info","Material "..State.material.itemId..": "..State.material.gathered..goalText.." items | "..State.material.kills.." kills | "..FormatDuration(State.material.remaining).." remaining"..((phase and phase~="") and (" | "..phase) or ""),{category="activity"})
end
local function HandleMessage(message)
    local parts=Split(message);if parts[1]~="1" then return end;local opcode=parts[2]
    if opcode=="HELLO_ACK" then State.bridgeReady=true;SBRPG.SetStatus("success","Protocol connected; waiting for capabilities.",{category="protocol"})
    elseif opcode=="CAPABILITIES" then ParseCapabilities(parts)
    elseif opcode=="MATERIAL_CATALOG" then ParseCatalog(parts)
    elseif opcode=="MATERIAL_SOURCE" then local requestId,index,total=unpack(parts,3);if tostring(requestId)==tostring(State.sourceRequest) then local s=Data.SourceCounts[State.sourceName] or {};s.received=(s.received or 0)+1;s.total=tonumber(total) or 0;s.pending=true;Data.SourceCounts[State.sourceName]=s end
    elseif opcode=="MATERIAL_SOURCES_END" then local requestId,total=unpack(parts,3);if tostring(requestId)==tostring(State.sourceRequest) then local s=Data.SourceCounts[State.sourceName] or {};s.total=tonumber(total) or s.total or 0;s.pending=false;Data.SourceCounts[State.sourceName]=s;SBRPG.NotifyTabs("OnSourcesUpdated",State.sourceName,s);if s.total==0 then SBRPG.SetStatus("warning",State.sourceName..": no indexed sources.",{category="activity"}) end end
    elseif opcode=="STATUS" then ParseStatus(parts)
    elseif opcode=="MATERIAL_STATUS" then ParseMaterialStatus(parts)
    elseif opcode=="SETTING" then local key,value=parts[3],parts[4];SelfBotRPGDB.Settings[key]=value;SBRPG.NotifyTabs("OnSettingUpdated",key,value);SBRPG.SetStatus("success","Applied "..tostring(key).." = "..tostring(value),{category="settings"})
    elseif opcode=="ACK" then State.bridgeReady=true;SBRPG.SetStatus("success",parts[4] or "Command accepted.",{category="activity"});SBRPG.RequestStatus(true)
    elseif opcode=="ERROR" then SBRPG.SetStatus("error","Error: "..tostring(parts[4] or parts[3] or "unknown"),{category="errors"})
    elseif opcode=="DEBUG" then SBRPG.SetStatus("debug",parts[3] or "",{category="debug"}) end
    local pending=State.pending[tostring(parts[3] or "")];if pending then State.pending[tostring(parts[3])]=nil;pending.callback(opcode,parts) end
end

local events=CreateFrame("Frame");events:RegisterEvent("PLAYER_LOGIN");events:RegisterEvent("CHAT_MSG_ADDON")
events:SetScript("OnEvent",function(_,event,prefix,message)
    if event=="PLAYER_LOGIN" then if RegisterAddonMessagePrefix then RegisterAddonMessagePrefix(PREFIX) end;SBRPG.Connect();return end
    if prefix==PREFIX then HandleMessage(message) end
end)
