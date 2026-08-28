# Build a Bug Monetization Plan

## Core rule

Monetization must not sell survival power.

- Bug archetypes determine movement, defense, abilities, and gameplay style.
- Cosmetics and premium Skins change appearance only.
- Standard cosmetics should usually be earnable through play with DNA or achievements.
- Premium full-body Skins are a separate Robux-only collection category.
- Unlockable gameplay bugs remain progression sidegrades rather than paid power.

## Cosmetic economy

Two DNA values remain intentionally separate:

- **Available DNA** is spendable on cosmetic and bug unlocks.
- **Lifetime DNA** is permanent progression used for levels and titles.

Spending DNA never lowers level or title.

Standard cosmetic ownership is account-wide. Once a player unlocks a cosmetic, it can be equipped on any compatible bug without repurchasing it. Equipped appearance and saved Builds remain per bug species.

## Catalog architecture

`CosmeticStyles.lua` owns visual appearance only.

`CosmeticCatalog.lua` owns commerce/progression metadata:

- DNA cost
- rarity
- current shop availability
- achievement ownership
- optional standard-cosmetic Robux eligibility
- future Developer Product ID where appropriate
- premium Skin Pass ID
- future rotation eligibility

This keeps prices and availability independent from rendering.

Current availability values:

- `always`: visible in the normal DNA shop.
- `rotation`: reserved for a future featured/limited-stock store.
- `achievement`: earned through gameplay only.
- `robux`: premium Skin, never purchasable for DNA.

All current Roblox product/pass IDs remain `0` until real items are created. Do not ship fake IDs or fake purchase buttons.

## Premium Skins

Skins are full-body visual treatments rather than mix-and-match parts. They are Robux-only and never affect movement, health, damage, rewards, or abilities.

First concept set:

- Neon Circuit
- Candy Pop
- Ember

Because Skins are intended as permanent one-time entitlements, use Roblox Passes for them rather than repeatable Developer Products. The Skin catalog already has `robuxPassId` placeholders and can map a real Pass ID back to the permanent entitlement once configured.

The client may show a Skin collection/preview before commerce is live, but must not show a fake purchasable price or imply a purchase can complete until a valid Pass ID exists.

## Standard cosmetic Robux path

Standard colors, eyes, patterns, and future mix-and-match cosmetics remain primarily earnable through DNA or achievements. Some may later have an optional Robux shortcut.

For any repeatable Developer Product purchase path:

1. Fetch live product information from Roblox rather than hard-coding the displayed Robux price.
2. Prompt the purchase with MarketplaceService.
3. Grant ownership only from the server receipt-processing path.
4. The receipt handler grants through the same permanent cosmetic ownership system used by DNA and achievements.
5. Receipt processing must be idempotent.
6. Do not use purchase-finished UI events as proof that the player paid.

For premium Skin Passes, ownership should be checked/granted through the Pass entitlement path instead of Developer Product receipts.

## Future featured store, likely v2

A rotating store can borrow the useful engagement pattern of collectible-stock games without making standard cosmetics Robux-exclusive.

Possible structure:

- Common cosmetics remain permanently available for DNA.
- Some rare cosmetics enter a rotating featured-stock pool.
- Featured stock changes on a predictable schedule.
- Players can return regularly to see what is available.
- Most rotating cosmetics should eventually be earnable for DNA when in stock.
- Eligible standard cosmetics may also have an always-available Robux shortcut even when DNA stock is absent.
- Achievement cosmetics remain outside the normal shop.
- Premium Skins remain their own Robux-only collection and do not depend on rotating DNA stock.

The rotation should create anticipation, not punish missed logins. Avoid extremely short windows or progression advantages tied to rare stock.

## Cosmetic categories

Current functional mix-and-match categories:

- Body Color
- Eyes
- Patterns

Premium architecture:

- Skins

Planned:

- Shell / wing treatment
- Antenna accents
- Trails
- Seasonal cosmetics
- Map/event cosmetics

## Store UI direction

Profile / Customize should scale through tabs rather than one long scrolling list.

Current tabs:

- Stats
- Builds
- Colors
- Eyes
- Patterns
- Awards

Potential later tabs:

- Skins
- Store
- Featured
- Trails
- Limited / Seasonal

The player should always be able to distinguish:

- selected
- owned
- locked
- DNA price
- rarity
- achievement requirement
- whether an item is currently in stock
- Robux-only Skin status
- live Robux option only when a valid Roblox item is actually configured
