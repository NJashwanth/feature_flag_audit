# Changelog

## 1.1.2

- Improved CLI output format for cleaner, more readable results.

## 1.1.1

- Added Firebase Remote Config console comparison using `project_id` and `service_account_path`.
- Added key diff reporting for shared, console-only, and code-only keys.
- Added graceful fallback when Firebase fetch fails so code scanning still completes.
- Added `--project-root` CLI option to audit projects outside the current working directory.
- Improved public API Dartdoc coverage for better pub.dev scoring.
- Reworked the example into a realistic Flutter-style sample directly under `example/`.
- Added and documented sample config, dummy service account file, and sample source files for detection.
- Updated README with Firebase console comparison setup, behavior, and usage examples.

## 1.0.0

- Initial release of `feature_flag_audit`.
- Added strongly typed configuration model with YAML loading.
- Added automatic root config discovery via `feature_flag_audit.yaml`.
- Added CLI override support for `project_id` and `service_account_path`.
- Added default scan and detection rules for Firebase Remote Config.
- Added validation with clear warnings and errors.
- Added scanner for usage methods, wrapper methods, and key class resolution.
- Added GitHub workflows for PR policy, tagging, and pub.dev publishing.