import "package:legion/crosstool.dart";

main() async {
  var crosstool = new CrossTool();

  var toolchain = await crosstool.listSamples();
  print("Got Toolchain: ${toolchain}");
}
