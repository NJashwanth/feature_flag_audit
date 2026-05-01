# Changelog

## 1.3.0

- Added pipeline enforcement via a new `policy` configuration section.
- Each finding type (`code_only_keys`, `console_only_keys`, `unresolved_references`) can independently be set to `fail`, `warn`, or `pass`.
- A `fail` rule causes the CLI to exit with code `1`, blocking the pipeline.
- A `warn` rule prints a `[WARN]` notice but exits `0` so the pipeline continues.
- A `pass` rule silently ignores the finding type.
- Added three CLI flags to override policy per run without changing YAML:
  - `--policy-code-only=fail|warn|pass`
  - `--policy-console-only=fail|warn|pass`
  - `--policy-unresolved=fail|warn|pass`
- Policy check results are printed at the end of every run with a clear `Pipeline result: PASSED / FAILED` summary line.
- All three rules default to `warn` so existing users see no behaviour change without opting in.

## 1.2.0

- Added YAML output toggles to control what sections are shown:
  - `show_unresolved_references`
  - `show_firebase_summary`
  - `show_firebase_console_only`
  - `show_firebase_code_only`

## 1.1.3

- Improved Firebase comparison output with a cleaner summary section.
- Added explicit breakdown sections for:
- Keys found in Firebase but not used in the Application.
- keys used in the code base but not in firebase.
- Added clearer empty-state output (`None`) for comparison breakdown lists.

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