part of legion.builder;

class BuildCycle {
  final Project project;
  final BuildStage stage;
  final List<String> targetNames;
  final List<String> extraArguments;

  BuildCycle(this.project, this.stage, this.targetNames, this.extraArguments);

  Future run() async {
    try {
      if (stage == BuildStage.configure) {
        await _configure();
      } else if (stage == BuildStage.build) {
        await _build();
      } else {
        throw new LegionError("Unknown build stage ${stage}");
      }
    } catch (e) {
      reportErrorMessage(e.toString());
    }
  }

  Stream<Target> getTargets() async* {
    var names = new List<String>.from(targetNames);

    if (names.isEmpty) {
      names.addAll(project.state.getList("targets", defaultValue: []));
    }

    for (var name in names) {
      var toolchainProvider = await getToolchainProvider(name);

      if (toolchainProvider == null) {
        reportErrorMessage("Unable to find toolchain for target ${name}");
        continue;
      }

      var toolchain = await toolchainProvider.getToolchain(name, project);

      if (toolchain == null) {
        reportErrorMessage("Unable to find toolchain for target ${name}");
        continue;
      }

      yield await project.getTarget(name, toolchain, extraArguments);
    }
  }

  Stream<Builder> getBuilders() async* {
    var builderProvider = await getBuilderProvider();

    if (builderProvider == null) {
      reportErrorMessage("Unable to find builder");
      return;
    }

    for (var target in await getTargets().toList()) {
      yield await builderProvider.create(target);
    }
  }

  Future _configure() async {
    for (var builder in await getBuilders().toList()) {
      reportStatusMessage("Generating target ${builder.target.name}");
      try {
        await builder.generate();

        if (!project.state.isInList("targets", builder.target.name)) {
          project.state.addToList("targets", builder.target.name);
        }

        reportStatusMessage("Generated target ${builder.target.name}");
      } catch (e) {
        reportErrorMessage(e.toString());
        if (project.state.isInList("targets", builder.target.name)) {
          project.state.removeFromList("targets", builder.target.name);
        }
      }
    }
  }

  Future _build() async {
    for (var builder in await getBuilders().toList()) {
      reportStatusMessage("Building target ${builder.target.name}");
      try {
        await builder.build();
        reportStatusMessage("Built target ${builder.target.name}");
      } catch (e) {
        reportErrorMessage(e.toString());
      }
    }
  }

  Future<ToolchainProvider> getToolchainProvider(String targetName) async {
    for (var provider in toolchainProviders) {
      var providerName  = await provider.getProviderName();

      if (targetName.startsWith("${providerName}:")) {
        targetName = targetName.substring("${providerName}:".length);
      }

      if (await provider.isTargetSupported(targetName, project)) {
        return provider;
      }
    }

    return null;
  }

  Future<BuilderProvider> getBuilderProvider() async {
    for (var provider in builderProviders) {
      if (await provider.isProjectSupported(project)) {
        return provider;
      }
    }

    return null;
  }
}
