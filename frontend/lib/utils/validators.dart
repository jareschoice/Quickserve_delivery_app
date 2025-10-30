class Validators {
  static String? required(String? v) => (v==null || v.trim().isEmpty) ? 'Required' : null;
  static String? email(String? v) {
    if (v==null || v.trim().isEmpty) return 'Required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }
  static String? min6(String? v) => (v!=null && v.length>=6) ? null : 'Min 6 chars';
}
