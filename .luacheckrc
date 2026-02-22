std = "lua51"
max_line_length = false
self = false -- Don't warn about unused self (standard WoW addon pattern)

-- Self-shadowing is standard WoW pattern: nested OnClick/OnEnter handlers
-- inside ns:Method() legitimately shadow the outer self with the frame self.
ignore = {
    "432/self", -- shadowing upvalue self (nested handlers inside ns:Method)
    "212/self", -- unused self arg in SetScript closures (frame captured via closure)
}

-- Third-party libraries: don't lint code we don't own
exclude_files = {"**/Libs/**"}

-- WoW globals that addons can write to
globals = {
    "SLASH_HEARTHSTONEHELPER1",
    "SLASH_HEARTHSTONEHELPER2",
    "SlashCmdList",
    "HearthstoneHelperDB",
    "HearthstoneHelper_OnAddonCompartmentClick",
    "HearthstoneHelper_OnAddonCompartmentEnter",
    "HearthstoneHelper_OnAddonCompartmentLeave",
}

-- WoW globals that addons can read (API, frames, utilities)
read_globals = {
    -- Lua extensions provided by WoW
    "wipe",
    "tinsert",
    "tremove",
    "strtrim",
    "strsub",
    "format",
    "CopyTable",

    -- WoW frame system
    "CreateFrame",
    "UIParent",
    "GameTooltip",

    -- WoW API functions
    "InCombatLockdown",
    "GetTime",
    "GetItemCooldown",
    "PlayerHasToy",
    "ShowUIPanel",
    "HideUIPanel",

    -- WoW namespaces
    "C_ToyBox",
    "C_AddOns",

    -- Settings API (10.0+)
    "Settings",
    "MinimalSliderWithSteppersMixin",

    -- UI templates / mixins
    "SearchBoxTemplate_OnTextChanged",

    -- Blizzard frames (loaded on demand)
    "CollectionsJournal",

    -- Libraries
    "LibStub",
}
