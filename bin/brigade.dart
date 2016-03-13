import "package:legion/crosstool.dart";
import "package:legion/utils.dart";

import "package:legit/io.dart";

import "dart:io";

final String LOCAL = "${getLocalOperatingSystem()}-${getLocalArch()}";

main(List<String> args) async {
  var toolchainConfig = await getTargetConfig();
  var config = await readJsonFile("legion.json");
  var crosstool = new CrossTool();

  List targets = config["targets"];

  if (targets == null) {
    targets = [];
  }

  targets.addAll(args);

  Map toolchainStandard = {
    "${LOCAL}": "/usr/bin"
  };

  Map toolchains = {};

  for (String name in targets) {
    if (toolchainConfig.containsKey(name)) {
      toolchains[name] = toolchainConfig[name];
    } else if (toolchainStandard.containsKey(name)) {
      toolchains[name] = toolchainStandard[name];
    } else {
      if (CROSSTOOL_TARGET_MAP.containsKey(name)) {
        name = CROSSTOOL_TARGET_MAP[name];
      }

      await crosstool.bootstrap();
      var samples = await crosstool.listSamples();

      if (samples.contains(name)) {
        toolchains[name] = await crosstool.getToolchain(name, install: true);
      } else {
        reportStatusMessage("Skipping build for ${name}");
      }
    }
  }

  for (String name in toolchains.keys) {
    reportStatusMessage("Generating build for ${name}");

    var toolchain = toolchains[name];
    var dir = new Directory("legion/${name}");

    if (await dir.exists()) {
      await dir.create(recursive: true);
    }
    await dir.create(recursive: true);

    var extraArgs = config["args"];
    var cmakeArgs = extraArgs == null ? [] : extraArgs["cmake"];

    var result = await executeCommand(
      "cmake",
      args: []..addAll(cmakeArgs)..add("../.."),
      workingDirectory: dir.path,
      environment: {
        "CMAKE_C_COMPILER": "${toolchain}/bin/cc",
        "CMAKE_CXX_COMPILER": "${toolchain}/bin/c++"
      },
      writeToBuffer: true
    );

    if (result.exitCode != 0) {
      reportErrorMessage("CMake Failed\n${result.output}");
    }
  }
}
