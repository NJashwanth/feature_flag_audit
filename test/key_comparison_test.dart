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

      final output = comparison.formatForCli(showDetails: true);

      expect(output, contains('Firebase comparison:'));
      expect(output, contains('Console-only keys:'));
      expect(output, contains('Code-only keys:'));
      expect(output, contains('consoleOnly'));
      expect(output, contains('codeOnly'));
    });
  });
}
