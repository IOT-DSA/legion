part of legion.builder;

class BuildStage {
  static const BuildStage configure = const BuildStage("configure");
  static const BuildStage build = const BuildStage("build");

  final String name;

  const BuildStage(this.name);

  @override
  String toString() => name;
}
