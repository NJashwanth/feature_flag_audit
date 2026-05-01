# feature_flag_audit

A Dart/Flutter CLI package to audit feature flag usage and Firebase Remote Config keys across your project.

By **Jashwanth Neela** · [jneela.dev](https://jneela.dev/)

---

## What it does

`feature_flag_audit` scans your Flutter project's Dart source files and:

1. **Detects** every feature flag key used in code (via direct calls like `getBool("key")` or wrapper helpers)
2. **Resolves** class-based references like `RemoteConfigKeys.myFlag` back to their actual string key values
3. **Compares** detected keys against your live Firebase Remote Config console (optional)
4. **Enforces** a configurable policy — fail the pipeline, warn, or pass — for each class of finding

---

## Installation

Add it to `dev_dependencies` in your Flutter project:

```yaml
dev_dependencies:
  feature_flag_audit: ^1.3.0
```

Or activate globally to run from anywhere:

```bash
dart pub global activate feature_flag_audit
feature_flag_audit
```

---

## Quick Start

Run in the root of your Flutter project with zero configuration:

```bash
dart run feature_flag_audit
```

This scans `lib/` for feature flag usage and prints a summary. No config file is needed to get started.

---

## Configuration

Create `feature_flag_audit.yaml` in your project root to customise behaviour:

```yaml
feature_flag_audit:

  # Firebase Remote Config connection (optional — enables console comparison)
  firebase:
    project_id: "your-firebase-project-id"
    service_account_path: "./service-account.json"

  # Which directories to scan
  scan:
    include:
      - lib
    exclude:
      - build
      - .dart_tool

  # Which method calls count as feature flag usage
  detection:
    usage_methods:
      - getBool
      - getString
      - getInt
      - getDouble
    wrapper_methods:
      - boolConfigValueProvider
      - stringConfigValueProvider
      - intConfigValueProvider
      - doubleConfigValueProvider
    key_classes:
      - RemoteConfigKeys

  # Control which output sections are printed
  output:
    show_used: true
    show_summary: true
    show_unresolved_references: true
    show_firebase_summary: true
    show_firebase_console_only: true
    show_firebase_code_only: true

  # Pipeline enforcement — what to do when findings exist
  policy:
    code_only_keys: warn        # keys used in code but missing from Firebase
    console_only_keys: warn     # keys in Firebase but not used in code
    unresolved_references: warn # references that couldn't be resolved
```

Each field has a sensible default — you only need to specify what you want to change.

---

## Detection: how keys are found

The scanner supports two patterns.

### Pattern 1 — String literal

```dart
remoteConfig.getBool("enable_dark_mode")
```

The key `enable_dark_mode` is captured directly.

### Pattern 2 — Class reference

```dart
// RemoteConfigKeys is configured as a key_class
class RemoteConfigKeys {
  static const enableDarkMode = "enable_dark_mode";
  static const showOnboarding = "show_onboarding";
}

// The scanner resolves RemoteConfigKeys.enableDarkMode → "enable_dark_mode"
remoteConfig.getBool(RemoteConfigKeys.enableDarkMode)
boolConfigValueProvider(RemoteConfigKeys.showOnboarding)
```

Both patterns are detected and resolved to the same key value. If a reference cannot be resolved (the class or member wasn't found in the scanned files), it appears in the **Unresolved references** section.

---

## Sample output

```
Configuration ready.

Scan summary:
  Dart files scanned: 12
  Keys detected: 4
  Total matches: 7
  Unresolved references: 1

Detected keys:
  enable_dark_mode (3)
    - getBool at lib/services/feature_flag_service.dart:14:5
    - getBool at lib/services/feature_flag_service.dart:28:5
    - boolConfigValueProvider at lib/widgets/theme_switcher.dart:9:3
  new_checkout_flow (2)
    - getBool at lib/services/feature_flag_service.dart:19:5
    - boolConfigValueProvider at lib/screens/checkout.dart:42:7

Unresolved key references:
  - FeatureFlags.legacyKey via getBool at lib/services/legacy.dart:5:3

Firebase comparison summary:
  Keys in Firebase: 5
  Keys in application code: 4
  Keys matched in both: 3
  Keys only in Firebase: 2
  Keys only in application code: 1

Breakdown:
Keys found in Firebase but not used in the Application:
  - old_rating_prompt
  - summer_sale_banner

keys used in the code base but not in firebase:
  - new_checkout_flow

Policy check results:
  [WARN] unresolved_references: 1 violation
    - FeatureFlags.legacyKey
  [WARN] code_only_keys: 1 violation
    - new_checkout_flow
  [PASS] console_only_keys: no violations

Pipeline result: PASSED
```

---

## Pipeline enforcement

The `policy` section controls how each class of finding affects the exit code.

| Value  | Behaviour                                               |
|--------|---------------------------------------------------------|
| `fail` | Prints `[FAIL]`, exits with code `1` — blocks pipeline  |
| `warn` | Prints `[WARN]`, exits with code `0` — advisory only    |
| `pass` | Silent — finding is ignored completely                  |

All three rules default to `warn`, so upgrading from an earlier version produces no behaviour change until you opt in.

### Recommended pipeline config

```yaml
feature_flag_audit:
  policy:
    code_only_keys: fail          # code references a key that doesn't exist in Firebase — likely a bug
    console_only_keys: warn       # stale Firebase keys — worth knowing, but not blocking
    unresolved_references: fail   # broken class reference — always fix these
```

With this config the pipeline fails when:
- a key is used in code but doesn't exist in Firebase Remote Config
- a class-based reference like `RemoteConfigKeys.myFlag` can't be resolved

### GitHub Actions example

```yaml
# .github/workflows/audit.yml
name: Feature flag audit

on:
  pull_request:
  push:
    branches: [main]

jobs:
  audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - uses: dart-lang/setup-dart@v1

      - name: Install dependencies
        run: dart pub get

      - name: Run feature flag audit
        run: dart run feature_flag_audit
        # Exit code 1 fails this step, blocking the PR
```

With `code_only_keys: fail` in your YAML, a PR that uses a key not yet added to Firebase Remote Config will be blocked automatically.

### Bitbucket Pipelines example

```yaml
# bitbucket-pipelines.yml
pipelines:
  pull-requests:
    '**':
      - step:
          name: Feature flag audit
          image: dart:stable
          script:
            - dart pub get
            - dart run feature_flag_audit
```

### Override policy from the command line

You can tighten or loosen policy for a specific run without changing the YAML — useful for local debugging or for running a stricter check in a release pipeline:

```bash
# Fail on everything locally to do a thorough cleanup
dart run feature_flag_audit \
  --policy-code-only=fail \
  --policy-console-only=fail \
  --policy-unresolved=fail

# Temporarily ignore console-only findings during a rolling flag deployment
dart run feature_flag_audit --policy-console-only=pass
```

CLI flags always take precedence over the YAML config.

---

## CLI Reference

```
dart run feature_flag_audit [options]
```

| Flag                        | Description                                                         |
|-----------------------------|---------------------------------------------------------------------|
| `--project-root`            | Target project root. Defaults to current directory                  |
| `--project-id`              | Override `firebase.project_id` from YAML                           |
| `--service-account`         | Override `firebase.service_account_path` from YAML                 |
| `--policy-code-only`        | Override policy for `code_only_keys` (`fail`/`warn`/`pass`)        |
| `--policy-console-only`     | Override policy for `console_only_keys` (`fail`/`warn`/`pass`)     |
| `--policy-unresolved`       | Override policy for `unresolved_references` (`fail`/`warn`/`pass`) |
| `-h, --help`                | Show usage                                                          |

### Exit codes

| Code | Meaning                                              |
|------|------------------------------------------------------|
| `0`  | All checks passed (warnings are fine)                |
| `1`  | At least one `fail` policy rule had violations       |
| `64` | Invalid CLI argument format                          |
| `78` | Configuration error (missing file, bad YAML, etc.)  |

---

## Firebase Remote Config comparison

When `firebase.project_id` and `firebase.service_account_path` are both set, the tool fetches your live Remote Config template and compares its keys against what was found in code.

### Setup

1. Open [Google Cloud Console](https://console.cloud.google.com/) for your Firebase project.
2. Go to **IAM & Admin → Service Accounts** and create a service account.
3. Grant it the **Firebase Remote Config Viewer** role (or `firebase.remoteconfig.get` permission).
4. Download the JSON key file and place it in your project — do not commit it, add it to `.gitignore`.
5. Set `service_account_path` to its relative path from the project root.

```yaml
feature_flag_audit:
  firebase:
    project_id: "my-app-12345"
    service_account_path: "./config/firebase-sa.json"
```

### Behaviour when Firebase is unavailable

If Firebase credentials are invalid or the API call fails, the code scan still completes and results are printed. The Firebase comparison is skipped with a clear warning, and `code_only_keys` / `console_only_keys` policy rules are not evaluated (only `unresolved_references` applies).

---

## Scanning another project

To audit a project outside your current directory:

```bash
dart run feature_flag_audit --project-root=../my_flutter_app
```

The tool reads `feature_flag_audit.yaml` and all source paths relative to `--project-root`.

---

## Validation rules

| Condition                                                     | Severity |
|---------------------------------------------------------------|----------|
| Firebase config fully omitted                                 | Warning — scan-only mode continues |
| Firebase partially defined but `project_id` missing           | Error — exits `78` |
| Firebase partially defined but `service_account_path` missing | Error — exits `78` |
| `service_account_path` file does not exist on disk            | Error — exits `78` |
| `scan.include` is empty                                       | Warning |
| `detection.usage_methods` is empty                            | Warning |

---

## License

MIT
