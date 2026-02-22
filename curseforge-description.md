## What it does

Ruby Slippers picks a random hearthstone from your collection and uses it when you click the floating button. Each click picks a new one. It also adds a "Hearthstones" tab to the Collections Journal where you can see every hearthstone toy in the game, which ones you own, and where to get the rest.

## Features

**Random hearthstone button** — A movable, scalable floating button. Left-click to use a random hearthstone, right-click to open the collection. A new hearthstone is picked after each use. Supports the default bag hearthstone and all 37+ toy hearthstones.

**Collections Journal tab** — Browse all hearthstones in a grid layout matching the Toy Box style. Owned hearthstones show in full color with gold borders; unowned ones are grayed out with their source listed in the tooltip. Click any owned hearthstone to use it directly, or drag it to your action bar.

**Favorites and exclusions** — Right-click a hearthstone to favorite it or exclude it from the random rotation. Favorites sync with Blizzard's native toy favorites, so changes show up in both places.

**Filters and search** — Filter by owned/unowned, search by name, or filter by category (Home, Garrison, Dalaran).

**Managed macro** — Optionally creates an "HS Random" account macro that you can put on your action bar. The macro icon updates automatically to show the next queued hearthstone.

**Settings** — Toggle the floating button on/off, lock its position, adjust scale, enable favorites-only mode, include or exclude Garrison/Dalaran/default hearthstone from the random pool. Access via `/rs config` or the Interface options.

**Minimap compartment** — Click the addon compartment entry to toggle the floating button.

## Slash Commands

| Command | Action |
|---------|--------|
| `/rs` | Toggle the floating button |
| `/rs show` / `/rs hide` | Show or hide the button |
| `/rs lock` / `/rs unlock` | Lock or unlock button position |
| `/rs random` | Pick a new random hearthstone |
| `/rs scale 0.5-2.0` | Set button scale |
| `/rs collection` | Open the Collections Journal tab |
| `/rs config` | Open settings |

## Macro Binding

You can bind the button to a key by creating a macro:

```
/click RubySlippersButton
```

Or enable "Create Action Bar Macro" in settings and Ruby Slippers will manage the macro for you, including updating the tooltip icon.

## Known Info

- Supports WoW 12.0 (Midnight), Interface 120001
- The default Hearthstone (item 6948) is handled as a bag item, not a toy
- All toy hearthstones added through The War Within and Midnight are included
- Uses SecureActionButtonTemplate — works with hardware clicks only, as required by Blizzard
- No external dependencies beyond bundled libraries (LibStub, SecureTabs-2.0)

## Reporting Bugs

Open an issue on [GitHub](https://github.com/mckalexee/ruby-slippers/issues) if you run into problems or have a feature request.
