# Example Apps

This folder contains a realistic sample project for `feature_flag_audit` directly in this directory.

## Sample project contents

This example includes:

- `feature_flag_audit.yaml`
- a dummy `service-account.json`
- a key class (`RemoteConfigKeys`)
- direct remote config usage (`getBool`, `getString`, `getInt`, `getDouble`)
- wrapper method usage (`boolConfigValueProvider`, `stringConfigValueProvider`, etc.)

Source files are under `lib/` and a sample `pubspec.yaml` is included.

Run the audit against this sample from the package root:

```bash
dart run feature_flag_audit --project-root=example
```

Notes:

- The service account file is intentionally fake and only demonstrates structure.
- Replace `service-account.json` with a real credential file only in your own environment.