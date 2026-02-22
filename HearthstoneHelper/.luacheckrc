std = "lua51"
max_line_length = false

exclude_files = {
    "Libs/**",
}

ignore = {
    "212/self",   -- Unused argument 'self' (common in WoW methods)
    "212/event",  -- Unused argument 'event' (common in event handlers)
}

globals = {
    -- SavedVariables
    "HearthstoneHelperDB",

    -- Addon Compartment functions (referenced by TOC metadata)
    "HearthstoneHelper_OnAddonCompartmentClick",
    "HearthstoneHelper_OnAddonCompartmentEnter",
    "HearthstoneHelper_OnAddonCompartmentLeave",

    -- Slash command globals
    "SLASH_HEARTHSTONEHELPER1",
    "SLASH_HEARTHSTONEHELPER2",

    -- Mutated globals
    "SlashCmdList",
}

read_globals = {
    -- Libraries
    "LibStub",

    -- Lua extensions provided by WoW
    "strtrim", "strsub", "format", "wipe", "tinsert",
    "CopyTable",

    -- WoW Frame API
    "CreateFrame",
    "UIParent",
    "InCombatLockdown",
    "ShowUIPanel",
    "HideUIPanel",
    "GetTime",
    "print",

    -- Toy API
    "PlayerHasToy",
    "GetItemCooldown",
    "C_ToyBox",

    -- Collections Journal
    "CollectionsJournal",

    -- Addon API
    "C_AddOns",

    -- Settings API
    "Settings",
    "MinimalSliderWithSteppersMixin",

    -- UI Templates / Mixins
    "SearchBoxTemplate_OnTextChanged",

    -- Sound
    "SOUNDKIT",
    "PlaySound",

    -- Tooltip
    "GameTooltip",
}
