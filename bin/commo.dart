import "package:legion/builder.dart";
import "package:legion/utils.dart";

main(List<String> args) async {
  reportStatusMessage("Supported Builders");
  for (var provider in builderProviders) {
    var name = await provider.getProviderName();
    GlobalState.currentStatusLevel++;
    reportStatusMessage("${name}");
    GlobalState.currentStatusLevel--;
  }

  reportStatusMessage("Supported Toolchains");

  for (var provider in toolchainProviders) {
    GlobalState.currentStatusLevel++;
    var name = await provider.getProviderName();
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
}
