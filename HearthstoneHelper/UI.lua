local addonName, ns = ...

-- ============================================================
-- UI.lua - Secure Action Button & Floating Frame
-- Creates a movable floating button that uses a random hearthstone
-- on click. Supports /click HearthstoneHelperButton macro.
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
local frame = CreateFrame("Frame", "HearthstoneHelperButtonFrame", UIParent, "BackdropTemplate")
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
local btn = CreateFrame("Button", "HearthstoneHelperButton", frame, "SecureActionButtonTemplate")
btn:SetSize(44, 44)
btn:SetPoint("CENTER", frame, "CENTER", 0, 0)
btn:RegisterForClicks("AnyDown", "AnyUp")

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

-- Cooldown overlay
local cooldownFrame = CreateFrame("Cooldown", nil, btn, "CooldownFrameTemplate")
cooldownFrame:SetAllPoints()
btn.cooldown = cooldownFrame

-- ------------------------------------
-- PreClick: select random hearthstone BEFORE the secure click fires
-- ------------------------------------
btn:SetScript("PreClick", function(self, button)
    if InCombatLockdown() then return end

    if button == "RightButton" then
        -- Right-click opens collection tab (handled in PostClick)
        self:SetAttribute("type", nil)
        return
    end

    local hs = ns:GetRandomHearthstone()
    if hs then
        self:SetAttribute("type", "toy")
        self:SetAttribute("toy", hs.itemID)
    end
end)

-- ------------------------------------
-- PostClick: update display, handle right-click
-- ------------------------------------
btn:SetScript("PostClick", function(self, button)
    if button == "RightButton" then
        -- Open the Collections Journal to our tab
        C_AddOns.LoadAddOn("Blizzard_Collections")
        if CollectionsJournal then
            if CollectionsJournal:IsShown() then
                HideUIPanel(CollectionsJournal)
            else
                ShowUIPanel(CollectionsJournal)
            end
        end
        return
    end

    -- Update icon/tooltip to show next random hearthstone
    ns:UpdateButtonDisplay()
end)

-- ------------------------------------
-- Tooltip
-- ------------------------------------
btn:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Hearthstone Helper", 1, 1, 1)
    GameTooltip:AddLine("Click to use a random hearthstone", 0.8, 0.8, 0.8)
    GameTooltip:AddLine("Right-click to open collection", 0.5, 0.8, 1)

    -- Show current hearthstone queued
    local toyID = self:GetAttribute("toy")
    if toyID then
        toyID = tonumber(toyID)
        if toyID then
            local _, toyName, toyIcon = C_ToyBox.GetToyInfo(toyID)
            if toyName then
                GameTooltip:AddLine(" ")
                GameTooltip:AddLine("Next: " .. toyName, 0, 1, 0)

                -- Show cooldown if any
                local startTime, duration, enable = GetItemCooldown(toyID)
                if duration and duration > 0 and enable == 1 then
                    local remaining = duration - (GetTime() - startTime)
                    if remaining > 0 then
                        local mins = math.floor(remaining / 60)
                        local secs = math.floor(remaining % 60)
                        GameTooltip:AddLine("Cooldown: " .. mins .. "m " .. secs .. "s", 1, 0.2, 0.2)
                    end
                end
            end
        end
    end

    GameTooltip:AddLine(" ")
    GameTooltip:AddLine("/click HearthstoneHelperButton", 0.5, 0.5, 0.5)

    if ns.db and not ns.db.buttonLocked then
        GameTooltip:AddLine("Drag to move", 0.5, 0.5, 0.5)
    end

    GameTooltip:Show()
end)

btn:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

-- ------------------------------------
-- Update the button icon, cooldown, and queued hearthstone
-- ------------------------------------
function ns:UpdateButtonDisplay()
    local toyID = btn:GetAttribute("toy")
    if toyID then
        toyID = tonumber(toyID)
    end

    if toyID then
        local _, _, toyIcon = C_ToyBox.GetToyInfo(toyID)
        if toyIcon then
            iconTex:SetTexture(toyIcon)
        end

        -- Update cooldown spinner
        local startTime, duration, enable = GetItemCooldown(toyID)
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
-- Pick and set a new random hearthstone on the button
-- ------------------------------------
function ns:SetRandomHearthstoneOnButton()
    if InCombatLockdown() then return end
    local hs = ns:GetRandomHearthstone()
    if hs then
        btn:SetAttribute("type", "toy")
        btn:SetAttribute("toy", hs.itemID)
    end
    ns:UpdateButtonDisplay()
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
-- Slash commands: /hs and /hearthstone
-- ------------------------------------
SLASH_HEARTHSTONEHELPER1 = "/hs"
SLASH_HEARTHSTONEHELPER2 = "/hearthstone"
SlashCmdList["HEARTHSTONEHELPER"] = function(msg)
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
        print("|cff00ccffHearthstone Helper:|r Button locked.")
    elseif msg == "unlock" then
        ns:SetButtonLocked(false)
        print("|cff00ccffHearthstone Helper:|r Button unlocked. Drag to move.")
    elseif msg == "random" or msg == "rand" then
        ns:SetRandomHearthstoneOnButton()
        local toyID = btn:GetAttribute("toy")
        if toyID then
            local _, toyName = C_ToyBox.GetToyInfo(tonumber(toyID))
            if toyName then
                print("|cff00ccffHearthstone Helper:|r Next hearthstone: " .. toyName)
            end
        end
    elseif msg == "config" or msg == "options" then
        -- Open addon settings if InterfaceOptionsFrame or Settings panel exists
        if Settings and Settings.OpenToCategory then
            Settings.OpenToCategory("Hearthstone Helper")
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
            print("|cff00ccffHearthstone Helper:|r Button scale set to " .. scaleVal)
        else
            print("|cff00ccffHearthstone Helper:|r Usage: /hs scale 0.5-2.0")
        end
    else
        print("|cff00ccffHearthstone Helper:|r Commands:")
        print("  /hs - Toggle button visibility")
        print("  /hs show / hide - Show or hide button")
        print("  /hs lock / unlock - Lock or unlock button position")
        print("  /hs random - Pick a new random hearthstone")
        print("  /hs scale <0.5-2.0> - Set button scale")
        print("  /hs collection - Open hearthstone collection")
        print("  /hs config - Open settings")
    end
end

-- ------------------------------------
-- Addon Compartment support (minimap dropdown in modern WoW)
-- These globals are read from the TOC metadata
-- ------------------------------------
function HearthstoneHelper_OnAddonCompartmentClick(addonName, buttonName)
    ns:ToggleButton()
end

function HearthstoneHelper_OnAddonCompartmentEnter(addonName, menuButtonFrame)
    GameTooltip:SetOwner(menuButtonFrame, "ANCHOR_RIGHT")
    GameTooltip:AddLine("Hearthstone Helper", 1, 1, 1)
    GameTooltip:AddLine("Click to toggle button", 0.8, 0.8, 0.8)
    GameTooltip:Show()
end

function HearthstoneHelper_OnAddonCompartmentLeave(addonName, menuButtonFrame)
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
end)

-- Refresh button when hearthstone data changes
ns:RegisterCallback("HEARTHSTONES_UPDATED", function()
    if frame:IsShown() then
        ns:SetRandomHearthstoneOnButton()
    end
end)
