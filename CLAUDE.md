# Ruby Slippers - WoW Addon

## What This Is

A World of Warcraft addon for tracking hearthstone toys and using a random one with a single click. Targets **WoW 12.0 Midnight** (Interface 120001).

## Addon Guide (READ FIRST)

A comprehensive WoW addon development guide lives at **`N:\src\addon-guide\`**. Start with `00-INDEX.md` for the table of contents. Key documents by topic:

| Topic | File |
|-------|------|
| TOC format, addon lifecycle | `01-getting-started.md` |
| Lua 5.1 environment, WoW-specific functions | `02-lua-environment.md` |
| API namespaces (C_ToyBox, C_Item, etc.) | `03-api-reference.md` |
| Events (ADDON_LOADED, TOYS_UPDATED, etc.) | `04-events-system.md` |
| Frames, UI, ScrollBox, MenuUtil, Settings API | `05-frames-and-ui.md` |
| SavedVariables, persistence | `06-data-persistence.md` |
| Slash commands | `07-slash-commands.md` |
| LibStub, Ace3, library embedding | `08-libraries-and-embeds.md` |
| Taint, combat lockdown, SecureActionButton, Secret Values | `13-security-and-restrictions.md` |
| Copy-paste code patterns | `16-common-patterns.md` |

When in doubt about any WoW API behavior, **check the addon guide first** before guessing.

## External References

| Resource | URL |
|----------|-----|
| WoW API Wiki | warcraft.wiki.gg/wiki/World_of_Warcraft_API |
| FrameXML Source | github.com/Gethe/wow-ui-source |
| 12.0 API Changes | warcraft.wiki.gg/wiki/Patch_12.0.0/API_changes |
| SecureTabs-2.0 (original) | github.com/Jaliborc/SecureTabs-2.0 |
| In-game API browser | `/api` command |
| In-game event trace | `/etrace` command |
| In-game frame inspector | `/fstack` command |

## Project Structure

```
(repo root)
  RubySlippers/                Addon folder (goes in Interface\AddOns\)
    RubySlippers.toc           Addon manifest (Interface 120001)
    Libs/
      LibStub/LibStub.lua      Standard WoW library loader
      SecureTabs-2.0/          Adds tabs to secure panels without taint (by Jaliborc)
    Data.lua                   All hearthstone toy IDs, names, categories, sources
    Core.lua                   Init, SavedVariables, scanning, random selection, callbacks
    UI.lua                     Floating button, SecureActionButton, slash commands, addon compartment
    CollectionsTab.lua         "Hearthstones" tab in Collections Journal
    Config.lua                 Settings panel (Settings API)
  .pkgmeta                     CurseForge packaging config
```

Libraries are included by copying their files into `Libs/` and loading them in the TOC. The `#@no-lib-strip@` tags in the TOC tell packagers (CurseForge, etc.) to strip embedded libs for users who install them standalone. See `N:\src\addon-guide\08-libraries-and-embeds.md` for full details on the WoW library ecosystem.

## File Load Order

Defined in the TOC: `LibStub.lua` -> `SecureTabs-2.0.lua` -> `Data.lua` -> `Core.lua` -> `UI.lua` -> `CollectionsTab.lua` -> `Config.lua`

Files share state through the addon namespace: `local addonName, ns = ...` at the top of every file. All shared functions and data hang off `ns`.

## Architecture

### Namespace (`ns`) Key Members

| Member | Set In | Description |
|--------|--------|-------------|
| `ns.HearthstoneData` | Data.lua | Array of `{itemID, name, category, source, isBagItem?}` for all known hearthstones |
| `ns.AllHearthstoneIDs` | Data.lua | `{[itemID] = true}` lookup set |
| `ns.HomeHearthstoneIDs` | Data.lua | `{[itemID] = true}` home-only subset |
| `ns.BagItemHearthstoneIDs` | Data.lua | `{[itemID] = true}` bag item (non-toy) subset |
| `ns.DefaultHearthstoneID` | Data.lua | 6948 — the default Hearthstone (bag item, not a toy) |
| `ns:IsBagItem(id)` | Data.lua | Check if a hearthstone is a bag item vs toy |
| `ns.db` | Core.lua | Reference to `RubySlippersDB` SavedVariables |
| `ns.ownedHearthstones` | Core.lua | Array of owned hearthstone info tables |
| `ns.ownedHearthstoneMap` | Core.lua | `{[itemID] = true}` for owned |
| `ns:ScanOwnedHearthstones()` | Core.lua | Refresh ownership data from `PlayerHasToy()` / `GetItemCount()` |
| `ns:GetRandomHearthstone()` | Core.lua | Returns a random owned, non-excluded hearthstone |
| `ns:GetHearthstoneInfo(id)` | Core.lua | Full info: name, icon, category, owned, fav, excluded, cooldown |
| `ns:IsOnCooldown(id)` | Core.lua | Returns `onCooldown, remaining` using `GetItemCooldown()` |
| `ns:ToggleFavorite(id)` | Core.lua | Toggle favorite status in SavedVariables |
| `ns:ToggleExcluded(id)` | Core.lua | Toggle exclusion from random |
| `ns:RegisterCallback(event, fn)` | Core.lua | Register for addon-internal events |
| `ns:FireCallback(event, ...)` | Core.lua | Fire addon-internal event |
| `ns:UpdateButtonDisplay()` | UI.lua | Refresh button icon and cooldown |
| `ns:SetRandomHearthstoneOnButton()` | UI.lua | Pick random HS and set button attributes |
| `ns:ShowButton()` / `ns:HideButton()` | UI.lua | Show/hide the floating button |
| `ns:InitCollectionsTab()` | CollectionsTab.lua | Create the Collections Journal tab |
| `ns:InitConfig()` | Config.lua | Register Settings panel |

### Internal Callback Events

| Event | Fired When |
|-------|------------|
| `ADDON_READY` | After PLAYER_LOGIN + initial scan complete |
| `HEARTHSTONES_UPDATED` | After any ownership rescan or favorite/exclude toggle |
| `SETTINGS_CHANGED` | After any setting is modified in the Config panel |

### SavedVariables (`RubySlippersDB`)

```lua
{
    excluded = {},         -- {[itemID] = true}
    includeDefaultHearthstone = true,
    includeGarrison = false,
    includeDalaran = false,
    favoritesOnly = false,
    buttonShown = true,
    buttonScale = 1.0,
    buttonLocked = false,
    createMacro = false,
    showMinimap = true,
    buttonPosition = nil,  -- {point, relPoint, x, y}
}
```

## Rules

- **Never recreate third-party libraries.** If a library needs to be embedded (LibStub, SecureTabs, etc.), fetch the real source from its canonical repository. If the fetch fails, stop and report the problem — do not write a "functionally equivalent" replacement.

## Critical Technical Details

### Protected Actions / Secure Buttons

Most hearthstones are toys. Using a toy is a **protected action** that requires a hardware event (user click). You cannot call `UseToy()` or `C_ToyBox.PlayWithToy()` directly from addon code. The default Hearthstone (6948) is a bag item (not a toy) and uses `type="item"` instead.

The solution: `SecureActionButtonTemplate` with `type="toy"`, `toy=itemID` for toy hearthstones, or `type="item"`, `item="item:itemID"` for the default bag-item hearthstone. `SetRandomHearthstoneOnButton()` sets the correct type based on the `isBagItem` flag. This works because:
1. Hearthstones can only be used out of combat
2. `PreClick` runs before the secure action handler
3. `SetAttribute()` is allowed when `InCombatLockdown()` is false

Users can bind this to a macro: `/click RubySlippersButton`

### Key WoW APIs Used

| API | Purpose | Notes |
|-----|---------|-------|
| `PlayerHasToy(itemID)` | Check toy ownership | **Global function**, not in C_ToyBox |
| `C_ToyBox.GetToyInfo(itemID)` | Get name, icon, quality | Returns: itemID, toyName, icon, isFavorite, hasFanfare, quality |
| `C_ToyBox.IsToyUsable(itemID)` | Class/race restriction check | |
| `GetItemCooldown(itemID)` | Cooldown info | Returns: startTime, duration, enable |
| `GameTooltip:SetToyByItemID(id)` | Show toy tooltip | |
| `C_AddOns.LoadAddOn("Blizzard_Collections")` | Force-load Collections UI | Required before accessing CollectionsJournal |
| `GetItemCount(itemID)` | Check bag item count | **Global function**; used for default Hearthstone ownership |
| `C_Item.GetItemInfo(itemID)` | Get item name, icon, etc. | Returns: name, link, quality, ..., icon (10th return) |
| `GameTooltip:SetItemByID(id)` | Show item tooltip | Used for bag-item hearthstones |
| `SecureActionButtonTemplate` | Secure clickable button | With `type="toy"`, `toy=itemID` or `type="item"`, `item="item:ID"` |
| `RegisterForClicks("AnyUp")` | Register click types | See note below about AnyDown vs AnyUp |
| `C_ToyBox.PickupToyBoxItem(itemID)` | Drag toy to cursor | For drag-to-action-bar; requires hardware event (OnDragStart) |

### Hearthstone Categories

- **home** - Teleports to bound inn. This is the vast majority (35+) of hearthstones.
- **garrison** - Garrison Hearthstone (110560). Goes to WoD garrison.
- **dalaran** - Dalaran Hearthstone (140192). Goes to Legion Dalaran.

Most hearthstones are toys. The default Hearthstone (item 6948) reverted to a bag item in WoW 12.0 and is handled separately via `isBagItem = true` in Data.lua. Entries with `isBagItem` use `GetItemCount()` for ownership, `C_Item.GetItemInfo()` for name/icon, `type="item"` on SecureActionButtons, and `GameTooltip:SetItemByID()` for tooltips.

### SecureTabs-2.0 Integration

The Collections Journal tab uses SecureTabs-2.0 to avoid taint. Key points:
- The library hooks `PanelTemplates_SetTab` to sync with Blizzard's tab system
- A `self.selecting` guard prevents re-entrancy when our code triggers `PanelTemplates_SetTab`
- A cover frame overlays Blizzard panel content when our tab is active
- The tab's `OnSelect`/`OnDeselect` callbacks manage panel visibility

If the tab causes taint issues, the fallback is a standalone `PortraitFrameTemplate` frame with `/rs collection` to open it.

### Collection Panel Layout

CollectionsTab.lua uses a 3x6 icon grid with paging (18 items per page), matching the Blizzard Toy Box layout. Each cell is a `SecureActionButtonTemplate` button so clicking uses the toy directly (no separate "Use" buttons). Icons are draggable to the action bar via `C_ToyBox.PickupToyBoxItem()` in `OnDragStart`.

## Adding New Hearthstones

When new hearthstones are added to the game, add entries to `Data.lua` in the `ns.HearthstoneData` table:

```lua
{ itemID = 123456, name = "New Hearthstone", category = "home", source = "How to obtain" },
```

The lookup tables (`AllHearthstoneIDs`, `HomeHearthstoneIDs`) are built automatically from this array.

## Slash Commands

| Command | Action |
|---------|--------|
| `/rs` | Toggle floating button visibility |
| `/rs show` / `/rs hide` | Show or hide the button |
| `/rs lock` / `/rs unlock` | Lock or unlock button dragging |
| `/rs random` | Pick a new random hearthstone |
| `/rs scale <0.5-2.0>` | Set button scale |
| `/rs macro` | Open settings for managed macro |
| `/rs collection` | Open Collections Journal |
| `/rs config` | Open settings panel |
| `/rs help` | Show command list |

## Installation

CurseForge packages the `RubySlippers/` subfolder via `.pkgmeta`. For local dev, junction the `RubySlippers/` subfolder into `Interface\AddOns\RubySlippers`.

## Versioning and Publishing

The TOC uses `@project-version@` which CurseForge's packager replaces with the git tag name. Do not hardcode a version number in the TOC.

To publish a release:
1. Commit and push all changes
2. Tag: `git tag 1.2.0 && git push --tags`
3. CurseForge webhook triggers automatic packaging

Tag naming determines release type:
- `1.2.0` → Release
- `1.2.0-beta1` → Beta
- `1.2.0-alpha1` → Alpha
- Untagged pushes → Alpha

CurseForge project: https://authors.curseforge.com/#/projects/1469357
GitHub repo: https://github.com/mckalexee/ruby-slippers

## Debugging

- **Enable Lua errors in-game**: `/console scriptErrors 1` then `/reload`. The old "Interface > Display > Lua Errors" checkbox does NOT exist in WoW 12.
- When a bug is reported, **get the actual error first** — do not guess at causes.

## WoW Lua Gotchas

- **Lua 5.1** - No `goto`, no integer division, no `utf8` lib. `unpack()` is global.
- **Trig in degrees** - `math.sin()`, `math.cos()` etc. use degrees, not radians.
- **`wipe(t)`** - WoW-specific function to efficiently clear a table.
- **`tinsert` / `tremove`** - Global aliases for `table.insert` / `table.remove`.
- **nil deletes keys** - In SavedVariables, setting a value to `nil` removes it. Use `false` for "explicitly off".
- **No `require()`** - Addon files are loaded by the TOC in order. Share state via the addon namespace.
- **Global pollution** - All addons share one global Lua namespace. Minimize globals.
