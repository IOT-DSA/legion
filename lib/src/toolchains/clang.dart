library legion.toolchains.clang;

import "dart:async";
import "dart:io";

import "package:legion/api.dart";
import "package:legion/utils.dart";

import "generic_compiler.dart";
import "package:legion/storage.dart";

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
  Future<String> getSystemName() async {
    return await clang.getSystemName();
  }

  @override
  Future<String> getToolPath(String tool) async {
    var prefix = clang.path;
    if (prefix.endsWith("-clang") || prefix.endsWith("/clang")) {
      prefix = prefix.substring(0, prefix.length - 5);
    } else {
      prefix = new File(clang.path).parent.absolute.path + "/";
    }

    if (tool == "cc") {
      tool = "clang";
    }

    if (tool == "c++") {
      tool = "clang++";
    }

    return "${prefix}${tool}";
  }

  @override
  Future<String> getToolchainBase() async {
    return new File(clang.path).parent.absolute.path;
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
    var machine = await clang.getTargetMachine();
    if (isTargetX86_32Bit(target)) {
      machine = machine.replaceAll("x86_64", "i386");
    }
    return machine;
  }
}

class ClangToolchainProvider extends ToolchainProvider {
  static final String defaultClangPath = findExecutableSync("clang");

  final String path;

  ClangToolchainProvider(this.path);

  @override
  Future<String> getProviderId() async => "clang";

  @override
  Future<Toolchain> getToolchain(String target, StorageContainer config) async {
    var clang = new ClangHelper(path);

    return new ClangToolchain(target, clang);
  }

  @override
  Future<bool> isTargetSupported(String target, StorageContainer config) async {
    if (path == null) {
      return false;
    }

    var clang = new ClangHelper(path);
    var targets = await clang.getTargetNames();

    return targets.contains(target);
  }

  @override
  Future<List<String>> listBasicTargets() async {
    if (path == null) {
      return const <String>[];
    }

    var clang = new ClangHelper(path);
    var targets = await clang.getTargetNames(basic: true);
    return targets;
  }

  @override
  Future<String> getProviderDescription() async {
    return "Clang (${path})";
  }
}
