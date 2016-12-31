part of legion.api;

abstract class ToolchainProvider {
  Future<String> getProviderName();
  Future<List<String>> listBasicTargets();
  Future<bool> isTargetSupported(String target, Project project);
  Future<Toolchain> getToolchain(String target, Project project);
}

abstract class Toolchain {
  Future<String> getToolchainBase();
  Future<String> getSystemName();
  Future<String> getToolPath(String tool);
  Future<List<String>> getCFlags();
  Future<List<String>> getCxxFlags();

  Future applyToBuilder(Builder builder);
}
