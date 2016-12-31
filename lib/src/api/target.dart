part of legion.api;

class Target {
  final Project project;
  final String name;
  final Toolchain toolchain;
  final List<String> extraArguments;

  Target(this.project, this.name, this.toolchain, this.extraArguments);

  Future<bool> getBooleanSetting(String name) async {
    return await project.getBooleanSetting(name) || project.config.getSubStorage(
      this.name
    ).getBoolean(name);
  }
}
