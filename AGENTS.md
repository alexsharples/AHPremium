# AGENTS.md

Guidance for AI agents and tools working in this repo. Read it before changing anything.

AH Premium is a small World of Warcraft: Forever addon. It reads Auctionator's last-scanned price, compares it with the vendor price, and shows a verdict on tooltips and bag slots. **Keeping it lightweight is the main goal.**

## Keep it lightweight

- **No libraries.** No Ace3, LibStub embeds or other bundled dependencies. Use the Blizzard API and Auctionator's public API only.
- **No new files, features or settings** unless asked. Prefer a few lines in an existing file over a new module.
- **Minimum code that solves the problem.** No speculative options, abstractions or future-proofing. Don't tidy or restructure code you weren't asked to touch.
- **Stay cheap at runtime.** Hooks run on every tooltip and bag refresh. Don't scan the whole bag or database each time, don't poll with `OnUpdate`, and don't build large tables.
- Check an addition earns its keep: if it adds a saved variable, an event or a hook, say why.

## Layout

```
AHPremium.toc   load order, Interface number, saved variables
Core.lua        defaults, saved-variable init, SW.Evaluate and its smeltOver helper (the one place the verdict is decided)
Smelting.lua    ore and alloy recipes, SW.SmeltPrices (bar values SW.Evaluate weighs)
Tooltip.lua     item tooltip line (TooltipDataProcessor post-call)
BagIcons.lua    bag slot coin (Bagnon and default bags)
IgnoreList.lua  window that lists and removes ignored items
Options.lua     Settings panel and /ahp slash commands
```

`SW.Evaluate` is shared by the tooltip and the bag icons. Change the verdict logic in Core.lua (`SW.Evaluate`, or `smeltOver` for when smelting wins), not in the display files.

## Rules that are easy to break

- **Interface number is `16001`** (the Forever client). Retail's `120105` makes the client hide the addon as out of date.
- **Auctionator is a hard dependency.** Use only `Auctionator.API.v1.*`, called through `pcall`, with `"AHPremium"` as the caller ID. Don't read its internal tables.
- **Saved variables:** `AHPremiumDB` (account) and `AHPremiumCharDB` (per character, holds `ignored[itemID]`). Renaming either wipes users' settings, so don't without a migration.
- **Defaults live in one place:** `SW.defaults` in `Core.lua`. Don't repeat a default elsewhere.
- **Auctionator ages are whole calendar days**, not hours. Don't add hour-based settings without our own timestamps.
- **Keep the options panel and ignore button wrapped in `pcall`.** The Forever client's Settings API may differ from retail, and a failure there must not break the addon.
- Soulbound, BoP and quest items are skipped by design. Grey items are skipped unless `includeJunk` is on.

## Verifying changes

There is no test harness, and no Lua compiler is required. Check in game:

1. `/reload` (full restart if the TOC or file list changed) and confirm no Lua errors (`/console scriptErrors 1`).
2. Hover a tradeable item in the loot window and in a bag. Both should show a verdict.
3. Change a setting and check bag icons refresh. Check ignore, unignore and the `/ahp list` window.

Say what was and wasn't verified. Don't claim a check passed if it was only read, not run.

## Style

- Australian English in code comments, UI text and docs ("colour", "organise", "licence" as a noun).
- Plain, direct prose. Comments say why, not what.
- Match the surrounding Lua style: two-space indent, `local` by default, no globals except `AHPremium` and the saved variables. The slash command (`SLASH_AHPREMIUM1`, `SlashCmdList.AHPREMIUM`) and the named ignore window (`AHPremiumIgnoreList`, needed for Esc to close it) are the only exceptions, because the client requires them.

## Git, releases and safety

- **Ask before anything outward-facing:** pushing, tagging, creating releases, or touching the user's WoW folder. Approval for one doesn't cover the next. The one standing exception is posting review comments on a PR the user asked to have reviewed (see CLAUDE.md).
- Commits: imperative subject, a short body saying why, plus the attribution trailer the harness specifies. On PowerShell 5.1, write the message to a file and use `git commit -F <file>`. Passing a here-string to `git commit -m` breaks when the message contains quotes.
- The game folder holds a **junction** to this repo at `...\_forever_\Interface\AddOns\AHPremium`. Remove it with `rmdir` on the link, never a recursive delete.
- Releases are tags named `v<version>` (for example `v1.0`), with a zip built from the committed tag: `git archive --format=zip --prefix=AHPremium/ -o AHPremium-<version>.zip v<version>`. Bump `## Version:` in the TOC first. `.gitattributes` marks `AGENTS.md`, `CLAUDE.md`, `README.md` and itself as `export-ignore`, so they stay out of the zip. Always build it with `git archive` (not by zipping the folder), and add any new dev-only file to `.gitattributes`.
- Licence is GPL-3.0. Don't add code with an incompatible licence.
