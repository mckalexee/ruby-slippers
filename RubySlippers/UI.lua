local _, ns = ...

-- ============================================================
-- UI.lua - Secure Action Button & Floating Frame
-- Creates a movable floating button that uses a random hearthstone
-- on click. Supports /click RubySlippersButton macro.
-- ============================================================

-- ------------------------------------
-- Backdrop style for the button frame
-- ------------------------------------
local BUTTON_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

-- ------------------------------------
-- Container frame (movable, has border)
-- ------------------------------------
local frame = CreateFrame("Frame", "RubySlippersButtonFrame", UIParent, "BackdropTemplate")
frame:SetSize(52, 52)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetBackdrop(BUTTON_BACKDROP)
frame:SetBackdropColor(0, 0, 0, 0.6)
frame:SetBackdropBorderColor(0.6, 0.6, 0.6, 0.8)
frame:SetClampedToScreen(true)
frame:SetFrameStrata("MEDIUM")
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:Hide() -- Hidden until initialized

frame:SetScript("OnDragStart", function(self)
    if ns.db and ns.db.buttonLocked then return end
    self:StartMoving()
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    -- Save position
    if ns.db then
        local point, _, relPoint, x, y = self:GetPoint()
        ns.db.buttonPosition = { point = point, relPoint = relPoint, x = x, y = y }
    end
end)

-- ------------------------------------
-- Secure action button (global name for /click macro)
-- ------------------------------------
local btn = CreateFrame("Button", "RubySlippersButton", frame, "SecureActionButtonTemplate")
btn:SetSize(44, 44)
btn:SetPoint("CENTER", frame, "CENTER", 0, 0)
btn:RegisterForClicks("AnyUp")
btn:SetAttribute("useOnKeyDown", false)

-- Icon texture
local iconTex = btn:CreateTexture(nil, "ARTWORK")
iconTex:SetAllPoints()
iconTex:SetTexCoord(0.07, 0.93, 0.07, 0.93)
iconTex:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
btn.icon = iconTex

-- Highlight overlay
local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
highlight:SetAllPoints()
highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
highlight:SetBlendMode("ADD")
highlight:SetAlpha(0.3)

-- Pushed overlay
local pushed = btn:CreateTexture(nil, "ARTWORK")
pushed:SetAllPoints()
pushed:SetTexture("Interface\\Buttons\\UI-Quickslot-Depress")
pushed:SetAlpha(0)
btn.pushed = pushed

btn:SetScript("OnMouseDown", function(self)
    self.pushed:SetAlpha(0.5)
end)
btn:SetScript("OnMouseUp", function(self)
    self.pushed:SetAlpha(0)
end)

-- Drag-to-move: register on the BUTTON (not the parent frame) because
-- the button sits on top and intercepts all mouse events.
btn:RegisterForDrag("LeftButton")
btn:SetScript("OnDragStart", function()
    if ns.db and ns.db.buttonLocked then return end
    frame:StartMoving()
end)
btn:SetScript("OnDragStop", function()
    frame:StopMovingOrSizing()
    if ns.db then
        local point, _, relPoint, x, y = frame:GetPoint()
        ns.db.buttonPosition = { point = point, relPoint = relPoint, x = x, y = y }
    end
end)

-- Cooldown overlay
local cooldownFrame = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
cooldownFrame:SetAllPoints()
btn.cooldown = cooldownFrame

-- ------------------------------------
-- Helpers for reading the current hearthstone from button attributes
-- ------------------------------------
local function GetCurrentButtonHearthstoneID()
    local btnType = btn:GetAttribute("type")
    if btnType == "toy" then
        local toyID = btn:GetAttribute("toy")
        return toyID and tonumber(toyID)
    elseif btnType == "item" then
        local itemAttr = btn:GetAttribute("item")
        if itemAttr then
            return tonumber(itemAttr:match("item:(%d+)"))
        end
    end
    return nil
end

local function GetHearthstoneName(itemID)
    if ns:IsBagItem(itemID) then
        return (C_Item.GetItemInfo(itemID))
    else
        local _, toyName = C_ToyBox.GetToyInfo(itemID)
        return toyName
    end
end

-- ------------------------------------
-- PreClick: set up attributes before the secure action fires.
-- Only fires on mouse-up (AnyUp registration). Right-click clears
-- type so the secure action is skipped; left-click type is pre-set
-- by SetRandomHearthstoneOnButton (either "toy" or "item").
-- ------------------------------------
btn:SetScript("PreClick", function(self, button)
    if InCombatLockdown() then return end

    if button == "RightButton" then
        self:SetAttribute("type", nil)
    end
end)

-- ------------------------------------
-- PostClick: pick next random hearthstone, handle right-click.
-- Only fires on mouse-up thanks to RegisterForClicks("AnyUp").
-- If a drag occurred, WoW suppresses OnClick entirely.
-- ------------------------------------
btn:SetScript("PostClick", function(self, button)
    if button == "RightButton" then
        C_AddOns.LoadAddOn("Blizzard_Collections")
        if CollectionsJournal then
            ShowUIPanel(CollectionsJournal)
            if ns.collectionsTab and ns.collectionsTab.Select then
                ns.collectionsTab.Select(ns.collectionsTab)
            end
        end
        -- Restore button attributes (PreClick cleared type for right-click)
        ns:SetRandomHearthstoneOnButton()
        return
    end

    -- Pick a new random hearthstone for the NEXT click and update display
    ns:SetRandomHearthstoneOnButton()
end)

-- ------------------------------------
-- Tooltip
-- ------------------------------------
btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")

    local currentID = GetCurrentButtonHearthstoneID()
    if currentID then
        -- Show the native hearthstone tooltip (name, description, cooldown, etc.)
        if ns:IsBagItem(currentID) then
            GameTooltip:SetItemByID(currentID)
        else
            GameTooltip:SetToyByItemID(currentID)
        end
    else
        GameTooltip:AddLine("Ruby Slippers", 1, 1, 1)
        GameTooltip:AddLine("No hearthstones available", 0.8, 0.8, 0.8)
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("Right-click to open collection", 0.5, 0.5, 0.5)
    GameTooltip:Show()
end)

btn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- ------------------------------------
-- Update the button icon, cooldown, and queued hearthstone
-- ------------------------------------
function ns:UpdateButtonDisplay()
    local currentID = GetCurrentButtonHearthstoneID()

    if currentID then
        local icon
        if ns:IsBagItem(currentID) then
            local _, _, _, _, _, _, _, _, _, itemIcon = C_Item.GetItemInfo(currentID)
            icon = itemIcon
        else
            local _, _, toyIcon = C_ToyBox.GetToyInfo(currentID)
            icon = toyIcon
        end

        if icon then
            iconTex:SetTexture(icon)
        end

        -- Update cooldown spinner
        local startTime, duration, enable = GetItemCooldown(currentID)
        if duration and duration > 0 and enable == 1 then
            cooldownFrame:SetCooldown(startTime, duration)
        else
            cooldownFrame:Clear()
        end
    else
        iconTex:SetTexture("Interface\\Icons\\INV_Misc_Rune_01")
        cooldownFrame:Clear()
    end
end

-- ------------------------------------
-- Managed macro: keeps #showtooltip in sync with the queued hearthstone
-- ------------------------------------
local MACRO_NAME = "HS Random"
local MACRO_ICON = 134400 -- INV_Misc_QuestionMark (auto-resolves from #showtooltip)
local MACRO_BODY_TEMPLATE = "#showtooltip item:%d\n/click RubySlippersButton"

local function UpdateMacro()
    if InCombatLockdown() then return end
    local idx = GetMacroIndexByName(MACRO_NAME)
    if idx == 0 then return end

    local currentID = GetCurrentButtonHearthstoneID()
    if currentID then
        EditMacro(idx, nil, nil, format(MACRO_BODY_TEMPLATE, currentID))
    end
end

-- Create or delete the managed macro based on the setting
function ns:SyncMacro()
    if InCombatLockdown() then return end
    local enabled = self.db and self.db.createMacro
    local idx = GetMacroIndexByName(MACRO_NAME)

    if enabled and idx == 0 then
        local numGlobal = GetNumMacros()
        if numGlobal >= MAX_ACCOUNT_MACROS then
            ns.Print("Cannot create macro — general macro slots are full.")
            return
        end
        local currentID = GetCurrentButtonHearthstoneID()
        local body = currentID and format(MACRO_BODY_TEMPLATE, currentID)
            or "#showtooltip\n/click RubySlippersButton"
        CreateMacro(MACRO_NAME, MACRO_ICON, body)
        ns.Print("Macro \"" .. MACRO_NAME .. "\" created. Drag it to your action bar from the macro panel (Esc > Macros).")
    elseif not enabled and idx > 0 then
        DeleteMacro(idx)
        ns.Print("Macro \"" .. MACRO_NAME .. "\" removed.")
    end
end

-- ------------------------------------
-- Pick and set a new random hearthstone on the button
-- ------------------------------------
function ns:SetRandomHearthstoneOnButton()
    if InCombatLockdown() then return end
    local hs = ns:GetRandomHearthstone()
    if hs then
        if hs.isBagItem then
            btn:SetAttribute("type", "item")
            btn:SetAttribute("item", "item:" .. hs.itemID)
        else
            btn:SetAttribute("type", "toy")
            btn:SetAttribute("toy", hs.itemID)
        end
    end
    ns:UpdateButtonDisplay()
    UpdateMacro()
end

-- ------------------------------------
-- Apply saved position and scale
-- ------------------------------------
local function ApplyButtonPosition()
    frame:ClearAllPoints()
    if ns.db and ns.db.buttonPosition then
        local pos = ns.db.buttonPosition
        frame:SetPoint(pos.point or "CENTER", UIParent, pos.relPoint or "CENTER", pos.x or 0, pos.y or 0)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    if ns.db and ns.db.buttonScale then
        frame:SetScale(ns.db.buttonScale)
    end
end

-- ------------------------------------
-- Show/hide the button
-- ------------------------------------
function ns:ShowButton()
    ApplyButtonPosition()
    frame:Show()
    ns:SetRandomHearthstoneOnButton()
end

function ns:HideButton()
    frame:Hide()
end

function ns:ToggleButton()
    if frame:IsShown() then
        ns:HideButton()
        if ns.db then ns.db.buttonShown = false end
    else
        ns:ShowButton()
        if ns.db then ns.db.buttonShown = true end
    end
end

function ns:SetButtonLocked(locked)
    if ns.db then ns.db.buttonLocked = locked end
end

function ns:SetButtonScale(scale)
    scale = math.max(0.5, math.min(2.0, scale))
    if ns.db then ns.db.buttonScale = scale end
    frame:SetScale(scale)
end

-- ------------------------------------
-- Slash commands: /rs and /rubyslippers
-- ------------------------------------
SLASH_RUBYSLIPPERS1 = "/rs"
SLASH_RUBYSLIPPERS2 = "/rubyslippers"
SlashCmdList["RUBYSLIPPERS"] = function(msg)
    msg = strtrim(msg or ""):lower()

    if msg == "" or msg == "toggle" then
        ns:ToggleButton()
    elseif msg == "show" then
        ns:ShowButton()
        if ns.db then ns.db.buttonShown = true end
    elseif msg == "hide" then
        ns:HideButton()
        if ns.db then ns.db.buttonShown = false end
    elseif msg == "lock" then
        ns:SetButtonLocked(true)
        print("|cff00ccffRuby Slippers:|r Button locked.")
    elseif msg == "unlock" then
        ns:SetButtonLocked(false)
        print("|cff00ccffRuby Slippers:|r Button unlocked. Drag to move.")
    elseif msg == "random" or msg == "rand" then
        ns:SetRandomHearthstoneOnButton()
        local currentID = GetCurrentButtonHearthstoneID()
        if currentID then
            local hsName = GetHearthstoneName(currentID)
            if hsName then
                print("|cff00ccffRuby Slippers:|r Next hearthstone: " .. hsName)
            end
        end
    elseif msg == "config" or msg == "options" then
        if ns.settingsCategory then
            Settings.OpenToCategory(ns.settingsCategory:GetID())
        end
    elseif msg == "macro" then
        print("|cff00ccffRuby Slippers:|r Use /rs config to enable or disable the managed macro.")
        if ns.settingsCategory then
            Settings.OpenToCategory(ns.settingsCategory:GetID())
        end
    elseif msg == "collection" or msg == "list" then
        C_AddOns.LoadAddOn("Blizzard_Collections")
        if CollectionsJournal then
            ShowUIPanel(CollectionsJournal)
        end
    elseif strsub(msg, 1, 5) == "scale" then
        local scaleVal = tonumber(strsub(msg, 7))
        if scaleVal then
            ns:SetButtonScale(scaleVal)
            print("|cff00ccffRuby Slippers:|r Button scale set to " .. scaleVal)
        else
            print("|cff00ccffRuby Slippers:|r Usage: /rs scale 0.5-2.0")
        end
    else
        print("|cff00ccffRuby Slippers:|r Commands:")
        print("  /rs - Toggle button visibility")
        print("  /rs show / hide - Show or hide button")
        print("  /rs lock / unlock - Lock or unlock button position")
        print("  /rs random - Pick a new random hearthstone")
        print("  /rs scale <0.5-2.0> - Set button scale")
        print("  /rs macro - Managed macro settings")
        print("  /rs collection - Open hearthstone collection")
        print("  /rs config - Open settings")
    end
end

-- ------------------------------------
-- Addon Compartment support (minimap dropdown in modern WoW)
-- These globals are read from the TOC metadata
-- ------------------------------------
function RubySlippers_OnAddonCompartmentClick(_addonName, _buttonName)
    ns:ToggleButton()
end

function RubySlippers_OnAddonCompartmentEnter(_addonName, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Ruby Slippers", 1, 1, 1)
    GameTooltip:AddLine("Click to toggle button", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end

function RubySlippers_OnAddonCompartmentLeave(_addonName, _menuButtonFrame)
    GameTooltip:Hide()
end

-- ------------------------------------
-- Event frame for combat state and initialization
-- ------------------------------------
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
eventFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        -- Combat just ended: update button attribute safely
        ns:SetRandomHearthstoneOnButton()
    end
end)

-- ------------------------------------
-- Initialize on PLAYER_LOGIN via ns callback system
-- ------------------------------------
ns:RegisterCallback("ADDON_READY", function()
    -- Apply saved preferences
    if ns.db.buttonShown ~= false then
        ns:ShowButton()
    end
    -- Create or sync the managed macro if enabled
    ns:SyncMacro()
end)

-- Refresh button when hearthstone data changes
ns:RegisterCallback("HEARTHSTONES_UPDATED", function()
    if frame:IsShown() then
        ns:SetRandomHearthstoneOnButton()
    end
end)

-- Apply settings changes live (scale, lock, etc.)
ns:RegisterCallback("SETTINGS_CHANGED", function()
    if ns.db then
        frame:SetScale(ns.db.buttonScale or 1.0)
    end
end)
