library legion.toolchains.gcc;

import "dart:async";
import "dart:io";

import "package:legion/api.dart";
import "package:legion/utils.dart";
import "package:legion/storage.dart";

import "generic_compiler.dart";

class GccHelper extends GenericCompilerHelper {
  GccHelper(String path) : super(path);
}

class GccToolchain extends Toolchain {
  final String target;
  final GccHelper gcc;

  GccToolchain(this.target, this.gcc);

  @override
  Future applyToBuilder(Builder builder) async {
  }

  @override
  Future<String> getSystemName() async {
    return await gcc.getSystemName();
  }

  @override
  Future<String> getToolPath(String tool) async {
    var prefix = gcc.path;
    if (prefix.endsWith("-gcc") || prefix.endsWith("/gcc")) {
      prefix = prefix.substring(0, prefix.length - 3);
    } else {
      prefix = new File(gcc.path).parent.absolute.path + "/";
    }

    if (tool == "cc") {
      tool = "gcc";
    }

    if (tool == "c++") {
      tool = "g++";
    }

    return "${prefix}${tool}";
  }

  @override
  Future<String> getToolchainBase() async {
    var prefix = gcc.path;
    if (prefix.endsWith("-gcc") || prefix.endsWith("/gcc")) {
      prefix = prefix.substring(0, prefix.length - 4);
    } else {
      prefix = new File(gcc.path).parent.absolute.path;
    }
    return prefix;
  }

  @override
  Future<Map<String, List<String>>> getEnvironmentVariables() async {
    var compilers = <String>[];

    if (isTargetX86_32Bit(target)) {
      compilers.add("-m32");
    }

    return <String, List<String>>{
      "CFLAGS": compilers,
      "CCFLAGS": compilers,
      "ASFLAGS": compilers
    };
  }

  @override
  Future<String> getTargetMachine() async {
    var machine = await gcc.getTargetMachine();
    if (isTargetX86_32Bit(target)) {
      machine = machine.replaceAll("x86_64", "i386");
    }
    return machine;
  }
}

class GccToolchainProvider extends ToolchainProvider {
  static final String defaultGccPath = findExecutableSync("gcc");

  final String path;

  GccToolchainProvider(this.path);

  @override
  Future<String> getProviderId() async => "gcc";

  @override
  Future<Toolchain> getToolchain(String target, StorageContainer config) async {
    if (path == null) {
      return null;
    }

    var gcc = new GccHelper(path);

    return new GccToolchain(target, gcc);
  }

  @override
  Future<bool> isTargetSupported(String target, StorageContainer config) async {
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

  @override
  Future<String> getProviderDescription() async {
    return "GCC (${path})";
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
