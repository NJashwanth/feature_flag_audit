import 'dart:io';

import 'package:path/path.dart' as p;

import 'config_issue.dart';

final class AuditConfig {
  const AuditConfig({
    required this.firebase,
    required this.scan,
    required this.detection,
    required this.output,
  });

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

  final FirebaseConfig firebase;
  final ScanConfig scan;
  final DetectionConfig detection;
  final OutputConfig output;

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

final class FirebaseConfig {
  const FirebaseConfig({
    this.projectId,
    this.serviceAccountPath,
  });

  final String? projectId;
  final String? serviceAccountPath;

  FirebaseConfig copyWith({
    String? projectId,
    String? serviceAccountPath,
  }) {
    return FirebaseConfig(
      projectId: projectId,
      serviceAccountPath: serviceAccountPath,
    );
  }

  FirebaseConfig mergeMap(Map<Object?, Object?> values,
      {required String source}) {
    return copyWith(
      projectId: _readString(values, 'project_id', source: source) ?? projectId,
      serviceAccountPath:
          _readString(values, 'service_account_path', source: source) ??
              serviceAccountPath,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'project_id': projectId,
      'service_account_path': serviceAccountPath,
    };
  }
}

final class ScanConfig {
  const ScanConfig({
    required this.include,
    required this.exclude,
  });

  final List<String> include;
  final List<String> exclude;

  ScanConfig copyWith({
    List<String>? include,
    List<String>? exclude,
  }) {
    return ScanConfig(
      include: include ?? this.include,
      exclude: exclude ?? this.exclude,
    );
  }

  ScanConfig mergeMap(Map<Object?, Object?> values, {required String source}) {
    return copyWith(
      include: _readStringList(values, 'include', source: source) ?? include,
      exclude: _readStringList(values, 'exclude', source: source) ?? exclude,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'include': include,
      'exclude': exclude,
    };
  }
}

final class DetectionConfig {
  const DetectionConfig({
    required this.usageMethods,
    required this.wrapperMethods,
    required this.keyClasses,
  });

  final List<String> usageMethods;
  final List<String> wrapperMethods;
  final List<String> keyClasses;

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

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'usage_methods': usageMethods,
      'wrapper_methods': wrapperMethods,
      'key_classes': keyClasses,
    };
  }
}

final class OutputConfig {
  const OutputConfig({
    required this.showUsed,
    required this.showSummary,
  });

  final bool showUsed;
  final bool showSummary;

  OutputConfig copyWith({
    bool? showUsed,
    bool? showSummary,
  }) {
    return OutputConfig(
      showUsed: showUsed ?? this.showUsed,
      showSummary: showSummary ?? this.showSummary,
    );
  }

  OutputConfig mergeMap(Map<Object?, Object?> values,
      {required String source}) {
    return copyWith(
      showUsed: _readBool(values, 'show_used', source: source) ?? showUsed,
      showSummary:
          _readBool(values, 'show_summary', source: source) ?? showSummary,
    );
  }

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
