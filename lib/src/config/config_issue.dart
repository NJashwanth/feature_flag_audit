/// Severity levels used during configuration validation.
enum ConfigIssueSeverity {
  /// A non-blocking issue.
  warning,

  /// A blocking issue that should stop execution.
  error,
}

/// A single warning or error discovered while validating configuration.
final class ConfigIssue {
  /// Creates a validation issue.
  const ConfigIssue({
    required this.severity,
    required this.message,
  });

  /// The issue severity.
  final ConfigIssueSeverity severity;

  /// Human-readable message for the issue.
  final String message;

  /// Whether this issue is an error.
  bool get isError => severity == ConfigIssueSeverity.error;
}

/// Validation outcome containing warnings and errors.
final class ConfigValidationResult {
  /// Creates a validation result from all discovered [issues].
  const ConfigValidationResult(this.issues);

  /// All validation issues.
  final List<ConfigIssue> issues;

  /// Errors only.
  List<ConfigIssue> get errors =>
      issues.where((issue) => issue.isError).toList(growable: false);

  /// Warnings only.
  List<ConfigIssue> get warnings =>
      issues.where((issue) => !issue.isError).toList(growable: false);

  /// Whether no blocking errors were found.
  bool get isValid => errors.isEmpty;
}

/// Exception thrown when configuration parsing fails.
final class AuditConfigException implements Exception {
  /// Creates a new configuration exception with [message].
  const AuditConfigException(this.message);

  /// Human-readable failure message.
  final String message;

  @override
  String toString() => 'AuditConfigException: $message';
}
