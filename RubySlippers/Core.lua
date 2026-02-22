local addonName, ns = ...

-- =============================================================================
-- Ruby Slippers - Core
-- Addon initialization, hearthstone scanning, random selection, slash commands
-- =============================================================================

-- SavedVariables defaults
local defaults = {
    excluded = {},
    includeDefaultHearthstone = true,
    includeGarrison = false,
    includeDalaran = false,
    favoritesOnly = false,
    buttonScale = 1.0,
    buttonShown = true,
    buttonLocked = false,
    createMacro = false,
    showMinimap = true,
    buttonPosition = nil,
}

-- Deep-merge defaults into saved variables (handles nil vs false properly)
local function ApplyDefaults(target, source)
    for k, v in pairs(source) do
        if target[k] == nil then
            if type(v) == "table" then
                target[k] = CopyTable(v)
            else
                target[k] = v
            end
        elseif type(v) == "table" and type(target[k]) == "table" then
            ApplyDefaults(target[k], v)
        end
    end
end

-- Simple callback system for UI updates
local callbacks = {}

function ns:RegisterCallback(event, func)
    if not callbacks[event] then
        callbacks[event] = {}
    end
    tinsert(callbacks[event], func)
end

function ns:FireCallback(event, ...)
    local cbs = callbacks[event]
    if cbs then
        for _, func in ipairs(cbs) do
            func(...)
        end
    end
end

-- Utility print
function ns.Print(msg)
    print(format("|cFF33FF99[Ruby Slippers]|r %s", msg))
end

-- Owned hearthstones cache
ns.ownedHearthstones = {}
ns.ownedHearthstoneMap = {}

-- Scan all owned hearthstones (toys + bag items)
function ns:ScanOwnedHearthstones()
    wipe(self.ownedHearthstones)
    wipe(self.ownedHearthstoneMap)

    for _, data in ipairs(self.HearthstoneData) do
        local isOwned = false
        local name, icon

        if data.isBagItem then
            isOwned = GetItemCount(data.itemID) > 0
            if isOwned then
                local itemName, _, _, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(data.itemID)
                name = itemName
                icon = itemIcon
            end
        else
            isOwned = PlayerHasToy(data.itemID)
            if isOwned then
                local _, toyName, toyIcon = C_ToyBox.GetToyInfo(data.itemID)
                name = toyName
                icon = toyIcon
            end
        end

        if isOwned then
            tinsert(self.ownedHearthstones, {
                itemID    = data.itemID,
                name      = name or data.name,
                icon      = icon or 0,
                category  = data.category,
                source    = data.source,
                isBagItem = data.isBagItem or false,
            })
            self.ownedHearthstoneMap[data.itemID] = true
        end
    end

    self:FireCallback("HEARTHSTONES_UPDATED")
end

-- Get a random hearthstone from owned list, filtered by user settings
function ns:GetRandomHearthstone()
    local db = self.db
    local candidates = {}

    for _, hs in ipairs(self.ownedHearthstones) do
        local dominated = false

        -- Check exclusion
        if db.excluded[hs.itemID] then
            dominated = true
        end

        -- Check favorites-only mode (uses Blizzard's native favorites)
        if not dominated and db.favoritesOnly then
            if hs.isBagItem then
                -- Bag items can't be Blizzard-favorited; exclude in favorites-only mode
                dominated = true
            else
                local _, _, _, isFav = C_ToyBox.GetToyInfo(hs.itemID)
                if not isFav then
                    dominated = true
                end
            end
        end

        -- Check category-controlled inclusion
        if not dominated and hs.isBagItem and not db.includeDefaultHearthstone then
            dominated = true
        end
        if not dominated and hs.category == "garrison" and not db.includeGarrison then
            dominated = true
        end
        if not dominated and hs.category == "dalaran" and not db.includeDalaran then
            dominated = true
        end

        if not dominated then
            tinsert(candidates, hs)
        end
    end

    if #candidates == 0 then
        return nil
    end

    return candidates[math.random(#candidates)]
end

-- Get info about a specific hearthstone
function ns:GetHearthstoneInfo(itemID)
    local db = self.db

    -- Find the data entry
    local data
    for _, d in ipairs(self.HearthstoneData) do
        if d.itemID == itemID then
            data = d
            break
        end
    end

    if not data then
        return nil
    end

    local name, icon, isFavorite
    if data.isBagItem then
        local itemName, _, _, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(itemID)
        name = itemName
        icon = itemIcon
        isFavorite = false
    else
        local _, toyName, toyIcon, toyFav = C_ToyBox.GetToyInfo(itemID)
        name = toyName
        icon = toyIcon
        isFavorite = toyFav or false
    end

    local isOwned = self.ownedHearthstoneMap[itemID] or false
    local isExcluded = db.excluded[itemID] or false
    local isOnCooldown, cooldownRemaining = self:IsOnCooldown(itemID)

    return name or data.name, icon or 0, data.category, isOwned, isFavorite, isExcluded, isOnCooldown, cooldownRemaining
end

-- Check if a hearthstone toy is on cooldown
function ns:IsOnCooldown(itemID)
    local startTime, duration = GetItemCooldown(itemID)
    if startTime and startTime > 0 and duration > 0 then
        local remaining = (startTime + duration) - GetTime()
        if remaining > 0 then
            return true, remaining
        end
    end
    return false, 0
end

-- Toggle favorite status (uses Blizzard's native toy favorite system)
function ns:ToggleFavorite(itemID)
    if self:IsBagItem(itemID) then return end
    local _, _, _, isFavorite = C_ToyBox.GetToyInfo(itemID)
    C_ToyBox.SetIsFavorite(itemID, not isFavorite)
    self:FireCallback("HEARTHSTONES_UPDATED")
end

-- Toggle excluded status
function ns:ToggleExcluded(itemID)
    local db = self.db
    if db.excluded[itemID] then
        db.excluded[itemID] = nil
    else
        db.excluded[itemID] = true
    end
    self:FireCallback("HEARTHSTONES_UPDATED")
end

-- Event handlers
local events = {}

function events:ADDON_LOADED(loadedAddon)
    if loadedAddon ~= addonName then return end

    -- Initialize saved variables
    if not RubySlippersDB then
        RubySlippersDB = {}
    end
    ApplyDefaults(RubySlippersDB, defaults)
    ns.db = RubySlippersDB

    self:UnregisterEvent("ADDON_LOADED")

    -- Initialize settings panel (deferred to ensure db is ready)
    if ns.InitConfig then
        ns:InitConfig()
    end
end

function events:PLAYER_ENTERING_WORLD()
    -- Migrate old addon favorites to Blizzard's native toy favorite system
    if ns.db.favorites then
        for itemID in pairs(ns.db.favorites) do
            if PlayerHasToy(itemID) then
                C_ToyBox.SetIsFavorite(itemID, true)
            end
        end
        ns.db.favorites = nil
    end

    ns:ScanOwnedHearthstones()
    ns:FireCallback("ADDON_READY")
    self:UnregisterEvent("PLAYER_ENTERING_WORLD")
end

function events:TOYS_UPDATED()
    ns:ScanOwnedHearthstones()
end

function events:NEW_TOY_ADDED()
    ns:ScanOwnedHearthstones()
end

function events:BAG_UPDATE_DELAYED()
    ns:ScanOwnedHearthstones()
end

-- Core event frame
local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...)
    if events[event] then
        events[event](self, ...)
    end
end)
for event in pairs(events) do
    frame:RegisterEvent(event)
end

-- Slash commands are registered in UI.lua which handles the full command set
