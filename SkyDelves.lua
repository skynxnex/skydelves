-- SkyDelves: Track and display bountiful delves
local addonName, addon = ...
addon = addon or {}  -- Make sure addon table exists

-- Initialize saved variables
if not SkyDelvesDB then
    SkyDelvesDB = {
        locked = false,
        posX = -140,
        posY = -100,
        isVisible = true
    }
end

-- Validate saved position is reasonable
if not SkyDelvesDB.posX or not SkyDelvesDB.posY or
   math.abs(SkyDelvesDB.posX) > 2000 or math.abs(SkyDelvesDB.posY) > 2000 then
    SkyDelvesDB.posX = -140
    SkyDelvesDB.posY = -100
end

-- Delves are discovered from the map API instead of a hardcoded POI list, so
-- new zones and new delves (e.g. The Coiled Isle in 12.1) show up automatically.

-- Continent maps whose zones are scanned for delves
local DELVE_CONTINENTS = {
    2537, -- Midnight
}

-- Zones scanned in addition to the ones discovered from the continent maps.
-- Only a safety net: a zone that is not returned as a map child of its
-- continent would otherwise be missed.
local KNOWN_DELVE_ZONES = {
    2393, -- Silvermoon City
    2395, -- Eversong Woods
    2405, -- Voidstorm
    2413, -- Harandar
    2424, -- Isle of Quel'Danas
    2437, -- Zul'Aman
    2444, -- Slayer's Rise
    2512, -- The Coiled Isle
}

-- Frame creation - Sleek minimal design
local frame = CreateFrame("Frame", "SkyDelvesFrame", UIParent)
frame:SetSize(280, 32) -- Start minimized
frame:SetPoint("TOPLEFT", UIParent, "TOP", SkyDelvesDB.posX, SkyDelvesDB.posY)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("HIGH")
frame:SetToplevel(true)  -- Only needs to be set once at creation
frame.isMinimized = true

-- Ensure position stays locked when size changes
frame:SetScript("OnSizeChanged", function(self)
    -- Re-anchor to saved position to prevent drift
    self:ClearAllPoints()
    self:SetPoint("TOPLEFT", UIParent, "TOP", SkyDelvesDB.posX, SkyDelvesDB.posY)
end)

-- Border
local border = frame:CreateTexture(nil, "BORDER")
border:SetAllPoints(frame)
border:SetColorTexture(0.3, 0.3, 0.3, 1)

-- Background
local innerBg = frame:CreateTexture(nil, "ARTWORK")
innerBg:SetPoint("TOPLEFT", 1, -1)
innerBg:SetPoint("BOTTOMRIGHT", -1, 1)
innerBg:SetColorTexture(0.08, 0.08, 0.08, 0.95)

-- Title bar (draggable)
local titleBar = CreateFrame("Frame", nil, frame)
titleBar:SetPoint("TOPLEFT", 1, -1)
titleBar:SetPoint("TOPRIGHT", -1, -1)
titleBar:SetHeight(30)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")
titleBar:SetScript("OnDragStart", function()
    if not SkyDelvesDB.locked then
        frame:StartMoving()
    end
end)
titleBar:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()

    -- Get absolute position of TOPLEFT corner
    local left = frame:GetLeft()
    local top = frame:GetTop()

    if left and top then
        -- Convert to offset from UIParent TOP center point
        local uiParentWidth = UIParent:GetWidth()
        local uiParentHeight = UIParent:GetHeight()
        local uiParentCenterX = uiParentWidth / 2
        local uiParentTop = uiParentHeight

        -- Calculate offsets for TOPLEFT anchor relative to UIParent TOP
        local xOfs = left - uiParentCenterX
        local yOfs = top - uiParentTop

        -- Save and immediately reapply to ensure consistency
        SkyDelvesDB.posX = xOfs
        SkyDelvesDB.posY = yOfs

        -- Force re-anchor to our standard anchor point
        frame:ClearAllPoints()
        frame:SetPoint("TOPLEFT", UIParent, "TOP", xOfs, yOfs)
    end
end)

local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
titleBg:SetAllPoints()
titleBg:SetColorTexture(0.15, 0.15, 0.15, 1)

frame.title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.title:SetPoint("LEFT", 10, 0)
frame.title:SetText("Bountiful Delves")
frame.title:SetTextColor(0.9, 0.9, 0.9, 1)

-- Minimize/Maximize button
frame.minMaxBtn = CreateFrame("Button", nil, titleBar)
frame.minMaxBtn:SetSize(24, 24)
frame.minMaxBtn:SetPoint("RIGHT", -54, 0)

-- Button background
local minMaxBg = frame.minMaxBtn:CreateTexture(nil, "BACKGROUND")
minMaxBg:SetAllPoints()
minMaxBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

frame.minMaxBtn.text = frame.minMaxBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.minMaxBtn.text:SetPoint("CENTER", 0, 0)
frame.minMaxBtn.text:SetText("-")
frame.minMaxBtn.text:SetTextColor(0.8, 0.8, 0.8, 1)
frame.minMaxBtn:SetScript("OnEnter", function(self)
    minMaxBg:SetColorTexture(0.3, 0.3, 0.3, 1)
    self.text:SetTextColor(1, 1, 1, 1)
end)
frame.minMaxBtn:SetScript("OnLeave", function(self)
    minMaxBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    self.text:SetTextColor(0.8, 0.8, 0.8, 1)
end)
frame.minMaxBtn:SetScript("OnClick", function(self)
    if frame.isMinimized then
        -- Expand - calculate height based on number of bountiful delves
        frame.isMinimized = false
        self.text:SetText("-")
        if addon.content then
            addon.content:Show()
        end
        addon:UpdateDelveList()
    else
        -- Minimize
        frame.isMinimized = true
        self.text:SetText("+")
        if addon.content then
            addon.content:Hide()
        end
        addon:SetFrameSize(280, 32)
    end
end)

-- Lock/Unlock button
frame.lockBtn = CreateFrame("Button", nil, titleBar)
frame.lockBtn:SetSize(24, 24)
frame.lockBtn:SetPoint("RIGHT", -28, 0)

local lockBg = frame.lockBtn:CreateTexture(nil, "BACKGROUND")
lockBg:SetAllPoints()
lockBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

frame.lockBtn.text = frame.lockBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
frame.lockBtn.text:SetPoint("CENTER", 0, 0)
frame.lockBtn.text:SetText(SkyDelvesDB.locked and "L" or "U")
frame.lockBtn.text:SetTextColor(0.8, 0.8, 0.8, 1)

frame.lockBtn:SetScript("OnEnter", function(self)
    lockBg:SetColorTexture(0.3, 0.3, 0.3, 1)
    self.text:SetTextColor(1, 1, 1, 1)
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(SkyDelvesDB.locked and "Click to Unlock" or "Click to Lock")
    GameTooltip:Show()
end)
frame.lockBtn:SetScript("OnLeave", function(self)
    lockBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    self.text:SetTextColor(0.8, 0.8, 0.8, 1)
    GameTooltip:Hide()
end)
frame.lockBtn:SetScript("OnClick", function(self)
    SkyDelvesDB.locked = not SkyDelvesDB.locked
    self.text:SetText(SkyDelvesDB.locked and "L" or "U")
    if SkyDelvesDB.locked then
        print("|cFF00FFFFSkyDelves|r locked")
    else
        print("|cFF00FFFFSkyDelves|r unlocked")
    end
end)

-- Close button
local closeBtn = CreateFrame("Button", nil, titleBar)
closeBtn:SetSize(24, 24)
closeBtn:SetPoint("RIGHT", -2, 0)

local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
closeBg:SetAllPoints()
closeBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

closeBtn.text = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
closeBtn.text:SetPoint("CENTER", 0, 1)
closeBtn.text:SetText("×")
closeBtn.text:SetTextColor(0.8, 0.8, 0.8, 1)
closeBtn:SetScript("OnEnter", function(self)
    closeBg:SetColorTexture(0.6, 0.1, 0.1, 1)
    self.text:SetTextColor(1, 1, 1, 1)
end)
closeBtn:SetScript("OnLeave", function(self)
    closeBg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
    self.text:SetTextColor(0.8, 0.8, 0.8, 1)
end)
closeBtn:SetScript("OnClick", function()
    frame:Hide()
    SkyDelvesDB.isVisible = false
    -- Stop any pending timer callbacks
    addon.timersActive = false
    C_Timer.After(0.1, function()
        addon.timersActive = true
    end)
end)

frame:Hide()

-- Content frame (no scroll needed, max 4 delves)
local content = CreateFrame("Frame", nil, frame)
content:SetPoint("TOPLEFT", frame, "TOPLEFT", 2, -32)
content:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -2, -32)
content:SetHeight(200) -- Will be adjusted dynamically
content:Hide() -- Start hidden (minimized)

-- Store references for access in functions
addon.frame = frame
addon.content = content
addon.delveEntries = {}
addon.timersActive = true  -- Flag to prevent timer callbacks after cleanup
addon.lastPOIUpdate = 0  -- Throttle AREA_POIS_UPDATED events

-- Helper function to set frame size while preserving TOPLEFT anchor
-- This ensures the frame always grows/shrinks from the top, not center
function addon:SetFrameSize(width, height)
    -- Just resize - OnSizeChanged callback will handle re-anchoring
    self.frame:SetSize(width, height)
end

-- How deep a map sits in the map hierarchy. Used to prefer the most specific
-- map reporting a delve, so a delve is labelled "Isle of Quel'Danas" rather
-- than the broader "Quel'Thalas" map that also carries a POI for it.
local function GetMapDepth(mapID)
    local depth = 0
    local currentID = mapID
    for _ = 1, 10 do
        local mapInfo = C_Map.GetMapInfo(currentID)
        if not (mapInfo and mapInfo.parentMapID and mapInfo.parentMapID > 0) then
            break
        end
        depth = depth + 1
        currentID = mapInfo.parentMapID
    end
    return depth
end

-- Build the list of maps to scan, most specific map first.
local zoneCache
function addon:GetDelveZones()
    if zoneCache then
        return zoneCache
    end

    local zones, seen = {}, {}
    local function add(mapID)
        if mapID and not seen[mapID] then
            seen[mapID] = true
            zones[#zones + 1] = mapID
        end
    end

    local discovered = false
    for _, continentID in ipairs(DELVE_CONTINENTS) do
        local success, children = pcall(C_Map.GetMapChildrenInfo, continentID, Enum.UIMapType.Zone, true)
        if success and children then
            for _, info in ipairs(children) do
                add(info.mapID)
                discovered = true
            end
        end
    end

    for _, mapID in ipairs(KNOWN_DELVE_ZONES) do
        add(mapID)
    end

    -- The continent maps themselves are deliberately not scanned: they carry a
    -- second POI for the same delve under a different poiID, which would show
    -- up as a duplicate labelled with the continent name.

    -- Deepest map first, so the most specific zone name wins on a duplicate
    local depths = {}
    for _, mapID in ipairs(zones) do
        depths[mapID] = GetMapDepth(mapID)
    end
    table.sort(zones, function(a, b)
        if depths[a] ~= depths[b] then
            return depths[a] > depths[b]
        end
        return a < b
    end)

    -- Only cache once map data was actually available, otherwise retry later
    if discovered then
        zoneCache = zones
    end
    return zones
end

-- Collect every POI id the API reports for a map (delve list + generic POI list)
local function CollectMapPOIs(mapID, out)
    local success, ids = pcall(C_AreaPoiInfo.GetDelvesForMap, mapID)
    if success and ids then
        for _, poiID in ipairs(ids) do
            out[#out + 1] = poiID
        end
    end

    success, ids = pcall(C_AreaPoiInfo.GetAreaPOIForMap, mapID)
    if success and ids then
        for _, poiID in ipairs(ids) do
            out[#out + 1] = poiID
        end
    end
end

-- A POI is a bountiful delve when its atlas is the bountiful delve icon.
-- Matched as a substring so icon renames like "delves-bountiful-2" still work.
local function IsBountifulAtlas(atlasName)
    return atlasName ~= nil and string.find(string.lower(atlasName), "bountiful", 1, true) ~= nil
end

-- Scan all delve zones and return the bountiful delves that are currently up
function addon:GetBountifulDelves()
    local results = {}
    if not (C_AreaPoiInfo and C_Map) then
        return results
    end

    -- The same delve is reported on several maps under different poiIDs, so
    -- dedupe on the delve name as well as the POI id
    local seenPOI, seenName = {}, {}
    for _, mapID in ipairs(self:GetDelveZones()) do
        local mapInfo = C_Map.GetMapInfo(mapID)
        local zoneName = mapInfo and mapInfo.name or ("Map " .. mapID)

        local poiIDs = {}
        CollectMapPOIs(mapID, poiIDs)

        for _, poiID in ipairs(poiIDs) do
            if not seenPOI[poiID] then
                seenPOI[poiID] = true
                local success, poiInfo = pcall(C_AreaPoiInfo.GetAreaPOIInfo, mapID, poiID)
                if success and poiInfo and IsBountifulAtlas(poiInfo.atlasName) then
                    local name = poiInfo.name or ("POI " .. poiID)
                    local nameKey = string.lower(name)
                    if not seenName[nameKey] then
                        seenName[nameKey] = true
                        results[#results + 1] = {
                            poiID = poiID,
                            mapID = mapID,
                            name = name,
                            zone = zoneName,
                        }
                    end
                end
            end
        end
    end

    table.sort(results, function(a, b)
        if a.zone ~= b.zone then
            return a.zone < b.zone
        end
        return a.name < b.name
    end)

    return results
end

-- Update the delve list display - ONLY show bountiful delves
function addon:UpdateDelveList()
    -- Clear existing entries
    if self.delveEntries then
        for _, entry in ipairs(self.delveEntries) do
            entry:Hide()
        end
    end

    local yOffset = 0
    local entryHeight = 38
    local displayIndex = 1

    -- Only bountiful delves are returned by the scan
    for _, delve in ipairs(self:GetBountifulDelves()) do
        if not self.delveEntries[displayIndex] then
            local entry = CreateFrame("Frame", nil, addon.content)
            entry:SetSize(276, entryHeight)

            entry.border = entry:CreateTexture(nil, "BORDER")
            entry.border:SetAllPoints()
            entry.border:SetColorTexture(0.25, 0.25, 0.25, 1)

            entry.innerBg = entry:CreateTexture(nil, "ARTWORK")
            entry.innerBg:SetPoint("TOPLEFT", 1, -1)
            entry.innerBg:SetPoint("BOTTOMRIGHT", -1, 1)
            entry.innerBg:SetColorTexture(0.12, 0.12, 0.12, 1)

            entry.name = entry:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            entry.name:SetPoint("TOPLEFT", entry, "TOPLEFT", 6, -6)
            entry.name:SetJustifyH("LEFT")
            entry.name:SetWidth(265)

            entry.zone = entry:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            entry.zone:SetPoint("TOPLEFT", entry.name, "BOTTOMLEFT", 0, -2)
            entry.zone:SetJustifyH("LEFT")

            self.delveEntries[displayIndex] = entry
        end

        local entry = self.delveEntries[displayIndex]
        entry:SetPoint("TOPLEFT", addon.content, "TOPLEFT", 0, -yOffset)

        entry.name:SetText(delve.name)
        entry.zone:SetText(delve.zone)

        entry:Show()
        yOffset = yOffset + entryHeight + 2
        displayIndex = displayIndex + 1
    end

    -- Adjust frame height based on number of bountiful delves
    local totalHeight = 32 + yOffset + 4 -- titlebar + delves + padding

    if displayIndex == 1 then
        -- No bountiful delves
        if not self.noDelveLabel then
            self.noDelveLabel = addon.content:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            self.noDelveLabel:SetPoint("TOP", addon.content, "TOP", 0, -20)
            self.noDelveLabel:SetText("No bountiful delves active")
            self.noDelveLabel:SetTextColor(0.8, 0.8, 0.8, 1)
        end
        self.noDelveLabel:Show()
        totalHeight = 32 + 50 -- minimal height
    else
        if self.noDelveLabel then
            self.noDelveLabel:Hide()
        end
    end

    -- Set frame height dynamically
    if not addon.frame.isMinimized then
        addon:SetFrameSize(280, totalHeight)
    end

    addon.content:SetHeight(yOffset)
end

-- Slash command
SLASH_SKYDELVES1 = "/skydelves"
SLASH_SKYDELVES2 = "/sd"
SlashCmdList["SKYDELVES"] = function(msg)
    msg = msg:lower():trim()

    -- Diagnostics: dump every delve POI the API reports, bountiful or not
    if msg == "scan" then
        print("|cFF00FFFFSkyDelves|r scanning " .. #addon:GetDelveZones() .. " maps...")
        local found = 0
        for _, mapID in ipairs(addon:GetDelveZones()) do
            local mapInfo = C_Map.GetMapInfo(mapID)
            local poiIDs = {}
            CollectMapPOIs(mapID, poiIDs)
            for _, poiID in ipairs(poiIDs) do
                local success, poiInfo = pcall(C_AreaPoiInfo.GetAreaPOIInfo, mapID, poiID)
                if success and poiInfo and poiInfo.atlasName and string.find(poiInfo.atlasName, "delve", 1, true) then
                    found = found + 1
                    print(string.format("  [%d] %s - %s (poi %d, atlas %s)%s",
                        mapID, mapInfo and mapInfo.name or "?", poiInfo.name or "?", poiID,
                        poiInfo.atlasName, IsBountifulAtlas(poiInfo.atlasName) and " |cFFFFD100BOUNTIFUL|r" or ""))
                end
            end
        end
        print("|cFF00FFFFSkyDelves|r found " .. found .. " delve POIs.")
        return
    end

    if addon.frame:IsShown() then
        addon.frame:Hide()
        SkyDelvesDB.isVisible = false
        -- Stop any pending timer callbacks
        addon.timersActive = false
        C_Timer.After(0.1, function()
            addon.timersActive = true
        end)
    else
        addon:UpdateDelveList()
        addon.frame:Show()
        SkyDelvesDB.isVisible = true
        -- Auto-expand when opened
        if addon.frame.isMinimized then
            addon.frame.minMaxBtn.text:SetText("-")
            addon.frame.isMinimized = false
            addon.content:Show()
        end
    end
end

-- Event handler
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("QUEST_TURNED_IN")
eventFrame:RegisterEvent("SCENARIO_COMPLETED")
eventFrame:RegisterEvent("AREA_POIS_UPDATED")
eventFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        local playerLevel = UnitLevel("player")
        local maxLevel = GetMaxLevelForPlayerExpansion()

        if playerLevel < maxLevel then
            print("|cFF00FFFFSkyDelves|r loaded! Available at max level (" .. maxLevel .. ").")
            return
        end

        print("|cFF00FFFFSkyDelves|r loaded! Use /sd to toggle window.")
        -- Auto-open window if it was visible last session
        if SkyDelvesDB.isVisible then
            C_Timer.After(1, function()
                if addon.timersActive then
                    addon:UpdateDelveList()
                    addon.frame:Show()
                    -- Expand on load
                    if addon.frame.isMinimized then
                        addon.frame.minMaxBtn.text:SetText("-")
                        addon.frame.isMinimized = false
                        addon.content:Show()
                    end
                end
            end)
        end
    elseif event == "QUEST_TURNED_IN" then
        -- Quest completed, update delve list after short delay
        C_Timer.After(2, function()
            if addon.timersActive and addon.frame:IsShown() then
                addon:UpdateDelveList()
            end
        end)
    elseif event == "SCENARIO_COMPLETED" then
        -- Delve completed, update list
        C_Timer.After(2, function()
            if addon.timersActive and addon.frame:IsShown() then
                addon:UpdateDelveList()
            end
        end)
    elseif event == "AREA_POIS_UPDATED" then
        -- POIs updated (weekly reset etc), refresh list
        -- Throttle this event to max once per 5 seconds to prevent spam
        local currentTime = GetTime()
        if currentTime - addon.lastPOIUpdate >= 5 then
            addon.lastPOIUpdate = currentTime
            if addon.frame:IsShown() then
                C_Timer.After(1, function()
                    if addon.timersActive then
                        addon:UpdateDelveList()
                    end
                end)
            end
        end
    end
end)

print("SkyDelves addon loaded!")
