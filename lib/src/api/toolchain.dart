part of legion.api;

abstract class ToolchainProvider {
  Future<String> getProviderId();
  Future<String> getProviderDescription();

  Future<List<String>> listBasicTargets();
  Future<bool> isTargetSupported(String target, Configuration config);
  Future<Toolchain> getToolchain(String target, Configuration config);
}

abstract class Toolchain {
  Future<String> getToolchainBase();
  Future<String> getSystemName();
  Future<String> getToolPath(String tool);
  Future<Map<String, List<String>>> getEnvironmentVariables();

  Future<String> getTargetMachine();

  Future applyToBuilder(Builder builder);
}
