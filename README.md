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
--project-id        Override firebase.project_id from YAML
--service-account   Override firebase.service_account_path from YAML
-h, --help          Show usage
```

Example:

```bash
dart run feature_flag_audit --project-id=my-project --service-account=./service-account.json
```

## Validation Rules

- Uses defaults when config file is missing
- Warns when Firebase is fully omitted (scan-only mode)
- Fails when Firebase config is partially defined but required fields are missing
- Fails when `service_account_path` does not exist

## Future-Friendly Design

The configuration model is structured to support future additions such as:

- multiple providers (for example, Firebase and LaunchDarkly)
- custom detection plugins
- CI policy flags (for example, fail on unused keys)

## License

MIT