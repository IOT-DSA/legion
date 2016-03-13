library legion.utils;

import "dart:async";
import "dart:io";
import "dart:convert";

import "package:dye/dye.dart";
import "package:ansicolor/ansicolor.dart" as ANSI;

import "package:path/path.dart" as pathlib;
import "package:system_info/system_info.dart";

const Map<String, String> _ARCHITECTURE_MAP = const {
  "x86_64": "x64",
  "i386": "x86",
  "i686": "x86"
};

class Icon {
  static const String NAV_ARROW = "\u27A4";
  static const String WARNING_SIGN = "\u26A0";
  static const String NIB = "\u2712";
}

String getHomeDirectory() {
  if (Platform.isWindows) {
    return Platform.environment["USERPROFILE"];
  } else {
    return Platform.environment["HOME"];
  }
}

String getLegionHome() {
  if (Platform.environment["LEGION_HOME"] is String) {
    return Platform.environment["LEGION_HOME"];
  } else {
    return pathlib.join(getHomeDirectory(), ".legion");
  }
}

String getToolchainHome() {
  return pathlib.join(getLegionHome(), "toolchains");
}

Directory getLegionHomeSubDir(String path) {
  return new Directory(pathlib.join(getLegionHome(), path));
}

File getLegionHomeFile(String path) {
  return new File(pathlib.join(getLegionHome(), path));
}

reportStatusMessage(String message) {
  print(
    "${'  ' * GlobalState.currentStatusLevel}${_boldCyan(Icon.NIB)}"
      "  ${_boldWhite(message)}"
  );
}

reportErrorMessage(String message) {
  print("${red(Icon.WARNING_SIGN)}  ${_boldWhite(message.trim())}");
}

class GlobalState {
  static int currentStatusLevel = 0;
}

_boldWhite(String message) {
  return (new ANSI.AnsiPen()..white(bold: true))(message);
}

_boldCyan(String message) {
  return (new ANSI.AnsiPen()..cyan(bold: true))(message);
}

Future<Map<String, String>> getTargetConfig() async {
  var file = getLegionHomeFile("toolchains.json");

  if (await file.exists()) {
    var content = await file.readAsString();

    return JSON.decode(content);
  } else {
    await file.create(recursive: true);
    await file.writeAsString("{}\n");
    return {};
  }
}

Future<dynamic> readJsonFile(String path) async {
  path = path.replaceAll("{LEGION}", getLegionHome());

  var file = new File(path);

  if (await file.exists()) {
    return JSON.decode(await file.readAsString());
  } else {
    return {};
  }
}

String getLocalArch() {
  var arch = SysInfo.kernelArchitecture;

  if (_ARCHITECTURE_MAP[arch] is String) {
    arch = _ARCHITECTURE_MAP[arch];
  }

  return arch;
}

String getLocalOperatingSystem() {
  var os = Platform.operatingSystem;

  if (os == "macos") {
    return "mac";
  }

  return os;
}
