part of legion.builder;

Future<List<ToolchainProvider>> loadCustomToolchains() async {
  Map<String, Map<String, dynamic>> json = await readJsonFile(
    getLegionHomeFile("toolchains.json").path,
    defaultValue: {}
  );

  var providers = <ToolchainProvider>[];

  for (var toolchainName in json.keys) {
    var m = json[toolchainName];
    if (m is! Map) continue;

    var type = m["type"];
    var path = m["path"];

    ToolchainProvider provider;

    if (type == "gcc") {
      provider = new Gcc.GccToolchainProvider(path);
    } else if (type == "clang") {
      provider = new Clang.ClangToolchainProvider(path);
    } else {
      throw new LegionError("Unknown custom toolchain type '${type}' for ${toolchainName}");
    }

    providers.add(provider);
  }

  return providers;
}
