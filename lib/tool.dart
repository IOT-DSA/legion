library legion.tool;

import "dart:async";

import "package:legion/utils.dart";
import "package:legion/src/tool/plugin_loader.dart" as PluginLoader;

import "package:path/path.dart" as pathlib;

export "package:legion/api.dart";
export "package:legion/builder.dart";
export "package:legion/utils.dart";

bool _hasLoadedPlugins = false;

Future loadPlugins() async {
  if (_hasLoadedPlugins) {
    return;
  }

  _hasLoadedPlugins = true;

  var pluginFilesList = await readGlobalConfigSetting("plugins", <String>[]);

  if (pluginFilesList is! List) {
    return;
  }

  var ctx = new pathlib.Context(current: getLegionHome());
  var fullFilePaths = <String>[];
  for (var element in pluginFilesList) {
    if (element is String) {
      var fullPath = ctx.absolute(element);

      if (!fullFilePaths.contains(fullPath)) {
        fullFilePaths.add(fullPath);
      }
    }
  }

  var stub = new StringBuffer();

  var idx = 1;
  for (var path in fullFilePaths) {
    stub.writeln('import "${path}" as __${idx};');
    idx++;
  }

  stub.writeln();
  stub.writeln("init() async {");

  for (idx = 1; idx <= fullFilePaths.length; idx++) {
    stub.writeln('  await __${idx}.init();');
  }
  stub.writeln("}");

  await PluginLoader.writePluginStub(stub.toString());
  await PluginLoader.attemptTotLoadPluginStub();
}
