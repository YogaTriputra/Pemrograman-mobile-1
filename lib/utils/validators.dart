class Validators {
  Validators._();

  static bool isValidEmail(String? value) {
    if (value == null || value.isEmpty || value.length > 254) return false;
    if (RegExp(r'\s').hasMatch(value)) return false;
    final match = RegExp(
      r"^([A-Za-z0-9!#$%&'*+/=?^_`{|}~.-]+)@([A-Za-z0-9.-]+)$",
    ).firstMatch(value);
    if (match == null || match.end != value.length) return false;
    final local = match.group(1)!;
    final domain = match.group(2)!;
    if (local.length > 64 ||
        local.startsWith('.') ||
        local.endsWith('.') ||
        local.contains('..')) {
      return false;
    }
    final labels = domain.split('.');
    return labels.length >= 2 &&
        labels.every(
          (label) =>
              label.isNotEmpty &&
              label.length <= 63 &&
              !label.startsWith('-') &&
              !label.endsWith('-'),
        );
  }

  static bool isNotEmpty(String? value) =>
      value != null && value.trim().isNotEmpty;

  static bool hasValidLength(String? value, {int min = 1, int max = 100}) {
    if (value == null || min < 0 || max < min) return false;
    final length = value.trim().length;
    return length >= min && length <= max;
  }

  static String sanitize(String value) => value
      .trim()
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&#39;');

  static String? validateText(
    String? value, {
    String fieldName = 'Field',
    int minLength = 1,
    int maxLength = 100,
    int? min,
    int? max,
  }) {
    if (!isNotEmpty(value)) return '$fieldName wajib diisi.';
    final minimum = min ?? minLength;
    final maximum = max ?? maxLength;
    if (!hasValidLength(value, min: minimum, max: maximum)) {
      return '$fieldName harus memiliki panjang $minimum hingga $maximum karakter.';
    }
    return null;
  }

  static String? validateEmail(String? value) =>
      isValidEmail(value?.trim()) ? null : 'Alamat email tidak valid.';

  static String? validatePhone(String? value) {
    if (value == null ||
        value.length < 10 ||
        value.length > 13 ||
        RegExp(r'[^0-9]').hasMatch(value)) {
      return 'Nomor telepon harus terdiri dari 10 hingga 13 digit.';
    }
    return null;
  }

  static String? validateUrl(String? value) {
    const error = 'URL harus berupa alamat HTTP atau HTTPS yang valid.';
    if (value == null ||
        value.isEmpty ||
        RegExp(r'[\s\x00-\x1f\x7f\\]').hasMatch(value) ||
        RegExp(r'^[^:]+://[^/?#]*@').hasMatch(value) ||
        RegExp(r'%(?![0-9a-fA-F]{2})').hasMatch(value) ||
        RegExp(r'[<>"{}|^`]').hasMatch(value) ||
        RegExp(
          r'%(?:0[0-9a-f]|1[0-9a-f]|7f)',
          caseSensitive: false,
        ).hasMatch(value)) {
      return error;
    }
    try {
      final uri = Uri.tryParse(value);
      if (uri == null ||
          (uri.scheme != 'http' && uri.scheme != 'https') ||
          !uri.hasAuthority ||
          uri.host.isEmpty ||
          uri.userInfo.isNotEmpty ||
          uri.authority.contains('@') ||
          (uri.hasPort && (uri.port < 1 || uri.port > 65535))) {
        return error;
      }
      return null;
    } on FormatException {
      return error;
    }
  }

  static String? validatePassword(String? value) {
    if (!isNotEmpty(value) ||
        value!.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value) ||
        !RegExp(r'[^A-Za-z0-9\s]').hasMatch(value)) {
      return 'Kata sandi harus memiliki minimal 8 karakter, huruf besar, angka, dan simbol.';
    }
    return null;
  }
}
