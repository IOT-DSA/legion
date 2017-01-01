import "dart:io";

import "package:legion/api.dart";
import "package:legion/builder.dart";

main(List<String> args) async {
  var targets = args.takeWhile((arg) => arg != "--").toList();
  var extraArguments = args.skip(targets.length).toList();

  if (extraArguments.length >= 1 && extraArguments.first == "--") {
    extraArguments = extraArguments.skip(1).toList();
  }

  var project = new Project(Directory.current);
  await project.init();

  if (targets.isEmpty) {
    targets.addAll(await project.getStringListSetting("defaultTargets"));
  }

  var executions = [
    new BuildStageExecution(
      BuildStage.build,
      targets,
      extraArguments
    )
  ];

  await executeBuildStages(
    Directory.current,
    executions
  );
}
