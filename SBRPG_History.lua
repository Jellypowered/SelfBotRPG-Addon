-- Persistent bounded status history.
SBRPG = SBRPG or {}
SBRPG.History = SBRPG.History or {}
local H=SBRPG.History
local MAX=100
local db=SelfBotRPGDB.History

local function Normalize()
    local normalized={}
    for _,entry in ipairs(db.entries or {}) do
        if type(entry)=="table" and entry.text then table.insert(normalized,{time=tostring(entry.time or "--:--:--"),kind=tostring(entry.kind or "info"),text=tostring(entry.text):sub(1,500),category=tostring(entry.category or "activity")}) end
    end
    while #normalized>MAX do table.remove(normalized,1) end
    db.entries=normalized
end
Normalize()
function H.Entries() return db.entries end
function H.Append(kind,text,metadata)
    if db.enabled==false or text=="" then return end
    if kind=="debug" and not (SelfBotRPGDB.Settings and tostring(SelfBotRPGDB.Settings.debug or "0")=="1") then return end
    local category=(metadata and metadata.category) or ((kind=="error") and "errors" or ((kind=="debug") and "debug" or "activity"))
    local last=db.entries[#db.entries]
    if last and last.kind==kind and last.text==text and last.category==category then return end
    table.insert(db.entries,{time=date and date("%H:%M:%S") or "--:--:--",kind=kind,text=tostring(text):sub(1,500),category=category})
    while #db.entries>MAX do table.remove(db.entries,1) end
    if SBRPG.RefreshHistory then SBRPG.RefreshHistory(true) end
end
function H.Clear() db.entries={} if SBRPG.RefreshHistory then SBRPG.RefreshHistory(false) end end
function H.Count() return #db.entries end
