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
