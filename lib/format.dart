library legion.format;

import "dart:async";
import "dart:io";

abstract class VariableStyle {
  static const _SingleBracketVariableStyle SINGLE_BRACKET =
  const _SingleBracketVariableStyle();
  static const _DoubleBracketVariableStyle DOUBLE_BRACKET =
  const _DoubleBracketVariableStyle();
  static const _BashBracketVariableStyle BASH_BRACKET =
  const _BashBracketVariableStyle();
  static VariableStyle DEFAULT = SINGLE_BRACKET;

  const VariableStyle();

  Set<String> findVariables(String input);
  String replace(String input, String variable, String value);

  /// Calls [action] in a [Zone] that has it's format
  /// variable style set to [style].
  static void withStyle(VariableStyle style, void action()) {
    runZoned(() {
      action();
    }, zoneValues: {
      "legion.format.variable_style": style
    });
  }
}

class _DoubleBracketVariableStyle extends VariableStyle {
  static final RegExp _REGEX = new RegExp(r"\{\{(.+?)\}\}");

  const _DoubleBracketVariableStyle();

  @override
  Set<String> findVariables(String input) {
    var matches = _REGEX.allMatches(input);
    var allKeys = new Set<String>();

    for (var match in matches) {

      var key = match.group(1);
      if (!allKeys.contains(key)) {
        allKeys.add(key);
      }
    }

    return allKeys;
  }

  @override
  String replace(String input, String variable, String value) {
    return input.replaceAll("{{${variable}}}", value);
  }
}

class _BashBracketVariableStyle extends VariableStyle {
  static final RegExp _REGEX = new RegExp(r"\$\{(.+?)\}");

  const _BashBracketVariableStyle();

  @override
  Set<String> findVariables(String input) {
    var matches = _REGEX.allMatches(input);
    var allKeys = new Set<String>();

    for (var match in matches) {

      var key = match.group(1);
      if (!allKeys.contains(key)) {
        allKeys.add(key);
      }
    }

    return allKeys;
  }

  @override
  String replace(String input, String variable, String value) {
    return input.replaceAll("\${${variable}}", value);
  }
}

class _SingleBracketVariableStyle extends VariableStyle {
  static final RegExp _REGEX = new RegExp(r"\{(.+?)\}");

  const _SingleBracketVariableStyle();

  @override
  Set<String> findVariables(String input) {
    var matches = _REGEX.allMatches(input);
    var allKeys = new Set<String>();

    for (var match in matches) {
      var key = match.group(1);
      if (!allKeys.contains(key)) {
        allKeys.add(key);
      }
    }

    return allKeys;
  }

  @override
  String replace(String input, String variable, String value) {
    return input.replaceAll("{${variable}}", value);
  }
}

typedef String VariableResolver(String variable);

String format(String input, {
  List<String> args,
  Map<String, String> replace,
  VariableStyle style,
  VariableResolver resolver
}) {
  if (style == null) {
    style = VariableStyle.DEFAULT;
  }

  if (Zone.current['legion.format.variable_style'] != null) {
    style = Zone.current['legion.format.variable_style'];
  }

  var out = input;
  var allKeys = style.findVariables(input);

  for (var id in allKeys) {
    if (args != null) {
      try {
        var index = int.parse(id);
        if (index < 0 || index > args.length - 1) {
          throw new RangeError.range(index, 0, args.length - 1);
        }
        out = style.replace(out, "${index}", args[index]);
        continue;
      } on FormatException {}
    }

    if (replace != null && replace.containsKey(id)) {
      out = style.replace(out, id, replace[id]);
      continue;
    }

    if (id.startsWith("env.")) {
      var envVariable = id.substring(4);
      if (envVariable.isEmpty) {
        throw new Exception("Unknown Key: ${id}");
      }
      var value = Platform.environment[envVariable];
      if (value == null) value = "";
      out = style.replace(out, id, value);
      continue;
    }

    if (id.startsWith("platform.")) {
      var variable = id.substring(9);

      if (variable.isEmpty) {
        throw new Exception("Unknown Key: ${id}");
      }

      var value = _resolvePlatformVariable(variable);

      out = style.replace(out, id, value);
      continue;
    }

    if (resolver != null) {
      var value = resolver(id);
      out = style.replace(out, id, value);
    } else {
      throw new Exception("Unknown Key: ${id}");
    }
  }

  return out;
}

String _resolvePlatformVariable(String name) {
  switch (name) {
    case "hostname":
      return Platform.localHostname;
    case "executable":
      return Platform.executable;
    case "os":
      return Platform.operatingSystem;
    case "version":
      return Platform.version;
    case "script":
      return Platform.script.toString();
    default:
      throw new Exception("Unsupported Platform Variable: ${name}");
  }
}
