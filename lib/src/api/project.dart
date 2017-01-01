part of legion.api;

class Project {
  final Directory directory;

  Storage _config;
  Storage _state;

  Storage get config => _config;
  Storage get state => _state;

  Project(this.directory);

  Future init() async {
    _config = new Storage(resolveWorkingPath(
      "legion.json",
      from: directory.absolute.path
    ), saveOnChange: false);

    _state = new Storage(resolveWorkingPath(
      "legion/.state",
      from: directory.absolute.path
    ), saveOnChange: true);

    _config.load();
    _state.load();
  }

  Future<Target> getTarget(
    String name,
    Toolchain toolchain,
    List<String> extraArguments) async {
    return new Target(this, name, toolchain, extraArguments);
  }

  Future<dynamic> getSetting(String key) async {
    return resolveConfigValue(config.entries, key);
  }

  Future<List<String>> getStringListSetting(String key) async {
    var value = resolveConfigValue(config.entries, key);
    if (value is List) {
      return value.where((x) => x is String).toList();
    }
    return const <String>[];
  }

  Future<Map<String, dynamic>> getMapSetting(String key) async {
    var value = resolveConfigValue(config.entries, key);
    if (value is Map) {
      return value;
    }
    return const <String, dynamic>{};
  }

  Future<bool> getBooleanSetting(String key) async {
    return resolveConfigValue(config.entries, key) == true;
  }

  Future<String> getStringSetting(String key, [String defaultValue = ""]) async {
    var str = resolveConfigValue(config.entries, key);

    if (str is! String) {
      str = defaultValue;
    }

    return str;
  }

  File getFile(String path) {
    var filePath = resolveWorkingPath(path, from: directory.path);
    return new File(filePath);
  }

  Future<bool> hasFile(String path) async {
    return await getFile(path).exists();
  }
}
