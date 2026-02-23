local _, ns = ...

-- Key Bindings UI labels (globals required by Bindings.xml)
BINDING_HEADER_RUBYSLIPPERS = "Ruby Slippers"
_G["BINDING_NAME_CLICK RubySlippersButton:LeftButton"] = "Use Random Hearthstone"

-- =============================================================================
-- Ruby Slippers - Data
-- All known hearthstone toy IDs with metadata
-- =============================================================================

-- Each entry: { itemID, name, category, source }
-- category: "home" (teleports to bound inn), "garrison", "dalaran"
ns.HearthstoneData = {
    -- Core hearthstones
    { itemID = 6948,   name = "Hearthstone",                          category = "home",     source = "Default item for all characters", isBagItem = true },
    { itemID = 110560, name = "Garrison Hearthstone",                 category = "garrison", source = "Warlords of Draenor garrison quest line" },
    { itemID = 140192, name = "Dalaran Hearthstone",                  category = "dalaran",  source = "Legion introductory quest line" },

    -- Classic / Legacy
    { itemID = 64488,  name = "The Innkeeper's Daughter",             category = "home",     source = "Archaeology - Dwarf artifact" },
    { itemID = 93672,  name = "Dark Portal",                          category = "home",     source = "Blizzard Shop / Promotion" },
    { itemID = 54452,  name = "Ethereal Portal",                      category = "home",     source = "Ethereal Soul-Trader companion promotion" },

    -- Diablo Anniversary
    { itemID = 142542, name = "Tome of Town Portal",                  category = "home",     source = "Diablo Anniversary event - Treasure Goblins" },

    -- Holiday / World Event
    { itemID = 165669, name = "Lunar Elder's Hearthstone",            category = "home",     source = "Lunar Festival - Elder currency vendor" },
    { itemID = 165670, name = "Peddlefeet's Lovely Hearthstone",      category = "home",     source = "Love is in the Air - 150 Love Tokens" },
    { itemID = 165802, name = "Noble Gardener's Hearthstone",         category = "home",     source = "Noblegarden - 250 Noblegarden Chocolates" },
    { itemID = 166746, name = "Fire Eater's Hearthstone",             category = "home",     source = "Midsummer Fire Festival - 350 Burning Blossoms" },
    { itemID = 166747, name = "Brewfest Reveler's Hearthstone",       category = "home",     source = "Brewfest - 200 Brewfest Prize Tokens" },
    { itemID = 163045, name = "Headless Horseman's Hearthstone",      category = "home",     source = "Hallow's End - 150 Tricky Treats" },
    { itemID = 162973, name = "Greatfather Winter's Hearthstone",     category = "home",     source = "Feast of Winter Veil - Gently Shaken Gift" },

    -- Shadowlands Covenant
    { itemID = 184353, name = "Kyrian Hearthstone",                   category = "home",     source = "Kyrian Covenant - Path of Ascension" },
    { itemID = 180290, name = "Night Fae Hearthstone",                category = "home",     source = "Night Fae Covenant - Queen's Conservatory" },
    { itemID = 182773, name = "Necrolord Hearthstone",                category = "home",     source = "Necrolord Covenant - Abomination Factory" },
    { itemID = 183716, name = "Venthyr Sinstone",                     category = "home",     source = "Venthyr Covenant - Ember Court" },

    -- Shadowlands Other
    { itemID = 188952, name = "Dominated Hearthstone",                category = "home",     source = "Torghast - The Jailer's Gauntlet: Layer 2" },
    { itemID = 190237, name = "Broker Translocation Matrix",          category = "home",     source = "Exalted with The Enlightened - sold by Vilo" },
    { itemID = 190196, name = "Enlightened Hearthstone",              category = "home",     source = "Hidden toy in Zereth Mortis" },
    { itemID = 172179, name = "Eternal Traveler's Hearthstone",       category = "home",     source = "Shadowlands Epic Edition purchase / Blizzard Shop" },

    -- Battle for Azeroth
    { itemID = 168907, name = "Holographic Digitalization Hearthstone", category = "home",   source = "Mechagon - quest chain" },

    -- Dragonflight
    { itemID = 193588, name = "Timewalker's Hearthstone",             category = "home",     source = "Chromie Time / Timewalking vendor" },
    { itemID = 200630, name = "Ohn'ir Windsage's Hearthstone",       category = "home",     source = "Achievement: Honor Our Ancestors" },
    { itemID = 206195, name = "Path of the Naaru",                    category = "home",     source = "Purchased from Gaal in Krokul Hovel (Argus currencies)" },
    { itemID = 209035, name = "Hearthstone of the Flame",             category = "home",     source = "Amirdrassil raid - Larodar encounter" },
    { itemID = 210455, name = "Draenic Hologem",                      category = "home",     source = "Quest: Our Path Forward (Draenei/Lightforged Draenei only)" },

    -- The War Within (11.x)
    { itemID = 208704, name = "Deepdweller's Earthen Hearthstone",    category = "home",     source = "The War Within Epic Edition / Blizzard Shop" },
    { itemID = 212337, name = "Stone of the Hearth",                  category = "home",     source = "Dr. Boom drop - Hearthstone 10th Anniversary event" },
    { itemID = 228940, name = "Notorious Thread's Hearthstone",       category = "home",     source = "Sold by Yamas the Provider (Severed Threads reputation)" },
    { itemID = 235016, name = "Redeployment Module",                  category = "home",     source = "Achievement: Overcharged Delver" },
    { itemID = 236687, name = "Explosive Hearthstone",                category = "home",     source = "Liberation of Undermine raid - Stix Bunkjunker boss drop" },
    { itemID = 245970, name = "P.O.S.T. Master's Express Hearthstone", category = "home",   source = "Mailroom Distribution in Tazavesh, the Veiled Market" },
    { itemID = 246565, name = "Cosmic Hearthstone",                   category = "home",     source = "Looted from Dimensius" },
    { itemID = 250411, name = "Timerunner's Hearthstone",             category = "home",     source = "WoW Remix: Legion - starting item for Timerunner characters" },

    -- Midnight (12.0)
    { itemID = 257736, name = "Lightcalled Hearthstone",              category = "home",     source = "Midnight expansion content" },
    { itemID = 263489, name = "Naaru's Enfold",                       category = "home",     source = "Outland Heroic/Epic Pack (BC Classic Anniversary Edition)" },
    { itemID = 265100, name = "Corewarden's Hearthstone",             category = "home",     source = "Sold by Telemancer Astrandis (10 Voidlight Marl)" },
}

-- Quick lookup: all hearthstone toy IDs
ns.AllHearthstoneIDs = {}
for _, data in ipairs(ns.HearthstoneData) do
    ns.AllHearthstoneIDs[data.itemID] = true
end

-- Quick lookup: home-only hearthstone IDs (teleport to bound inn)
ns.HomeHearthstoneIDs = {}
for _, data in ipairs(ns.HearthstoneData) do
    if data.category == "home" then
        ns.HomeHearthstoneIDs[data.itemID] = true
    end
end

-- Special destination IDs
ns.GarrisonHearthstoneID = 110560
ns.DalaranHearthstoneID = 140192
ns.DefaultHearthstoneID = 6948

-- Quick lookup: bag item hearthstone IDs (not toys)
ns.BagItemHearthstoneIDs = {}
for _, data in ipairs(ns.HearthstoneData) do
    if data.isBagItem then
        ns.BagItemHearthstoneIDs[data.itemID] = true
    end
end

-- Check if a hearthstone is a bag item (not a toy)
function ns:IsBagItem(itemID)
    return self.BagItemHearthstoneIDs[itemID] or false
end
