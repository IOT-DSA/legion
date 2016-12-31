library legion.toolchains.gcc;

import "dart:async";
import "dart:io";

import "package:legion/api.dart";
import "package:legion/utils.dart";

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
  Future<List<String>> getCFlags() async {
    var args = <String>[];

    if (isTargetX86_32Bit(target)) {
      args.add("-m32");
    }

    return args;
  }

  @override
  Future<List<String>> getCxxFlags() async {
    var args = <String>[];

    if (isTargetX86_32Bit(target)) {
      args.add("-m32");
    }

    return args;
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
}

class GccToolchainProvider extends ToolchainProvider {
  @override
  Future<String> getProviderName() async => "gcc";

  @override
  Future<Toolchain> getToolchain(String target, Project project) async {
    var executable = await findExecutable("gcc");
    var gcc = new GccHelper(executable);

    return new GccToolchain(target, gcc);
  }

  @override
  Future<bool> isTargetSupported(String target, Project project) async {
    var executable = await findExecutable("gcc");
    if (executable == null) {
      return false;
    }

    var gcc = new GccHelper(executable);
    var targets = await gcc.getTargetNames();

    return targets.contains(target);
  }

  @override
  Future<List<String>> listBasicTargets() async {
    var executable = await findExecutable("gcc");

    if (executable == null) {
      return const [];
    }

    var gcc = new GccHelper(executable);
    var targets = await gcc.getTargetNames(basic: true);
    return targets;
  }
}
