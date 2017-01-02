library legion.toolchains.gcc;

import "dart:async";

import "package:legion/api.dart";
import "package:legion/utils.dart";

import "generic_compiler.dart";

class GccHelper extends GenericCompilerHelper {
  GccHelper(String path) : super(path);
}

class GccToolchain extends GenericToolchain {
  GccToolchain(String target, GccHelper compiler) :
      super(target, compiler, "gcc", "g++");
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

    var gcc = new GccHelper(path);

    return new GccToolchain(target, gcc);
  }

  @override
  Future<bool> isTargetSupported(String target, Configuration config) async {
    if (path == null) {
      return false;
    }

    var gcc = new GccHelper(path);
    var targets = await gcc.getTargetNames();

    return targets.contains(target);
  }

  @override
  Future<List<String>> listBasicTargets() async {
    if (path == null) {
      return const <String>[];
    }

    var gcc = new GccHelper(path);
    var targets = await gcc.getTargetNames(basic: true);

    return targets;
  }

  Future<bool> isValidCompiler() async {
    var gcc = new GccHelper(path);

    try {
      await gcc.getVersion();
      return true;
    } catch (e) {
      return false;
    }
  }
}
