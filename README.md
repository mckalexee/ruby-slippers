# Ruby Slippers

A World of Warcraft addon that tracks your hearthstone toy collection and lets you use a random hearthstone with one click.

## Features

- **Random Hearthstone Button** - A floating button that uses a random hearthstone from your collection each click. Bind it to a key with `/click RubySlippersButton` in a macro.
- **Collection Tab** - Adds a "Hearthstones" tab to the Collections Journal showing all 37+ hearthstone toys, which ones you own, and where to get the rest.
- **Favorites & Exclusions** - Star your favorites or exclude hearthstones from the random pool.
- **Filters & Search** - Filter by category (Home/Garrison/Dalaran), ownership, or search by name.
- **Settings** - Configure button scale, lock position, toggle Garrison/Dalaran hearthstones in the random pool, favorites-only mode.
- **Managed Macro** - Optionally creates an "HS Random" action bar macro with auto-updating icon.
- **Minimap Compartment** - Access from the addon compartment dropdown on the minimap.

## Installation

Copy the `RubySlippers/` folder into:

```
World of Warcraft/_retail_/Interface/AddOns/
```

## Usage

### Slash Commands

| Command | Action |
|---------|--------|
| `/rs` | Toggle the floating button |
| `/rs show` / `hide` | Show or hide the button |
| `/rs lock` / `unlock` | Lock or unlock button dragging |
| `/rs random` | Pick a new random hearthstone |
| `/rs scale 0.5-2.0` | Set button scale |
| `/rs collection` | Open the Collections Journal |
| `/rs config` | Open settings |

### Macro

Create a macro with the following to bind a random hearthstone to a key:

```
/click RubySlippersButton
```

Or enable "Create Action Bar Macro" in `/rs config` for an auto-managed macro with updating icon.

### Button Controls

- **Left-click** - Use a random hearthstone
- **Right-click** - Pick a new random hearthstone
- **Shift-right-click** - Open the Collections Journal
- **Drag** - Move the button (unless locked)

## Requirements

- World of Warcraft 12.0 (The War Within / Midnight)
- Interface version 120001

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for a full history of changes.

## Bundled Libraries

- [LibStub](https://www.wowace.com/addons/libstub/) - Library versioning
- [SecureTabs-2.0](https://github.com/Jaliborc/SecureTabs-2.0) by Jaliborc - Taint-free tab injection
