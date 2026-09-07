-- Gathering tab: mining/herbalism node farming.
SBRPG = SBRPG or {}
SBRPG.RegisterTab("gathering","Gathering",1,function(panel)
    local db=SelfBotRPGDB.Gathering;local D=SBRPG.Data
    SBRPG.CreateSectionHeader(panel,"Gathering",-16)
    local help=SBRPG.CreateLabel(panel,"Farm mining and herbalism nodes in the current map/zone using normal playerbot gathering.",16,-44,650);help:SetTextColor(unpack(SBRPG.Theme.gray))
    SBRPG.CreateLabel(panel,"Profession",16,-76,150)
    local profession=SBRPG.CreateDropdown(panel,"SBRPGGatherProfession",16,-94,150,{{label="Mining",value="mining"},{label="Herbalism",value="herbalism"},{label="Both",value="both"}},function(value)db.profession=value;panel:RefreshResources()end);profession:SetValue(db.profession or "mining",({mining="Mining",herbalism="Herbalism",both="Both"})[db.profession or "mining"])
    local search=SBRPG.CreateInput(panel,"Filter resources",190,-76,190,"",false,"Filter by resource name. This is plain text, not a Lua pattern.")
    local selected=SBRPG.CreateLabel(panel,"Selected: "..tostring(db.resource or "Copper"),410,-96,245);selected:SetTextColor(unpack(SBRPG.Theme.goldLight))
    local scroll,child=SBRPG.CreateScrollList(panel,16,-130,655,215,24);local rows={}
    local function Select(name)itemName=name;db.resource=name;selected:SetText("Selected: "..name);panel:RefreshResources()end
    function panel:RefreshResources()
        for _,row in ipairs(rows)do row:Hide()end
        local values={};for _,name in ipairs(D.Resources[db.profession or "mining"] or {})do table.insert(values,name)end;if db.profession~="both" then table.insert(values,"Zone")end
        local needle=string.lower(search:GetText() or "");local shown=0
        for _,name in ipairs(values)do if needle=="" or string.find(string.lower(name),needle,1,true)then shown=shown+1;local row=rows[shown]
            if not row then row=CreateFrame("Button",nil,child);row:SetSize(625,24);row.bg=row:CreateTexture(nil,"BACKGROUND");row.bg:SetAllPoints();row.bg:SetTexture("Interface\\Buttons\\WHITE8x8");row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetSize(18,18);row.icon:SetPoint("LEFT",5,0);row.text=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.text:SetPoint("LEFT",row.icon,"RIGHT",7,0);rows[shown]=row end
            row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-(shown-1)*24);row.text:SetText(name);row.icon:SetTexture(D.ItemIcon(D.ResourceItemIds[name]));local active=name==db.resource;row.bg:SetVertexColor(active and .22 or .08,active and .18 or .08,active and .07 or .10,active and .9 or .45);row:SetScript("OnClick",function()Select(name)end);row:SetScript("OnEnter",function(self)if D.ResourceItemIds[name] then SBRPG.ShowItemTooltip(self,{itemId=D.ResourceItemIds[name],name=name},"Select this node resource.")else GameTooltip:SetOwner(self,"ANCHOR_RIGHT");GameTooltip:SetText("Zone gathering",1,.82,.22);GameTooltip:AddLine("Gather eligible nodes for the selected profession in the current zone.",.8,.8,.8,true);GameTooltip:Show()end end);row:SetScript("OnLeave",function()GameTooltip:Hide()end);row:Show()end end
        child:SetHeight(math.max(1,shown*24))
    end
    search:SetScript("OnTextChanged",function()panel:RefreshResources()end)
    local duration=SBRPG.CreateInput(panel,"Duration (minutes; 0 = unlimited)",16,-362,210,db.duration or "0",true,"Allowed range: 0–10080 minutes.")
    local quantity=SBRPG.CreateInput(panel,"Quantity (0 = unlimited)",245,-362,190,db.quantity or "0",true,"Stop after this many of the selected resource item. Exact-resource mode only; allowed range: 0–999999.")
    duration:SetScript("OnTextChanged",function(self)db.duration=self:GetText()end);quantity:SetScript("OnTextChanged",function(self)db.quantity=self:GetText()end)
    local start=SBRPG.CreateButton(panel,"Start Gathering",150,500,-380,function()
        local value,errorText=SBRPG.Number(duration:GetText(),0,10080,"Duration");if not value then SBRPG.SetStatus("error",errorText,{category="errors"});return end
        local goal,goalError=SBRPG.Number(quantity:GetText(),0,999999,"Quantity");if not goal then SBRPG.SetStatus("error",goalError,{category="errors"});return end
        if goal>0 and (db.resource=="Zone" or db.profession=="both") then SBRPG.SetStatus("error","A quantity goal requires one exact mining or herbalism resource.",{category="errors"});return end
        if not SBRPG.State.bridgeReady then SBRPG.Connect();return end
        if not SBRPG.HasCapability("START") then SBRPG.SetStatus("warning","Gathering is not supported by this server.",{category="protocol"});return end
        if db.resource=="Zone" and db.profession~="both" then SBRPG.Send("START",{"zone",db.profession,tostring(value),tostring(goal)})else SBRPG.Send("START",{db.profession,db.resource,tostring(value),tostring(goal)})end
        for _,key in ipairs({"attempts","failedblacklist","emptyblacklist","zone","settledelay"})do local v=SelfBotRPGDB.Settings[key];if v~=nil then SBRPG.Send("SET",{key,tostring(v)})end end;SBRPG.Send("STATUS",{})
    end);SBRPG.Tooltip(start,"Start gathering",function()return start.disabledReason or "Start the selected node-farming run."end)
    function panel:OnCapabilitiesUpdated()SBRPG.SetEnabled(start,SBRPG.State.bridgeReady and SBRPG.HasCapability("START"),"Server does not advertise START.")end
    function panel:OnShowTab()panel:RefreshResources();panel:OnCapabilitiesUpdated()end
    panel:RefreshResources();panel:OnCapabilitiesUpdated()
end)
