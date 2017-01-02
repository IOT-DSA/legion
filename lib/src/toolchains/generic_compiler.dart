library legion.toolchains.generic_compiler;

import "dart:async";
import "dart:io";

import "package:legion/api.dart";
import "package:legion/io.dart";
import "package:legion/utils.dart";

class GenericCompilerHelper {
  final String path;

  GenericCompilerHelper(this.path);

  Future<bool> exists() async {
    var file = new File(path);
    return await file.exists();
  }

  Future<String> getVersion() async {
    var result = await executeCommand(path, args: [
      "-dumpversion"
    ], writeToBuffer: true);

    if (result.exitCode != 0) {
      throw new Exception(
        "Failed to get compiler version. "
          "Exited with status ${result.exitCode}.");
    }

    return result.stdout.toString().trim();
  }

  Future<String> getTargetMachine() async {
    var result = await executeCommand(path, args: [
      "-dumpmachine"
    ], writeToBuffer: true);

    if (result.exitCode != 0) {
      throw new Exception(
        "Failed to get compiler target machine. "
          "Exited with status ${result.exitCode}.");
    }

    return result.stdout.toString().trim();
  }

  Future<String> getSystemName() async {
    var machine = await getTargetMachine();

    if (machine.contains("darwin")) {
      return "Darwin";
    } else if (machine.contains("mingw32") || machine.contains("cygwin")) {
      return "Windows";
    } else if (machine.contains("solaris")) {
      return "SunOS";
    } else if (machine.contains("freebsd")) {
      return "FreeBSD";
    } else if (machine.contains("openbsd")) {
      return "OpenBSD";
    } else if (machine.contains("netbsd")) {
      return "NetBSD";
    } else if (machine.contains("hpux")) {
      return "HP-UX";
    } else {
      return "Linux";
    }
  }

  Future<List<String>> getTargetNames({bool basic: false}) async {
    var machine = await getTargetMachine();
    var names = <String>[];

    if (!basic) {
      names.add(machine);
    }

    var arch = machine.split("-").first;
    var sys = (await getSystemName()).toLowerCase();
    var systems = <String>[sys];
    var arches = <String>[arch];

    if (arch == "x86_64") {
      arches.remove("x86_64");
      arches.add("x32");
      arches.add("x64");

      if (!basic) {
        arches.add("x86");
        arches.add("amd64");
      }
    }

    if (arch == "i386" || arch == "i686") {
      arches.remove(arch);
      arches.add("x32");

      if (!basic) {
        arches.add("x86");
      }
    }

    if (sys == "darwin") {
      systems.add("mac");

      if (basic) {
        systems.remove("darwin");
      }
    }

    for (var system in systems) {
      for (var arch in arches) {
        names.add("${system}-${arch}");
      }
    }

    return names;
  }
}

class GenericToolchain extends Toolchain {
  final String target;
  final GenericCompilerHelper compiler;
  final String cc;
  final String cxx;

  GenericToolchain(this.target, this.compiler, this.cc, this.cxx);

  @override
  Future applyToBuilder(Builder builder) async {
  }

  @override
  Future<String> getSystemName() async {
    return await compiler.getSystemName();
  }

  @override
  Future<String> getToolPath(String tool) async {
    var prefix = compiler.path;
    if (prefix.endsWith("-${cc}") || prefix.endsWith("/${cc}")) {
      prefix = prefix.substring(0, prefix.length - cc.length);
    } else {
      prefix = new File(compiler.path).parent.absolute.path + "/";
    }

    if (tool == "cc") {
      tool = cc;
    }

    if (tool == "c++") {
      tool = cxx;
    }

    return "${prefix}${tool}";
  }

  @override
  Future<String> getToolchainBase() async {
    var prefix = compiler.path;
    if (prefix.endsWith("-${cc}") || prefix.endsWith("/${cc}")) {
      prefix = prefix.substring(0, prefix.length - 4);
    } else {
      prefix = new File(compiler.path).parent.absolute.path;
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
    var machine = await compiler.getTargetMachine();
    if (isTargetX86_32Bit(target)) {
      machine = machine.replaceAll("x86_64", "i386");
    }
    return machine;
  }
}
