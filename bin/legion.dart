import "brigade.dart" as Brigade;
import "platoon.dart" as Platoon;

import "dart:io";

main(List<String> args) async {
  if (args.isEmpty) {
    print("Usage: legion <command> [args]");
    exit(0);
  }

  String cmd = args[0];
  List<String> argv = args.skip(1).toList();

  if (cmd == "brigade" || cmd == "generate") {
    return await Brigade.main(argv);
  } else if (cmd == "platoon" || cmd == "build") {
    return await Platoon.main(argv);
  } else {
    print("Unknown Command: ${cmd}");
    exit(1);
  }
}
