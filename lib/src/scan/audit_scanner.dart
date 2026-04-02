import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../config/audit_config.dart';

enum AuditMatchKind {
  usageMethod,
  wrapperMethod,
}

final class AuditFinding {
  const AuditFinding({
    required this.key,
    required this.method,
    required this.kind,
    required this.filePath,
    required this.line,
    required this.column,
    required this.argument,
  });

  final String key;
  final String method;
  final AuditMatchKind kind;
  final String filePath;
  final int line;
  final int column;
  final String argument;
}

final class AuditUnresolvedReference {
  const AuditUnresolvedReference({
    required this.reference,
    required this.method,
    required this.kind,
    required this.filePath,
    required this.line,
    required this.column,
  });

  final String reference;
  final String method;
  final AuditMatchKind kind;
  final String filePath;
  final int line;
  final int column;
}

final class AuditScanResult {
  const AuditScanResult({
    required this.projectRoot,
    required this.scannedFiles,
    required this.findings,
    required this.unresolvedReferences,
  });

  final String projectRoot;
  final List<String> scannedFiles;
  final List<AuditFinding> findings;
  final List<AuditUnresolvedReference> unresolvedReferences;

  List<String> get usedKeys {
    final keys = findings.map((finding) => finding.key).toSet().toList()..sort();
    return List.unmodifiable(keys);
  }

  Map<String, int> get keyUsageCounts {
    final counts = <String, int>{};
    for (final finding in findings) {
      counts.update(finding.key, (value) => value + 1, ifAbsent: () => 1);
    }
    return Map.unmodifiable(counts);
  }

  String formatForCli({
    required bool showUsed,
    required bool showSummary,
  }) {
    final lines = <String>[];

    if (showSummary) {
      lines.add('Scan summary:');
      lines.add('  Dart files scanned: ${scannedFiles.length}');
      lines.add('  Keys detected: ${usedKeys.length}');
      lines.add('  Total matches: ${findings.length}');
      lines.add('  Unresolved references: ${unresolvedReferences.length}');
    }

    if (showUsed) {
      if (lines.isNotEmpty) {
        lines.add('');
      }

      if (findings.isEmpty) {
        lines.add('No feature flag usage detected.');
      } else {
        lines.add('Detected keys:');
        final grouped = <String, List<AuditFinding>>{};
        for (final finding in findings) {
          grouped.putIfAbsent(finding.key, () => <AuditFinding>[]).add(finding);
        }
        final sortedKeys = grouped.keys.toList()..sort();
        for (final key in sortedKeys) {
          final matches = grouped[key]!..sort((left, right) {
            final fileCompare = left.filePath.compareTo(right.filePath);
            if (fileCompare != 0) {
              return fileCompare;
            }
            final lineCompare = left.line.compareTo(right.line);
            if (lineCompare != 0) {
              return lineCompare;
            }
            return left.column.compareTo(right.column);
          });
          lines.add('  $key (${matches.length})');
          for (final match in matches) {
            final relativePath = p.relative(match.filePath, from: projectRoot);
            lines.add(
              '    - ${match.method} at $relativePath:${match.line}:${match.column}',
            );
          }
        }
      }
    }

    if (unresolvedReferences.isNotEmpty) {
      if (lines.isNotEmpty) {
        lines.add('');
      }
      lines.add('Unresolved key references:');
      for (final unresolved in unresolvedReferences) {
        final relativePath = p.relative(unresolved.filePath, from: projectRoot);
        lines.add(
          '  - ${unresolved.reference} via ${unresolved.method} at $relativePath:${unresolved.line}:${unresolved.column}',
        );
      }
    }

    return lines.join('\n');
  }
}

final class AuditScanner {
  const AuditScanner();

  Future<AuditScanResult> scan({
    required String projectRoot,
    required AuditConfig config,
  }) async {
    final files = await _collectDartFiles(
      projectRoot: projectRoot,
      includePaths: config.scan.include,
      excludePaths: config.scan.exclude,
    );

    final keyDefinitions = <String, Map<String, String>>{};
    final sourceByFile = <String, String>{};

    for (final filePath in files) {
      final source = await File(filePath).readAsString();
      sourceByFile[filePath] = source;
      _extractKeyDefinitions(
        source: source,
        keyClasses: config.detection.keyClasses,
        into: keyDefinitions,
      );
    }

    final findings = <AuditFinding>[];
    final unresolvedReferences = <AuditUnresolvedReference>[];

    for (final filePath in files) {
      final source = sourceByFile[filePath]!;
      _collectMatches(
        filePath: filePath,
        source: source,
        methods: config.detection.usageMethods,
        kind: AuditMatchKind.usageMethod,
        keyDefinitions: keyDefinitions,
        findings: findings,
        unresolvedReferences: unresolvedReferences,
      );
      _collectMatches(
        filePath: filePath,
        source: source,
        methods: config.detection.wrapperMethods,
        kind: AuditMatchKind.wrapperMethod,
        keyDefinitions: keyDefinitions,
        findings: findings,
        unresolvedReferences: unresolvedReferences,
      );
    }

    files.sort();
    findings.sort(_compareFindings);
    unresolvedReferences.sort(_compareUnresolvedReferences);

    return AuditScanResult(
      projectRoot: projectRoot,
      scannedFiles: List.unmodifiable(files),
      findings: List.unmodifiable(findings),
      unresolvedReferences: List.unmodifiable(unresolvedReferences),
    );
  }
}

Future<List<String>> _collectDartFiles({
  required String projectRoot,
  required List<String> includePaths,
  required List<String> excludePaths,
}) async {
  final files = <String>{};
  for (final includePath in includePaths) {
    final resolvedIncludePath = _resolvePath(projectRoot, includePath);
    final type = FileSystemEntity.typeSync(resolvedIncludePath);
    if (type == FileSystemEntityType.notFound) {
      continue;
    }
    if (type == FileSystemEntityType.file) {
      if (_isDartFile(resolvedIncludePath) &&
          !_isExcluded(resolvedIncludePath, projectRoot, excludePaths)) {
        files.add(p.normalize(resolvedIncludePath));
      }
      continue;
    }

    await for (final entity
        in Directory(resolvedIncludePath).list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      if (!_isDartFile(entity.path)) {
        continue;
      }
      if (_isExcluded(entity.path, projectRoot, excludePaths)) {
        continue;
      }
      files.add(p.normalize(entity.path));
    }
  }
  return files.toList(growable: false);
}

bool _isDartFile(String path) => path.endsWith('.dart');

bool _isExcluded(String path, String projectRoot, List<String> excludePaths) {
  final normalizedPath = p.normalize(path);
  final relativePath = p.normalize(p.relative(normalizedPath, from: projectRoot));

  for (final excludePath in excludePaths) {
    final normalizedExcludePath = p.normalize(excludePath);
    final resolvedExcludePath = _resolvePath(projectRoot, normalizedExcludePath);
    final normalizedResolvedExcludePath = p.normalize(resolvedExcludePath);

    if (normalizedPath == normalizedResolvedExcludePath ||
        p.isWithin(normalizedResolvedExcludePath, normalizedPath)) {
      return true;
    }

    if (relativePath == normalizedExcludePath ||
        p.isWithin(normalizedExcludePath, relativePath)) {
      return true;
    }
  }

  return false;
}

String _resolvePath(String projectRoot, String pathValue) {
  if (p.isAbsolute(pathValue)) {
    return pathValue;
  }
  return p.join(projectRoot, pathValue);
}

void _extractKeyDefinitions({
  required String source,
  required List<String> keyClasses,
  required Map<String, Map<String, String>> into,
}) {
  for (final className in keyClasses) {
    var searchOffset = 0;
    while (searchOffset < source.length) {
      final classMatch = RegExp('class\\s+$className\\b[^\\{]*\\{').matchAsPrefix(
        source,
        searchOffset,
      );
      if (classMatch == null) {
        final nextOffset = source.indexOf('class $className', searchOffset);
        if (nextOffset == -1) {
          break;
        }
        searchOffset = nextOffset;
        continue;
      }

      final bodyStart = classMatch.end;
      final bodyEnd = _findMatchingBrace(source, bodyStart - 1);
      if (bodyEnd == -1) {
        break;
      }

      final body = source.substring(bodyStart, bodyEnd);
      final target = into.putIfAbsent(className, () => <String, String>{});
      final constPattern = RegExp(
        "(?:static\\s+)?const(?:\\s+[A-Za-z_][A-Za-z0-9_<>?, ]*)?\\s+([A-Za-z_][A-Za-z0-9_]*)\\s*=\\s*([\"'])((?:.|\\n)*?)\\2\\s*;",
      );
      for (final match in constPattern.allMatches(body)) {
        final memberName = match.group(1);
        final keyValue = match.group(3);
        if (memberName == null || keyValue == null) {
          continue;
        }
        target[memberName] = keyValue;
      }

      searchOffset = bodyEnd + 1;
    }
  }
}

void _collectMatches({
  required String filePath,
  required String source,
  required List<String> methods,
  required AuditMatchKind kind,
  required Map<String, Map<String, String>> keyDefinitions,
  required List<AuditFinding> findings,
  required List<AuditUnresolvedReference> unresolvedReferences,
}) {
  for (final method in methods) {
    final pattern = RegExp(
      "\\b${RegExp.escape(method)}\\s*\\(\\s*(?:([\"'])([^\"']+)\\1|([A-Za-z_][A-Za-z0-9_]*\\.[A-Za-z_][A-Za-z0-9_]*))",
    );
    for (final match in pattern.allMatches(source)) {
      final location = _offsetToLocation(source, match.start);
      final literalKey = match.group(2);
      final reference = match.group(3);
      if (literalKey != null) {
        findings.add(
          AuditFinding(
            key: literalKey,
            method: method,
            kind: kind,
            filePath: filePath,
            line: location.$1,
            column: location.$2,
            argument: literalKey,
          ),
        );
        continue;
      }

      if (reference == null) {
        continue;
      }

      final parts = reference.split('.');
      if (parts.length != 2) {
        continue;
      }

      final resolvedKey = keyDefinitions[parts[0]]?[parts[1]];
      if (resolvedKey == null) {
        unresolvedReferences.add(
          AuditUnresolvedReference(
            reference: reference,
            method: method,
            kind: kind,
            filePath: filePath,
            line: location.$1,
            column: location.$2,
          ),
        );
        continue;
      }

      findings.add(
        AuditFinding(
          key: resolvedKey,
          method: method,
          kind: kind,
          filePath: filePath,
          line: location.$1,
          column: location.$2,
          argument: reference,
        ),
      );
    }
  }
}

(int, int) _offsetToLocation(String source, int offset) {
  var line = 1;
  var column = 1;
  for (var index = 0; index < offset; index++) {
    if (source.codeUnitAt(index) == 10) {
      line++;
      column = 1;
    } else {
      column++;
    }
  }
  return (line, column);
}

int _findMatchingBrace(String source, int openBraceOffset) {
  var depth = 0;
  for (var index = openBraceOffset; index < source.length; index++) {
    final char = source.codeUnitAt(index);
    if (char == 123) {
      depth++;
    } else if (char == 125) {
      depth--;
      if (depth == 0) {
        return index;
      }
    }
  }
  return -1;
}

int _compareFindings(AuditFinding left, AuditFinding right) {
  final fileCompare = left.filePath.compareTo(right.filePath);
  if (fileCompare != 0) {
    return fileCompare;
  }
  final lineCompare = left.line.compareTo(right.line);
  if (lineCompare != 0) {
    return lineCompare;
  }
  return left.column.compareTo(right.column);
}

int _compareUnresolvedReferences(
  AuditUnresolvedReference left,
  AuditUnresolvedReference right,
) {
  final fileCompare = left.filePath.compareTo(right.filePath);
  if (fileCompare != 0) {
    return fileCompare;
  }
  final lineCompare = left.line.compareTo(right.line);
  if (lineCompare != 0) {
    return lineCompare;
  }
  return left.column.compareTo(right.column);
}