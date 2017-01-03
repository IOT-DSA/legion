library legion.toolchains.gcc;

import "dart:async";

import "package:legion/api.dart";
import "package:legion/utils.dart";

import "generic_compiler.dart";

class GccTool extends GenericCompilerTool {
  GccTool(String path) : super(path);

  @override
  Future<String> getCompilerId() async {
    return "GCC";
  }
}

class GccToolchain extends GenericToolchain {
  GccToolchain(String target, GccTool compiler) :
      super(target, compiler, "gcc", "g++");

  @override
  Future<GenericCompilerTool> getCompilerWrapper(String path) async =>
    new GccTool(path);
}

class GccToolchainProvider extends ToolchainProvider {
  static final String defaultGccPath = findExecutableSync("gcc");

  final String path;

  GccToolchainProvider(this.path);

  @override
  Future<String> getProviderId() async => "gcc";

  @override
  Future<String> getProviderDescription() async {
    return "GCC (${path})";
  }

  @override
  Future<Toolchain> getToolchain(String target, Configuration config) async {
    if (path == null) {
      return null;
    }

    var gcc = new GccTool(path);

    return new GccToolchain(target, gcc);
  }

  @override
  Future<bool> isTargetSupported(String target, Configuration config) async {
    if (path == null) {
      return false;
    }

    var gcc = new GccTool(path);
    var targets = await gcc.getTargetNames();

    return targets.contains(target);
  }

  @override
  Future<List<String>> listBasicTargets() async {
    if (path == null) {
      return const <String>[];
    }

    var gcc = new GccTool(path);
    var targets = await gcc.getTargetNames(basic: true);

    return targets;
  }

  Future<bool> isValidCompiler() async {
    var gcc = new GccTool(path);

    try {
      await gcc.getVersion();
      return true;
    } catch (e) {
      return false;
    }
  }
}
