---
name: deploy-ios
description: Use when preparing a UMCApp TestFlight internal or App Store deployment, including release branches, build-number allocation, Xcode Cloud server routing, or archive verification.
---

# Deploy iOS

Build a distinct archive for each backend environment. A branch is only a workflow trigger;
`USE_DEV_SERVER` determines the injected API base URL.

## Select the target

| Target | Branch | Server | Xcode Cloud variable |
| --- | --- | --- | --- |
| Internal TestFlight | `testflight/internal/{version}/{build}` | dev | `USE_DEV_SERVER=1` |
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
4. Create and push the target branch. Commit the version change when needed, without AI
   attribution. A push is the Xcode Cloud deployment trigger; do not create a PR unless
   requested.
5. Verify the build number and manifest generation on the deployment branch:

   ```sh
   cd UMCApp
   make generate
   ```

   Confirm the generated configuration has the requested `MARKETING_VERSION` and
   `CURRENT_PROJECT_VERSION`. Report the branch, version, build number, and selected server.

## Xcode Cloud preflight

`BASE_URL_DEBUG` and `BASE_URL_RELEASE` must be available to both workflows. The internal
workflow alone must set `USE_DEV_SERVER=1`; the App Store workflow must not set it.
The App Store workflow's TestFlight post-action distributes the same prod archive and is
not a dev-server TestFlight deployment.

The Makefile recognizes `release/{version}/{build}` and
`testflight/internal/{version}/{build}`. Keep its branch parser aligned with these two
contracts and verify it resolves the requested build number before pushing.

## Stop conditions

Stop and ask for direction when the target is ambiguous, the branch or build number is
already used, the worktree is dirty, App Store Connect cannot confirm build availability,
or the required Xcode Cloud environment variables are not configured. Never substitute a
dev server for an App Store release or a prod archive for the internal-dev workflow.
