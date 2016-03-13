import "dart:io";

import "package:legit/io.dart";
import "package:legion/utils.dart";

main(List<String> args) async {
  var dir = new Directory("legion");

  List<Directory> dirs = await dir
    .list()
    .where((entity) => entity is Directory)
    .toList();

  for (Directory sdir in dirs) {
    var result = await executeCommand(
      "make",
      args: args,
      inherit: true,
      workingDirectory: sdir.path
    );

    if (result.exitCode != 0) {
      exit(result.exitCode);
    }
  }
}
