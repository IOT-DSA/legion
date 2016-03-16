library legion.cmake;

import "dart:async";
import "dart:io";

import "clang.dart";

String getCMakeSystemName(String target) {
  if (target.contains("linux")) {
    return "Linux";
  } else if (target.contains("win32") || target.contains("mingw32")) {
    return "Windows";
  } else if (target.contains("darwin") || target.contains("mac")) {
    return "Darwin";
  } else {
    return "Unknown";
  }
}

Map generateClangCMakeToolchain(String system, String target) {
  if (system == null) {
    system = getCMakeSystemName(target);
  }

  var clangTarget = target;

  if (clangTargetMap.containsKey(target)) {
    clangTarget = clangTargetMap[clangTarget];
  }

  var map = {
    "CMAKE_SYSTEM_NAME": system,
    "CMAKE_C_COMPILER": "clang",
    "CMAKE_CXX_COMPILER": "clang",
    "CMAKE_C_COMPILER_TARGET": clangTarget,
    "CMAKE_CXX_COMPILER_TARGET": clangTarget
  };

  var cflags = [];
  var cxxflags = [];

  addBoth(String flag) {
    cflags.add(flag);
    cxxflags.add(flag);
  }

  if (target.contains("-x86")) {
    addBoth("-m32");
  }

  map["CMAKE_C_FLAGS"] = cflags.join(" ");
  map["CMAKE_CXX_FLAGS"] = cxxflags.join(" ");

  return map;
}

Map generateNormalCMakeToolchain(
  String system,
  String target,
  String cc,
  String cpp) {
  if (system == null) {
    system = getCMakeSystemName(target);
  }

  var map = {
    "CMAKE_SYSTEM_NAME": system,
    "CMAKE_C_COMPILER": cc,
    "CMAKE_CXX_COMPILER": cpp
  };

  return map;
}

class TargetConfig {
  final String targetName;

  String toolchainFilePath;
  Map<String, dynamic> defs = <String, dynamic>{};
  Map<String, List<String>> toolchainDefs = <String, List<String>>{};

  TargetConfig(this.targetName);

  Future configureCMakeTarget() async {
    var file = new File("legion/.toolchains/${targetName}.cmake");

    var out = new StringBuffer();
    for (var key in toolchainDefs.keys) {
      String mval = '"' + toolchainDefs[key].join(" ") + '"';
      out.writeln("set(${key} ${mval})");
    }

    if (await file.exists()) {
      await file.delete();
    }

    await file.create(recursive: true);
    await file.writeAsString(out.toString());

    toolchainFilePath = file.absolute.path;
  }

  void define(String key, value) {
    defs[key] = value;
  }

  Future configure() async {
    await configureCMakeTarget();

    if (toolchainFilePath != null) {
      defs["CMAKE_TOOLCHAIN_FILE"] = toolchainFilePath;
    }
  }

  void addToolchainDefs(Map<String, String> map) {
    for (String key in map.keys) {
      var nval = map[key];
      var val = toolchainDefs[key];

      if (val == null) {
        val = toolchainDefs[key] = [];
      }

      val.add(nval);
    }
  }

  List<String> generateArguments([List<String> post]) {
    if (post == null) {
      post = <String>[];
    }

    var args = <String>[];

    for (String key in defs.keys) {
      args.add("-D${key}=${defs[key]}");
    }

    args.addAll(post);

    return args;
  }
}
