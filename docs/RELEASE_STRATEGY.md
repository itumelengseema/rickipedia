# Release Strategy

## Branches

- `develop`: combines completed features and fixes through pull requests.
- `staging`: holds a release candidate for regression testing.
- `main`: holds approved code used for tagged releases.

## Working branches

Create working branches from `develop` using:

- `feature/<issue-number>-<short-description>`
- `fix/<issue-number>-<short-description>`
- `chore/<issue-number>-<short-description>`
- `docs/<issue-number>-<short-description>`
- `test/<issue-number>-<short-description>`

Open pull requests from working branches into `develop`.

## Release promotion

1. Merge completed working branches into `develop` through pull requests.
2. Open a pull request from `develop` into `staging` when preparing a release.
3. Validate the release candidate on `staging`.
4. Open a pull request from `staging` into `main` after validation passes.
5. Tag the approved release commit on `main`.

Passing CI is required before merging promotion pull requests.

## Versioning

The version in `pubspec.yaml` uses MAJOR.MINOR.PATCH+BUILD.

- MAJOR: breaking changes to supported behaviour or compatibility.
- MINOR: new features that preserve existing behaviour.
- PATCH: fixes that preserve existing behaviour.
- BUILD: an increasing integer for each distributed build, including
  release candidates. It does not reset when the release version changes.

Release candidates use a prerelease suffix, for example:

- Pubspec version: `1.0.0-rc.1+2`
- Git tag: `v1.0.0-rc.1`

A subsequent approved release could use:

- Pubspec version: `1.0.0+3`
- Git tag: `v1.0.0`

The Git tag matches the pubspec version before the `+BUILD` suffix.
Create the tag on the commit containing the matching pubspec version.

## Release validation

Before promoting `staging` into `main`:

- Require passing CI for the latest release candidate commit.
- Test character loading, pagination, search and character details.
- Test refresh while results are already displayed.
- Test empty search results, network failures and retry behaviour.
- Check image loading and error placeholders.
- Build and manually test each platform declared as supported for v1.0.

Record the commit SHA, platform, device or browser, test results and
known limitations in the release promotion PR.

## Supported platforms

The v1.0 release targets Android and iOS.

Before publishing, build and manually validate the release candidate
on both platforms. Record the tested devices and OS versions in the
release promotion PR.

Web is not a supported platform for v1.0. Existing web functionality
is experimental. Web support will be introduced in a later release
after the responsive work in issue #17 and web validation are complete.

Publish only after the required validation and documentation are complete.

## Hotfixes

For an urgent production fix:

1. Create `fix/<issue-number>-<short-description>` from `main`.
2. Implement and validate the smallest necessary fix.
3. Open a PR into `main` and require passing CI.
4. Update the patch version, build number and changelog.
5. Tag the approved release commit after merging.
6. Open PRs to merge `main` back into `staging`, then `staging`
   into `develop`, resolving conflicts and validating each merge.

## Rollback

Keep previous release tags and distributed artifacts available.

If a release has a serious regression:

- Where deployment supports it, restore the previous known-good artifact.
- Revert the faulty changes through a PR and require passing CI.
- Release the corrected code with a new version and higher build number.
- Propagate the correction back into `staging` and `develop`.

Do not move existing release tags or rewrite shared branch history.

## Branch protection

An active GitHub branch ruleset targets `develop`, `staging` and `main`.

- Changes require a pull request.
- The `analyze-and-test` GitHub Actions check must pass.
- PR branches must be up to date with their target before merging.
- Branch deletion and force pushes are blocked.
- No bypass actors are configured.
- Required approvals are set to 0 because this is a solo project.

Ruleset availability and enforcement depend on repository visibility
and the GitHub account plan. Recheck these if either changes.

## Issue completion

Keep `main` as the repository’s default branch.

Normal working PRs target `develop` and use `Refs #<issue-number>`
to link their issue.

Close an implementation issue manually when:
- All its acceptance criteria are met.
- Required CI passes.
- Its PR is merged into `develop`.

Before closing, add a comment linking the merged PR and recording
validation results and any known limitations.

Merging into `develop` means the work is integrated, not released.

Issues with release-specific acceptance criteria remain open until
those criteria are met, including platform validation or publishing
where required.