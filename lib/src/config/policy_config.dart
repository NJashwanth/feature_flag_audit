import 'config_issue.dart';

/// Action to take when a policy rule has violations.
enum PolicyAction {
  /// Exit with code 1 — blocks the pipeline.
  fail,

  /// Print a warning but exit with code 0 — advisory only.
  warn,

  /// Silently ignore violations.
  pass,
}

/// Controls pipeline enforcement behavior for each class of audit finding.
final class PolicyConfig {
  /// Creates policy settings.
  const PolicyConfig({
    required this.codeOnlyKeys,
    required this.consoleOnlyKeys,
    required this.unresolvedReferences,
  });

  /// Action when keys appear in code but are missing from Firebase.
  final PolicyAction codeOnlyKeys;

  /// Action when keys exist in Firebase but are not used in code.
  final PolicyAction consoleOnlyKeys;

  /// Action when key references in code cannot be resolved to a definition.
  final PolicyAction unresolvedReferences;

  /// Creates a copy with optional updates.
  PolicyConfig copyWith({
    PolicyAction? codeOnlyKeys,
    PolicyAction? consoleOnlyKeys,
    PolicyAction? unresolvedReferences,
  }) {
    return PolicyConfig(
      codeOnlyKeys: codeOnlyKeys ?? this.codeOnlyKeys,
      consoleOnlyKeys: consoleOnlyKeys ?? this.consoleOnlyKeys,
      unresolvedReferences: unresolvedReferences ?? this.unresolvedReferences,
    );
  }

  /// Merges values from a parsed map.
  PolicyConfig mergeMap(Map<Object?, Object?> values,
      {required String source}) {
    return copyWith(
      codeOnlyKeys:
          _readAction(values, 'code_only_keys', source: source) ?? codeOnlyKeys,
      consoleOnlyKeys:
          _readAction(values, 'console_only_keys', source: source) ??
              consoleOnlyKeys,
      unresolvedReferences:
          _readAction(values, 'unresolved_references', source: source) ??
              unresolvedReferences,
    );
  }

  /// Converts this section to a map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'code_only_keys': codeOnlyKeys.name,
      'console_only_keys': consoleOnlyKeys.name,
      'unresolved_references': unresolvedReferences.name,
    };
  }
}

PolicyAction? _readAction(
  Map<Object?, Object?> map,
  String key, {
  required String source,
}) {
  final value = map[key];
  if (value == null) return null;
  if (value is! String) {
    throw AuditConfigException(
      'Expected $source.$key to be a string (fail/warn/pass), got ${value.runtimeType}.',
    );
  }
  return switch (value.toLowerCase().trim()) {
    'fail' => PolicyAction.fail,
    'warn' => PolicyAction.warn,
    'pass' => PolicyAction.pass,
    _ => throw AuditConfigException(
        'Invalid value for $source.$key: "$value". Expected fail, warn, or pass.',
      ),
  };
}
