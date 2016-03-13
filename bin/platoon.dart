import "dart:io";

import "package:legit/io.dart";
import "package:legion/utils.dart";

main(List<String> args) async {
  Directory dir = new Directory("legion");
  List<String> targets = await readJsonFile(
    ".targets",
    inside: dir,
    defaultValue: null
  );

  if (targets == null) {
    reportErrorMessage("No targets have been generated");
    exit(1);
  }

  var command = "/usr/bin/make";

  if (args.isNotEmpty) {
    command += " ";
    command += args.join(" ");
  }

  var scriptArgs = ["-qfc", command, "/dev/null"];

  if (Platform.isMacOS) {
    scriptArgs = ["-q", "/dev/null", "make"]..addAll(args);
  }

  for (String target in targets) {
    var result = await executeCommand(
      "script",
      args: scriptArgs,
      inherit: true,
      workingDirectory: resolveWorkingPath(target, from: dir)
    );

    if (result.exitCode != 0) {
      exit(result.exitCode);
    }
  }
}
