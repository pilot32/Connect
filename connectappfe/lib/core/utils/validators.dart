/// Form validators that intentionally mirror the backend's zod schemas
/// (see `connectappbe/src/controllers/auth.controller.js`).
///
/// Client-side checks exist to give instant feedback, not to be the source of
/// truth — the server still validates every field.
class Validators {
  const Validators._();

  static final RegExp _email = RegExp(r'^[\w.!#$%&’*+/=?^`{|}~-]+@[\w-]+(\.[\w-]+)+$');

  static String? email(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Email is required';
    if (!_email.hasMatch(text)) return 'Enter a valid email address';
    return null;
  }

  /// Backend requires 8+ characters and nothing else, so we don't invent
  /// stricter rules that would reject passwords the API would happily accept.
  static String? password(String? value) {
    final String text = value ?? '';
    if (text.isEmpty) return 'Password is required';
    if (text.length < 8) return 'Use at least 8 characters';
    return null;
  }

  static String? Function(String?) confirmPassword(String Function() original) {
    return (String? value) {
      if ((value ?? '').isEmpty) return 'Re-enter your password';
      if (value != original()) return "Passwords don't match";
      return null;
    };
  }

  static String? Function(String?) required(String label) {
    return (String? value) {
      if ((value ?? '').trim().isEmpty) return '$label is required';
      return null;
    };
  }

  static String? yearsInService(String? value) {
    final String text = (value ?? '').trim();
    if (text.isEmpty) return 'Years in service is required';
    final int? years = int.tryParse(text);
    if (years == null) return 'Enter a whole number';
    if (years < 0) return "Years in service can't be negative";
    if (years > 60) return 'That looks too high — check the value';
    return null;
  }

  /// Optional free text with an upper bound, used for the bio field.
  static String? Function(String?) maxLength(int limit) {
    return (String? value) {
      if ((value ?? '').length > limit) return 'Keep it under $limit characters';
      return null;
    };
  }
}
