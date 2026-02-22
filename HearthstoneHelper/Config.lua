local addonName, ns = ...

-- =============================================================================
-- Hearthstone Helper - Config
-- Settings panel using the modern Settings API (10.0+)
-- =============================================================================

function ns:InitConfig()
    local db = self.db
    if not db then return end

    local category = Settings.RegisterVerticalLayoutCategory("Hearthstone Helper")

    -- Include Garrison Hearthstone in random
    do
        local setting = Settings.RegisterAddOnSetting(category,
            "Include Garrison Hearthstone",
            "includeGarrison",
            db,
            Settings.VarType.Boolean,
            false
        )
        setting:SetValueChangedCallback(function()
            ns:FireCallback("SETTINGS_CHANGED")
        end)
        Settings.CreateCheckbox(category, setting,
            "Include the Garrison Hearthstone when selecting a random hearthstone. It teleports to your garrison, not your bound inn.")
    end

    -- Include Dalaran Hearthstone in random
    do
        local setting = Settings.RegisterAddOnSetting(category,
            "Include Dalaran Hearthstone",
            "includeDalaran",
            db,
            Settings.VarType.Boolean,
            false
        )
        setting:SetValueChangedCallback(function()
            ns:FireCallback("SETTINGS_CHANGED")
        end)
        Settings.CreateCheckbox(category, setting,
            "Include the Dalaran Hearthstone when selecting a random hearthstone. It teleports to Dalaran, not your bound inn.")
    end

    -- Favorites only mode
    do
        local setting = Settings.RegisterAddOnSetting(category,
            "Favorites Only",
            "favoritesOnly",
            db,
            Settings.VarType.Boolean,
            false
        )
        setting:SetValueChangedCallback(function()
            ns:FireCallback("SETTINGS_CHANGED")
        end)
        Settings.CreateCheckbox(category, setting,
            "Only use favorited hearthstones when selecting a random hearthstone.")
    end

    -- Button scale
    do
        local setting = Settings.RegisterAddOnSetting(category,
            "Button Scale",
            "buttonScale",
            db,
            Settings.VarType.Number,
            1.0
        )
        setting:SetValueChangedCallback(function()
            ns:FireCallback("SETTINGS_CHANGED")
        end)
        local options = Settings.CreateSliderOptions(0.5, 2.0, 0.1)
        options:SetLabelFormatter(MinimalSliderWithSteppersMixin.Label.Right)
        Settings.CreateSlider(category, setting, options,
            "Adjust the scale of the hearthstone button.")
    end

    -- Lock button position
    do
        local setting = Settings.RegisterAddOnSetting(category,
            "Lock Button Position",
            "buttonLocked",
            db,
            Settings.VarType.Boolean,
            false
        )
        setting:SetValueChangedCallback(function()
            ns:FireCallback("SETTINGS_CHANGED")
        end)
        Settings.CreateCheckbox(category, setting,
            "Prevent the hearthstone button from being moved by dragging.")
    end

    Settings.RegisterAddOnCategory(category)
    ns.settingsCategory = category
end
