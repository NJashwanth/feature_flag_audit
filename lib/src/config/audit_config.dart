import 'dart:io';

import 'package:path/path.dart' as p;

import 'config_issue.dart';

/// Complete package configuration used for loading, validation, and scanning.
final class AuditConfig {
  /// Creates a configuration object.
  const AuditConfig({
    required this.firebase,
    required this.scan,
    required this.detection,
    required this.output,
  });

  /// Returns package defaults used when no configuration file is present.
  factory AuditConfig.defaults() {
    return const AuditConfig(
      firebase: FirebaseConfig(),
      scan: ScanConfig(
        include: ['lib'],
        exclude: [],
      ),
      detection: DetectionConfig(
        usageMethods: ['getBool', 'getString', 'getInt', 'getDouble'],
        wrapperMethods: [
          'boolConfigValueProvider',
          'stringConfigValueProvider',
          'intConfigValueProvider',
          'doubleConfigValueProvider',
        ],
        keyClasses: ['RemoteConfigKeys'],
      ),
      output: OutputConfig(
        showUsed: true,
        showSummary: true,
      ),
    );
  }

  /// Firebase-specific settings.
  final FirebaseConfig firebase;

  /// File scanning settings.
  final ScanConfig scan;

  /// Method and key-detection settings.
  final DetectionConfig detection;

  /// Output formatting settings.
  final OutputConfig output;

  /// Creates a copy with updated sections.
  AuditConfig copyWith({
    FirebaseConfig? firebase,
    ScanConfig? scan,
    DetectionConfig? detection,
    OutputConfig? output,
  }) {
    return AuditConfig(
      firebase: firebase ?? this.firebase,
      scan: scan ?? this.scan,
      detection: detection ?? this.detection,
      output: output ?? this.output,
    );
  }

  /// Merges values from a parsed YAML map.
  AuditConfig mergeMap(Map<Object?, Object?> values, {required String source}) {
    return copyWith(
      firebase: firebase.mergeMap(
        _readMap(values, 'firebase', source: source),
        source: '$source.firebase',
      ),
      scan: scan.mergeMap(
        _readMap(values, 'scan', source: source),
        source: '$source.scan',
      ),
      detection: detection.mergeMap(
        _readMap(values, 'detection', source: source),
        source: '$source.detection',
      ),
      output: output.mergeMap(
        _readMap(values, 'output', source: source),
        source: '$source.output',
      ),
    );
  }

  /// Applies CLI override values over the current config.
  AuditConfig mergeCliOverrides({
    String? projectId,
    String? serviceAccountPath,
  }) {
    return copyWith(
      firebase: firebase.copyWith(
        projectId: projectId ?? firebase.projectId,
        serviceAccountPath: serviceAccountPath ?? firebase.serviceAccountPath,
      ),
    );
  }

  /// Validates config values for the given [projectRoot].
  ///
  /// If [requireFirebase] is true, firebase fields become mandatory.
  ConfigValidationResult validate({
    required String projectRoot,
    bool requireFirebase = false,
  }) {
    final issues = <ConfigIssue>[];
    final hasProjectId =
        firebase.projectId != null && firebase.projectId!.isNotEmpty;
    final hasServiceAccountPath = firebase.serviceAccountPath != null &&
        firebase.serviceAccountPath!.isNotEmpty;
    final hasAnyFirebaseConfig = hasProjectId || hasServiceAccountPath;

    if (!hasAnyFirebaseConfig && !requireFirebase) {
      issues.add(
        const ConfigIssue(
          severity: ConfigIssueSeverity.warning,
          message:
              'Firebase config not provided. Continuing with default scan-only behavior.',
        ),
      );
    }

    if ((requireFirebase || hasAnyFirebaseConfig) && !hasProjectId) {
      issues.add(
        const ConfigIssue(
          severity: ConfigIssueSeverity.error,
          message:
              'Missing required firebase.project_id. Set it in feature_flag_audit.yaml or pass --project-id.',
        ),
      );
    }

    if ((requireFirebase || hasAnyFirebaseConfig) && !hasServiceAccountPath) {
      issues.add(
        const ConfigIssue(
          severity: ConfigIssueSeverity.error,
          message:
              'Missing required firebase.service_account_path. Set it in feature_flag_audit.yaml or pass --service-account.',
        ),
      );
    }

    if (hasServiceAccountPath) {
      final resolvedPath = p.normalize(
        p.isAbsolute(firebase.serviceAccountPath!)
            ? firebase.serviceAccountPath!
            : p.join(projectRoot, firebase.serviceAccountPath!),
      );

      if (!File(resolvedPath).existsSync()) {
        issues.add(
          ConfigIssue(
            severity: ConfigIssueSeverity.error,
            message:
                'firebase.service_account_path does not exist: $resolvedPath',
          ),
        );
      }
    }

    if (scan.include.isEmpty) {
      issues.add(
        const ConfigIssue(
          severity: ConfigIssueSeverity.warning,
          message:
              'scan.include is empty. No source directories will be scanned.',
        ),
      );
    }

    if (detection.usageMethods.isEmpty) {
      issues.add(
        const ConfigIssue(
          severity: ConfigIssueSeverity.warning,
          message:
              'detection.usage_methods is empty. Default Firebase usage calls will not be detected.',
        ),
      );
    }

    return ConfigValidationResult(issues);
  }

  /// Converts the config into a serializable map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'firebase': firebase.toMap(),
      'scan': scan.toMap(),
      'detection': detection.toMap(),
      'output': output.toMap(),
    };
  }

  @override
  String toString() => toMap().toString();
}

/// Firebase project and credential configuration.
final class FirebaseConfig {
  /// Creates firebase settings.
  const FirebaseConfig({
    this.projectId,
    this.serviceAccountPath,
  });

  /// Firebase project identifier.
  final String? projectId;

  /// Path to the service account json file.
  final String? serviceAccountPath;

  /// Creates a copy with optional updates.
  FirebaseConfig copyWith({
    String? projectId,
    String? serviceAccountPath,
  }) {
    return FirebaseConfig(
      projectId: projectId,
      serviceAccountPath: serviceAccountPath,
    );
  }

  /// Merges values from a parsed map.
  FirebaseConfig mergeMap(Map<Object?, Object?> values,
      {required String source}) {
    return copyWith(
      projectId: _readString(values, 'project_id', source: source) ?? projectId,
      serviceAccountPath:
          _readString(values, 'service_account_path', source: source) ??
              serviceAccountPath,
    );
  }

  /// Converts this section to a map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'project_id': projectId,
      'service_account_path': serviceAccountPath,
    };
  }
}

/// Controls which source paths are included or excluded.
final class ScanConfig {
  /// Creates scan settings.
  const ScanConfig({
    required this.include,
    required this.exclude,
  });

  /// Relative paths or files to scan.
  final List<String> include;

  /// Relative paths or files to skip.
  final List<String> exclude;

  /// Creates a copy with optional updates.
  ScanConfig copyWith({
    List<String>? include,
    List<String>? exclude,
  }) {
    return ScanConfig(
      include: include ?? this.include,
      exclude: exclude ?? this.exclude,
    );
  }

  /// Merges values from a parsed map.
  ScanConfig mergeMap(Map<Object?, Object?> values, {required String source}) {
    return copyWith(
      include: _readStringList(values, 'include', source: source) ?? include,
      exclude: _readStringList(values, 'exclude', source: source) ?? exclude,
    );
  }

  /// Converts this section to a map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'include': include,
      'exclude': exclude,
    };
  }
}

/// Controls method and key class detection rules.
final class DetectionConfig {
  /// Creates detection settings.
  const DetectionConfig({
    required this.usageMethods,
    required this.wrapperMethods,
    required this.keyClasses,
  });

  /// Methods called directly on a remote config instance.
  final List<String> usageMethods;

  /// Wrapper helper methods that accept keys.
  final List<String> wrapperMethods;

  /// Classes that define static const key members.
  final List<String> keyClasses;

  /// Creates a copy with optional updates.
  DetectionConfig copyWith({
    List<String>? usageMethods,
    List<String>? wrapperMethods,
    List<String>? keyClasses,
  }) {
    return DetectionConfig(
      usageMethods: usageMethods ?? this.usageMethods,
      wrapperMethods: wrapperMethods ?? this.wrapperMethods,
      keyClasses: keyClasses ?? this.keyClasses,
    );
  }

  /// Merges values from a parsed map.
  DetectionConfig mergeMap(Map<Object?, Object?> values,
      {required String source}) {
    return copyWith(
      usageMethods: _readStringList(values, 'usage_methods', source: source) ??
          usageMethods,
      wrapperMethods:
          _readStringList(values, 'wrapper_methods', source: source) ??
              wrapperMethods,
      keyClasses:
          _readStringList(values, 'key_classes', source: source) ?? keyClasses,
    );
  }

  /// Converts this section to a map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'usage_methods': usageMethods,
      'wrapper_methods': wrapperMethods,
      'key_classes': keyClasses,
    };
  }
}

/// Controls CLI output sections.
final class OutputConfig {
  /// Creates output settings.
  const OutputConfig({
    required this.showUsed,
    required this.showSummary,
  });

  /// Whether to print per-key usage details.
  final bool showUsed;

  /// Whether to print summary totals.
  final bool showSummary;

  /// Creates a copy with optional updates.
  OutputConfig copyWith({
    bool? showUsed,
    bool? showSummary,
  }) {
    return OutputConfig(
      showUsed: showUsed ?? this.showUsed,
      showSummary: showSummary ?? this.showSummary,
    );
  }

  /// Merges values from a parsed map.
  OutputConfig mergeMap(Map<Object?, Object?> values,
      {required String source}) {
    return copyWith(
      showUsed: _readBool(values, 'show_used', source: source) ?? showUsed,
      showSummary:
          _readBool(values, 'show_summary', source: source) ?? showSummary,
    );
  }

  /// Converts this section to a map.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'show_used': showUsed,
      'show_summary': showSummary,
    };
  }
}

Map<Object?, Object?> _readMap(
  Map<Object?, Object?> map,
  String key, {
  required String source,
}) {
  final value = map[key];
  if (value == null) {
    return const <Object?, Object?>{};
  }
  if (value is Map<Object?, Object?>) {
    return value;
  }
  throw AuditConfigException(
      'Expected $source.$key to be a map, got ${value.runtimeType}.');
}

String? _readString(
  Map<Object?, Object?> map,
  String key, {
  required String source,
}) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is String) {
    return value;
  }
  throw AuditConfigException(
      'Expected $source.$key to be a string, got ${value.runtimeType}.');
}

bool? _readBool(
  Map<Object?, Object?> map,
  String key, {
  required String source,
}) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is bool) {
    return value;
  }
  throw AuditConfigException(
      'Expected $source.$key to be a bool, got ${value.runtimeType}.');
}

List<String>? _readStringList(
  Map<Object?, Object?> map,
  String key, {
  required String source,
}) {
  final value = map[key];
  if (value == null) {
    return null;
  }
  if (value is! List) {
    throw AuditConfigException(
      'Expected $source.$key to be a list of strings, got ${value.runtimeType}.',
    );
  }

  final items = <String>[];
  for (var index = 0; index < value.length; index++) {
    final item = value[index];
    if (item is! String) {
      throw AuditConfigException(
        'Expected $source.$key[$index] to be a string, got ${item.runtimeType}.',
      );
    }
    items.add(item);
  }
  return List.unmodifiable(items);
}
