# Changelog

Changes to AH Premium, newest first. Each PR adds a line under Unreleased; a release moves those lines under its version.

## Unreleased

- Bag refreshes do a little less work when checking smelting advice. No visible change.
- Development: added CLAUDE.md with the repo workflow, required a review and a changelog entry on every PR, and brought the README and AGENTS.md up to date.

## 1.2.0 (2026-11-25)

- Ore now gets smelting advice. If a bar sells for more than the ore, the tooltip tells you to smelt it first, and the bag coin agrees. Covers Copper, Tin, Silver, Iron, Gold, Mithril, Truesilver, Thorium and Dark Iron, plus Bronze and Steel when you're carrying the other half. Only recipes your character knows are suggested.
- If you have more ore than partners for an alloy (say 20 Copper and 3 Tin), the advice is split: how many to make into Bronze, and what to do with the rest.
- Items a vendor always has in stock, such as food, water and arrows, are skipped once you've seen them at a vendor. Turn this off with "Ignore vendor-bought items".
- The price lines under the verdict are now hidden by default. Turn on "Show price breakdown" in the options to get them back.

## 1.1.2 (2026-11-23)

- The grey vendor coin now sits in the top right of the slot, so it no longer covers the stack count.

## 1.1.1 (2026-11-23)

- AH Premium now sits under the Auctions group in the addon list.

## 1.1 (2026-11-23)

- Tooltips on bag items show the stack total (AH after cut / vendor) when the stack is above 1.
- Bag slots get a grey coin for items better sold to a vendor. Turn it off with "Show vendor icon".
- Bag icons refresh when the auction house closes, so they update after a fresh Auctionator scan.

## 1.0 (2026-11-22)

- First release. Adds a tooltip line saying whether to sell on the AH or vendor, a coin on bag slots worth selling on the AH, stale price marking, and a per-character ignore list (`/ahp list`).
