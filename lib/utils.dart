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
  var lines = message.trim().split("\n");
  var out = "${red(Icon.WARNING_SIGN)}  ";

  int i = 0;
  for (String line in lines) {
    if (i == 0) {
      out += _boldWhite(line);
    } else {
      out += line;
    }
    out += "\n";
    i++;
  }

  print(out.trim());
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

Future<Map<String, Map<String, dynamic>>> getTargetConfig() async {
  var file = getLegionHomeFile("targets.json");

  if (await file.exists()) {
    var content = await file.readAsString();

    return JSON.decode(content);
  } else {
    await file.create(recursive: true);
    await file.writeAsString("{}\n");
    return {};
  }
}

String resolveWorkingPath(String path, {from}) {
  if (from != null) {
    if (from is Directory) {
      from = from.path;
    } else if (from is! String) {
      from = from.toString();
    }
  } else {
    from = Directory.current.path;
  }

  return pathlib.join(from, path);
}

Future<dynamic> readJsonFile(String path, {inside, defaultValue}) async {
  path = path.replaceAll("{LEGION}", getLegionHome());

  if (inside != null) {
    if (inside is Directory) {
      inside = inside.path;
    } else if (inside is! String) {
      inside = inside.toString();
    }

    path = pathlib.join(inside, path);
  }

  var file = new File(path);

  if (await file.exists()) {
    return JSON.decode(await file.readAsString());
  } else {
    return defaultValue;
  }
}

Future writeJsonFile(String path, data) async {
  var file = new File(path);
  if (!(await file.exists())) {
    await file.create(recursive: true);
  }
  await file.writeAsString(const JsonEncoder.withIndent("  ").convert(
    data
  ) + "\n");
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

Future<String> findExecutable(String name) async {
  var paths = Platform.environment["PATH"].split(
    Platform.isWindows ? ";" : ":"
  );
  var tryFiles = [name];

  if (Platform.isWindows) {
    tryFiles.addAll(["${name}.exe", "${name}.bat"]);
  }

  for (var p in paths) {
    if (Platform.environment.containsKey("HOME")) {
      p = p.replaceAll("~/", Platform.environment["HOME"]);
    }

    var dir = new Directory(pathlib.normalize(p));

    if (!(await dir.exists())) {
      continue;
    }

    for (var t in tryFiles) {
      var file = new File("${dir.path}/${t}");

      if (await file.exists()) {
        return file.path;
      }
    }
  }

  return null;
}

bool getBooleanSetting(String name, [config]) {
  var env = "LEGION_" + name.replaceAll(".", "_").toUpperCase();

  if (const [
    "yes",
    "y",
    "1",
    "true",
    "ON",
    "on"
  ].contains(Platform.environment[env])) {
    return true;
  }

  if (config != null && config[name] == true) {
    return true;
  }

  return false;
}
