import "dart:async";
import "dart:io";

import "package:legion/builder.dart";
import "package:legion/utils.dart";

main(List<String> args) async {
  // Protect print statements from clobbering for evaluation
  return await Zone.current.fork(specification: new ZoneSpecification(
    print: (Zone self, ZoneDelegate parent, Zone zone, String line) {
      stderr.writeln(line);
    }
  )).run(() async {
    return await _main(args);
  });
}

_main(List<String> args) async {
  if (args.length != 1) {
    print("Usage: foxhole <target>");
    exitCode = 1;
    return;
  }

  var targetName = args[0];

  try {
    var toolchain = await resolveToolchain(targetName);
    if (toolchain != null) {
      var cc = await toolchain.getToolPath("cc");
      var cxx = await toolchain.getToolPath("c++");
      var as = await toolchain.getToolPath("as");
      var ld = await toolchain.getToolPath("ld");
      var ar = await toolchain.getToolPath("ar");
      var sys = await toolchain.getSystemName();
      var base = await toolchain.getToolchainBase();

      print("AS=${escapeShellArgument(as)}");
      print("CC=${escapeShellArgument(cc)}");
      print("CXX=${escapeShellArgument(cxx)}");
      print("LD=${escapeShellArgument(ld)}");
      print("AR=${escapeShellArgument(ar)}");

      var env = await toolchain.getEnvironmentVariables();

      for (var key in env.keys) {
        if (env[key].isNotEmpty) {
          print("${key}=${escapeShellArgumentList(env[key])}");
        }
      }

      print("SYSNAME=${escapeShellArgument(sys)}");
      print("TOOLCHAIN_PREFIX=${escapeShellArgument(base)}");
    } else {
      reportErrorMessage("Unknown target ${targetName}");
      exitCode = 1;
      return;
    }
  } on LegionError catch (e) {
    reportErrorMessage(e.toString());
    exitCode = 1;
    return;
  }
}
