---
name: release
description: Publish a release to CurseForge and GitHub. Use when the user asks to publish, release, or tag a version.
argument-hint: "[version] (e.g., 1.2.0, 1.2.0-beta1)"
disable-model-invocation: true
---

# Release Procedure

**NEVER run this without explicit user instruction to publish.**

## Inputs

- **Version**: provided as `$ARGUMENTS`, or ask the user. Suggest based on `## Unreleased` content in `CHANGELOG.md`: all bug fixes → patch bump, any new features → minor bump.
- **Release type**: determined by tag name — `1.2.0` = Release, `1.2.0-beta1` = Beta, `1.2.0-alpha1` = Alpha.

## Pre-flight Checks

1. Read `CHANGELOG.md` and confirm there are entries under `## Unreleased`. If empty, stop and ask.
2. Run `git status` — working tree must be clean. If not, stop and ask.
3. Run `git log --oneline -5` — confirm we're on `main` (or a `hotfix/*` branch if doing a hotfix release).
4. Confirm the version number with the user before proceeding.

## Final Release (e.g., `1.2.0`)

1. In `CHANGELOG.md`:
   - Rename `## Unreleased` → `## X.Y.Z - YYYY-MM-DD` (today's date).
   - Add a fresh `## Unreleased` section with no entries above it.
2. Copy **only** the new version's section (the `## X.Y.Z - date` heading and its bullet points) into `RELEASE_NOTES.md`, replacing its entire contents.
3. Commit all changes: `"Release X.Y.Z"`
4. Push the commit.
5. Tag and push: `git tag X.Y.Z && git push --tags`
6. Confirm: the GitHub Actions workflow will build and upload to CurseForge + create a GitHub Release. Show the user the Actions URL.

## Pre-release (e.g., `1.2.0-beta1`)

Pre-releases do NOT rename the Unreleased section — 1.2.0 isn't final yet.

1. **Do NOT modify `CHANGELOG.md`** headings. The `## Unreleased` section stays as-is.
2. Copy the current `## Unreleased` content (just the bullet points, not the heading) into `RELEASE_NOTES.md`, replacing its entire contents. Add a heading like `## 1.2.0-beta1` at the top.
3. Commit: `"Pre-release X.Y.Z-betaN"`
4. Push the commit.
5. Tag and push: `git tag X.Y.Z-betaN && git push --tags`
6. The packager marks this as Beta/Alpha on CurseForge automatically.

## After Release

- Verify the GitHub Actions run started: `gh run list --limit 1`
- Tell the user the release is in progress and link to the Actions run.
