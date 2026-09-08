# Contributing to fastlane-plugin-charles

First off, thanks for taking the time to contribute! Any contribution, large or small, is welcome.

This project is small and maintained by one person in their spare time, so please be patient with response times.

## Code of Conduct

This project and everyone participating in it is governed by the [Code of Conduct](CODE_OF_CONDUCT.md). By participating, you are expected to uphold it.

## I Have a Question

Before opening a new issue, please check the [README](README.md) and search [existing issues](https://github.com/jakekrog/fastlane-plugin-charles/issues) — your question may already be answered there. If it isn't, go ahead and [open an issue](https://github.com/jakekrog/fastlane-plugin-charles/issues/new), including as much context as you can (your Ruby/fastlane versions, the command you ran, and your `charles.yml` if relevant — please redact anything sensitive).

## I Want to Contribute

By contributing, you agree that your contributions may be distributed under the project's [MIT license](LICENSE).

### Reporting Bugs

Before submitting a bug report:

- Update to the latest version of the plugin and confirm the bug still occurs.
- Search [existing issues](https://github.com/jakekrog/fastlane-plugin-charles/issues) to check it hasn't already been reported.
- Collect the relevant details: your Ruby version, fastlane version, the exact command you ran, and the full error output.

When filing the issue, please include:

- A clear description of what you expected to happen vs. what actually happened.
- Steps to reproduce it, ideally with a minimal `charles.yml`.
- Whether it's reproducible consistently or only sometimes.

### Suggesting Enhancements

Before suggesting an enhancement, check [`docs/tool-configuration.md`](docs/tool-configuration.md) if it relates to a Charles `toolConfiguration` tool — several were already evaluated there, with notes on why they were or weren't taken on.

When filing the suggestion, please describe:

- The use case it solves and why it doesn't fit the existing options.
- A rough shape for how it'd look in `charles.yml` or as an action option, if applicable.

### Your First Code Contribution

```bash
git clone https://github.com/jakekrog/fastlane-plugin-charles.git
cd fastlane-plugin-charles
bundle install
```

Run the test suite and style checks (same command CI runs, across Ruby 3.1–3.4 and 4.0):

```bash
bundle exec rake
```

Or individually:

```bash
bundle exec rspec       # test suite only
bundle exec rubocop -a  # autocorrect style issues
```

Please make sure `bundle exec rake` passes before opening a PR.

This repo also has a [pre-commit](https://pre-commit.com) config (`.pre-commit-config.yaml`) that runs rubocop, [mdl](https://github.com/markdownlint/markdownlint) (Markdown lint, configured via `.mdlrc`/`.mdl_style.rb`), and a few general hygiene checks (trailing whitespace, YAML syntax, merge conflict markers, etc.) on changed files. It's optional but recommended — install it once per clone with:

```bash
pre-commit install
```

After that it runs automatically on `git commit`. You can also run it manually, e.g. against everything:

```bash
pre-commit run --all-files
```

### Improving the Documentation

- If you add or change a `charles.yml` key, document it inline in [`example/charles.yml`](example/charles.yml), and update the README's Options table if it's action-level (not YAML-level) config.
- Keep [`CHANGELOG.md`](CHANGELOG.md) up to date for user-facing changes, following [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## Styleguide

Code style is enforced by RuboCop (`bundle exec rubocop`, config in [`.rubocop.yml`](.rubocop.yml)) rather than a prose styleguide — please run it (`-a` to autocorrect) before opening a PR.

## Releasing (maintainers)

Releases are published via [RubyGems Trusted Publishing](https://guides.rubygems.org/trusted-publishing/) — there's no API key stored anywhere, and no manual `gem push` from a local machine. There are three separate, non-triggering-each-other steps: merge the version bump, run the release workflow (this is the only step that actually publishes to RubyGems), and — entirely separately, whenever you get to it — create the GitHub Release. Nothing here happens automatically as a side effect of anything else.

1. **Bump the version and changelog, via a PR.** Bump [`lib/fastlane/plugin/charles/version.rb`](lib/fastlane/plugin/charles/version.rb) and add a matching entry to [`CHANGELOG.md`](CHANGELOG.md) (move the `[Unreleased]` items under a new `## [X.Y.Z] - YYYY-MM-DD` heading). `main` has a ruleset requiring PRs for everyone including the repo owner, so this has to go through a branch + PR + passing CI, same as any other change — there's no direct-push shortcut here anymore. Merge it (squash) once CI is green.

2. **Trigger the `Release` workflow.** This is the only step that touches RubyGems, and it's the one deliberately-manual step in the whole process — it never runs automatically on a push, only on `workflow_dispatch`:

   ```bash
   gh workflow run release.yml --repo jakekrog/fastlane-plugin-charles --ref main
   ```

   (Or: Actions tab → "Release" → "Run workflow".) Either way, this pauses for approval per the `release` environment's required-reviewer gate — go approve the run in the Actions UI. Once approved, it runs `rake release`, which builds the gem, tags the merge commit `vX.Y.Z`, pushes that tag, and pushes to RubyGems.org via a short-lived, workflow-scoped OIDC token. The tag push isn't affected by the `main` ruleset — rulesets here target the branch, not tags — so this step needs no special handling despite the branch protection.

3. **Create the GitHub Release, separately and whenever.** This step is purely cosmetic on GitHub's side — it doesn't touch RubyGems and isn't required for the gem to be usable, so there's no urgency or ordering constraint relative to step 2 beyond "the tag has to exist first," which it will once step 2 has run.

   ```bash
   gh release create vX.Y.Z --repo jakekrog/fastlane-plugin-charles --title vX.Y.Z --notes-file <(awk '/^## \[X\.Y\.Z\]/{flag=1; next} /^## \[/{flag=0} /^\[.*\]: /{flag=0} flag' CHANGELOG.md)
   ```

   Or just copy the relevant `[X.Y.Z]` section from `CHANGELOG.md` into the "Draft a new release" form at `https://github.com/jakekrog/fastlane-plugin-charles/releases/new`, picking the tag step 2 already pushed (don't create a new tag from this form). Any relative markdown links copied in from the changelog (e.g. `example/charles.yml`) won't resolve on the release page the way they do in the repo — turn those into absolute `https://github.com/jakekrog/fastlane-plugin-charles/blob/vX.Y.Z/...` links first.

One-time setup (before the first release only): configure a [pending trusted publisher](https://guides.rubygems.org/trusted-publishing/adding-a-publisher/) on RubyGems.org for this repo + the `release.yml` workflow filename. Trusted publishing supports brand-new gems, so this can be done — and the whole release, including the very first one, can go through the workflow — without ever running `gem push` locally.
