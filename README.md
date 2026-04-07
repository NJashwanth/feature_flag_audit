# feature_flag_audit

A Dart/Flutter CLI package to audit feature flag usage and Firebase Remote Config keys across your project.

It supports:

- zero-config scanning out of the box
- optional `feature_flag_audit.yaml` configuration
- CLI overrides for Firebase settings
- detection from direct usage methods and wrapper methods
- key resolution from configured key classes like `RemoteConfigKeys`

## Keywords

flutter feature flags, firebase remote config, dart cli, static analysis, feature flag audit

## Installation

Run directly:

```bash
dart run feature_flag_audit
```

Or activate globally:

```bash
dart pub global activate feature_flag_audit
feature_flag_audit
```

## Quick Start

In the root of your Flutter project:

```bash
dart run feature_flag_audit
```

This will:

1. load `feature_flag_audit.yaml` if present
2. merge any CLI overrides
3. validate config
4. scan source files and print summary and detected keys

## Configuration

Create `feature_flag_audit.yaml` in the project root:

```yaml
feature_flag_audit:
  firebase:
    project_id: "your-project-id"
    service_account_path: "./service-account.json"

  scan:
    include:
      - lib
    exclude:
      - build
      - .dart_tool

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

  output:
    show_used: true
    show_summary: true
```

## CLI Options

```text
--project-root      Target project root. Defaults to current directory
--project-id        Override firebase.project_id from YAML
--service-account   Override firebase.service_account_path from YAML
-h, --help          Show usage
```

Example:

```bash
dart run feature_flag_audit --project-id=my-project --service-account=./service-account.json
```

Audit another project directory from your current location:

```bash
dart run feature_flag_audit --project-root=example
```

## Validation Rules

- Uses defaults when config file is missing
- Warns when Firebase is fully omitted (scan-only mode)
- Fails when Firebase config is partially defined but required fields are missing
- Fails when `service_account_path` does not exist

## Firebase Console Comparison

When `firebase.project_id` and `firebase.service_account_path` are provided,
the CLI also fetches Firebase Remote Config keys from your project and compares
them with keys detected in code.

It reports:

- a cleaner comparison summary (counts for Firebase, code, matched, and mismatches)
- **Keys found in Firebase but not used in the Application**
- **keys used in the code base but not in firebase**

If a breakdown section has no keys, the CLI prints `None`.

### Required setup

1. Create a service account in Google Cloud for the same Firebase project.
2. Grant permissions that allow reading Firebase Remote Config templates.
3. Download the JSON key file and set it as `service_account_path`.
4. Set the correct `project_id` in `feature_flag_audit.yaml`.

### Behavior when Firebase is unavailable

- Code scan still runs and produces usage results.
- Firebase comparison is skipped with a clear warning if:
  - the credentials are invalid,
  - the project id is wrong,
  - or the API call fails.

### Example

```bash
dart run feature_flag_audit \
  --project-root=. \
  --project-id=your-project-id \
  --service-account=./service-account.json
```

## Future-Friendly Design

The configuration model is structured to support future additions such as:

- multiple providers (for example, Firebase and LaunchDarkly)
- custom detection plugins
- CI policy flags (for example, fail on unused keys)

## License

MIT