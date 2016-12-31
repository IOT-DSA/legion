library legion.toolchains.clang;

import "dart:async";
import "dart:io";

import "package:legion/api.dart";
import "package:legion/utils.dart";
import "generic_compiler.dart";

const Map<String, String> clangTargetMap = const {
  "linux-x64": "x86_64-linux-eabi",
  "linux-x86": "x86-linux-eabi",
  "linux-arm": "arm-linux-eabi",
  "linux-armv7a": "armv7a-linux-eabi",
  "linux-armv7m": "armv7m-linux-aebi",
  "mac-x64": "x86_64-apple-darwin-eabi",
  "mac-x86": "x86-apple-darwin-eabi"
};

class ClangHelper extends GenericCompilerHelper {
  ClangHelper(String path) : super(path);
}

class ClangToolchain extends Toolchain {
  final String target;
  final ClangHelper clang;

  ClangToolchain(this.target, this.clang);

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
    return await clang.getSystemName();
  }

  @override
  Future<String> getToolPath(String tool) async {
    var prefix = new File(clang.path).parent.absolute.path + "/";

    if (tool == "cc") {
      tool = "clang";
    }

    if (tool == "c++") {
      tool = "clang++";
    }

    return "${prefix}/${tool}";
  }

  @override
  Future<String> getToolchainBase() async {
    return new File(clang.path).parent.absolute.path;
  }
}

class ClangToolchainProvider extends ToolchainProvider {
  @override
  Future<String> getProviderName() async => "clang";

  @override
  Future<Toolchain> getToolchain(String target, Project project) async {
    var executable = await findExecutable("clang");
    var clang = new ClangHelper(executable);

    return new ClangToolchain(target, clang);
  }

  @override
  Future<bool> isTargetSupported(String target, Project project) async {
    var executable = await findExecutable("clang");
    if (executable == null) {
      return false;
    }

    var clang = new ClangHelper(executable);
    var targets = await clang.getTargetNames();

    return targets.contains(target);
  }

  @override
  Future<List<String>> listBasicTargets() async {
    var executable = await findExecutable("clang");

    if (executable == null) {
      return const [];
    }

    var clang = new ClangHelper(executable);
    var targets = await clang.getTargetNames(basic: true);
    return targets;
  }
}
