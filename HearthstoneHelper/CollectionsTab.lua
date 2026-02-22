local addonName, ns = ...

-- ============================================================
-- CollectionsTab.lua - Hearthstone Collection Panel
-- Adds a "Hearthstones" tab to the Collections Journal via
-- SecureTabs-2.0. Shows all known hearthstones with ownership,
-- favorites, filtering, search, and secure use buttons.
-- ============================================================

local PANEL_WIDTH = 660
local ROW_HEIGHT = 50
local ICON_SIZE = 44
local NUM_USE_BUTTONS = 20 -- Pre-created secure action buttons for visible rows

-- Category filter definitions
local CATEGORY_FILTERS = {
    { key = "all",      label = "All" },
    { key = "home",     label = "Home" },
    { key = "garrison", label = "Garrison" },
    { key = "dalaran",  label = "Dalaran" },
}

local OWNERSHIP_FILTERS = {
    { key = "all",     label = "All" },
    { key = "owned",   label = "Owned" },
    { key = "unowned", label = "Unowned" },
}

-- Active filter state
local activeCategory = "all"
local activeOwnership = "all"
local searchText = ""

-- Panel and scroll references (set during init)
local panel, scrollBox, scrollBar, countText
local filteredData = {}
local useButtons = {}

-- ------------------------------------
-- Build the filtered data list
-- ------------------------------------
local function BuildFilteredList()
    filteredData = {}

    if not ns.HearthstoneData then return end

    local searchLower = searchText:lower()

    for _, entry in ipairs(ns.HearthstoneData) do
        local dominated = false

        -- Category filter
        if activeCategory ~= "all" and entry.category ~= activeCategory then
            dominated = true
        end

        -- Ownership filter
        if not dominated and activeOwnership ~= "all" then
            local isOwned = ns.ownedHearthstoneMap and ns.ownedHearthstoneMap[entry.itemID]
            if activeOwnership == "owned" and not isOwned then
                dominated = true
            elseif activeOwnership == "unowned" and isOwned then
                dominated = true
            end
        end

        -- Search filter
        if not dominated and searchLower ~= "" then
            local nameLower = (entry.name or ""):lower()
            local sourceLower = (entry.source or ""):lower()
            if not nameLower:find(searchLower, 1, true) and not sourceLower:find(searchLower, 1, true) then
                dominated = true
            end
        end

        if not dominated then
            table.insert(filteredData, entry)
        end
    end

    -- Sort: owned first, then by name
    table.sort(filteredData, function(a, b)
        local aOwned = ns.ownedHearthstoneMap and ns.ownedHearthstoneMap[a.itemID] or false
        local bOwned = ns.ownedHearthstoneMap and ns.ownedHearthstoneMap[b.itemID] or false
        if aOwned ~= bOwned then
            return aOwned
        end
        return (a.name or "") < (b.name or "")
    end)
end

-- ------------------------------------
-- Update the collected count text
-- ------------------------------------
local function UpdateCountText()
    if not countText then return end
    local total = ns.HearthstoneData and #ns.HearthstoneData or 0
    local owned = ns.ownedHearthstones and #ns.ownedHearthstones or 0
    countText:SetFormattedText("Collected: |cffffffff%d|r / %d", owned, total)
end

-- ------------------------------------
-- Create a pool of SecureActionButtons for the "Use" column
-- These are pre-created because you cannot create secure frames
-- during combat. We reuse them for visible rows.
-- ------------------------------------
local function CreateUseButtonPool(parent)
    for i = 1, NUM_USE_BUTTONS do
        local useBtn = CreateFrame("Button", "HSHelper_UseBtn" .. i, parent, "SecureActionButtonTemplate")
        useBtn:SetSize(60, 22)
        useBtn:RegisterForClicks("AnyDown", "AnyUp")
        useBtn:Hide()

        -- Button background
        local bg = useBtn:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.2, 0.6, 0.2, 0.6)
        useBtn.bg = bg

        -- Button text
        local text = useBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        text:SetPoint("CENTER")
        text:SetText("Use")
        text:SetTextColor(1, 1, 1)
        useBtn.text = text

        -- Highlight
        local hl = useBtn:CreateTexture(nil, "HIGHLIGHT")
        hl:SetAllPoints()
        hl:SetColorTexture(1, 1, 1, 0.15)

        useBtn:SetScript("OnEnter", function(self)
            if self.toyID then
                GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                GameTooltip:SetToyByItemID(self.toyID)
                GameTooltip:Show()
            end
        end)
        useBtn:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)

        useButtons[i] = useBtn
    end
end

-- ------------------------------------
-- Create a single row frame for the scroll list
-- ------------------------------------
local function CreateRow(parent, index)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(PANEL_WIDTH - 40, ROW_HEIGHT)

    -- Hover highlight
    local highlight = row:CreateTexture(nil, "BACKGROUND")
    highlight:SetAllPoints()
    highlight:SetColorTexture(1, 1, 1, 0.05)
    highlight:Hide()
    row.highlight = highlight

    row:EnableMouse(true)
    row:SetScript("OnEnter", function(self)
        self.highlight:Show()
        if self.data then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetToyByItemID(self.data.itemID)
            if self.data.source then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Source: " .. self.data.source, 0.5, 0.8, 1, true)
            end
            GameTooltip:Show()
        end
    end)
    row:SetScript("OnLeave", function(self)
        self.highlight:Hide()
        GameTooltip:Hide()
    end)

    -- Icon
    local icon = row:CreateTexture(nil, "ARTWORK")
    icon:SetSize(ICON_SIZE, ICON_SIZE)
    icon:SetPoint("LEFT", 4, 0)
    icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.Icon = icon

    -- Owned checkmark overlay on icon
    local checkmark = row:CreateTexture(nil, "OVERLAY")
    checkmark:SetSize(16, 16)
    checkmark:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 2, -2)
    checkmark:SetTexture("Interface\\RaidFrame\\ReadyCheck-Ready")
    checkmark:Hide()
    row.Checkmark = checkmark

    -- Name
    local name = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    name:SetPoint("LEFT", icon, "RIGHT", 8, 6)
    name:SetWidth(280)
    name:SetJustifyH("LEFT")
    row.Name = name

    -- Source text
    local source = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    source:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
    source:SetWidth(280)
    source:SetJustifyH("LEFT")
    source:SetTextColor(0.5, 0.5, 0.5)
    row.Source = source

    -- Favorite star button
    local favBtn = CreateFrame("Button", nil, row)
    favBtn:SetSize(20, 20)
    favBtn:SetPoint("LEFT", icon, "RIGHT", 300, 0)

    local favTex = favBtn:CreateTexture(nil, "ARTWORK")
    favTex:SetAllPoints()
    favTex:SetTexture("Interface\\Common\\FavoritesIcon")
    favTex:SetDesaturated(true)
    favTex:SetAlpha(0.4)
    favBtn.tex = favTex

    local favHL = favBtn:CreateTexture(nil, "HIGHLIGHT")
    favHL:SetAllPoints()
    favHL:SetTexture("Interface\\Common\\FavoritesIcon")
    favHL:SetAlpha(0.3)

    favBtn:SetScript("OnClick", function(self)
        if self.itemID then
            ns:ToggleFavorite(self.itemID)
            RefreshPanel()
        end
    end)
    favBtn:SetScript("OnEnter", function(self)
        row.highlight:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Toggle Favorite", 1, 1, 1)
        GameTooltip:Show()
    end)
    favBtn:SetScript("OnLeave", function(self)
        row.highlight:Hide()
        GameTooltip:Hide()
    end)
    row.FavButton = favBtn

    -- Exclude toggle button
    local exclBtn = CreateFrame("Button", nil, row)
    exclBtn:SetSize(20, 20)
    exclBtn:SetPoint("LEFT", favBtn, "RIGHT", 8, 0)

    local exclTex = exclBtn:CreateTexture(nil, "ARTWORK")
    exclTex:SetAllPoints()
    exclTex:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    exclTex:SetAlpha(0.4)
    exclBtn.tex = exclTex

    local exclHL = exclBtn:CreateTexture(nil, "HIGHLIGHT")
    exclHL:SetAllPoints()
    exclHL:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
    exclHL:SetAlpha(0.3)

    exclBtn:SetScript("OnClick", function(self)
        if self.itemID then
            ns:ToggleExcluded(self.itemID)
            RefreshPanel()
        end
    end)
    exclBtn:SetScript("OnEnter", function(self)
        row.highlight:Show()
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine("Toggle Exclude from Random", 1, 1, 1)
        GameTooltip:AddLine("Excluded hearthstones won't be", 0.8, 0.8, 0.8)
        GameTooltip:AddLine("selected by the random button.", 0.8, 0.8, 0.8)
        GameTooltip:Show()
    end)
    exclBtn:SetScript("OnLeave", function(self)
        row.highlight:Hide()
        GameTooltip:Hide()
    end)
    row.ExclButton = exclBtn

    -- Separator line at bottom
    local sep = row:CreateTexture(nil, "ARTWORK")
    sep:SetHeight(1)
    sep:SetPoint("BOTTOMLEFT", 4, 0)
    sep:SetPoint("BOTTOMRIGHT", -4, 0)
    sep:SetColorTexture(0.3, 0.3, 0.3, 0.3)

    return row
end

-- ------------------------------------
-- Update a row with data
-- ------------------------------------
local function UpdateRow(row, data, useBtnIndex)
    if not data then
        row:Hide()
        return useBtnIndex
    end

    row.data = data
    row:Show()

    local isOwned = ns.ownedHearthstoneMap and ns.ownedHearthstoneMap[data.itemID] or false
    local isFavorite = ns.db and ns.db.favorites and ns.db.favorites[data.itemID] or false
    local isExcluded = ns.db and ns.db.excluded and ns.db.excluded[data.itemID] or false

    -- Icon
    local _, _, toyIcon = C_ToyBox.GetToyInfo(data.itemID)
    row.Icon:SetTexture(toyIcon or "Interface\\Icons\\INV_Misc_QuestionMark")

    if isOwned then
        row.Icon:SetDesaturated(false)
        row.Name:SetTextColor(1, 1, 1)
        row.Checkmark:Show()
    else
        row.Icon:SetDesaturated(true)
        row.Name:SetTextColor(0.5, 0.5, 0.5)
        row.Checkmark:Hide()
    end

    -- Name
    row.Name:SetText(data.name or "Unknown")

    -- Source
    row.Source:SetText(data.source or "")

    -- Favorite star
    row.FavButton.itemID = data.itemID
    if isFavorite then
        row.FavButton.tex:SetDesaturated(false)
        row.FavButton.tex:SetAlpha(1)
    else
        row.FavButton.tex:SetDesaturated(true)
        row.FavButton.tex:SetAlpha(0.4)
    end

    -- Exclude button
    row.ExclButton.itemID = data.itemID
    if isExcluded then
        row.ExclButton.tex:SetAlpha(1)
    else
        row.ExclButton.tex:SetAlpha(0.4)
    end

    -- Attach a "Use" secure button if owned and we have one available
    if isOwned and useBtnIndex and useBtnIndex <= NUM_USE_BUTTONS then
        local useBtn = useButtons[useBtnIndex]
        useBtn:SetParent(row)
        useBtn:ClearAllPoints()
        useBtn:SetPoint("RIGHT", row, "RIGHT", -8, 0)
        useBtn.toyID = data.itemID

        if not InCombatLockdown() then
            useBtn:SetAttribute("type", "toy")
            useBtn:SetAttribute("toy", data.itemID)
        end

        -- Check cooldown
        local startTime, duration, enable = GetItemCooldown(data.itemID)
        if duration and duration > 0 and enable == 1 then
            useBtn.bg:SetColorTexture(0.4, 0.4, 0.4, 0.6)
            useBtn.text:SetText("CD")
        else
            useBtn.bg:SetColorTexture(0.2, 0.6, 0.2, 0.6)
            useBtn.text:SetText("Use")
        end

        useBtn:Show()
        return useBtnIndex + 1
    end

    return useBtnIndex
end

-- ------------------------------------
-- Create a filter button
-- ------------------------------------
local function CreateFilterButton(parent, text, width)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width or 70, 24)

    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
    btn.bg = bg

    local border = btn:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0.4, 0.4, 0.4, 0.6)
    btn.border = border

    local label = btn:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("CENTER")
    label:SetText(text)
    btn.label = label

    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints()
    hl:SetColorTexture(1, 1, 1, 0.1)

    return btn
end

local function SetFilterActive(btn, active)
    if active then
        btn.bg:SetColorTexture(0.2, 0.4, 0.6, 0.8)
        btn.label:SetTextColor(1, 1, 1)
    else
        btn.bg:SetColorTexture(0.15, 0.15, 0.15, 0.8)
        btn.label:SetTextColor(0.7, 0.7, 0.7)
    end
end

-- ------------------------------------
-- Simple manual scroll panel (no ScrollBox template dependency)
-- Uses a clip frame + offset-based scrolling
-- ------------------------------------
local scrollOffset = 0
local maxVisible = 0
local rows = {}

local function GetMaxScroll()
    local totalRows = #filteredData
    local visible = maxVisible
    if totalRows <= visible then return 0 end
    return totalRows - visible
end

-- Forward declarations
local RefreshRows, RefreshPanel

local function ScrollTo(offset)
    offset = math.max(0, math.min(offset, GetMaxScroll()))
    scrollOffset = offset
    RefreshRows()
end

-- ------------------------------------
-- Refresh visible rows from filteredData
-- ------------------------------------
RefreshRows = function()
    -- Use buttons are SecureActionButtonTemplate frames. Hide/Show/SetParent
    -- are protected operations, so skip all use button manipulation in combat.
    local inCombat = InCombatLockdown()

    if not inCombat then
        for _, ub in ipairs(useButtons) do
            ub:Hide()
        end
    end

    local useBtnIdx = 1
    for i, row in ipairs(rows) do
        local dataIdx = scrollOffset + i
        local data = filteredData[dataIdx]
        useBtnIdx = UpdateRow(row, data, not inCombat and useBtnIdx) or useBtnIdx
    end

    -- Update scrollbar position
    if scrollBar then
        local maxScroll = GetMaxScroll()
        if maxScroll > 0 then
            scrollBar:SetMinMaxValues(0, maxScroll)
            scrollBar:SetValue(scrollOffset)
            scrollBar:Show()
        else
            scrollBar:Hide()
        end
    end
end

-- ------------------------------------
-- Full refresh: rebuild filtered list and update display
-- ------------------------------------
RefreshPanel = function()
    BuildFilteredList()
    UpdateCountText()
    scrollOffset = 0
    RefreshRows()
end

-- ------------------------------------
-- Initialize the Collections Tab
-- ------------------------------------
function ns:InitCollectionsTab()
    -- Ensure Blizzard_Collections is loaded
    C_AddOns.LoadAddOn("Blizzard_Collections")

    if not CollectionsJournal then
        return
    end

    -- Create the panel frame
    panel = CreateFrame("Frame", "HearthstoneHelperPanel", CollectionsJournal)
    panel:SetAllPoints()
    panel:Hide()

    -- Add tab via SecureTabs-2.0
    local SecureTabs = LibStub("SecureTabs-2.0", true)
    if SecureTabs then
        local tab = SecureTabs:Add(CollectionsJournal, panel, "Hearthstones")

        tab.OnSelect = function()
            RefreshPanel()
        end
    end

    -- === Title / Count ===
    local title = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 70, -30)
    title:SetText("Hearthstone Collection")

    countText = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    countText:SetPoint("LEFT", title, "RIGHT", 16, 0)

    -- === Search Box ===
    local searchBox = CreateFrame("EditBox", "HearthstoneHelperSearchBox", panel, "SearchBoxTemplate")
    searchBox:SetSize(180, 20)
    searchBox:SetPoint("TOPRIGHT", -30, -32)
    searchBox:SetScript("OnTextChanged", function(self)
        SearchBoxTemplate_OnTextChanged(self)
        searchText = self:GetText() or ""
        RefreshPanel()
    end)

    -- === Category Filter Buttons ===
    local catLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    catLabel:SetPoint("TOPLEFT", 16, -60)
    catLabel:SetText("Category:")
    catLabel:SetTextColor(0.7, 0.7, 0.7)

    local catButtons = {}
    local prevBtn
    for _, filter in ipairs(CATEGORY_FILTERS) do
        local btn = CreateFilterButton(panel, filter.label)
        if prevBtn then
            btn:SetPoint("LEFT", prevBtn, "RIGHT", 4, 0)
        else
            btn:SetPoint("LEFT", catLabel, "RIGHT", 8, 0)
        end
        btn.filterKey = filter.key
        btn:SetScript("OnClick", function(self)
            activeCategory = self.filterKey
            for _, cb in ipairs(catButtons) do
                SetFilterActive(cb, cb.filterKey == activeCategory)
            end
            RefreshPanel()
        end)
        SetFilterActive(btn, filter.key == activeCategory)
        table.insert(catButtons, btn)
        prevBtn = btn
    end

    -- === Ownership Filter Buttons ===
    local ownLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    ownLabel:SetPoint("LEFT", prevBtn, "RIGHT", 20, 0)
    ownLabel:SetText("Show:")
    ownLabel:SetTextColor(0.7, 0.7, 0.7)

    local ownButtons = {}
    prevBtn = nil
    for _, filter in ipairs(OWNERSHIP_FILTERS) do
        local btn = CreateFilterButton(panel, filter.label)
        if prevBtn then
            btn:SetPoint("LEFT", prevBtn, "RIGHT", 4, 0)
        else
            btn:SetPoint("LEFT", ownLabel, "RIGHT", 8, 0)
        end
        btn.filterKey = filter.key
        btn:SetScript("OnClick", function(self)
            activeOwnership = self.filterKey
            for _, ob in ipairs(ownButtons) do
                SetFilterActive(ob, ob.filterKey == activeOwnership)
            end
            RefreshPanel()
        end)
        SetFilterActive(btn, filter.key == activeOwnership)
        table.insert(ownButtons, btn)
        prevBtn = btn
    end

    -- === Column headers ===
    local headerY = -88
    local headerBg = panel:CreateTexture(nil, "BACKGROUND")
    headerBg:SetPoint("TOPLEFT", 8, headerY)
    headerBg:SetPoint("TOPRIGHT", -8, headerY)
    headerBg:SetHeight(22)
    headerBg:SetColorTexture(0.1, 0.1, 0.1, 0.5)

    local hdrIcon = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrIcon:SetPoint("TOPLEFT", 16, headerY - 4)
    hdrIcon:SetText("Icon")
    hdrIcon:SetTextColor(0.7, 0.7, 0.7)

    local hdrName = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrName:SetPoint("TOPLEFT", 64, headerY - 4)
    hdrName:SetText("Name / Source")
    hdrName:SetTextColor(0.7, 0.7, 0.7)

    local hdrFav = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrFav:SetPoint("TOPLEFT", 364, headerY - 4)
    hdrFav:SetText("Fav")
    hdrFav:SetTextColor(0.7, 0.7, 0.7)

    local hdrExcl = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrExcl:SetPoint("TOPLEFT", 396, headerY - 4)
    hdrExcl:SetText("Excl")
    hdrExcl:SetTextColor(0.7, 0.7, 0.7)

    local hdrUse = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hdrUse:SetPoint("TOPRIGHT", -20, headerY - 4)
    hdrUse:SetText("Action")
    hdrUse:SetTextColor(0.7, 0.7, 0.7)

    -- === Scroll area ===
    local scrollAreaTop = headerY - 24

    -- Clip frame for row content
    local clipFrame = CreateFrame("Frame", nil, panel)
    clipFrame:SetPoint("TOPLEFT", 8, scrollAreaTop)
    clipFrame:SetPoint("BOTTOMRIGHT", -28, 8)
    clipFrame:SetClipsChildren(true)

    -- Calculate visible rows
    -- The panel height inside CollectionsJournal is approximately 524 total
    -- minus top offset (~112) minus bottom padding (8) = ~404 usable
    local usableHeight = 404
    maxVisible = math.floor(usableHeight / ROW_HEIGHT)

    -- Create row frames
    for i = 1, maxVisible do
        local row = CreateRow(clipFrame, i)
        row:SetPoint("TOPLEFT", 0, -((i - 1) * ROW_HEIGHT))
        rows[i] = row
    end

    -- Create the secure action button pool
    CreateUseButtonPool(clipFrame)

    -- === Scrollbar ===
    scrollBar = CreateFrame("Slider", nil, panel, "UIPanelScrollBarTemplate")
    scrollBar:SetPoint("TOPRIGHT", -10, scrollAreaTop - 16)
    scrollBar:SetPoint("BOTTOMRIGHT", -10, 24)
    scrollBar:SetWidth(16)
    scrollBar:SetMinMaxValues(0, 1)
    scrollBar:SetValueStep(1)
    scrollBar:SetValue(0)
    scrollBar:SetObeyStepOnDrag(true)

    scrollBar:SetScript("OnValueChanged", function(self, value)
        ScrollTo(math.floor(value + 0.5))
    end)

    -- Mouse wheel scrolling on the clip frame
    clipFrame:EnableMouseWheel(true)
    clipFrame:SetScript("OnMouseWheel", function(self, delta)
        ScrollTo(scrollOffset - delta * 3)
    end)

    -- Also allow mouse wheel on the panel itself
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(self, delta)
        ScrollTo(scrollOffset - delta * 3)
    end)

    -- === Register for updates ===
    ns:RegisterCallback("HEARTHSTONES_UPDATED", function()
        if panel:IsShown() then
            RefreshPanel()
        end
    end)

    -- Panel show handler: refresh on every show
    panel:SetScript("OnShow", function()
        RefreshPanel()
    end)

    -- Refresh use buttons when combat ends (they were skipped during combat)
    local combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatFrame:SetScript("OnEvent", function()
        if panel:IsShown() then
            RefreshRows()
        end
    end)
end

-- ------------------------------------
-- Initialize when addon is ready
-- ------------------------------------
ns:RegisterCallback("ADDON_READY", function()
    ns:InitCollectionsTab()
end)
