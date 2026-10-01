---
name: deploy-ios
description: Use when preparing a UMCApp TestFlight external or App Store deployment, including release branches, build-number allocation, Xcode Cloud server routing, or archive verification.
---

# Deploy iOS

Build a distinct archive for each backend environment. A branch is only a workflow trigger;
`USE_DEV_SERVER` determines the injected API base URL.

## Select the target

| Target | Branch | Server | Xcode Cloud variable |
| --- | --- | --- | --- |
| External TestFlight | `testflight/external/{version}/{build}` | dev | `USE_DEV_SERVER=1` |
| App Store release | `release/{version}/{build}` | prod | unset `USE_DEV_SERVER` |

TestFlight and App Store uploads for the same marketing version must use different build
numbers. Start at 105. Use the next unused number across both branch families and confirm
it is unused in App Store Connect before uploading.

## Deploy

1. Read `UMCApp/ci_scripts/ci_post_clone.sh`, `UMCApp/Makefile`, and the current version
   in `UMCApp/Tuist/ProjectDescriptionHelpers/Settings+Recommended.swift`.
2. Fetch remote refs. Require a clean worktree, a target explicitly named by the user, and
   a branch name not already present. Do not force-push or reuse a build number.
3. Start from `origin/develop` unless the user identifies a different source revision.
   Update `MARKETING_VERSION` only when it differs from the requested version; the branch
   name supplies `CURRENT_PROJECT_VERSION`.
4. Create the target branch. Commit the version change when needed, without AI attribution.
5. Verify the build number and manifest generation on the deployment branch:

   ```sh
   cd UMCApp
   make generate
   ```

   Confirm the generated configuration has the requested `MARKETING_VERSION` and
   `CURRENT_PROJECT_VERSION`, then push the branch to trigger Xcode Cloud. Do not create a
   PR for the deployment branch unless requested.
6. Sync the requested `MARKETING_VERSION` back to `develop` when develop's version is lower
   (compare numeric version components, not strings). Follow `docs/claude/git-workflow.md`: reuse
   or create an issue, use a `{type}/{issue}` branch from `origin/develop`, and open a PR
   targeting `develop` with the required template, assignee, and label. This version-sync
   PR is part of deployment; the no-PR rule above applies only to the deployment branch.
   Copy only `MARKETING_VERSION` in `Settings+Recommended.swift`; never merge the
   deployment branch or carry over server settings or deployment-only changes. Preserve
   the local `CURRENT_PROJECT_VERSION` default of `1`, not the deployment build number.
   Skip the PR if `develop` already has the same or a higher version; never downgrade it.
7. After the PR is merged, update local `develop` without discarding local changes and run
   `cd UMCApp && make generate` without a deployment build-number override. Verify the
   generated settings match `develop`'s `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION=1`.
   Report deployment push/Cloud status separately from develop sync and local generation
   status, alongside the branch, version, build number, and selected server. A pending PR
   is not a completed develop sync, and a push does not prove an upload succeeded.

## Xcode Cloud preflight

`BASE_URL_DEBUG` and `BASE_URL_RELEASE` must be available to both workflows. The external
TestFlight workflow must set `USE_DEV_SERVER=1`; the App Store workflow must not set it.
The App Store workflow's TestFlight post-action distributes the same prod archive and is
not a dev-server TestFlight deployment.

The Makefile recognizes `release/{version}/{build}` and
`testflight/external/{version}/{build}`. Keep its branch parser aligned with these two
contracts and verify it resolves the requested build number before pushing.

## Stop conditions

Stop and ask for direction when the target is ambiguous, the branch or build number is
already used, the worktree is dirty, App Store Connect cannot confirm build availability,
or the required Xcode Cloud environment variables are not configured. Never substitute a
dev server for an App Store release or a prod archive for the external-dev workflow.
