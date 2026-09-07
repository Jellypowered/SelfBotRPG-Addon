-- Shared catalogs, selections, and plain-text filtering.
SBRPG = SBRPG or {}
SBRPG.Data = SBRPG.Data or {}
local Data = SBRPG.Data

Data.Resources = {
    both = { "Zone" },
    mining = { "Copper", "Tin", "Silver", "Iron", "Gold", "Mithril", "Truesilver", "Thorium", "Fel Iron", "Adamantite", "Khorium", "Cobalt", "Saronite", "Titanium" },
    herbalism = { "Peacebloom", "Silverleaf", "Earthroot", "Mageroyal", "Briarthorn", "Bruiseweed", "Wild Steelbloom", "Kingsblood", "Liferoot", "Fadeleaf", "Goldthorn", "Felweed", "Goldclover", "Lichbloom", "Icethorn", "Frost Lotus" },
}
Data.ResourceItemIds = {
    Copper=2770,Tin=2771,Silver=2775,Iron=2772,Gold=2776,Mithril=3858,Truesilver=7911,Thorium=10620,
    ["Fel Iron"]=23424,Adamantite=23425,Khorium=23426,Cobalt=36909,Saronite=36912,Titanium=36910,
    Peacebloom=2447,Silverleaf=765,Earthroot=2449,Mageroyal=785,Briarthorn=2450,Bruiseweed=2453,
    ["Wild Steelbloom"]=3355,Kingsblood=3356,Liferoot=3357,Fadeleaf=3818,Goldthorn=3821,Felweed=22785,
    Goldclover=36901,Lichbloom=36905,Icethorn=36906,["Frost Lotus"]=36907,
}
Data.FallbackMaterials = {
    {2589,"linen-cloth","Linen Cloth","cloth","loot"},{2592,"wool-cloth","Wool Cloth","cloth","loot"},
    {4306,"silk-cloth","Silk Cloth","cloth","loot"},{4338,"mageweave-cloth","Mageweave Cloth","cloth","loot"},
    {14047,"runecloth","Runecloth","cloth","loot"},{21877,"netherweave-cloth","Netherweave Cloth","cloth","loot"},
    {33470,"frostweave-cloth","Frostweave Cloth","cloth","loot"},{2318,"light-leather","Light Leather","leather","skinning"},
    {2319,"medium-leather","Medium Leather","leather","skinning"},{4234,"heavy-leather","Heavy Leather","leather","skinning"},
    {4235,"thick-leather","Thick Leather","leather","skinning"},{4304,"rugged-leather","Rugged Leather","leather","skinning"},
    {21887,"knothide-leather","Knothide Leather","leather","skinning"},{33568,"borean-leather","Borean Leather","leather","skinning"},
    {22572,"mote-of-air","Mote of Air","elemental","loot"},{22573,"mote-of-earth","Mote of Earth","elemental","loot"},
    {22574,"mote-of-fire","Mote of Fire","elemental","loot"},{6358,"oily-blackmouth","Oily Blackmouth","fishing","fishing"},
    {6359,"firefin-snapper","Firefin Snapper","fishing","fishing"},{6522,"deviate-fish","Deviate Fish","fishing","fishing"},
    {27422,"barbed-gill-trout","Barbed Gill Trout","fishing","fishing"},{27425,"spotted-feltail","Spotted Feltail","fishing","fishing"},
    {27429,"zangarian-sporefish","Zangarian Sporefish","fishing","fishing"},{27438,"golden-darter","Golden Darter","fishing","fishing"},
    {27439,"furious-crawdad","Furious Crawdad","fishing","fishing"},{41800,"deep-sea-monsterbelly","Deep Sea Monsterbelly","fishing","fishing"},
    {41801,"moonglow-cuttlefish","Moonglow Cuttlefish","fishing","fishing"},{41802,"imperial-manta-ray","Imperial Manta Ray","fishing","fishing"},
    {41803,"rockfin-grouper","Rockfin Grouper","fishing","fishing"},{34760,"borean-man-o-war","Borean Man O' War","fishing","fishing"},
}
Data.Materials = {}
Data.MaterialByName = {}
Data.CatalogComplete = false
Data.SourceCounts = {}

local function Normalize(row)
    return { itemId=tonumber(row.itemId or row[1]) or 0, key=tostring(row.key or row[2] or ""), name=tostring(row.name or row[3] or "Unknown"), family=string.lower(tostring(row.family or row[4] or "other")), methods=tostring(row.methods or row[5] or "unknown") }
end
function Data.ResetCatalog()
    Data.Materials = {}; Data.MaterialByName = {}; Data.CatalogComplete = false
end
function Data.AddMaterial(row)
    row = Normalize(row)
    table.insert(Data.Materials, row); Data.MaterialByName[row.name] = row
end
function Data.LoadFallbackCatalog()
    if #Data.Materials > 0 then return end
    for _, row in ipairs(Data.FallbackMaterials) do Data.AddMaterial(row) end
end
Data.LoadFallbackCatalog()

function Data.ItemIcon(itemId)
    itemId = tonumber(itemId) or 0
    local texture = itemId > 0 and GetItemIcon and GetItemIcon(itemId)
    if not texture and itemId > 0 and GetItemInfo then
        local _,_,_,_,_,_,_,_,_,icon = GetItemInfo(itemId); texture = icon
    end
    return texture or "Interface\\Icons\\INV_Misc_QuestionMark"
end
function Data.ItemLink(itemId, fallback)
    itemId = tonumber(itemId) or 0
    if itemId > 0 and GetItemInfo then
        local name, link = GetItemInfo(itemId)
        if link then return link end
        if name then fallback = name end
    end
    return tostring(fallback or (itemId > 0 and ("Item #" .. itemId) or "Unknown item"))
end
function Data.IsFishing(row) return row and string.lower(row.family or "") == "fishing" end
function Data.FilterMaterials(search, fishingOnly, family)
    local needle = string.lower(tostring(search or ""))
    local result = {}
    for _, row in ipairs(Data.Materials) do
        local fishing = Data.IsFishing(row)
        local familyMatch = not family or family == "all" or row.family == family
        local haystack = string.lower(table.concat({row.name,row.key,row.family,row.methods,tostring(row.itemId)}, " "))
        if fishing == fishingOnly and familyMatch and (needle == "" or string.find(haystack, needle, 1, true)) then table.insert(result, row) end
    end
    table.sort(result, function(a,b) if a.family == b.family then return a.name < b.name end return a.family < b.family end)
    return result
end
function Data.MaterialFamilies()
    local seen, out = {}, {"all"}
    for _, row in ipairs(Data.Materials) do if not Data.IsFishing(row) and not seen[row.family] then seen[row.family]=true; table.insert(out,row.family) end end
    table.sort(out, function(a,b) if a=="all" then return true elseif b=="all" then return false else return a<b end end)
    return out
end
