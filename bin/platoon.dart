import "dart:io";

import "package:legit/io.dart";
import "package:legion/utils.dart";

main(List<String> args) async {
  Directory dir = new Directory("legion");
  Map<String, dynamic> state = await readJsonFile(
    ".state",
    inside: dir,
    defaultValue: null
  );

  if (state == null) {
    reportErrorMessage("No targets have been generated");
    exit(1);
  }

  List<String> targets = state["targets"];

  if (targets == null) {
    reportErrorMessage("Bad state, targets are missing.");
    exit(1);
  }

  String command = const {
    "Unix Makefiles": "make",
    "Xcode": "xcodebuild",
    "Ninja": "ninja"
  }[state["generator"]];

  if (command == null) {
    command = "make";
  }

  var scriptArgs = [];

  if (Platform.isMacOS) {
    scriptArgs = ["-q", "/dev/null", command]..addAll(args);
  } else {
    if (args.isNotEmpty) {
      command += " ";
      command += args.join(" ");
    }

    scriptArgs = ["-qfc", command, "/dev/null"];
  }

  for (String target in targets) {
    reportStatusMessage("Building target ${target}");

    var result = await executeCommand(
      "script",
      args: scriptArgs,
      inherit: true,
      workingDirectory: resolveWorkingPath(target, from: dir)
    );

    if (result.exitCode != 0) {
      reportErrorMessage("Failed to build target ${target}");
      exit(result.exitCode);
    }

    reportStatusMessage("Built target ${target}");
  }
}
