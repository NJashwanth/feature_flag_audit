import '../legacy/legacy_flags.dart';
import '../mock_remote_config.dart';
import '../remote_config_keys.dart';

class ExperimentService {
  ExperimentService(this._remoteConfig);

  final MockRemoteConfig _remoteConfig;

  // ── Example 3: resolved class reference ───────────────────────────────────
  //
  // RemoteConfigKeys is a configured key_class so this resolves correctly to
  // "onboarding_variant".
  //
  String readOnboardingVariant() {
    return _remoteConfig.getString(RemoteConfigKeys.onboardingVariant);
  }

  // ── Example 4: code-only key ──────────────────────────────────────────────
  //
  // "ab_test_new_pdp" is used in code but has not yet been created in the
  // Firebase Remote Config console. With `code_only_keys: fail` the pipeline
  // blocks until the key is added to Firebase, preventing a runtime mismatch.
  //
  bool readNewPdpExperiment() {
    return _remoteConfig.getBool('ab_test_new_pdp');
  }

  // ── Example 5: unresolved reference ───────────────────────────────────────
  //
  // LegacyFlags is defined in lib/legacy/ which is listed under scan.exclude,
  // so the scanner never sees that class. The reference LegacyFlags.promoV1
  // appears in "Unresolved key references" — exactly what would happen if the
  // class had been deleted or moved outside the scan path without updating its
  // call sites.
  //
  // With `unresolved_references: fail` this blocks the pipeline.
  //
  bool readPromoV1() {
    return _remoteConfig.getBool(LegacyFlags.promoV1);
  }
}
