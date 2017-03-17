library legion.tool.plugin_loader;

import "dart:async";
import "dart:io";

//import "file://C:/tmp/__legion.plugins.dart" deferred as _WindowsPlugins;
//import "file:///tmp/__legion.plugins.dart" deferred as _UnixPlugins;
//
//const String _legionUnixPluginsPath = "/tmp/__legion.plugins.dart";
//const String _legionWindowsPluginsPath = "C:\\tmp\__legion.plugins.dart";

Future writePluginStub(String content) async {
//  var file = new File(
//    Platform.isWindows ?
//    _legionWindowsPluginsPath :
//    _legionUnixPluginsPath
//  );
//
//  if (!(await file.parent.exists())) {
//    await file.parent.create(recursive: true);
//  }
//
//  await file.writeAsString(content.trimLeft());
}

Future attemptToLoadPluginStub() async {
//  var file = new File(
//    Platform.isWindows ?
//    _legionWindowsPluginsPath :
//    _legionUnixPluginsPath
//  );
//
//  if (!(await file.exists())) {
//    return;
//  }
//
//  if (Platform.isWindows) {
//    await _WindowsPlugins.loadLibrary();
//    await _WindowsPlugins.init();
//  } else {
//    await _UnixPlugins.loadLibrary();
//    await _UnixPlugins.init();
//  }
}
