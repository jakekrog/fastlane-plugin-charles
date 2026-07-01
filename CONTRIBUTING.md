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

Run the test suite and style checks (same command CI runs, across Ruby 3.0–3.4):

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

Releases are published via [RubyGems Trusted Publishing](https://guides.rubygems.org/trusted-publishing/) — there's no API key stored anywhere, and no manual `gem push` from a local machine.

1. Bump the version in [`lib/fastlane/plugin/charles/version.rb`](lib/fastlane/plugin/charles/version.rb) and add a matching entry to [`CHANGELOG.md`](CHANGELOG.md).
2. Merge that to the default branch.
3. Manually run the [`Release` workflow](https://github.com/jakekrog/fastlane-plugin-charles/actions/workflows/release.yml) (`workflow_dispatch`, triggered from the Actions tab — this is deliberate, not automatic on every push). It runs `rake release`, which builds the gem, tags the commit `vX.Y.Z`, pushes the tag, and pushes to RubyGems.org via a short-lived, workflow-scoped OIDC token.
4. Optionally, create a [GitHub Release](https://github.com/jakekrog/fastlane-plugin-charles/releases/new) pointing at the tag the workflow just pushed, with notes copied from the CHANGELOG entry — this is separate from and doesn't trigger the RubyGems publish, it's purely for GitHub-side visibility.

One-time setup (before the first release only): configure a [pending trusted publisher](https://guides.rubygems.org/trusted-publishing/adding-a-publisher/) on RubyGems.org for this repo + the `release.yml` workflow filename. Trusted publishing supports brand-new gems, so this can be done — and the whole release, including the very first one, can go through the workflow — without ever running `gem push` locally.
