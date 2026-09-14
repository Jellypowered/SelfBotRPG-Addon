-- Persistent minimap launcher via LibDBIcon, matching PBAltManager.
SBRPG = SBRPG or {}
SelfBotRPGDB = SelfBotRPGDB or {}
SelfBotRPGDB.Minimap = SelfBotRPGDB.Minimap or {}
SelfBotRPGMinimapDB = SelfBotRPGMinimapDB or { hide = false, minimapPos = 225 }

-- SelfBotRPGDB.Minimap is the table already used by the released addon and
-- confirmed to contain the user's saved position. Keep it authoritative for
-- LibDBIcon; the per-character table is only a compatibility mirror.
local db = SelfBotRPGDB.Minimap
if db.minimapPos == nil then db.minimapPos = tonumber(db.angle or SelfBotRPGDB.minimapPos or SelfBotRPGDB.minimapAngle) or 225 end
if db.hidden == nil then db.hidden = false end

local function SyncConfig()
    db.minimapPos = tonumber(db.minimapPos) or 225
    db.angle = db.minimapPos
    db.hidden = db.hidden and true or false
    SelfBotRPGMinimapDB.minimapPos = db.minimapPos
    SelfBotRPGMinimapDB.hide = db.hidden
end
SyncConfig()

local dbicon = LibStub("LibDBIcon-1.0", true)
local ldb = LibStub("LibDataBroker-1.1", true)
if not dbicon or not ldb then
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[SBRPG]|r LibDBIcon is unavailable; minimap launcher disabled.") end
    return
end

local launcher = ldb:NewDataObject("SelfBotRPG", {
    type = "launcher",
    text = "SelfBot RPG",
    icon = "Interface\\Icons\\INV_Pick_02",
    OnClick = function(_, button)
        if button == "RightButton" then SBRPG.ToggleWindow("settings") else SBRPG.ToggleWindow() end
    end,
    OnTooltipShow = function(tooltip)
        tooltip:AddLine("|cffE6C45ASelfBot RPG|r")
        tooltip:AddLine("Left-click: toggle control window", 1, 1, 1)
        tooltip:AddLine("Right-click: open Settings", .7, .7, .7)
        tooltip:AddLine("Drag: reposition", .7, .7, .7)
    end,
})
dbicon:Register("SelfBotRPG", launcher, db)
local iconButton = dbicon.objects and dbicon.objects["SelfBotRPG"]
if iconButton and iconButton.HookScript then
    iconButton:HookScript("OnDragStop", function()
        -- LibDBIcon writes minimapPos during its OnUpdate. Copy it again at
        -- the exact release boundary so logout cannot race the final update.
        if iconButton.db and iconButton.db.minimapPos ~= nil then
            db.minimapPos = tonumber(iconButton.db.minimapPos) or db.minimapPos
            SyncConfig()
        end
    end)
end

function SBRPG.SetMinimapHidden(hidden)
    db.hidden = hidden and true or false
    SyncConfig()
    if db.hidden then dbicon:Hide("SelfBotRPG") else dbicon:Show("SelfBotRPG") end
    dbicon:Refresh("SelfBotRPG", db)
end

local syncFrame = CreateFrame("Frame")
syncFrame:RegisterEvent("PLAYER_LOGIN")
syncFrame:RegisterEvent("PLAYER_LOGOUT")
syncFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then
        db.minimapPos = tonumber(SelfBotRPGDB.Minimap.minimapPos) or db.minimapPos or 225
        dbicon:Refresh("SelfBotRPG", db)
    elseif event == "PLAYER_LOGOUT" then
        if iconButton and iconButton.db and iconButton.db.minimapPos ~= nil then
            db.minimapPos = tonumber(iconButton.db.minimapPos) or db.minimapPos
        end
    end
    SyncConfig()
end)

-- LibDBIcon updates db.minimapPos during drag; mirror it to the account DB.
local syncTicker = CreateFrame("Frame")
syncTicker:SetScript("OnUpdate", function(self, elapsed)
    self.t = (self.t or 0) + elapsed
    if self.t < 0.5 then return end
    self.t = 0
    SyncConfig()
end)
