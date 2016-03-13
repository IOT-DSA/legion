import "package:legion/crosstool.dart";
import "package:legion/cmake.dart";
import "package:legion/clang.dart";
import "package:legion/utils.dart";

import "package:legit/io.dart";

import "dart:io";

final String LOCAL = "${getLocalOperatingSystem()}-${getLocalArch()}";

main(List<String> args) async {
  var toolchainConfig = await getTargetConfig();
  var legionConfig = await readJsonFile("legion.json", defaultValue: {});
  var crosstool = new CrossTool();
  var legionDir = new Directory("legion");

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

      var system = toolchainDef["system"];
      var path = toolchainDef["path"];

      if (toolchainDef["defs"] is Map) {
        config.defs.addAll(toolchainDef["defs"]);
      }

      await writeToolchainFile(
        generateNormalCMakeToolchain(system, targetName, path)
      );
    } else if (targetName == LOCAL) {
      var localToolchainPath = Platform.environment["LEGION_LOCAL_TOOLCHAIN"];

      if (localToolchainPath == null) {
        localToolchainPath = "/usr";
      }

      await writeToolchainFile(
        generateNormalCMakeToolchain(null, targetName, localToolchainPath)
      );
    } else {
      var tryClang = await isClangInstalled();

      if (Platform.environment["LEGION_IGNORE_CLANG"] == "true") {
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

  for (TargetConfig config in configs) {
    reportStatusMessage("Generating build for ${config.targetName}");

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

    var inherit = Platform.environment["LEGION_VERBOSE"] == "true";

    if (legionConfig["verbose"] == true) {
      inherit = true;
    }

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
    }
  }

  await writeJsonFile("legion/.targets", targetsToGenerate);
}
