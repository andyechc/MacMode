# MacMode Agent Instructions

Read `SPEC.md` before making architectural or product decisions.

## Product

MacMode is a native macOS menu bar utility that switches between DEV and GAMING system profiles.

The MVP controls Function Key behavior.

The product will eventually have a dedicated landing page for presenting and distributing the application.

The landing page is future scope unless explicitly requested.

## Engineering

* Use Swift + SwiftUI.
* Use AppKit when macOS integration requires it.
* Prefer native Apple frameworks.
* Isolate low-level macOS APIs behind interfaces.
* Keep the application independent from the future website.
* Do not introduce Electron, Tauri, Node, Python or third-party system frameworks without a documented technical reason.
* Research macOS APIs before implementing system-level behavior.
* Never fake system integrations.
* Never claim unverified behavior works.
* Never bypass macOS permissions or security.
* Never log or persist keyboard input.
* Keep network access out of the application unless explicitly required.

## Repository

The GitHub repository is part of the product.

Keep:

* README.md
* SPEC.md
* AGENTS.md
* LICENSE
* docs/

up to date.

Do not commit:

* secrets,
* API keys,
* certificates,
* provisioning profiles,
* build artifacts,
* Xcode user state,
* personal machine configuration.

Use clean, focused Git commits.

Verify the GitHub remote before pushing.

## GitHub

If repository creation is required, create it in the user's authenticated GitHub account.

Never invent the GitHub username.

Never create a repository under another account or organization without explicit authorization.

Do not expose credentials or tokens.

## Documentation

Document important technical decisions.

For system-level behavior, distinguish:

* verified facts,
* assumptions,
* unverified behavior.

Function Key research must live in:

`docs/research/function-keys.md`

## Testing

Build and test after meaningful changes.

Do not declare completion solely because the project compiles.

Real macOS behavior must be verified on a real Mac when required.

## Scope

Do not implement roadmap features unless explicitly requested.

Prefer small, reversible changes over large rewrites.

When a critical decision affects security, privacy, permissions, compatibility, repository ownership, distribution, or architecture and cannot be resolved from available evidence, ask the user.

Otherwise, make reasonable engineering decisions and continue.

