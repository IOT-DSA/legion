library legion.cmake;

import "clang.dart";

const String _templateCMakeToolchainClang = r"""
set(CMAKE_SYSTEM_NAME {SYS})

set(triple {TRIPLE})

set(CMAKE_C_COMPILER clang)
set(CMAKE_C_COMPILER_TARGET ${triple})
set(CMAKE_CXX_COMPILER clang++)
set(CMAKE_CXX_COMPILER_TARGET ${triple})
set(CMAKE_AR ar)
""";

const String _templateCMakeToolchainNormal = r"""
set(CMAKE_SYSTEM_NAME {SYS})

set(CMAKE_C_COMPILER {CC})
set(CMAKE_CXX_COMPILER {CXX})

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
""";

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

String generateClangCMakeToolchain(String system, String target) {
  if (system == null) {
    system = getCMakeSystemName(target);
  }

  var out = _templateCMakeToolchainClang;

  if (clangTargetMap.containsKey(target)) {
    target = clangTargetMap[target];
  }

  out = out.replaceAll("{SYS}", system);
  out = out.replaceAll("{TRIPLE}", target);

  return out;
}

String generateNormalCMakeToolchain(
  String system,
  String target,
  String cc,
  String cpp) {
  if (system == null) {
    system = getCMakeSystemName(target);
  }

  var out = _templateCMakeToolchainNormal;

  out = out.replaceAll("{SYS}", system);
  out = out.replaceAll("{CC}", cc);
  out = out.replaceAll("{CXX}", cpp);

  return out;
}

class TargetConfig {
  final String targetName;

  String toolchainFilePath;
  Map<String, dynamic> defs = <String, dynamic>{};

  TargetConfig(this.targetName);

  void define(String key, value) {
    defs[key] = value;
  }

  List<String> generateArguments([List<String> post]) {
    if (post == null) {
      post = <String>[];
    }

    if (toolchainFilePath != null) {
      defs["CMAKE_TOOLCHAIN_FILE"] = toolchainFilePath;
    }

    var args = <String>[];

    for (String key in defs.keys) {
      args.add("-D${key}=${defs[key]}");
    }

    args.addAll(post);

    return args;
  }
}
