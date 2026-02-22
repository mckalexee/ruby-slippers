local _, ns = ...

-- ============================================================
-- CollectionsTab.lua - Hearthstone Collection Panel
-- Adds a "Hearthstones" tab to the Collections Journal via
-- SecureTabs-2.0. Displays all known hearthstones in a grid
-- matching the Blizzard Toy Box visual style.
-- ============================================================

-- Layout constants matching Blizzard Toy Box
local ITEMS_PER_ROW = 3
local ITEMS_PER_PAGE = 18 -- 3 columns x 6 rows
local BUTTON_SIZE = 50
local ICON_SIZE = 42
local COL_SPACING = 208 -- Horizontal distance between button origins
local ROW_SPACING = 16  -- Vertical gap between rows
local GRID_OFFSET_X = 40
local GRID_OFFSET_Y = -53
local NAME_WIDTH = 135

-- Filter state
local activeOwnership = "all"
local searchText = ""

-- Panel references (set during init)
local panel
local filteredData = {}
local cells = {}
local currentPage = 1
local totalPages = 1
local pageText, prevPageBtn, nextPageBtn
local progressBar, progressText

-- Forward declarations
local RefreshPage, RefreshPanel

-- ------------------------------------
-- Build the filtered data list
-- ------------------------------------
local function BuildFilteredList()
    filteredData = {}
    if not ns.HearthstoneData then return end

    local searchLower = searchText:lower()

    for _, entry in ipairs(ns.HearthstoneData) do
        local dominated = false

        -- Ownership filter
        if activeOwnership ~= "all" then
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
            if not nameLower:find(searchLower, 1, true)
               and not sourceLower:find(searchLower, 1, true) then
                dominated = true
            end
        end

        if not dominated then
            tinsert(filteredData, entry)
        end
    end

    -- Sort: owned first, then garrison/dalaran last, favorites first, then alphabetical
    table.sort(filteredData, function(a, b)
        local aOwned = ns.ownedHearthstoneMap and ns.ownedHearthstoneMap[a.itemID] or false
        local bOwned = ns.ownedHearthstoneMap and ns.ownedHearthstoneMap[b.itemID] or false
        if aOwned ~= bOwned then return aOwned end
        local aSpecial = a.category == "garrison" or a.category == "dalaran"
        local bSpecial = b.category == "garrison" or b.category == "dalaran"
        if aSpecial ~= bSpecial then return bSpecial end
        local aFav, bFav = false, false
        if not a.isBagItem then
            local _, _, _, f = C_ToyBox.GetToyInfo(a.itemID)
            aFav = f or false
        end
        if not b.isBagItem then
            local _, _, _, f = C_ToyBox.GetToyInfo(b.itemID)
            bFav = f or false
        end
        if aFav ~= bFav then return aFav end
        return (a.name or "") < (b.name or "")
    end)
end

-- ------------------------------------
-- Update progress bar
-- ------------------------------------
local function UpdateProgressBar()
    if not progressBar then return end
    local total = ns.HearthstoneData and #ns.HearthstoneData or 0
    local owned = ns.ownedHearthstones and #ns.ownedHearthstones or 0
    progressBar:SetMinMaxValues(0, math.max(1, total))
    progressBar:SetValue(owned)
    if progressText then
        progressText:SetFormattedText("%d / %d", owned, total)
    end
end

-- ------------------------------------
-- Show right-click context menu for a hearthstone
-- ------------------------------------
local function ShowContextMenu(cellFrame, itemID)
    if not itemID then return end
    local isOwned = ns.ownedHearthstoneMap and ns.ownedHearthstoneMap[itemID]
    if not isOwned then return end

    local isBagItem = ns:IsBagItem(itemID)
    local isFavorite = false
    if not isBagItem then
        local _, _, _, toyFav = C_ToyBox.GetToyInfo(itemID)
        isFavorite = toyFav
    end
    local isExcluded = ns.db and ns.db.excluded and ns.db.excluded[itemID]
    local isCategoryControlled = itemID == ns.GarrisonHearthstoneID
        or itemID == ns.DalaranHearthstoneID
        or itemID == ns.DefaultHearthstoneID

    MenuUtil.CreateContextMenu(cellFrame, function(_, rootDescription)
        if not isBagItem then
            if isFavorite then
                rootDescription:CreateButton("Unfavorite", function()
                    ns:ToggleFavorite(itemID)
                end)
            else
                rootDescription:CreateButton("Set Favorite", function()
                    ns:ToggleFavorite(itemID)
                end)
            end
        end

        if isCategoryControlled then
            rootDescription:CreateButton("Controlled by Settings (/rs config)")
        elseif isExcluded then
            rootDescription:CreateButton("Include in Random", function()
                ns:ToggleExcluded(itemID)
            end)
        else
            rootDescription:CreateButton("Exclude from Random", function()
                ns:ToggleExcluded(itemID)
            end)
        end
    end)
end

-- ------------------------------------
-- Create a single grid cell (SecureActionButton for toy use)
-- ------------------------------------
local function CreateCell(parent, index)
    local btn = CreateFrame("Button", "RSCell" .. index, parent, "SecureActionButtonTemplate")
    btn:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:SetAttribute("useOnKeyDown", false)
    btn:RegisterForDrag("LeftButton")
    btn:Hide()

    -- Icon texture (collected/owned)
    local iconTex = btn:CreateTexture(nil, "ARTWORK")
    iconTex:SetSize(ICON_SIZE, ICON_SIZE)
    iconTex:SetPoint("CENTER", btn, "CENTER", 0, 1)
    iconTex:SetTexCoord(0.043, 0.957, 0.043, 0.957)
    btn.iconTexture = iconTex

    -- Icon texture (uncollected - desaturated, faded)
    local iconUncollected = btn:CreateTexture(nil, "ARTWORK")
    iconUncollected:SetSize(ICON_SIZE, ICON_SIZE - 1)
    iconUncollected:SetPoint("CENTER", btn, "CENTER", 0, 2)
    iconUncollected:SetTexCoord(0.063, 0.938, 0.063, 0.938)
    iconUncollected:SetDesaturated(true)
    iconUncollected:SetAlpha(0.18)
    iconUncollected:Hide()
    btn.iconTextureUncollected = iconUncollected

    -- Collected border (gold) - atlas
    local borderCollected = btn:CreateTexture(nil, "OVERLAY", nil, 1)
    borderCollected:SetSize(56, 56)
    borderCollected:SetPoint("CENTER", btn, "CENTER", 0, 0)
    borderCollected:SetAtlas("collections-itemborder-collected")
    borderCollected:Hide()
    btn.slotFrameCollected = borderCollected

    -- Uncollected border (gray) - atlas
    local borderUncollected = btn:CreateTexture(nil, "OVERLAY", nil, 1)
    borderUncollected:SetSize(50, 50)
    borderUncollected:SetPoint("CENTER", btn, "CENTER", 0, 2)
    borderUncollected:SetAtlas("collections-itemborder-uncollected")
    borderUncollected:Hide()
    btn.slotFrameUncollected = borderUncollected

    -- Uncollected inner glow - atlas (useAtlasSize=true to avoid stretching)
    local innerGlow = btn:CreateTexture(nil, "ARTWORK")
    innerGlow:SetPoint("CENTER", btn, "CENTER", 0, 2)
    innerGlow:SetAtlas("collections-itemborder-uncollected-innerglow", true)
    innerGlow:SetAlpha(0.18)
    innerGlow:Hide()
    btn.innerGlow = innerGlow

    -- Name text (to the right of the icon)
    local name = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    name:SetJustifyH("LEFT")
    name:SetWidth(NAME_WIDTH)
    name:SetMaxLines(3)
    name:SetPoint("LEFT", iconTex, "RIGHT", 9, 3)
    btn.name = name

    -- Favorite star - atlas
    local favStar = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    favStar:SetPoint("TOPLEFT", btn, "TOPLEFT", -12, 13)
    favStar:SetAtlas("collections-icon-favorites", true)
    favStar:Hide()
    btn.favoriteStar = favStar

    -- Excluded overlay (red tint + X icon)
    local excludedOverlay = btn:CreateTexture(nil, "ARTWORK", nil, 2)
    excludedOverlay:SetAllPoints(iconTex)
    excludedOverlay:SetColorTexture(0.5, 0, 0, 0.4)
    excludedOverlay:Hide()
    btn.excludedOverlay = excludedOverlay

    local excludedIcon = btn:CreateTexture(nil, "OVERLAY", nil, 2)
    excludedIcon:SetSize(20, 20)
    excludedIcon:SetPoint("BOTTOMRIGHT", iconTex, "BOTTOMRIGHT", 2, -2)
    excludedIcon:SetAtlas("transmog-icon-hidden", true)
    excludedIcon:Hide()
    btn.excludedIcon = excludedIcon

    -- Cooldown frame
    local cooldown = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
    cooldown:SetPoint("TOPLEFT", iconTex, "TOPLEFT", 0, 0)
    cooldown:SetPoint("BOTTOMRIGHT", iconTex, "BOTTOMRIGHT", 0, 0)
    btn.cooldown = cooldown

    -- Highlight texture (ADD blend like Blizzard)
    local hl = btn:CreateTexture(nil, "HIGHLIGHT")
    hl:SetSize(48, 48)
    hl:SetPoint("CENTER", btn, "CENTER", 0, 2)
    hl:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    hl:SetBlendMode("ADD")

    -- Pushed texture (pre-created, toggled on mouse down/up)
    local pushedTex = btn:CreateTexture(nil, "ARTWORK", nil, 7)
    pushedTex:SetSize(ICON_SIZE, ICON_SIZE)
    pushedTex:SetPoint("CENTER", btn, "CENTER", 0, 1)
    pushedTex:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
    pushedTex:SetAlpha(0)

    btn:SetScript("OnMouseDown", function()
        pushedTex:SetAlpha(1)
    end)
    btn:SetScript("OnMouseUp", function()
        pushedTex:SetAlpha(0)
    end)

    -- Tooltip
    btn:SetScript("OnEnter", function(self)
        if not self.itemID then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        if self.isBagItem then
            GameTooltip:SetItemByID(self.itemID)
        else
            GameTooltip:SetToyByItemID(self.itemID)
        end
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    -- Drag: pick up toy for action bar placement
    btn:SetScript("OnDragStart", function(self)
        if self.itemID and not InCombatLockdown() then
            if self.isBagItem then
                -- Find the item in bags and pick it up
                for bag = 0, 4 do
                    for slot = 1, C_Container.GetContainerNumSlots(bag) do
                        local info = C_Container.GetContainerItemInfo(bag, slot)
                        if info and info.itemID == self.itemID then
                            C_Container.PickupContainerItem(bag, slot)
                            return
                        end
                    end
                end
            else
                C_ToyBox.PickupToyBoxItem(self.itemID)
            end
        end
    end)

    -- Right-click: context menu (handled in PostClick since we use SecureActionButtonTemplate)
    btn:SetScript("PreClick", function(self, button)
        if InCombatLockdown() then return end
        if button == "RightButton" then
            self:SetAttribute("type", nil) -- Suppress secure action for right-click
        else
            -- Left-click: use the hearthstone
            local isOwned = self.itemID and ns.ownedHearthstoneMap and ns.ownedHearthstoneMap[self.itemID]
            if isOwned then
                if self.isBagItem then
                    self:SetAttribute("type", "item")
                    self:SetAttribute("item", "item:" .. self.itemID)
                else
                    self:SetAttribute("type", "toy")
                    self:SetAttribute("toy", self.itemID)
                end
            else
                self:SetAttribute("type", nil)
            end
        end
    end)

    btn:SetScript("PostClick", function(self, button)
        if button == "RightButton" then
            ShowContextMenu(self, self.itemID)
        end
    end)

    btn.cellIndex = index
    return btn
end

-- ------------------------------------
-- Update a single cell with data
-- ------------------------------------
local function UpdateCell(cell, data)
    if not data then
        cell:Hide()
        cell.itemID = nil
        cell.isBagItem = false
        return
    end

    cell.itemID = data.itemID
    cell.isBagItem = data.isBagItem or false
    cell:Show()

    local isOwned = ns.ownedHearthstoneMap and ns.ownedHearthstoneMap[data.itemID] or false
    local isFavorite = false
    local icon
    if data.isBagItem then
        local _, _, _, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(data.itemID)
        icon = itemIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
    else
        local _, _, toyIcon, toyFav = C_ToyBox.GetToyInfo(data.itemID)
        icon = toyIcon or "Interface\\Icons\\INV_Misc_QuestionMark"
        isFavorite = toyFav or false
    end
    -- Effective exclusion: per-item OR category setting
    local isExcluded = ns.db and ns.db.excluded and ns.db.excluded[data.itemID] or false
    if not isExcluded and ns.db then
        if data.isBagItem and not ns.db.includeDefaultHearthstone then
            isExcluded = true
        elseif data.category == "garrison" and not ns.db.includeGarrison then
            isExcluded = true
        elseif data.category == "dalaran" and not ns.db.includeDalaran then
            isExcluded = true
        end
    end

    if isOwned then
        -- Collected: full color icon, gold text, gold border
        cell.iconTexture:SetTexture(icon)
        cell.iconTexture:Show()
        cell.iconTextureUncollected:Hide()
        cell.slotFrameCollected:Show()
        cell.slotFrameUncollected:Hide()
        cell.innerGlow:Hide()
        cell.name:SetTextColor(1, 0.82, 0, 1)
        cell.name:SetShadowColor(0, 0, 0, 1)

        -- Favorite star
        cell.favoriteStar:SetShown(isFavorite)

        -- Excluded overlay
        cell.excludedOverlay:SetShown(isExcluded)
        cell.excludedIcon:SetShown(isExcluded)

        -- Cooldown
        local startTime, duration, enable = GetItemCooldown(data.itemID)
        if duration and duration > 0 and enable == 1 then
            cell.cooldown:SetCooldown(startTime, duration)
        else
            cell.cooldown:Clear()
        end
    else
        -- Uncollected: desaturated, faded, gray border
        cell.iconTexture:Hide()
        cell.iconTextureUncollected:SetTexture(icon)
        cell.iconTextureUncollected:Show()
        cell.slotFrameCollected:Hide()
        cell.slotFrameUncollected:Show()
        cell.innerGlow:Show()
        cell.name:SetTextColor(0.33, 0.27, 0.20, 1)
        cell.name:SetShadowColor(0, 0, 0, 0.33)
        cell.favoriteStar:Hide()
        cell.excludedOverlay:Hide()
        cell.excludedIcon:Hide()
        cell.cooldown:Clear()
    end

    cell.name:SetText(data.name or "Unknown")
end

-- ------------------------------------
-- Refresh visible cells for the current page
-- ------------------------------------
RefreshPage = function()
    local startIdx = (currentPage - 1) * ITEMS_PER_PAGE

    for i, cell in ipairs(cells) do
        local dataIdx = startIdx + i
        UpdateCell(cell, filteredData[dataIdx])
    end

    -- Update paging controls
    if pageText then
        pageText:SetFormattedText("Page %d / %d", currentPage, totalPages)
    end
    if prevPageBtn then
        if currentPage > 1 then
            prevPageBtn:Enable()
        else
            prevPageBtn:Disable()
        end
    end
    if nextPageBtn then
        if currentPage < totalPages then
            nextPageBtn:Enable()
        else
            nextPageBtn:Disable()
        end
    end
end

-- ------------------------------------
-- Full refresh: rebuild filtered list and update display
-- ------------------------------------
RefreshPanel = function()
    BuildFilteredList()
    UpdateProgressBar()
    totalPages = math.max(1, math.ceil(#filteredData / ITEMS_PER_PAGE))
    if currentPage > totalPages then
        currentPage = totalPages
    end
    RefreshPage()
end

-- ------------------------------------
-- Initialize the Collections Tab
-- ------------------------------------
function ns:InitCollectionsTab()
    C_AddOns.LoadAddOn("Blizzard_Collections")
    if not CollectionsJournal then return end

    -- Create the panel frame with PortraitFrameTemplate (provides its own
    -- NineSlice, PortraitContainer, CloseButton, TitleContainer chrome).
    -- SecureTabs will manage show/hide and calls SetAllPoints(true) + SetFrameLevel(+600).
    panel = CreateFrame("Frame", "RubySlippersPanel", CollectionsJournal, "PortraitFrameTemplate")
    panel:Hide()
    panel:SetAllPoints()
    panel:SetPortraitToAsset("Interface\\Icons\\INV_Misc_Rune_01")
    panel:SetTitle("Ruby Slippers")

    -- Mouse blocker to prevent clicks reaching content underneath
    panel:EnableMouse(true)

    -- === Progress bar (green bar matching Blizzard style) ===
    progressBar = CreateFrame("StatusBar", nil, panel)
    progressBar:SetSize(196, 13)
    progressBar:SetPoint("TOP", panel, "TOP", 0, -39)
    progressBar:SetStatusBarTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar")
    progressBar:SetStatusBarColor(0.03125, 0.85, 0.0)
    progressBar:SetMinMaxValues(0, 1)
    progressBar:SetValue(0)

    -- Progress bar border
    local barBorder = progressBar:CreateTexture(nil, "OVERLAY")
    barBorder:SetSize(205, 29)
    barBorder:SetPoint("CENTER")
    barBorder:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")

    -- Progress text
    progressText = progressBar:CreateFontString(nil, "OVERLAY", "TextStatusBarText")
    progressText:SetPoint("CENTER")
    progressText:SetText("0 / 0")

    -- === Search Box ===
    local searchBox = CreateFrame("EditBox", "RSSearchBox", panel, "SearchBoxTemplate")
    searchBox:SetSize(115, 20)
    searchBox:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -107, -35)
    searchBox:SetScript("OnTextChanged", function(self)
        SearchBoxTemplate_OnTextChanged(self)
        searchText = self:GetText() or ""
        currentPage = 1
        RefreshPanel()
    end)

    -- === Filter dropdown (Collected/Uncollected) ===
    local filterBtn = CreateFrame("DropdownButton", "RSFilterBtn", panel, "WowStyle1FilterDropdownTemplate")
    filterBtn:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -12, -35)
    filterBtn:SetWidth(90)
    filterBtn.Text:SetText("Filter")
    filterBtn:SetupMenu(function(_, rootDescription)
        rootDescription:CreateTitle("Collection")

        local function IsChecked(key)
            return activeOwnership == key
        end
        local function SetFilter(key)
            activeOwnership = key
            currentPage = 1
            RefreshPanel()
        end

        rootDescription:CreateRadio("All", IsChecked, SetFilter, "all")
        rootDescription:CreateRadio("Collected", IsChecked, SetFilter, "owned")
        rootDescription:CreateRadio("Not Collected", IsChecked, SetFilter, "unowned")
    end)

    -- === Icons frame (InsetFrameTemplate provides tiled marble background + inset border) ===
    local iconsFrame = CreateFrame("Frame", nil, panel, "InsetFrameTemplate")
    iconsFrame:SetPoint("TOPLEFT", 4, -60)
    iconsFrame:SetPoint("BOTTOMRIGHT", -6, 5)

    -- Create 18 cells in a 3x6 grid
    for i = 1, ITEMS_PER_PAGE do
        local row = math.ceil(i / ITEMS_PER_ROW) - 1
        local col = (i - 1) % ITEMS_PER_ROW

        local cell = CreateCell(iconsFrame, i)
        cell:SetPoint("TOPLEFT", iconsFrame, "TOPLEFT",
            GRID_OFFSET_X + (col * COL_SPACING),
            GRID_OFFSET_Y - (row * (BUTTON_SIZE + ROW_SPACING)))
        cells[i] = cell
    end

    -- === Paging Controls (matching CollectionsPagingFrameTemplate) ===
    local pagingFrame = CreateFrame("Frame", nil, panel)
    pagingFrame:SetSize(180, 32)
    pagingFrame:SetPoint("BOTTOM", panel, "BOTTOM", 21, 43)

    prevPageBtn = CreateFrame("Button", nil, pagingFrame)
    prevPageBtn:SetSize(32, 32)
    prevPageBtn:SetPoint("CENTER", pagingFrame, "CENTER", -50, 0)
    prevPageBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
    prevPageBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
    prevPageBtn:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Disabled")
    prevPageBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    prevPageBtn:SetScript("OnClick", function()
        if currentPage > 1 then
            currentPage = currentPage - 1
            RefreshPage()
        end
    end)

    pageText = pagingFrame:CreateFontString(nil, "OVERLAY", "GameFontWhite")
    pageText:SetPoint("CENTER", pagingFrame, "CENTER", 0, 0)
    pageText:SetText("Page 1 / 1")

    nextPageBtn = CreateFrame("Button", nil, pagingFrame)
    nextPageBtn:SetSize(32, 32)
    nextPageBtn:SetPoint("CENTER", pagingFrame, "CENTER", 50, 0)
    nextPageBtn:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
    nextPageBtn:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
    nextPageBtn:SetDisabledTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Disabled")
    nextPageBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    nextPageBtn:SetScript("OnClick", function()
        if currentPage < totalPages then
            currentPage = currentPage + 1
            RefreshPage()
        end
    end)

    -- Mouse wheel paging on the panel
    panel:EnableMouseWheel(true)
    panel:SetScript("OnMouseWheel", function(_, delta)
        if delta > 0 and currentPage > 1 then
            currentPage = currentPage - 1
            RefreshPage()
        elseif delta < 0 and currentPage < totalPages then
            currentPage = currentPage + 1
            RefreshPage()
        end
    end)

    -- === Add tab via SecureTabs-2.0 ===
    local SecureTabs = LibStub("SecureTabs-2.0", true)
    if SecureTabs then
        local tab = SecureTabs:Add(CollectionsJournal, panel, "Hearthstones")
        ns.collectionsTab = tab

        tab.OnSelect = function()
            RefreshPanel()
        end
    end

    -- Panel show handler
    panel:SetScript("OnShow", function()
        RefreshPanel()
    end)

    -- Register for updates
    ns:RegisterCallback("HEARTHSTONES_UPDATED", function()
        if panel:IsShown() then
            RefreshPanel()
        end
    end)

    -- Refresh when combat ends (secure buttons may need attribute updates)
    local combatFrame = CreateFrame("Frame")
    combatFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    combatFrame:SetScript("OnEvent", function()
        if panel:IsShown() then
            RefreshPage()
        end
    end)
end

-- ------------------------------------
-- Initialize when addon is ready
-- ------------------------------------
ns:RegisterCallback("ADDON_READY", function()
    ns:InitCollectionsTab()
end)
