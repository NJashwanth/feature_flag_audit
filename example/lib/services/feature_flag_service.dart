import '../mock_remote_config.dart';
import '../remote_config_keys.dart';

// ── Example 1: class-reference pattern ──────────────────────────────────────
//
// The scanner detects RemoteConfigKeys.enableCheckoutRevamp and resolves it to
// the string "enable_checkout_revamp" by reading the key class definition.
//
class FeatureFlagService {
  FeatureFlagService(this._remoteConfig);

  final MockRemoteConfig _remoteConfig;

  bool readCheckoutRevampFlag() {
    return _remoteConfig.getBool(RemoteConfigKeys.enableCheckoutRevamp);
  }

  String readHomeBannerText() {
    return _remoteConfig.getString(RemoteConfigKeys.homeBannerText);
  }

  int readPromoLimit() {
    return intConfigValueProvider(RemoteConfigKeys.maxPromoCount);
  }

  double readProductTileAspectRatio() {
    return doubleConfigValueProvider(RemoteConfigKeys.productTileAspectRatio);
  }

  bool readDarkModeFlag() {
    return boolConfigValueProvider(RemoteConfigKeys.enableDarkMode);
  }

  // ── Example 2: literal key string ─────────────────────────────────────────
  //
  // The scanner also detects plain string literals passed directly to usage or
  // wrapper methods. No class reference needed.
  //
  String readOnboardingVariant() {
    return _remoteConfig.getString('onboarding_variant');
  }

  // Wrapper methods — these are listed under detection.wrapper_methods so the
  // scanner treats them as feature flag access points.
  bool boolConfigValueProvider(String key) => _remoteConfig.getBool(key);
  String stringConfigValueProvider(String key) => _remoteConfig.getString(key);
  int intConfigValueProvider(String key) => _remoteConfig.getInt(key);
  double doubleConfigValueProvider(String key) => _remoteConfig.getDouble(key);
}
