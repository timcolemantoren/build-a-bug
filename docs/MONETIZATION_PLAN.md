# Build a Bug Monetization Plan

## Core rule

Monetization must not sell survival power.

- Bug archetypes determine movement, defense, abilities, and gameplay style.
- Cosmetics change appearance only.
- Nearly every standard cosmetic should be earnable through play with DNA or achievements.
- Robux can provide an alternate acquisition path without creating stronger bugs.

## Cosmetic economy

Two DNA values remain intentionally separate:

- **Available DNA** is spendable on cosmetic unlocks.
- **Lifetime DNA** is permanent progression used for levels and titles.

Spending DNA never lowers level or title.

Cosmetic ownership is account-wide. Once a player unlocks a cosmetic, it can be equipped on any compatible bug without repurchasing it.

## Catalog architecture

`CosmeticStyles.lua` owns visual appearance only.

`CosmeticCatalog.lua` owns commerce/progression metadata:

- DNA cost
- rarity
- current shop availability
- Robux eligibility
- future Roblox Developer Product ID
- future rotation eligibility

This keeps prices and availability independent from rendering.

Current availability values:

- `always`: visible in the normal DNA shop.
- `rotation`: reserved for a future featured/limited-stock store.

Current Robux product IDs remain `0` until real Roblox Developer Products are created. Do not ship fake IDs.

## Robux purchase path

When real Developer Product IDs are configured:

1. The client can offer a Robux purchase option for an eligible catalog item.
2. Fetch live product information from Roblox rather than hard-coding the displayed Robux price.
3. Prompt the purchase with MarketplaceService.
4. Grant ownership only from the server receipt-processing path.
5. The receipt handler grants the cosmetic through `PlayerDataService.GrantCosmetic()` so DNA, achievement, and Robux unlocks all converge on one ownership system.
6. Receipt processing must be idempotent and persist the processed receipt before acknowledging the purchase.
7. Do not use purchase-finished UI events as proof that the player paid.

## Future featured store, likely v2

A rotating store can borrow the useful engagement pattern of collectible-stock games without making cosmetics Robux-exclusive.

Possible structure:

- Common cosmetics remain permanently available for DNA.
- Some rare cosmetics enter a rotating featured-stock pool.
- Featured stock changes on a predictable schedule.
- Players can return regularly to see what is available.
- Most rotating cosmetics should eventually be earnable for DNA when in stock.
- Eligible cosmetics may also have an always-available Robux purchase path even when their DNA stock is absent.
- Achievement and event cosmetics can remain outside the normal shop entirely.

The rotation should create anticipation, not punish missed logins. Avoid extremely short windows or progression advantages tied to rare stock.

## Future cosmetic categories

Current:

- Body Color
- Eyes
- Patterns

Planned:

- Shell / wing treatment
- Antenna accents
- Trails
- Achievement cosmetics
- Seasonal cosmetics
- Map/event cosmetics

## Store UI direction

Profile / Customize should scale through tabs rather than one long scrolling list.

Current tabs:

- Stats
- Colors
- Eyes
- Patterns

Potential later tabs:

- Store
- Featured
- Achievements
- Trails
- Limited / Seasonal

The player should always be able to distinguish:

- selected
- owned
- locked
- DNA price
- rarity
- whether an item is currently in stock
- Robux option, when configured
