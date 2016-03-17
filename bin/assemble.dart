import "dart:io";

import "package:legion/utils.dart";

import "package:path/path.dart" as pathlib;

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
  var distConfig = state["dists"];
  Map<String, String> dists = {};

  if (distConfig is List) {
    for (var e in distConfig) {
      dists[e.toString()] = "{TARGET}-${e.toString()}";
    }
  } else if (distConfig is Map) {
    dists = distConfig;
  }

  if (targets == null) {
    reportErrorMessage("No distributions configured");
    exit(1);
  }

  var distDir = new Directory("dists");
  if (await distDir.exists()) {
    await distDir.create(recursive: true);
  }

  for (String target in targets) {
    reportStatusMessage("Assembling target ${target}");

    for (var source in dists.keys) {
      var file = new File(pathlib.join("legion", target, source));
      var targetBase = dists[source];
      targetBase = targetBase.replaceAll("{TARGET}", target);
      targetBase = targetBase.replaceAll(
        "{TARGET_UNDERSCORE}",
        target.replaceAll("-", "_")
      );
      var targetPath = pathlib.join("dists", targetBase);
      var targetFile = new File(targetPath);
      if (await file.exists()) {
        if (await targetFile.exists()) {
          await targetFile.delete(recursive: true);
        }
        await targetFile.parent.create(recursive: true);
        await file.copy(targetPath);
      } else {
        reportWarningMessage(
          "Distributable '${source}' not found for target ${target}"
        );
      }
    }

    reportStatusMessage("Assembled target ${target}");
  }
}
