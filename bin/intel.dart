import "dart:convert";

import "package:args/args.dart";

import "package:legion/tool.dart";

main(List<String> args) async {
  await loadPlugins();

  var argp = new ArgParser();
  argp.addOption("format", abbr: "f", allowed: const <String>[
    "human",
    "json",
    "raw"
  ], defaultsTo: "human");

  var opts = argp.parse(args);

  try {
    var toolchains = await loadAllToolchains();
    var format = opts["format"];

    if (format == "human") {
      await printHumanOutput(toolchains);
    } else if (format == "json") {
      await printJsonOutput(toolchains);
    } else {
      await printRawOutput(toolchains);
    }
  } on LegionError catch (e) {
    reportErrorMessage(e.toString());
    return;
  }
}

printHumanOutput(List<ToolchainProvider> toolchains) async {
  reportStatusMessage("Supported Builders");
  for (var provider in builderProviders) {
    var info = await provider.describe();
    GlobalState.currentStatusLevel++;
    reportStatusMessage("${info.description}");
    GlobalState.currentStatusLevel--;
  }

  reportStatusMessage("Supported Toolchains");

  for (var provider in toolchains) {
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
}

printJsonOutput(List<ToolchainProvider> toolchains) async {
  var json = {
    "builders": {},
    "toolchains": {}
  };

  for (var builder in builderProviders) {
    var info = await builder.describe();
    json["builders"][info.id] = info.encode();
  }

  for (var toolchain in toolchains) {
    var info = await toolchain.describe();
    var data = info.encode();
    data["targets"] = await toolchain.listBasicTargets();
    json["toolchains"][info.id] = data;
  }

  print(JSON.encode(json));
}

printRawOutput(List<ToolchainProvider> toolchains) async {
  for (var builder in builderProviders) {
    var info = await builder.describe();
    print("builder::${info.id}::${info.type}::${info.description}");
  }

  for (var toolchain in toolchains) {
    var info = await toolchain.describe();
    print("toolchain::${info.id}::${info.type}::${info.description}");

    for (var target in await toolchain.listBasicTargets()) {
      print("target::${info.id}::${target}");
    }
  }
}
