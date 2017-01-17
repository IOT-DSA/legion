library legion.toolchains.osxcross;

import "dart:async";
import "dart:io";

import "package:legit/legit.dart";

import "package:legion/io.dart";
import "package:legion/utils.dart";

import "package:legion/api.dart";

import "clang.dart";

const String _gitUrl = "https://github.com/IOT-DSA/osxcross.git";

class OsxCrossToolchainProvider extends ToolchainProvider {
  @override
  Future<ProviderDescription> describe() async => new ProviderDescription.generic(
    "osxcross",
    "OSXCross"
  );

  _bootstrap({bool force: false}) async {
    if (!force) {
      if (await getLegionHomeFile("osxcross/target/bin/x86_64-apple-darwin12-ld").exists()) {
        return;
      }
    }

    reportStatusMessage("Updating OSXCross Source");

    var dir = _getGitDir();

    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }

    var git = new GitClient.forDirectory(dir);

    if (!(await git.isRepository())) {
      await git.clone(_gitUrl);
    }

    reportStatusMessage("Building OSXCross");

    var result = await executeCommand(
      "bash",
      args: ["build.sh"],
      workingDirectory: dir.path,
      writeToBuffer: true
    );

    if (result.exitCode != 0) {
      throw new LegionError(
        "Failed to bootstrap OSXCross\n${result.output}".trim()
      );
    }
  }

  Directory _getGitDir() {
    if (_gitDir == null) {
      _gitDir = getLegionHomeSubDir("osxcross").absolute;
    }
    return _gitDir;
  }

  Directory _gitDir;

  @override
  Future<Toolchain> getToolchain(String target, Configuration config) async {
    await _bootstrap();
    var path = "${_getGitDir().path}/target/bin/x86_64-apple-darwin12-clang";
    var helper = new ClangTool(path);

    return new ClangToolchain(target, helper);
  }

  @override
  Future<bool> isTargetSupported(String target, Configuration config) async {
    return (await listFriendlyTargets()).contains(target);
  }

  @override
  Future<List<String>> listFriendlyTargets() async {
    return <String>[
      "mac-x86",
      "mac-x64"
    ];
  }

  @override
  Future<List<String>> listSupportedTargets() async {
    return await listFriendlyTargets();
  }
}
