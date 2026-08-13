import 'package:connectappfe/core/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pure-Dart tests for the form validators.
///
/// These replace the generated counter-app smoke test, which referenced the
/// scaffold's `MyApp` and no longer compiles. Validators are worth pinning
/// because they're meant to mirror the backend's zod rules — if the two drift,
/// users get rejected by the server after the client said they were fine.
void main() {
  group('Validators.email', () {
    test('rejects empty and malformed addresses', () {
      expect(Validators.email(null), isNotNull);
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('   '), isNotNull);
      expect(Validators.email('officer'), isNotNull);
      expect(Validators.email('officer@'), isNotNull);
      expect(Validators.email('officer@gov'), isNotNull);
      expect(Validators.email('@gov.in'), isNotNull);
    });

    test('accepts well-formed addresses', () {
      expect(Validators.email('officer@department.gov.in'), isNull);
      expect(Validators.email('a.b-c@sub.domain.org'), isNull);
      expect(Validators.email('  spaced@example.com  '), isNull);
    });
  });

  group('Validators.password', () {
    test('enforces the backend minimum of 8 characters', () {
      expect(Validators.password(''), isNotNull);
      expect(Validators.password('short'), isNotNull);
      expect(Validators.password('1234567'), isNotNull);
      expect(Validators.password('12345678'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('matches against the live value of the original field', () {
      String original = 'password123';
      final String? Function(String?) validator =
          Validators.confirmPassword(() => original);

      expect(validator('password123'), isNull);
      expect(validator('nope'), isNotNull);
      expect(validator(''), isNotNull);

      // Changing the original invalidates a previously matching confirmation.
      original = 'changed123';
      expect(validator('password123'), isNotNull);
    });
  });

  group('Validators.yearsInService', () {
    test('requires a non-negative whole number', () {
      expect(Validators.yearsInService(''), isNotNull);
      expect(Validators.yearsInService('abc'), isNotNull);
      expect(Validators.yearsInService('3.5'), isNotNull);
      expect(Validators.yearsInService('-1'), isNotNull);
      expect(Validators.yearsInService('0'), isNull);
      expect(Validators.yearsInService('12'), isNull);
    });

    test('flags implausibly long careers', () {
      expect(Validators.yearsInService('61'), isNotNull);
      expect(Validators.yearsInService('60'), isNull);
    });
  });

  group('Validators.required', () {
    test('treats whitespace-only input as missing', () {
      final String? Function(String?) validator = Validators.required('Name');
      expect(validator(null), 'Name is required');
      expect(validator('   '), 'Name is required');
      expect(validator('Asha'), isNull);
    });
  });

  group('Validators.maxLength', () {
    test('allows values up to the limit', () {
      final String? Function(String?) validator = Validators.maxLength(5);
      expect(validator(null), isNull);
      expect(validator('12345'), isNull);
      expect(validator('123456'), isNotNull);
    });
  });
}
