-- Material tab: exact non-fishing catalog targets.
SBRPG = SBRPG or {}
SBRPG.RegisterTab("material","Material",2,function(panel)
    local db=SelfBotRPGDB.Material;local D=SBRPG.Data;db.family=db.family or "all"
    SBRPG.CreateSectionHeader(panel,"Material Farming",-16)
    local help=SBRPG.CreateLabel(panel,"Select one exact server catalog item. Combat, loot, and corpse gathering remain stock playerbot actions.",16,-44,650);help:SetTextColor(unpack(SBRPG.Theme.gray))
    local search=SBRPG.CreateInput(panel,"Search name, family, method, or item ID",16,-76,280,db.search or "",false,"Case-insensitive plain-text filtering.")
    SBRPG.CreateLabel(panel,"Family",320,-76,140)
    local family=SBRPG.CreateDropdown(panel,"SBRPGMaterialFamily",320,-94,150,{},function(value)db.family=value;panel:RefreshList()end);family:SetValue(db.family,string.upper(string.sub(db.family,1,1))..string.sub(db.family,2))
    local selected=SBRPG.CreateLabel(panel,"No material selected",490,-94,175);selected:SetJustifyH("RIGHT");selected:SetTextColor(unpack(SBRPG.Theme.goldLight))
    local scroll,child=SBRPG.CreateScrollList(panel,16,-130,655,190,26);local rows={};local empty=SBRPG.CreateLabel(panel,"",26,-160,620);empty:SetTextColor(unpack(SBRPG.Theme.gray))
    local function Select(row)db.selectedName=row.name;db.selectedItemId=row.itemId;selected:SetText(D.ItemLink(row.itemId,row.name));SBRPG.RequestMaterialSources(row);panel:RefreshList()end
    function panel:RefreshList()
        family:SetItems((function()local out={};for _,name in ipairs(D.MaterialFamilies())do table.insert(out,{value=name,label=name=="all" and "All families" or (string.upper(string.sub(name,1,1))..string.sub(name,2))})end;return out end)())
        for _,row in ipairs(rows)do row:Hide()end;local data=D.FilterMaterials(search:GetText(),false,db.family);empty:SetText(#data==0 and (D.CatalogComplete and "No materials match this filter." or "Catalog is loading; no current matches.") or "")
        for index,item in ipairs(data)do local captured=item;local row=rows[index]
            if not row then row=CreateFrame("Button",nil,child);row:SetSize(625,25);row.bg=row:CreateTexture(nil,"BACKGROUND");row.bg:SetAllPoints();row.bg:SetTexture("Interface\\Buttons\\WHITE8x8");row.icon=row:CreateTexture(nil,"ARTWORK");row.icon:SetSize(20,20);row.icon:SetPoint("LEFT",4,0);row.name=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.name:SetPoint("LEFT",row.icon,"RIGHT",7,0);row.name:SetWidth(285);row.name:SetJustifyH("LEFT");row.meta=row:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall");row.meta:SetPoint("LEFT",330,0);row.meta:SetWidth(280);row.meta:SetJustifyH("RIGHT");rows[index]=row end
            row:ClearAllPoints();row:SetPoint("TOPLEFT",0,-(index-1)*26);row.icon:SetTexture(D.ItemIcon(item.itemId));row.name:SetText(D.ItemLink(item.itemId,item.name));local source=D.SourceCounts[item.name];local sourceText=source and ((source.pending and "checking sources" or ((source.total or 0).." sources"))) or item.methods;row.meta:SetText(item.family.." | "..sourceText);local active=item.name==db.selectedName;row.bg:SetVertexColor(active and .22 or .08,active and .18 or .08,active and .07 or .10,active and .9 or .45);row:SetScript("OnClick",function()Select(captured)end);row:SetScript("OnEnter",function(self)SBRPG.ShowItemTooltip(self,captured,"Family: "..captured.family.."\nMethods: "..captured.methods)end);row:SetScript("OnLeave",function()GameTooltip:Hide()end);row:Show()
        end;child:SetHeight(math.max(1,#data*26))
        local current=D.MaterialByName[db.selectedName or ""];if current then selected:SetText(D.ItemLink(current.itemId,current.name))elseif db.selectedName and db.selectedName~="" then selected:SetText(db.selectedName.." (unavailable)")end
    end
    search:SetScript("OnTextChanged",function(self)db.search=self:GetText();panel:RefreshList()end)
    local duration=SBRPG.CreateInput(panel,"Duration (minutes; 0 = unlimited)",16,-340,205,db.duration or "0",true,"Allowed range: 0–10080.")
    local quantity=SBRPG.CreateInput(panel,"Quantity (0 = unlimited)",240,-340,185,db.quantity or "0",true,"Stop after this many requested items. Allowed range: 0–999999.")
    duration:SetScript("OnTextChanged",function(self)db.duration=self:GetText()end);quantity:SetScript("OnTextChanged",function(self)db.quantity=self:GetText()end)
    local start=SBRPG.CreateButton(panel,"Start Material Run",165,500,-358,function()
        local d,e=SBRPG.Number(duration:GetText(),0,10080,"Duration");if not d then SBRPG.SetStatus("error",e,{category="errors"});return end;local q,qe=SBRPG.Number(quantity:GetText(),0,999999,"Quantity");if not q then SBRPG.SetStatus("error",qe,{category="errors"});return end
        local row=D.MaterialByName[db.selectedName or ""];if not row or D.IsFishing(row)then SBRPG.SetStatus("error","Select an available non-fishing material.",{category="errors"});return end
        if not SBRPG.State.bridgeReady then SBRPG.Connect();return end;if not SBRPG.HasCapability("START_MATERIAL")then SBRPG.SetStatus("warning","Material farming is not supported by this server.",{category="protocol"});return end
        SBRPG.Send("START_MATERIAL",{"material",row.name,tostring(d),tostring(q)})
    end);SBRPG.Tooltip(start,"Start material run",function()return start.disabledReason or "Farm the exact selected material."end)
    function panel:OnCatalogUpdated()panel:RefreshList()end;function panel:OnSourcesUpdated()panel:RefreshList()end
    function panel:OnCapabilitiesUpdated()SBRPG.SetEnabled(start,SBRPG.State.bridgeReady and SBRPG.HasCapability("START_MATERIAL"),"Server does not advertise START_MATERIAL.")end
    function panel:OnShowTab()panel:RefreshList();panel:OnCapabilitiesUpdated()end
    panel:RefreshList();panel:OnCapabilitiesUpdated()
end)
