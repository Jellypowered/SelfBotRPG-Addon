-- Persistent minimap launcher via LibDBIcon, matching PBAltManager.
SBRPG = SBRPG or {}

-- Define placeholder tables that will be overwritten or populated when data loads
local db 
SelfBotRPGMinimapDB = SelfBotRPGMinimapDB or { hide = false, minimapPos = 225 }

local function SyncConfig()
    if not db then return end -- Don't run until data is safely loaded
    db.minimapPos = tonumber(db.minimapPos) or 225
    db.angle = db.minimapPos
    db.hidden = db.hidden and true or false
    SelfBotRPGMinimapDB.minimapPos = db.minimapPos
    SelfBotRPGMinimapDB.hide = db.hidden
end

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

-- We register the icon later inside PLAYER_LOGIN once the db reference is stable
local iconButton

function SBRPG.SetMinimapHidden(hidden)
    if not db then return end
    db.hidden = hidden and true or false
    SyncConfig()
    if db.hidden then dbicon:Hide("SelfBotRPG") else dbicon:Show("SelfBotRPG") end
    dbicon:Refresh("SelfBotRPG", db)
end

local syncFrame = CreateFrame("Frame")
syncFrame:RegisterEvent("ADDON_LOADED")
syncFrame:RegisterEvent("PLAYER_LOGIN")
syncFrame:RegisterEvent("PLAYER_LOGOUT")

syncFrame:SetScript("OnEvent", function(_, event, arg1)
    -- 1. Safely anchor your data structure here
    if event == "ADDON_LOADED" and arg1 == "SelfBotRPG" then 
        -- Initialize missing sub-tables securely without wiping existing ones
        SelfBotRPGDB = SelfBotRPGDB or {}
        SelfBotRPGDB.Minimap = SelfBotRPGDB.Minimap or {}
        
        -- Now point db to the live, loaded SavedVariable table
        db = SelfBotRPGDB.Minimap
        
        -- Run your initial migration checks safely on the actual loaded data
        if db.minimapPos == nil then db.minimapPos = tonumber(db.angle or SelfBotRPGDB.minimapPos or SelfBotRPGDB.minimapAngle) or 225 end
        if db.hidden == nil then db.hidden = false end
        
        SyncConfig()
        
    -- 2. Bind the active configuration table directly to LibDBIcon
    elseif event == "PLAYER_LOGIN" then
        if db then
            dbicon:Register("SelfBotRPG", launcher, db)
            iconButton = dbicon.objects and dbicon.objects["SelfBotRPG"]
            
            if iconButton and iconButton.HookScript then
                iconButton:HookScript("OnDragStop", function()
                    if iconButton.db and iconButton.db.minimapPos ~= nil then
                        db.minimapPos = tonumber(iconButton.db.minimapPos) or db.minimapPos
                        SyncConfig()
                    end
                end)
            end
            dbicon:Refresh("SelfBotRPG", db)
        end
        
    -- 3. Save parameters gracefully on exit
    elseif event == "PLAYER_LOGOUT" then
        if db and iconButton and iconButton.db and iconButton.db.minimapPos then
            db.minimapPos = tonumber(iconButton.db.minimapPos) or db.minimapPos
            SyncConfig()
        end
    end
end)

-- Mirror variables smoothly via background frames
local syncTicker = CreateFrame("Frame")
syncTicker:SetScript("OnUpdate", function(self, elapsed)
    self.t = (self.t or 0) + elapsed
    if self.t < 0.5 then return end
    self.t = 0
    SyncConfig()
end)

