library legion.clang;

import "dart:async";

import "utils.dart";

const Map<String, String> clangTargetMap = const {
  "linux-x64": "x86_64-linux-eabi",
  "linux-x86": "x86-linux-eabi",
  "linux-arm": "arm-linux-eabi",
  "linux-armv7a": "armv7a-linux-eabi",
  "linux-armv7m": "armv7m-linux-aebi",
  "mac-x64": "x86_64-apple-darwin-eabi",
  "mac-x86": "x86-apple-darwin-eabi"
};

Future<bool> isClangInstalled() async {
  return (await findExecutable("clang")) != null;
}
