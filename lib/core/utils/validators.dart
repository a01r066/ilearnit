/// Lightweight form validators returned to TextFormField `validator:` callbacks.
class Validators {
  const Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required.';
    final regex = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');
    if (!regex.hasMatch(value.trim())) return 'Enter a valid email.';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'At least 8 characters.';
    return null;
  }

  static String? required(String? value, {String label = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$label is required.';
    return null;
  }

  static String? matches(
    String? value,
    String other, {
    String label = 'Confirmation',
  }) {
    if (value != other) return '$label does not match.';
    return null;
  }
}
