/// Comparison result between keys used in code and keys defined in Firebase.
final class AuditKeyComparison {
  /// Creates a key comparison result.
  const AuditKeyComparison({
    required this.consoleKeys,
    required this.codeKeys,
    required this.consoleOnlyKeys,
    required this.codeOnlyKeys,
    required this.sharedKeys,
  });

  /// Keys currently present in Firebase Remote Config.
  final List<String> consoleKeys;

  /// Keys detected in source code.
  final List<String> codeKeys;

  /// Keys defined in console but not used in code.
  final List<String> consoleOnlyKeys;

  /// Keys used in code but missing from console.
  final List<String> codeOnlyKeys;

  /// Keys present in both code and console.
  final List<String> sharedKeys;

  /// Builds a comparison from key sets.
  factory AuditKeyComparison.compare({
    required Set<String> consoleKeys,
    required Set<String> codeKeys,
  }) {
    final sortedConsole = consoleKeys.toList()..sort();
    final sortedCode = codeKeys.toList()..sort();
    final consoleOnly = consoleKeys.difference(codeKeys).toList()..sort();
    final codeOnly = codeKeys.difference(consoleKeys).toList()..sort();
    final shared = consoleKeys.intersection(codeKeys).toList()..sort();

    return AuditKeyComparison(
      consoleKeys: List.unmodifiable(sortedConsole),
      codeKeys: List.unmodifiable(sortedCode),
      consoleOnlyKeys: List.unmodifiable(consoleOnly),
      codeOnlyKeys: List.unmodifiable(codeOnly),
      sharedKeys: List.unmodifiable(shared),
    );
  }

  /// Formats comparison details for CLI output.
  String formatForCli({bool showDetails = true}) {
    final lines = <String>[
      'Firebase comparison summary:',
      '  Keys in Firebase: ${consoleKeys.length}',
      '  Keys in application code: ${codeKeys.length}',
      '  Keys matched in both: ${sharedKeys.length}',
      '  Keys only in Firebase: ${consoleOnlyKeys.length}',
      '  Keys only in application code: ${codeOnlyKeys.length}',
    ];

    if (!showDetails) {
      return lines.join('\n');
    }

    lines
      ..add('')
      ..add('Breakdown:')
      ..add('Keys found in Firebase but not used in the Application:');
    if (consoleOnlyKeys.isEmpty) {
      lines.add('  - None');
    } else {
      for (final key in consoleOnlyKeys) {
        lines.add('  - $key');
      }
    }

    lines.add('');
    lines.add('keys used in the code base but not in firebase:');
    if (codeOnlyKeys.isEmpty) {
      lines.add('  - None');
    } else {
      for (final key in codeOnlyKeys) {
        lines.add('  - $key');
      }
    }

    return lines.join('\n');
  }
}
