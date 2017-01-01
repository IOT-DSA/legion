import "brigade.dart" as Brigade;
import "platoon.dart" as Platoon;
import "assemble.dart" as Assemble;

import "dart:io";

import "package:legion/utils.dart";

main(List<String> args) async {
  if (args.isEmpty) {
    print("Usage: legion <command> [args]");
    exit(0);
  }

  String cmd = args[0];
  List<String> argv = args.skip(1).toList();

  if (cmd == "brigade" || cmd == "generate") {
    return await Brigade.main(argv);
  } else if (cmd == "platoon" || cmd == "build" || cmd == "make") {
    return await Platoon.main(argv);
  } else if (cmd == "assemble" || cmd == "dist") {
    return await Assemble.main(argv);
  } else if (cmd == "quick" || cmd == "qbuild" || cmd == "war") {
    await Brigade.main(argv);

    if (GlobalState.hasError) {
      return null;
    }

    var platoonArgString = Platform.environment["LEGION_BUILD_ARGS"];
    var platoonArgs = <String>[];

    if (platoonArgString is String) {
      platoonArgs.addAll(platoonArgString.split(" "));
    }

    await Platoon.main(platoonArgs);
  } else {
    print("Unknown Command: ${cmd}");
    exit(1);
  }
}
