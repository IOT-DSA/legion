part of legion.api;

abstract class BuilderProvider {
  Future<String> getProviderName();
  Future<bool> isProjectSupported(Project project);
  Future<Builder> create(Target target);
}

abstract class Builder {
  final Target target;

  Builder(this.target);

  Future generate();
  Future build();
}
