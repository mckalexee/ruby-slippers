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
    "RubySlippersDB",

    -- Addon Compartment functions (referenced by TOC metadata)
    "RubySlippers_OnAddonCompartmentClick",
    "RubySlippers_OnAddonCompartmentEnter",
    "RubySlippers_OnAddonCompartmentLeave",

    -- Slash command globals
    "SLASH_RUBYSLIPPERS1",
    "SLASH_RUBYSLIPPERS2",

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

    -- Item / Container API
    "GetItemCount",
    "C_Item",
    "C_Container",

    -- Menu API
    "MenuUtil",

    -- Macro API
    "GetNumMacros",
    "GetMacroIndexByName",
    "CreateMacro",
    "EditMacro",
    "DeleteMacro",
    "MAX_ACCOUNT_MACROS",

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
