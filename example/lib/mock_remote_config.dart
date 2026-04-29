class MockRemoteConfig {
  bool getBool(String key) => key.isNotEmpty;
  String getString(String key) => key;
  int getInt(String key) => key.length;
  double getDouble(String key) => key.length / 10;
}
