# CLAUDE.md

How to work in this repo. Read AGENTS.md first: it covers the addon's rules (lightweight, Auctionator API, saved variables, release zips). This file covers the workflow around them.

## Approach

1. **Don't assume. Raise confusion and tradeoffs.** When something is unclear or there are competing approaches, say so. Name the tradeoff, give a recommendation, and wait for direction.
2. **Minimum code that solves the problem.** No speculative features, premature abstractions or future-proofing.
3. **Touch only what you must.** Don't clean up adjacent code, rename things you didn't break, or restructure areas you weren't asked to touch.
4. **Define success criteria, then loop until verified.** Before non-trivial work, state what "done" looks like, and check against it before calling the work complete.

## Writing

- Australian English everywhere: "colour", "organise", "behaviour", "licence" as a noun.
- Write docs, PR descriptions, release notes and comments like a person, not a language model:
  - Use em dashes sparingly. Prefer a full stop, a comma, or a rewrite.
  - Avoid stock phrases: "real power", "wake-up call", "key takeaway", "it's worth noting", "at the end of the day", "game-changer", "robust", "seamless", "leverage" (as a verb), "navigate" or "landscape" (metaphorical), "dive deep", "unpack", "elevate", "empower", "delve", "moreover", "furthermore", "additionally".
  - No "Here's the thing:" openers, habitual lists of three, or summaries that repeat what was just said.
  - Vary sentence length, and say things directly in plain words ("use", not "utilise").
  - When editing someone else's text, keep its facts, tone and length.

## Branches

- Never commit to `main` directly. Every change goes on a branch off `main` and reaches `main` through a PR, including docs, version bumps and one-line fixes. The default branch is `main`; there is no `master`.
- Before reading code to answer a question or starting work, `git fetch --prune` and check the local branch isn't behind its remote (in PowerShell, `git rev-list --count 'HEAD..@{u}'`). If it is, pull before drawing any conclusions.
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
