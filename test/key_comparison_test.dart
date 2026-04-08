import 'package:feature_flag_audit/feature_flag_audit.dart';
import 'package:test/test.dart';

void main() {
  group('AuditKeyComparison', () {
    test('computes console-only, code-only, and shared keys', () {
      final comparison = AuditKeyComparison.compare(
        consoleKeys: {'a', 'b', 'c'},
        codeKeys: {'b', 'c', 'd'},
      );

      expect(comparison.consoleKeys, ['a', 'b', 'c']);
      expect(comparison.codeKeys, ['b', 'c', 'd']);
      expect(comparison.sharedKeys, ['b', 'c']);
      expect(comparison.consoleOnlyKeys, ['a']);
      expect(comparison.codeOnlyKeys, ['d']);
    });

    test('formats summary and detailed sections', () {
      final comparison = AuditKeyComparison.compare(
        consoleKeys: {'consoleOnly', 'sharedKey'},
        codeKeys: {'codeOnly', 'sharedKey'},
      );

      final output = comparison.formatForCli();

      expect(output, contains('Firebase comparison summary:'));
      expect(
        output,
        contains('Keys found in Firebase but not used in the Application:'),
      );
      expect(
        output,
        contains('keys used in the code base but not in firebase:'),
      );
      expect(output, contains('consoleOnly'));
      expect(output, contains('codeOnly'));
    });

    test('shows None when breakdown sections are empty', () {
      final comparison = AuditKeyComparison.compare(
        consoleKeys: {'sharedKey'},
        codeKeys: {'sharedKey'},
      );

      final output = comparison.formatForCli();

      expect(output,
          contains('Keys found in Firebase but not used in the Application:'));
      expect(
          output, contains('keys used in the code base but not in firebase:'));
      expect(output, contains('  - None'));
    });

    test('can hide individual breakdown sections', () {
      final comparison = AuditKeyComparison.compare(
        consoleKeys: {'consoleOnly', 'sharedKey'},
        codeKeys: {'codeOnly', 'sharedKey'},
      );

      final output = comparison.formatForCli(
        showSummary: true,
        showConsoleOnly: false,
        showCodeOnly: true,
      );

      expect(output, contains('Firebase comparison summary:'));
      expect(
        output,
        isNot(contains(
            'Keys found in Firebase but not used in the Application:')),
      );
      expect(
          output, contains('keys used in the code base but not in firebase:'));
      expect(output, contains('  - codeOnly'));
    });
  });
}
