library legion.crosstool;

import "dart:async";
import "dart:io";

import "utils.dart";

import "package:legit/legit.dart";
import "package:legit/io.dart";
import "package:path/path.dart" as pathlib;

const String _GIT_URL = "https://github.com/crosstool-ng/crosstool-ng.git";

const Map<String, String> CROSSTOOL_TARGET_MAP = const {
  "linux-x64": "x86_64-unknown-linux-gnu",
  "windows-x64": "x86_64-w64-mingw32",
  "linux-arm": "arm-unknown-eabi",
  "linux-arm-rpi1": "armv6-rpi-linux-gnueabi",
  "linux-arm-rpi2": "armv7-rpi2-linux-gnueabihf",
  "linux-arm-rpi3": "armv8-rpi3-linux-gnueabihf",
  "linux-aarch64-rpi3": "aarch64-rpi3-linux-gnueabi",
  "linux-powerpc": "powerpc-unknown-linux-gnu"
};

class CrossTool {
  CrossTool();

  bootstrap({bool force: false}) async {
    if (!force) {
      if (await getLegionHomeFile(
        pathlib.join("crosstool-install", "bin", "ct-ng")
      ).exists()) {
        return;
      }
    }

    reportStatusMessage("Updating CrossTool Source");

    var dir = _getGitDir();

    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }

    var git = new GitClient.forDirectory(dir);

    if (!(await git.isRepository())) {
      await git.clone(_GIT_URL);
    }

    reportStatusMessage("Bootstrapping CrossTool");

    var result = await executeCommand(
      "bash",
      args: ["bootstrap"],
      workingDirectory: dir.path,
      writeToBuffer: true
    );

    if (result.exitCode != 0) {
      reportErrorMessage("Failed to bootstrap CrossTool:\n${result.output}".trim());
      exit(1);
    }

    reportStatusMessage("Configuring CrossTool");

    result = await executeCommand(
      "bash",
      args: ["configure", "--prefix", _getInstallDir().path],
      workingDirectory: dir.path,
      writeToBuffer: true
    );

    if (result.exitCode != 0) {
      reportErrorMessage("Failed to configure CrossTool:\n${result.output}");
      exit(1);
    }

    reportStatusMessage("Making CrossTool");

    result = await executeCommand(
      "make",
      args: ["install"],
      workingDirectory: dir.path,
      writeToBuffer: true
    );

    if (result.exitCode != 0) {
      reportErrorMessage("Failed to make CrossTool:\n${result.output}");
      exit(1);
    }
  }

  Directory _getGitDir() {
    if (_gitDir == null) {
      _gitDir = getLegionHomeSubDir("crosstool-git").absolute;
    }
    return _gitDir;
  }

  Directory _getInstallDir() {
    if (_installDir == null) {
      _installDir = getLegionHomeSubDir("crosstool-install").absolute;
      if (!_installDir.existsSync()) {
        _installDir.createSync(recursive: true);
      }
    }

    return _installDir;
  }

  Directory _getWorkingDir() {
    if (_workingDir == null) {
      _workingDir = getLegionHomeSubDir("crosstool-work").absolute;
      if (!_workingDir.existsSync()) {
        _workingDir.createSync(recursive: true);
      }
    }

    return _workingDir;
  }

  Directory _gitDir;
  Directory _installDir;
  Directory _workingDir;

  Future<BetterProcessResult > _run(List<String> args, {
    bool inherit: false,
    Map<String, String> env: const {}
  }) async {
    return await executeCommand(
      pathlib.join(_getInstallDir().path, "bin", "ct-ng"),
      args: args,
      writeToBuffer: true,
      workingDirectory: _getWorkingDir().path,
      environment: env,
      outputHandler: (String out) {
        if (inherit && out.trim().isNotEmpty) {
          stdout.writeln(out);
        }
      }
    );
  }

  Future<List<String>> listSamples() async {
    var result = await _run(["list-samples"]);
    var lines = result.output.split("\n");

    var out = [];

    for (String line in lines) {
      if (!line.startsWith("[")) {
        continue;
      }

      var status = line.substring(1, line.indexOf("]"));
      if (status.contains("B")) {
        continue;
      }

      var name = line.substring(line.indexOf("]") + 2).trim();

      out.add(name);
    }

    return out;
  }

  Future chooseSample(String name) async {
    var result = await _run([name]);

    if (result.exitCode != 0) {
      throw new Exception(
        "Failed to choose sample: ${name}\n${result.output}"
      );
    }

    _lastToolchainSwitch = name;
  }

  Future build({bool inherit: true}) async {
    await changeConfigFile({
      "LOG_PROGRESS_BAR": "n",
      "CT_PREFIX_DIR": pathlib.join(getToolchainHome(), _lastToolchainSwitch),
      "CT_LOCAL_TARBALLS_DIR": pathlib.join(_getWorkingDir().path, "src")
    });

    reportStatusMessage("Building toolchain ${_lastToolchainSwitch}");

    var result = await _run([
      "build"
    ], inherit: inherit);

    if (result.exitCode != 0) {
      reportErrorMessage(
        "Failed to build toolchain ${_lastToolchainSwitch}" +
          (inherit ? "" : ".\n${result.output}")
      );

      exit(1);
    }
  }

  String _lastToolchainSwitch = "unknown";

  Future<String> getToolchain(String name, {bool install: false}) async {
    var dir = new Directory(pathlib.join(getToolchainHome(), name));
    if (await dir.exists()) {
      return pathlib.join(getToolchainHome(), name, "bin", "${name}-");
    } else {
      if (install) {
        await bootstrap();
        await chooseSample(name);
        await build();
        return pathlib.join(getToolchainHome(), name, "bin", "${name}-");
      } else {
        reportErrorMessage("Toolchain ${name} not found");
        exit(1);
        return null;
      }
    }
  }

  Future changeConfigFile(Map<String, dynamic> custom) async {
    var file = new File(pathlib.join(_getWorkingDir().path, ".config"));
    var lines = await file.readAsLines();
    var out = {};
    for (String line in lines) {
      if (line.startsWith("#")) {
        continue;
      }

      if (!line.contains("=")) {
        continue;
      }

      var parts = line.split("=");
      var key = parts[0];
      var value = parts.skip(1).join("=");
      out[key] = value;
    }

    for (var key in custom.keys) {
      var mkey = key;
      if (!key.startsWith("CT_")) {
        key = "CT_${key}";
      }

      out[key] = custom[mkey];
    }

    var wlines = [];
    for (var key in out.keys) {
      wlines.add("${key}=${out[key]}");
    }
    await file.writeAsString(wlines.join("\n"));
  }
}
