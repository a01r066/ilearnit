import '../../l10n/l10n.dart';
/// Lightweight form validators returned to TextFormField `validator:` callbacks.
class Validators {
  const Validators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return L10n.current.valEmailRequired;
    final regex = RegExp(r'^[\w\.\-+]+@[\w\-]+(\.[\w\-]+)+$');
    if (!regex.hasMatch(value.trim())) return L10n.current.valEmailInvalid;
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return L10n.current.valPasswordRequired;
    if (value.length < 8) return L10n.current.valPasswordMin;
    return null;
  }

  static String? required(String? value, {String? label}) {
    if (value == null || value.trim().isEmpty) {
      final l = L10n.current;
      return l.valFieldRequired(label ?? l.valThisField);
    }
    return null;
  }

  static String? matches(
    String? value,
    String other, {
    String? label,
  }) {
    if (value != other) {
      final l = L10n.current;
      return l.valMismatch(label ?? l.valConfirmation);
    }
    return null;
  }
}
