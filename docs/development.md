# Development

## Prereqs

* Xcode 27.0+, Swift 6.4+, macOS host for builds.
* `xcodegen` (`brew install xcodegen`) — the `.xcodeproj` is generated from
  `project.yml`, which is the source of truth. Never hand-edit the
  `.xcodeproj`.

## Everyday commands

```bash
# (once per checkout, after project.yml changes)
xcodegen generate

# build
xcodebuild -scheme MacMode -configuration Debug \
  -destination 'platform=macOS' build

# tests
xcodebuild test -scheme MacMode -destination 'platform=macOS'
```

Scheme/destination names above are verified working (`xcodebuild -list`
shows schemes `MacMode`; build + test green 2026-09-24).

## Workflow

1. `inspect → research → reason → implement → test → verify → document`.
2. Small commits: `feat:`, `fix:`, `test:`, `docs:`, `chore:`, `research:`.
3. Build + run relevant tests after each meaningful change.
4. System behavior (Function Keys, permissions, persistence-vs-system sync)
   must be verified manually on a real Mac; mark anything unverifiable as
   `UNVERIFIED` with what a real Mac run must cover.
5. Keep `README.md`, `SPEC.md`, `AGENTS.md`, `docs/` truthful: planned
   features are never presented as implemented.

## What stays manual (for now)

* Xcode project generation via `xcodegen` (documented above).
* Manual verification checklist in `SPEC.md` §29.
* No CI yet — evaluate a minimal GitHub Actions workflow (build + test)
  once the scaffold exists. No release pipeline until a real release
  process is requested.
* No GitHub Release until a distributable artifact exists.
