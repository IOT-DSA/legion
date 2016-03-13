import "package:legion/crosstool.dart";
import "package:legion/cmake.dart";
import "package:legion/clang.dart";
import "package:legion/utils.dart";

import "package:legit/io.dart";

import "dart:io";

final String LOCAL = "${getLocalOperatingSystem()}-${getLocalArch()}";

main(List<String> args) async {
  var hasError = false;
  var toolchainConfig = await getTargetConfig();
  var legionConfig = await readJsonFile("legion.json", defaultValue: {});
  var crosstool = new CrossTool();
  var legionDir = new Directory("legion");
  var state = {};

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
    File toolchainCMakeFile = new File("legion/.toolchains/${targetName}.cmake");
    TargetConfig config = new TargetConfig(targetName);

    writeToolchainFile(String content) async {
      if (await toolchainCMakeFile.exists()) {
        await toolchainCMakeFile.delete();
      }

      await toolchainCMakeFile.create(recursive: true);
      await toolchainCMakeFile.writeAsString(content);
    }

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

      await writeToolchainFile(
        generateNormalCMakeToolchain(
          system,
          targetName,
          "${prefix}${gnu}cc",
          "${prefix}${gnu}c++"
        )
      );
    } else if (targetName == LOCAL &&
      !getBooleanSetting("ignore.local", legionConfig)) {
      var localToolchainPath = Platform.environment["LEGION_LOCAL_TOOLCHAIN"];

      if (localToolchainPath == null) {
        localToolchainPath = "/usr";
      }

      await writeToolchainFile(
        generateNormalCMakeToolchain(
          null,
          targetName,
          "${localToolchainPath}/bin/gcc",
          "${localToolchainPath}/bin/g++"
        )
      );
    } else {
      var tryClang = await isClangInstalled();

      if (getBooleanSetting("ignore.clang", legionConfig)) {
        tryClang = false;
      }

      if (legionConfig["clang"] == false) {
        tryClang = false;
      }

      if (tryClang && clangTargetMap.containsKey(targetName)) {
        await writeToolchainFile(generateClangCMakeToolchain(
          null,
          targetName
        ));
      } else {
        String sampleName = targetName;
        if (CROSSTOOL_TARGET_MAP.containsKey(targetName)) {
          sampleName = CROSSTOOL_TARGET_MAP[targetName];
        }

        await crosstool.bootstrap();
        var samples = await crosstool.listSamples();

        if (samples.contains(sampleName)) {
          var prefix = await crosstool.getToolchain(sampleName, install: true);
          await writeToolchainFile(generateNormalCMakeToolchain(
            null,
            targetName,
            "${prefix}cc",
            "${prefix}c++"
          ));
        } else {
          reportStatusMessage("Skipping build for ${targetName}");
          targetsToGenerate.remove(targetName);
          continue;
        }
      }
    }

    config.toolchainFilePath = toolchainCMakeFile.path;

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

    var result = await executeCommand(
      "cmake",
      args: config.generateArguments(cmakeArgs),
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

  await writeJsonFile("legion/.state", state);

  if (hasError) {
    exit(1);
  }
}
