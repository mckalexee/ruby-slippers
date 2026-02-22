---
name: hotfix
description: Create a hotfix branch to patch a published release when main has unreleased work. Use when the user needs to fix a bug in a published version.
argument-hint: "[version-to-fix] (e.g., 1.2.0)"
disable-model-invocation: true
---

# Hotfix Procedure

Use this when a bug is found in a published version and `main` has unreleased work that shouldn't ship yet.

## When to Use

- A release tag exists (e.g., `1.2.0`) and users are on that version.
- `main` has commits after that tag with unreleased feature work.
- A bug needs to be fixed and shipped as a patch (e.g., `1.2.1`) without including the unreleased work.

If `main` has no unreleased work beyond the last tag, skip this — just fix on `main` and use `/release`.

## Procedure

### 1. Create the Hotfix Branch

```
git fetch --tags
git checkout -b hotfix/X.Y.Z <release-tag-to-fix>
```

Example: `git checkout -b hotfix/1.2.1 1.2.0`

### 2. Fix the Bug

- Make the fix on the hotfix branch.
- Add a changelog entry. Since this branch won't have `## Unreleased`, write the version section directly in `CHANGELOG.md`:

```markdown
## 1.2.1 - YYYY-MM-DD
- Fix: description of the bug fix
```

### 3. Update Release Notes

Copy the new version section into `RELEASE_NOTES.md`, replacing its contents.

### 4. Commit

```
git add -A && git commit -m "Release X.Y.Z"
```

### 5. Tag and Push

```
git push -u origin hotfix/X.Y.Z
git tag X.Y.Z && git push --tags
```

GitHub Actions will build and publish from the tag.

### 6. Merge Fix Back to Main

```
git checkout main
git cherry-pick <hotfix-commit-hash>
```

If the cherry-pick conflicts, resolve manually. Make sure the fix ends up under `## Unreleased` in main's `CHANGELOG.md` (it may need rewording since main's Unreleased section is different).

### 7. Clean Up

```
git branch -d hotfix/X.Y.Z
git push origin --delete hotfix/X.Y.Z
```

## Important

- The hotfix branch is short-lived — create it, fix, tag, merge back, delete.
- NEVER leave a hotfix branch lingering. It should be deleted the same day.
- The tag triggers the build, not the branch. The branch is just a workspace.
