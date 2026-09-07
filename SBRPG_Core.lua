-- SelfBotRPG core: namespace, SavedVariables migration, lifecycle, and slash commands.
SBRPG = SBRPG or {}
SBRPG.Version = "0.3.0"
SBRPG.SchemaVersion = 2
SBRPG.State = SBRPG.State or { capabilities = {}, bridgeReady = false }
SBRPG.Tabs = SBRPG.Tabs or {}

SelfBotRPGDB = SelfBotRPGDB or {}

local function CopyMissing(target, source)
    if type(source) ~= "table" then return end
    for key, value in pairs(source) do
        if target[key] == nil then target[key] = value end
    end
end

function SBRPG.MigrateDatabase()
    local db = SelfBotRPGDB
    db.Window = type(db.Window) == "table" and db.Window or {}
    db.Gathering = type(db.Gathering) == "table" and db.Gathering or {}
    db.Material = type(db.Material) == "table" and db.Material or {}
    db.Fishing = type(db.Fishing) == "table" and db.Fishing or {}
    db.Settings = type(db.Settings) == "table" and db.Settings or {}
    db.History = type(db.History) == "table" and db.History or {}
    db.Minimap = type(db.Minimap) == "table" and db.Minimap or {}

    local old = type(db.Panel) == "table" and db.Panel or {}
    CopyMissing(db.Window, { x = old.x, y = old.y, activeTab = old.activeTab or "gathering" })
    CopyMissing(db.Gathering, {
        profession = old.profession or "mining",
        resource = old.resource or "Copper",
        duration = old.duration or "0",
    })
    CopyMissing(db.Material, {
        selectedName = old.material or "",
        search = old.search or "",
        duration = old.duration or "0",
        quantity = old.quantity or "0",
    })
    CopyMissing(db.Fishing, {
        selectedName = old.fishingTarget or "",
        search = "",
        duration = old.duration or "0",
        quantity = old.quantity or "0",
    })
    if db.Minimap.angle == nil then db.Minimap.angle = tonumber(db.minimapPos or db.minimapAngle) or 225 end
    if db.Minimap.hidden == nil then db.Minimap.hidden = false end
    if db.History.enabled == nil then db.History.enabled = true end
    db.History.entries = type(db.History.entries) == "table" and db.History.entries or {}
    db.SchemaVersion = SBRPG.SchemaVersion
end
SBRPG.MigrateDatabase()

local jobs = {}
local scheduler
function SBRPG.After(delay, callback)
    if type(callback) ~= "function" then return end
    if C_Timer and C_Timer.After then C_Timer.After(delay, callback); return end
    if not scheduler then
        scheduler = CreateFrame("Frame")
        scheduler:SetScript("OnUpdate", function(_, elapsed)
            for index = #jobs, 1, -1 do
                local job = jobs[index]
                job.remaining = job.remaining - elapsed
                if job.remaining <= 0 then
                    table.remove(jobs, index)
                    local ok, err = pcall(job.callback)
                    if not ok and DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cffff4444[SBRPG]|r " .. tostring(err)) end
                end
            end
        end)
    end
    table.insert(jobs, { remaining = tonumber(delay) or 0, callback = callback })
end

function SBRPG.Chat(text, color)
    if not DEFAULT_CHAT_FRAME then return end
    DEFAULT_CHAT_FRAME:AddMessage((color or "|cffd4b038") .. "[SelfBot RPG]|r " .. tostring(text or ""))
end

function SBRPG.SetStatus(kind, text, metadata)
    kind = kind or "info"
    text = tostring(text or "")
    SBRPG.State.status = { kind = kind, text = text, metadata = metadata }
    if SBRPG.History and SBRPG.History.Append then SBRPG.History.Append(kind, text, metadata) end
    if SBRPG.UpdateStatusUI then SBRPG.UpdateStatusUI() end
    if SBRPG.NotifyTabs then SBRPG.NotifyTabs("OnStatusUpdated", SBRPG.State.status) end
end

function SBRPG.ToggleWindow(tabId)
    if not SBRPG.MainWindow then return end
    if tabId then SBRPG.SelectTab(tabId) end
    if SBRPG.MainWindow:IsShown() and not tabId then SBRPG.MainWindow:Hide() else SBRPG.MainWindow:Show() end
end

SLASH_SELFBOTRPG1 = "/sbrpg"
SlashCmdList.SELFBOTRPG = function(text)
    text = tostring(text or "")
    if string.lower(text) == "material status" then
        SBRPG.ToggleWindow()
        if SBRPG.RequestMaterialStatus then SBRPG.RequestMaterialStatus(true) end
        return
    end
    SBRPG.ToggleWindow()
end

SLASH_SELFBOTRPGCHAT1 = "/sbrpgchat"
SlashCmdList.SELFBOTRPGCHAT = function(text)
    SendChatMessage(".sbrpg " .. tostring(text or ""), "SAY")
end
