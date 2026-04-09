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
frame:SetToplevel(true)  -- Only needs to be set once at creation
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
    -- Just resize and re-anchor to saved position
    -- Don't read position here - only update it on drag
    self.frame:SetSize(width, height)
    self.frame:ClearAllPoints()
    self.frame:SetPoint("TOPLEFT", UIParent, "TOP", SkyDelvesDB.posX, SkyDelvesDB.posY)
end

-- Debug functions - only loaded when DEBUG mode is enabled via /sd debug
-- These are kept for development/troubleshooting but not loaded in production

-- Function to check if a delve is bountiful (using atlasName)
function addon:IsDelveBountiful(delve)
    -- Check if the delve's POI has atlasName "delves-bountiful"
    if not (C_AreaPoiInfo and delve.poiID and delve.mapID) then
        return false
    end

    -- Protected call in case API changes or fails
    local success, poiInfo = pcall(C_AreaPoiInfo.GetAreaPOIInfo, delve.mapID, delve.poiID)
    if success and poiInfo and poiInfo.atlasName == "delves-bountiful" then
        return true
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
        local isBountiful = self:IsDelveBountiful(delve)

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
