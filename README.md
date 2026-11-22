# AH Premium

A World of Warcraft: Forever addon that works with Auctionator. It compares an item's last-scanned AH price (after the 5% AH cut) with its vendor price and tells you which is the better sale.

- Tooltip line: "sell on AH (+X% over vendor)", "vendor it", or "no AH data".
- A small coin on the top right of bag slots worth selling on the AH. Works with Bagnon and the default bags.
- Soulbound and bind-on-pickup items are ignored.
- Prices older than the stale limit are dimmed and get no bag icon.

Settings: `/ahp` or Esc > Options > AddOns > AH Premium. The default premium is 10%.

## Install for development

Keep the repo here and link it into the game:

```powershell
New-Item -ItemType Junction -Path "I:\Games\World of Warcraft\_forever_\Interface\AddOns\AHPremium" -Target C:\dev\AHPremium
```

Then `/reload` in game after each change. Requires Auctionator.
