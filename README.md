# AH Premium

A World of Warcraft: Forever addon that works with Auctionator. It compares an item's last-scanned AH price (after the 5% AH cut) with its vendor price and tells you which is the better sale.

- Tooltip line: "sell on AH (+X% over vendor)", "vendor it", "smelt to …, sell on AH", or "no AH data".
- A gold coin on the top right of bag slots worth selling on the AH, and a grey coin on ones better vendored. Works with Bagnon and the default bags.
- Ore gets smelting advice when its bars sell for more, for recipes your character knows. Bronze and Steel are suggested when you carry the other half, and the advice is split if you have more ore than partners.
- Items a vendor always has in stock, such as food, water and arrows, are skipped once you've seen them at a vendor.
- Soulbound and bind-on-pickup items are ignored.
- Prices older than the stale limit are dimmed and get no bag icon.

Settings: `/ahp` or Esc > Options > AddOns > AH Premium. Turn on "Show price breakdown" to see the AH, vendor and smelted prices under the tooltip line. `/ahp list` shows the items you've ignored.

## Requirements

[Auctionator](https://www.curseforge.com/wow/addons/auctionator) must be installed and enabled. AH Premium doesn't collect prices itself. It reads the ones Auctionator saves, so the addon won't load without it.

Install Auctionator first, then run a scan at the auction house (Auctionator's full scan, or just search for the items you care about). Items Auctionator hasn't seen show "no AH data".

## Install

1. Install Auctionator (see above).
2. Extract the AH Premium zip into your WoW Forever addon directory (`World of Warcraft\_forever_\Interface\AddOns\`).
3. Restart the game.

## Install for development

Keep the repo here and link it into the game:

```powershell
New-Item -ItemType Junction -Path "I:\Games\World of Warcraft\_forever_\Interface\AddOns\AHPremium" -Target C:\dev\AHPremium
```

Then `/reload` in game after each change. A new or renamed file, or a TOC change, needs a full restart of the client.

## Licence

Copyright (c) 2026 Alex Sharples. Licensed under the GNU General Public License v3.0. See [LICENSE](LICENSE).
