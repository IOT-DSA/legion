import "package:legion/crosstool.dart";
import "package:legion/cmake.dart";
import "package:legion/clang.dart";
import "package:legion/utils.dart";

import "package:legit/io.dart";

import "dart:io";

final String LOCAL = "${getLocalOperatingSystem()}-${getLocalArch()}";
final String LOCAL_32BIT = "${getLocalOperatingSystem()}-x86";

main(List<String> args) async {
  var hasError = false;
  var toolchainConfig = await getTargetConfig();
  var legionConfig = await readJsonFile("legion.json", defaultValue: {});
  var crosstool = new CrossTool();
  var legionDir = new Directory("legion");
  var state = {
    "cmake": {}
  };

  if (await legionDir.exists()) {
    await legionDir.delete(recursive: true);
  }

  await legionDir.create(recursive: true);

  List targetsToGenerate = legionConfig["targets"];

  if (targetsToGenerate == null) {
    targetsToGenerate = [];
  }

  targetsToGenerate.addAll(args);

  List<TargetConfig> configs = <TargetConfig>[];

  for (String targetName in targetsToGenerate.toList()) {
    TargetConfig config = new TargetConfig(targetName);

    if (toolchainConfig.containsKey(targetName)) {
      var toolchainDef = toolchainConfig[targetName];

      String system = toolchainDef["system"];
      String prefix = toolchainDef["prefix"];

      if (prefix == null) {
        prefix = "/usr/bin";
      }

      if (toolchainDef["defs"] is Map) {
        config.defs.addAll(toolchainDef["defs"]);
      }

      if (!prefix.endsWith("-") && !prefix.endsWith("/")) {
        prefix += "/";
      }

      String gnu = "g";

      if (toolchainDef["gnu"] == false) {
        gnu = "";
      }

      config.addToolchainDefs(
        generateNormalCMakeToolchain(
          system,
          targetName,
          "${prefix}${gnu}cc",
          "${prefix}${gnu}c++"
        )
      );
    } else if ((
      targetName == LOCAL ||
        (targetName == LOCAL_32BIT && LOCAL.endsWith("-x64"))
    ) && !getBooleanSetting("ignore.local", legionConfig)) {
      var localToolchainPath = Platform.environment["LEGION_LOCAL_TOOLCHAIN"];

      if (localToolchainPath == null) {
        localToolchainPath = "/usr";
      }

      config.addToolchainDefs(generateNormalCMakeToolchain(
        null,
        targetName,
        "${localToolchainPath}/bin/gcc",
        "${localToolchainPath}/bin/g++"
      ));

      if (targetName == LOCAL_32BIT) {
        config.defs.addAll({
          "CMAKE_C_FLAGS": "-m32",
          "CMAKE_CXX_FLAGS": "-m32"
        });
      }
    } else {
      var tryClang = await isClangInstalled();

      if (getBooleanSetting("ignore.clang", legionConfig)) {
        tryClang = false;
      }

      if (legionConfig["clang"] == false) {
        tryClang = false;
      }

      if (tryClang && clangTargetMap.containsKey(targetName)) {
        config.addToolchainDefs(generateClangCMakeToolchain(
          null,
          targetName
        ));
      } else {
        String sampleName = targetName;
        if (crosstoolTargetMap.containsKey(targetName)) {
          sampleName = crosstoolTargetMap[targetName];
        }

        if (sampleName.endsWith("--x86")) {
          sampleName = sampleName.substring(0, sampleName.length - 5);
        }

        await crosstool.bootstrap();
        var samples = await crosstool.listSamples();

        if (samples.contains(sampleName)) {
          var prefix = await crosstool.getToolchain(sampleName, install: true);
          config.addToolchainDefs(generateNormalCMakeToolchain(
            null,
            targetName,
            "${prefix}cc",
            "${prefix}c++"
          ));

          if (sampleName == "arm-unknown-linux-gnueabi") {
            config.defs["TOOLCHAIN_DYNAMIC_LINK_ENABLE"] = "OFF";
          }

          if (getBooleanSetting("link.static", legionConfig)) {
            config.defineOrAppend("CMAKE_EXE_LINKER_FLAGS", "-static");
          }

          if (getBooleanSetting("toolchain.force.x86")) {
            config.defineOrAppend("CMAKE_C_FLAGS", "-m32");
            config.defineOrAppend("CMAKE_CXX_FLAGS", "-m32");
            config.defineOrAppend("CMAKE_EXE_LINKER_FLAGS", "-m32");
          }
        } else {
          reportStatusMessage("Skipping build for ${targetName}");
          targetsToGenerate.remove(targetName);
          continue;
        }
      }
    }

    await config.configure();

    configs.add(config);
  }

  String generatorName = legionConfig["generator"];

  if (generatorName == null) {
    generatorName = "Unix Makefiles";
  }

  for (TargetConfig config in configs) {
    reportStatusMessage("Generating target ${config.targetName}");

    var dir = new Directory("legion/${config.targetName}");

    if (await dir.exists()) {
      await dir.create(recursive: true);
    }
    await dir.create(recursive: true);

    var extraArgs = legionConfig["args"];
    List<String> cmakeArgs = extraArgs == null ? [] : extraArgs["cmake"];

    if (Platform.environment["LEGION_CMAKE_ARGS"] is String) {
      cmakeArgs.addAll(Platform.environment["LEGION_CMAKE_ARGS"].split(" "));
    }

    cmakeArgs.add("../..");

    var inherit = getBooleanSetting("brigade.verbose", legionConfig);

    if (legionConfig["verbose"] == true) {
      inherit = true;
    }

    cmakeArgs.addAll(["-G", generatorName]);

    cmakeArgs = config.generateArguments(cmakeArgs);

    state["cmake"][config.targetName] = {
      "args": cmakeArgs
    };

    var result = await executeCommand(
      "cmake",
      args: cmakeArgs,
      workingDirectory: dir.path,
      writeToBuffer: true,
      inherit: inherit
    );

    if (result.exitCode != 0) {
      reportErrorMessage(
        "CMake Failed for target"
        " ${config.targetName}\n${result.output}");
      hasError = true;
      targetsToGenerate.remove(config.targetName);
    } else {
      reportStatusMessage("Generated target ${config.targetName}");
    }
  }

  state.addAll({
    "targets": targetsToGenerate,
    "generator": generatorName
  });

  if (legionConfig["dists"] != null) {
    state["dists"] = legionConfig["dists"];
  }

  await writeJsonFile("legion/.state", state);

  if (hasError) {
    exit(1);
  }
}
