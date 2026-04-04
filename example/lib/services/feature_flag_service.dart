import '../remote_config_keys.dart';

class MockRemoteConfig {
  bool getBool(String key) => key.isNotEmpty;
  String getString(String key) => key;
  int getInt(String key) => key.length;
  double getDouble(String key) => key.length / 10;
}

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

  bool boolConfigValueProvider(String key) => _remoteConfig.getBool(key);

  String stringConfigValueProvider(String key) => _remoteConfig.getString(key);

  int intConfigValueProvider(String key) => _remoteConfig.getInt(key);

  double doubleConfigValueProvider(String key) => _remoteConfig.getDouble(key);
}
