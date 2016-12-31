library legion.builder;

import "dart:async";
import "dart:io";

import "api.dart";
import "utils.dart";

import "src/builders/cmake.dart" as CMake;
import "src/toolchains/crosstool.dart" as CrossTool;
import "src/toolchains/gcc.dart" as Gcc;
import "src/toolchains/clang.dart" as Clang;

part "src/builder/stage.dart";
part "src/builder/cycle.dart";

final List<BuilderProvider> builderProviders = <BuilderProvider>[
  new CMake.CMakeBuilderProvider()
];

final List<ToolchainProvider> toolchainProviders = <ToolchainProvider>[
  new Gcc.GccToolchainProvider(),
  new Clang.ClangToolchainProvider(),
  new CrossTool.CrossToolToolchainProvider()
];

class BuildStageExecution {
  final BuildStage stage;
  final List<String> extraArguments;
  final List<String> targets;

  BuildStageExecution(this.stage, this.targets, this.extraArguments);
}

executeBuildStages(Directory directory, List<BuildStageExecution> executions) async {
  var project = new Project(directory);
  await project.init();

  for (var execution in executions) {
    var cycle = new BuildCycle(
      project,
      execution.stage,
      execution.targets,
      execution.extraArguments
    );

    await cycle.run();
  }
}
