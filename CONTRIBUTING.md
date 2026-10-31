# Contributing

All contributions are welcome, but this my highly opionated "data-class" helper for Dart, which is inspired by `dart_mappable` and `json_serializable` but makes many decisions based on my own preferences; so please open issues to discuss non-trivial changes. I might add a "Non-Goals" section here in the future to document all discarded ideas.

## Goals

* speed (benchmarks soon)

# Development

Use the scripts on the `scripts/` folder in order to verify your changes:

* `build.sh` will run pub and generate files
* `check.sh` runs lint (format, analysis) and tests (`--fix` flag to auto-fix lint).

## PR

Feel free to send us a PR to help the project!

Merged commits must follow [conventional commits](https://www.conventionalcommits.org), with a capitalized subject, as in `feat: Add the direct writer`, starting with a verb in the infinitive.

## Releasing

To make a release, running `scripts/release.sh` locally will guide you through creating a tag and pushing. The `publish.yml` GitHub actions picks up from there.  Both `charcoal` and `charcoal_builder` are always released in lock-step for clarity.

`scripts/publish.sh --dry-run` validates both packages without publishing.

Changelogs are automatically managed from commit messages (see above), and thus should not be manually updated.