import "package:legion/builder.dart";
import "package:legion/api.dart";
import "package:legion/utils.dart";

main(List<String> args) async {
  try {
    var toolchainProviderList =
      new List<ToolchainProvider>.from(toolchainProviders);

    toolchainProviderList.addAll(await loadCustomToolchains());

    reportStatusMessage("Supported Builders");
    for (var provider in builderProviders) {
      var name = await provider.getProviderName();
      GlobalState.currentStatusLevel++;
      reportStatusMessage("${name}");
      GlobalState.currentStatusLevel--;
    }

    reportStatusMessage("Supported Toolchains");

    for (var provider in toolchainProviderList) {
      GlobalState.currentStatusLevel++;
      var name = await provider.getProviderDescription();
      var targets = await provider.listBasicTargets();
      if (targets.isEmpty) {
        reportStatusMessage("${name} (No Targets Available)");
      } else {
        reportStatusMessage("${name}");
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
