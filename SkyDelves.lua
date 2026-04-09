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

-- Delve data with POI IDs and locations (from BountifulDelvesHunter-Midnight)
local DELVES = {
    -- Silvermoon
    {poiID = 8426, name = "Collegiate Calamity", zone = "Silvermoon", mapID = 2393, coords = "40.8, 54.1"},
    {poiID = 8440, name = "The Darkway", zone = "Silvermoon", mapID = 2393, coords = "39.3, 31.8"},

    -- Isle of Quel'Danas
    {poiID = 8428, name = "Parhelion Plaza", zone = "Isle of Quel'Danas", mapID = 2424, coords = "46.3, 41.6"},

    -- Eversong Woods
    {poiID = 8438, name = "The Shadow Enclave", zone = "Eversong Woods", mapID = 2395, coords = "45.4, 86.0"},

    -- Zul'Aman
    {poiID = 8444, name = "Atal'Aman", zone = "Zul'Aman", mapID = 2437, coords = "24.8, 53.0"},
    {poiID = 8442, name = "Twilight Crypts", zone = "Zul'Aman", mapID = 2437, coords = "25.4, 84.3"},

    -- Voidstorm
    {poiID = 8432, name = "Shadowguard Point", zone = "Voidstorm", mapID = 2405, coords = "37.4, 47.7"},
    {poiID = 8430, name = "Sunkiller Sanctum", zone = "Voidstorm", mapID = 2405, coords = "54.8, 47.0"},

    -- Harandar
    {poiID = 8436, name = "The Gulf of Memory", zone = "Harandar", mapID = 2413, coords = "36.3, 49.2"},
    {poiID = 8434, name = "The Grudge Pit", zone = "Harandar", mapID = 2413, coords = "70.5, 64.9"},
}

-- Frame creation - Sleek minimal design
local frame = CreateFrame("Frame", "SkyDelvesFrame", UIParent)
frame:SetSize(280, 32) -- Start minimized
frame:SetPoint("TOPLEFT", UIParent, "TOP", SkyDelvesDB.posX, SkyDelvesDB.posY)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("HIGH")
frame.isMinimized = true

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
    -- Save the new position to DB by converting absolute position to offset
    local left = frame:GetLeft()
    local top = frame:GetTop()

    if left and top then
        local screenWidth = UIParent:GetWidth()
        local screenHeight = UIParent:GetHeight()

        -- Convert absolute position to offset from UIParent TOP center
        SkyDelvesDB.posX = left - (screenWidth / 2)
        SkyDelvesDB.posY = top - screenHeight
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

-- Helper function to set frame size while preserving TOPLEFT anchor
-- This ensures the frame always grows/shrinks from the top, not center
function addon:SetFrameSize(width, height)
    -- Just resize and re-anchor to saved position
    -- Don't read position here - only update it on drag
    self.frame:SetSize(width, height)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", UIParent, "TOP", SkyDelvesDB.posX, SkyDelvesDB.posY)
end

-- Debug function to print ALL quests
function addon:PrintAllQuests()
    print("=== ALL QUESTS IN QUEST LOG ===")

    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
        local numQuests = C_QuestLog.GetNumQuestLogEntries()
        print(string.format("Total quests: %d", numQuests))

        for i = 1, numQuests do
            local info = C_QuestLog.GetInfo(i)
            if info then
                if info.isHeader then
                    print(string.format("\n[HEADER] %s", info.title or "Unknown"))
                else
                    local title = C_QuestLog.GetTitleForQuestID(info.questID) or info.title
                    print(string.format("  Quest: %s (ID: %d)", title, info.questID))

                    -- Check objectives for delve names
                    local objectives = C_QuestLog.GetQuestObjectives(info.questID)
                    if objectives and #objectives > 0 then
                        for _, obj in ipairs(objectives) do
                            if obj.text then
                                print(string.format("    Objective: %s", obj.text))
                            end
                        end
                    end
                end
            end
        end
    end

    print("=== END QUEST LIST ===")
end

-- Debug function to check for Delve APIs
function addon:CheckDelveAPIs()
    print("=== CHECKING FOR DELVE APIs ===")

    -- Check if C_Delves exists
    if C_Delves then
        print("C_Delves API EXISTS!")
        print("Available functions:")
        for k, v in pairs(C_Delves) do
            if type(v) == "function" then
                print("  C_Delves." .. k)
            end
        end

        -- Try to get delve info
        if C_Delves.GetDelves then
            print("\nCalling C_Delves.GetDelves():")
            local delves = C_Delves.GetDelves()
            if delves then
                for i, delve in ipairs(delves) do
                    print(string.format("  Delve %d: %s", i, tostring(delve)))
                end
            end
        end
    else
        print("C_Delves API NOT FOUND")
    end

    -- Check C_VignetteInfo for delve vignettes
    if C_VignetteInfo then
        print("\nC_VignetteInfo API EXISTS!")
        if C_VignetteInfo.GetVignettes then
            local vignettes = C_VignetteInfo.GetVignettes()
            if vignettes and #vignettes > 0 then
                print(string.format("Found %d vignettes:", #vignettes))
                for _, vignetteGUID in ipairs(vignettes) do
                    local info = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
                    if info and info.name and info.name:lower():find("delve") then
                        print(string.format("  Vignette: %s", info.name))
                        print(string.format("    Atlas: %s", tostring(info.atlasName)))
                    end
                end
            end
        end
    else
        print("C_VignetteInfo API NOT FOUND")
    end

    print("=== END API CHECK ===")
end

-- Debug function to scan ALL maps for delve POIs
function addon:ScanAllMapsForDelves()
    print("=== SCANNING ALL MAPS FOR ALL POIs ===")

    -- Known Midnight map IDs
    local midnightMaps = {
        2393, -- Silvermoon City
        2552, -- Quel'Thalas
        2601, -- Isle of Quel'Danas
        2600, -- Voidstorm
        2651, -- Zul'Aman
    }

    for _, mapID in ipairs(midnightMaps) do
        local mapInfo = C_Map.GetMapInfo(mapID)
        if mapInfo then
            print(string.format("=== Map: %s (ID: %d) ===", mapInfo.name, mapID))

            if C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOIForMap then
                local pois = C_AreaPoiInfo.GetAreaPOIForMap(mapID)
                if pois and #pois > 0 then
                    print(string.format("  Found %d POIs:", #pois))
                    for _, poiID in ipairs(pois) do
                        local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
                        if info and info.name then
                            print(string.format("  POI: %s (ID: %d)", info.name, poiID))
                            print(string.format("    Atlas: %s", tostring(info.atlasName)))
                            print(string.format("    Texture: %s", tostring(info.textureIndex)))
                            print(string.format("    Widget: %s", tostring(info.widgetSetID)))
                            if info.description and info.description ~= "" then
                                print(string.format("    Description: %s", info.description))
                            end
                        end
                    end
                else
                    print("  No POIs found")
                end
            end
        end
    end

    print("=== END SCAN ===")
end

-- Debug function to print all available bountiful activities
function addon:DebugPrintBountifulDelves()
    print("=== DEBUG: Checking Bountiful Delves ===")

    -- Method 1: C_PerksActivities
    if C_PerksActivities and C_PerksActivities.GetPerksActivitiesInfo then
        print("Method 1: C_PerksActivities.GetPerksActivitiesInfo()")
        local activities = C_PerksActivities.GetPerksActivitiesInfo()
        if activities and #activities > 0 then
            for i, activity in ipairs(activities) do
                print(string.format("  Activity %d: %s", i, tostring(activity.activityName or "nil")))
            end
        else
            print("  No activities found")
        end
    else
        print("Method 1: C_PerksActivities.GetPerksActivitiesInfo NOT AVAILABLE")
    end

    -- Method 2: Check quest log (ALL quests with "delve")
    if C_QuestLog and C_QuestLog.GetNumQuestLogEntries then
        print("Method 2: Quest Log (All delve-related quests)")
        local found = false
        for i = 1, C_QuestLog.GetNumQuestLogEntries() do
            local info = C_QuestLog.GetInfo(i)
            if info and not info.isHeader and info.questID then
                local title = C_QuestLog.GetTitleForQuestID(info.questID)
                if title and title:lower():find("delve") then
                    print(string.format("  Quest: %s (ID: %d)", title, info.questID))
                    found = true
                end
            end
        end
        if not found then
            print("  No delve quests found")
        end
    else
        print("Method 2: C_QuestLog NOT AVAILABLE")
    end

    -- Method 3: Check World Map POIs
    if C_AreaPoiInfo and C_AreaPoiInfo.GetAreaPOISecondsLeft then
        print("Method 3: World Map POIs")
        local mapID = C_Map.GetBestMapForUnit("player")
        if mapID then
            print("  Current Map ID:", mapID)
            local pois = C_AreaPoiInfo.GetAreaPOIForMap(mapID)
            if pois and #pois > 0 then
                for _, poiID in ipairs(pois) do
                    local info = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
                    if info and info.name then
                        print(string.format("  POI: %s (ID: %d)", info.name, poiID))
                    end
                end
            else
                print("  No POIs found on current map")
            end
        else
            print("  No map ID found")
        end
    else
        print("Method 3: C_AreaPoiInfo NOT AVAILABLE")
    end

    -- Method 4: Weekly Rewards
    if C_WeeklyRewards and C_WeeklyRewards.GetActivities then
        print("Method 4: Weekly Rewards Activities")
        local activities = C_WeeklyRewards.GetActivities()
        if activities and #activities > 0 then
            for i, activity in ipairs(activities) do
                if activity then
                    print(string.format("  Activity %d: type=%s, level=%s", i, tostring(activity.type), tostring(activity.level)))
                end
            end
        else
            print("  No weekly activities found")
        end
    else
        print("Method 4: C_WeeklyRewards NOT AVAILABLE")
    end

    print("=== END DEBUG ===")
end

-- Function to check if a delve is bountiful (using atlasName)
function addon:IsDelveBoumtiful(delve)
    -- Check if the delve's POI has atlasName "delves-bountiful"
    if C_AreaPoiInfo and delve.poiID and delve.mapID then
        local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(delve.mapID, delve.poiID)
        if poiInfo and poiInfo.atlasName == "delves-bountiful" then
            return true
        end
    end
    return false
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

    -- Filter to only bountiful delves
    for i, delve in ipairs(DELVES) do
        local isBountiful = self:IsDelveBoumtiful(delve)

        if isBountiful then
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

    if msg == "debug" then
        addon:DebugPrintBountifulDelves()
    elseif msg == "scan" then
        addon:ScanAllMapsForDelves()
    elseif msg == "api" then
        addon:CheckDelveAPIs()
    elseif msg == "quests" then
        addon:PrintAllQuests()
    elseif addon.frame:IsShown() then
        addon.frame:Hide()
        SkyDelvesDB.isVisible = false
    else
        addon:UpdateDelveList()
        addon.frame:Show()
        addon.frame:SetFrameStrata("DIALOG")
        addon.frame:SetToplevel(true)
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
                addon:UpdateDelveList()
                addon.frame:Show()
                addon.frame:SetFrameStrata("DIALOG")
                addon.frame:SetToplevel(true)
                -- Expand on load
                if addon.frame.isMinimized then
                    addon.frame.minMaxBtn.text:SetText("-")
                    addon.frame.isMinimized = false
                    addon.content:Show()
                end
            end)
        end
    elseif event == "QUEST_TURNED_IN" then
        -- Quest completed, update delve list after short delay
        C_Timer.After(2, function()
            if addon.frame:IsShown() then
                addon:UpdateDelveList()
            end
        end)
    elseif event == "SCENARIO_COMPLETED" then
        -- Delve completed, update list
        C_Timer.After(2, function()
            if addon.frame:IsShown() then
                addon:UpdateDelveList()
            end
        end)
    elseif event == "AREA_POIS_UPDATED" then
        -- POIs updated (weekly reset etc), refresh list
        if addon.frame:IsShown() then
            C_Timer.After(1, function()
                addon:UpdateDelveList()
            end)
        end
    end
end)

print("SkyDelves addon loaded!")
