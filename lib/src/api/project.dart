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

  Future<bool> getBooleanSetting(String name) async {
    return getBooleanEnvSetting(name) || config.getBoolean(name);
  }

  File getFile(String path) {
    var filePath = resolveWorkingPath(path, from: directory.path);
    return new File(filePath);
  }

  Future<bool> hasFile(String path) async {
    return await getFile(path).exists();
  }
}
