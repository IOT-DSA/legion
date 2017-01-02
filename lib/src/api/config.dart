part of legion.api;

abstract class Configuration {
  Future<dynamic> getSetting(String key);
  Future<List<String>> getStringListSetting(String key);
  Future<Map<String, dynamic>> getMapSetting(String key);
  Future<bool> getBooleanSetting(String key);
  Future<String> getStringSetting(String key, [String defaultValue = ""]);
}

class MockConfiguration extends Configuration {
  @override
  Future<bool> getBooleanSetting(String key) async => false;

  @override
  Future<Map<String, dynamic>> getMapSetting(String key) async =>
    <String, dynamic>{};

  @override
  Future<dynamic> getSetting(String key) async => null;

  @override
  Future<List<String>> getStringListSetting(String key) async =>
    const <String>[];

  @override
  Future<String> getStringSetting(String key, [String defaultValue = ""]) async =>
    defaultValue;
}
