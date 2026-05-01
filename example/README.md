# Example project

This folder is a self-contained sample that demonstrates every detection pattern
and policy rule supported by `feature_flag_audit`.

Run the audit against it from the package root:

```bash
dart run feature_flag_audit --project-root=example
```

---

## What this example demonstrates

### Finding type 1 — Class reference (resolved)

Keys defined as `static const` members of a configured `key_class` are resolved
automatically. The scanner reads `RemoteConfigKeys` and maps member names to
their string values.

```dart
// lib/remote_config_keys.dart
class RemoteConfigKeys {
  static const enableCheckoutRevamp = 'enable_checkout_revamp';
  static const enableDarkMode       = 'enable_dark_mode';
  // ...
}

// lib/services/feature_flag_service.dart
_remoteConfig.getBool(RemoteConfigKeys.enableCheckoutRevamp)
// → detected key: "enable_checkout_revamp"
```

### Finding type 2 — String literal (resolved)

Plain string literals passed directly to a usage or wrapper method are also
detected, no class needed.

```dart
_remoteConfig.getString('onboarding_variant')
// → detected key: "onboarding_variant"
```

### Finding type 3 — Unresolved reference

`LegacyFlags` is referenced in `experiment_service.dart` but its file lives
under `lib/legacy/`, which is listed in `scan.exclude`. The scanner cannot
resolve `LegacyFlags.promoV1` to a key value, so it appears in the
**Unresolved key references** section.

This simulates what happens when a key class is deleted or moved outside the
scan path without updating its call sites.

```dart
// lib/services/experiment_service.dart
_remoteConfig.getBool(LegacyFlags.promoV1)
// → unresolved: "LegacyFlags.promoV1"
```

With `unresolved_references: fail` in the policy, this causes exit code `1`.

### Finding type 4 — Code-only key

`'ab_test_new_pdp'` is used in code but does not exist in the Firebase Remote
Config console. With `code_only_keys: fail` the pipeline would block until the
key is added to Firebase.

```dart
// lib/services/experiment_service.dart
_remoteConfig.getBool('ab_test_new_pdp')
// → code-only key: "ab_test_new_pdp"  (visible when real Firebase creds are set)
```

> In this example `service-account.json` is intentionally fake, so Firebase
> comparison is skipped. Set real credentials to see `code_only_keys` and
> `console_only_keys` policy rules evaluated.

---

## File structure

```
example/
├── feature_flag_audit.yaml          # Full config with all sections including policy
├── service-account.json             # Placeholder — replace with a real credential file
└── lib/
    ├── main.dart                    # Entry point — exercises both services
    ├── mock_remote_config.dart      # Shared stub that satisfies the usage method calls
    ├── remote_config_keys.dart      # key_class — defines static const key strings
    ├── legacy/
    │   └── legacy_flags.dart        # Excluded from scanning → produces unresolved reference
    └── services/
        ├── feature_flag_service.dart  # Class references + literal keys + wrapper methods
        └── experiment_service.dart    # Unresolved reference + code-only key
```

---

## Expected output

```
Loading configuration from example/feature_flag_audit.yaml.
Configuration ready.

Scan summary:
  Dart files scanned: 5
  Keys detected: 7
  Total matches: 8
  Unresolved references: 1

Detected keys:
  ab_test_new_pdp (1)
    - getBool at lib/services/experiment_service.dart:26:26
  enable_checkout_revamp (1)
    - getBool at lib/services/feature_flag_service.dart:15:26
  enable_dark_mode (1)
    - boolConfigValueProvider at lib/services/feature_flag_service.dart:31:12
  home_banner_text (1)
    - getString at lib/services/feature_flag_service.dart:19:26
  max_promo_count (1)
    - intConfigValueProvider at lib/services/feature_flag_service.dart:23:12
  onboarding_variant (2)
    - getString at lib/services/experiment_service.dart:16:26
    - getString at lib/services/feature_flag_service.dart:40:26
  product_tile_aspect_ratio (1)
    - doubleConfigValueProvider at lib/services/feature_flag_service.dart:27:12

Unresolved key references:
  - LegacyFlags.promoV1 via getBool at lib/services/experiment_service.dart:40:26

Fetching Firebase Remote Config template...
Firebase comparison skipped: <invalid credentials — expected with placeholder file>

Policy check results:
  [FAIL] unresolved_references: 1 violation
    - LegacyFlags.promoV1

Pipeline result: FAILED
```

Exit code `1` because `unresolved_references` is set to `fail` and one violation
was found. Fix it by either removing the stale call site or adding
`lib/legacy` back to `scan.include`.

---

## Trying the policy rules

Override any rule from the command line without changing the YAML:

```bash
# Downgrade unresolved references to a warning so the pipeline passes
dart run feature_flag_audit --project-root=example --policy-unresolved=warn

# Silence everything to see only the scan output
dart run feature_flag_audit --project-root=example \
  --policy-code-only=pass \
  --policy-console-only=pass \
  --policy-unresolved=pass
```
