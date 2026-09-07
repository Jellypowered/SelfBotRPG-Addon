-- History tab: persistent read-only terminal-style status log.
SBRPG = SBRPG or {}
SBRPG.RegisterTab("history","History",5,function(panel)
    local filter="all";local autoScroll=true
    SBRPG.CreateSectionHeader(panel,"History",-16)
    local hint=SBRPG.CreateLabel(panel,"Newest first; latest entry stays highlighted. Oldest entries are evicted after 100.",16,-44,460);hint:SetTextColor(unpack(SBRPG.Theme.gray))
    local counter=SBRPG.CreateLabel(panel,"0 / 100",585,-44,80);counter:SetJustifyH("RIGHT")
    local filters=SBRPG.CreateDropdown(panel,"SBRPGHistoryFilter",16,-70,150,{{label="All",value="all"},{label="Activity",value="activity"},{label="Protocol",value="protocol"},{label="Settings",value="settings"},{label="Errors",value="errors"},{label="Debug",value="debug"}},function(value)filter=value;SBRPG.RefreshHistory(false)end);filters:SetValue("all","All")
    local auto=SBRPG.CreateCheck(panel,"Keep newest visible",205,-67,true,"Return to the newest visible entry at the top whenever History is updated.");auto:SetScript("OnClick",function(self)autoScroll=self:GetChecked()and true or false end)
    local clear=SBRPG.CreateButton(panel,"Clear History",120,548,-66,function()SBRPG.ShowConfirm("Clear all saved SelfBot RPG history?",function()SBRPG.History.Clear()end)end);SBRPG.Tooltip(clear,"Clear History","Delete all saved History entries. Capacity eviction never requires confirmation.")
    local scroll,child=SBRPG.CreateScrollList(panel,16,-105,655,300,17);SBRPG.ApplyBackdrop(scroll,true);local rows={};local empty=SBRPG.CreateLabel(panel,"No history entries yet.",32,-145,600);empty:SetTextColor(unpack(SBRPG.Theme.gray))
    function SBRPG.RefreshHistory(isAppend)
        if not panel or not panel:IsShown()then return end
        for _,row in ipairs(rows)do row:Hide()end;local shown=0;local y=0
        local entries=SBRPG.History.Entries()
        for index=#entries,1,-1 do local entry=entries[index];if filter=="all"or entry.category==filter then shown=shown+1;local row=rows[shown]
            if not row then row=CreateFrame("Frame",nil,child);row:SetWidth(615);row.bg=row:CreateTexture(nil,"BACKGROUND");row.bg:SetAllPoints();row.bg:SetTexture("Interface\\Buttons\\WHITE8x8");row.time=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.time:SetPoint("TOPLEFT",4,-4);row.time:SetWidth(58);row.time:SetJustifyH("LEFT");row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.text:SetPoint("TOPLEFT",64,-4);row.text:SetWidth(545);row.text:SetJustifyH("LEFT");row.text:SetJustifyV("TOP");row.text:SetWordWrap(true);rows[shown]=row end
            row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-y);row.time:SetText(entry.time);row.time:SetTextColor(unpack(SBRPG.Theme.dim));row.text:SetText(entry.text);row.text:SetTextColor(unpack(SBRPG.ColorForStatus(entry.kind)));row.bg:SetVertexColor(.36,.27,.06,shown==1 and .70 or .16);local height=math.max(14,row.text:GetStringHeight()+5);row:SetHeight(height);row:Show();y=y+height
        end end
        child:SetHeight(math.max(1,y));if shown==0 then empty:Show()else empty:Hide()end;counter:SetText(SBRPG.History.Count().." / 100")
        if autoScroll and (isAppend or panel:IsShown())then SBRPG.After(0,function()if scroll:IsShown()then scroll:SetVerticalScroll(0)end end)end
    end
    function panel:OnShowTab()SBRPG.RefreshHistory(false)end
end)
