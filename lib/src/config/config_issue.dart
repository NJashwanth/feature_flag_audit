enum ConfigIssueSeverity {
  warning,
  error,
}

final class ConfigIssue {
  const ConfigIssue({
    required this.severity,
    required this.message,
  });

  final ConfigIssueSeverity severity;
  final String message;

  bool get isError => severity == ConfigIssueSeverity.error;
}

final class ConfigValidationResult {
  const ConfigValidationResult(this.issues);

  final List<ConfigIssue> issues;

  List<ConfigIssue> get errors =>
      issues.where((issue) => issue.isError).toList(growable: false);

  List<ConfigIssue> get warnings =>
      issues.where((issue) => !issue.isError).toList(growable: false);

  bool get isValid => errors.isEmpty;
}

final class AuditConfigException implements Exception {
  const AuditConfigException(this.message);

  final String message;

  @override
  String toString() => 'AuditConfigException: $message';
}
