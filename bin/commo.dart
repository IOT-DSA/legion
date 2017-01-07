import "package:legion/builder.dart";
import "package:legion/utils.dart";

main(List<String> args) async {
  try {
    var toolchainProviderList = await loadAllToolchains();

    reportStatusMessage("Supported Builders");
    for (var provider in builderProviders) {
      var info = await provider.describe();
      GlobalState.currentStatusLevel++;
      reportStatusMessage("${info.description}");
      GlobalState.currentStatusLevel--;
    }

    reportStatusMessage("Supported Toolchains");

    for (var provider in toolchainProviderList) {
      GlobalState.currentStatusLevel++;
      var info = await provider.describe();
      var targets = await provider.listBasicTargets();
      if (targets.isEmpty) {
        reportStatusMessage("${info.description} (No Targets Available)");
      } else {
        reportStatusMessage("${info.description}");
        for (var target in targets) {
          GlobalState.currentStatusLevel++;
          reportStatusMessage("${target}");
          GlobalState.currentStatusLevel--;
        }
      }
      GlobalState.currentStatusLevel--;
    }
  } on LegionError catch (e) {
    reportErrorMessage(e.toString());
    return;
  }
}
