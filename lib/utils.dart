library legion.utils;

import "dart:async";
import "dart:io";
import "dart:convert";

import "package:ansicolor/ansicolor.dart" as ANSI;

import "package:path/path.dart" as pathlib;
import "package:system_info/system_info.dart";

const Map<String, String> _architectures = const {
  "x86_64": "x64",
  "i386": "x86",
  "i686": "x86",
  "amd64": "x64"
};

class LegionError {
  final String message;

  LegionError(this.message);

  @override
  String toString() => message;
}

bool isArchX86_32Bit(String arch) =>
  [arch, _architectures[arch]].any((x) => const ["x86", "x32"].contains(x));

bool isTargetX86_32Bit(String target) =>
    isArchX86_32Bit(target.split("-").last);

class Icon {
  static const String NAV_ARROW = "\u27A4";
  static const String WARNING_SIGN = "\u26A0";
  static const String NIB = "\u2712";
  static const String RIGHTWARDS_ARROWHEAD = "\u27A4";
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

void reportStatusMessage(String message) {
  var msg = "${'  ' * GlobalState.currentStatusLevel}"
            "${_blue(Icon.NAV_ARROW)} ${_magenta(message)}";

  print(msg);
}

void reportErrorMessage(String message) {
  GlobalState.hasError = true;
  exitCode = 1;

  var lines = message.trim().split("\n");
  var out = "${'  ' * GlobalState.currentStatusLevel}"
            "${_boldRed(Icon.NAV_ARROW)} ";

  int i = 0;
  for (String line in lines) {
    if (i == 0) {
      out += _magenta(line);
    } else {
      out += line;
    }
    out += "\n";
    i++;
  }

  print(out.trim());
}

Future executeWithStatusLevel(function()) async {
  GlobalState.currentStatusLevel++;

  try {
    await function();
  } finally {
    GlobalState.currentStatusLevel--;
  }
}

void reportWarningMessage(String message) {
  var lines = message.trim().split("\n");
  var out = "${'  ' * GlobalState.currentStatusLevel}"
            "${_gold(Icon.WARNING_SIGN)} ";

  int i = 0;
  for (String line in lines) {
    if (i == 0) {
      out += _magenta(line);
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
  static bool hasError = false;
}

_magenta(String message) {
  return (new ANSI.AnsiPen()..magenta())(message);
}

_gold(String message) {
  return (new ANSI.AnsiPen()..yellow(bold: true))(message);
}

_boldCyan(String message) {
  return (new ANSI.AnsiPen()..cyan(bold: true))(message);
}

_blue(String message) {
  return (new ANSI.AnsiPen()..blue(bold: true))(message);
}

_boldRed(String message) {
  return (new ANSI.AnsiPen()..red(bold: true))(message);
}

_red(String message) {
  return (new ANSI.AnsiPen()..red())(message);
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

  if (_architectures[arch] is String) {
    arch = _architectures[arch];
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

String findExecutableSync(String name) {
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

    if (!dir.existsSync()) {
      continue;
    }

    for (var t in tryFiles) {
      var file = new File("${dir.path}/${t}");

      if (file.existsSync()) {
        return file.path;
      }
    }
  }

  return null;
}

bool getBooleanEnvSetting(String name) {
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

  return false;
}

List<List<String>> splitExtraArguments(List<String> args) {
  var out = <List<String>>[];

  var list = <String>[];
  for (var arg in args) {
    if (arg == "--") {
      out.add(list);
      list = <String>[];
    } else {
      list.add(arg);
    }
  }

  if (list.isNotEmpty) {
    out.add(list);
  }

  return out;
}

Future<dynamic> makeChoiceByFileExistence(Map<String, dynamic> files, {from}) async {
  for (var key in files.keys) {
    var p = resolveWorkingPath(key, from: from);
    var file = new File(p);

    if (await file.exists()) {
      return files[key];
    }
  }

  return files["_"];
}

final RegExp _shellEscapeNeeded = new RegExp(r"[^A-Za-z0-9_\/:=-]");
final RegExp _shellEscapeDupSingle = new RegExp(r"^(?:'')+");
final RegExp _shellEscapeNonEscaped = new RegExp(r"\\'''");

String escapeShellArgument(String arg) {
  if (_shellEscapeNeeded.hasMatch(arg)) {
    arg = "'" + arg.replaceAll("'", "'\\''") + "'";
    arg = arg
      .replaceAll(_shellEscapeDupSingle, "")
      .replaceAll(_shellEscapeNonEscaped, "\\'");
  }
  return arg;
}

String escapeShellArgumentList(List<String> args) {
  return args.map(escapeShellArgument).join(" ");
}

String escapeShellArguments(String exe, List<String> args) {
  var out = <String>[];

  void escape(String arg) {
    out.add(escapeShellArgument(arg));
  }

  escape(exe);

  for (var arg in args) {
    escape(arg);
  }

  return out.join(" ");
}
