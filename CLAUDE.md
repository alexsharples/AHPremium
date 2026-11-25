# CLAUDE.md

How to work in this repo. Read AGENTS.md first: it covers the addon's rules (lightweight, Auctionator API, saved variables, release zips). This file covers the workflow around them.

## Branches

- Never commit to `main` directly. Every change goes on a branch off `main` and reaches `main` through a PR, including docs, version bumps and one-line fixes. The default branch is `main`; there is no `master`.
- Before starting, `git fetch --prune` and make sure `main` is current.
- Once a branch is merged, delete it locally and on the remote in the same step as the merge: `gh pr merge <n> --merge --delete-branch`, or `git branch -d <name>` and `git push origin --delete <name>`. Then `git fetch --prune`.
- Don't leave dangling branches. If `git branch --merged main` lists anything besides `main`, delete it.

## Commits and PRs

- PowerShell 5.1 mangles quotes in here-strings passed to `git commit -m`. Write the message to a file in the scratchpad and use `git commit -F <file>`. Do the same for PR bodies with `gh pr create --body-file`.
- Keep the PR description in step with the branch. If later commits change the scope, update it with `gh pr edit <n> --body-file`.
- Run `/code-review` on the PR before merging, and list what was fixed and what was left.
- The PR description has a testing checklist. Tick only what was run in game.

## Verifying

- There is no Lua compiler or test harness on this machine. Say so: code that was only read is unverified, including its syntax.
- Item and spell IDs written from memory must be flagged as such until checked in game.
- A new file or a TOC change needs a full client restart, not `/reload`. Mention it whenever it applies.

## Releases

- Follow the release steps in AGENTS.md: bump `## Version:` in the TOC on the branch before merging, tag the merge commit, build the zip from the tag with `git archive`.
- Publish untested builds as GitHub pre-releases. Mark one Latest only after the user confirms it works in game.
- Release notes are for players: what changed for them, plus the Auctionator requirement and install line. Match the style of earlier releases.
- New dev-only files (like this one) go in `.gitattributes` as `export-ignore` so they stay out of the zip.
