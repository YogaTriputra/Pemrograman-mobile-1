import 'package:flutter_test/flutter_test.dart';
import 'package:secure_http/utils/validators.dart';

void main() {
  String repeat(String value, int count) => List.filled(count, value).join();

  group('email', () {
    test('accepts anchored addresses and subdomains', () {
      for (final value in [
        'user@example.test',
        'first.last+tag@sub.example.test',
        "o'hara@example.test",
        '${repeat('a', 64)}@example.test',
        'a@${repeat('b', 63)}.test',
      ]) {
        expect(Validators.isValidEmail(value), isTrue, reason: value);
        expect(Validators.validateEmail(value), isNull);
      }
    });

    test('rejects null, whitespace, malformed addresses, and label bounds', () {
      for (final value in <String?>[
        null,
        '',
        ' ',
        'user\t@example.test',
        'user@exam ple.test',
        'user@\u00a0example.test',
        'user@example',
        '@example.test',
        'user@@example.test',
        '.user@example.test',
        'user.@example.test',
        'u..ser@example.test',
        'user@.example.test',
        'user@example..test',
        'user@example.test.',
        'user@-example.test',
        'user@example-.test',
        '${repeat('a', 65)}@example.test',
        'a@${repeat('b', 64)}.test',
        'user@example.test<script>',
        'user\x00@example.test',
      ]) {
        expect(Validators.isValidEmail(value), isFalse, reason: '$value');
        expect(Validators.validateEmail(value), isNotNull);
      }
    });

    test('trims surrounding input only in validateEmail', () {
      for (final value in [
        ' user@example.test',
        'user@example.test ',
        '\tuser@example.test\r\n',
        '\u00a0user@example.test\u00a0',
      ]) {
        expect(Validators.isValidEmail(value), isFalse, reason: value);
        expect(Validators.validateEmail(value), isNull, reason: value);
      }
      expect(Validators.validateEmail(null), 'Alamat email tidak valid.');
      expect(Validators.validateEmail('  '), 'Alamat email tidak valid.');
    });

    test(
      'enforces total length of 254 independently of local and label limits',
      () {
        final domain = List.filled(3, repeat('b', 63)).join('.');
        final atLimit = '${repeat('a', 62)}@$domain';
        expect(atLimit.length, 254);
        expect(Validators.isValidEmail(atLimit), isTrue);
        expect(Validators.isValidEmail('a$atLimit'), isFalse);
      },
    );
  });

  group('text', () {
    test('checks emptiness without changing input', () {
      for (final value in <String?>[null, '', ' \t\r\n', '\u00a0']) {
        expect(Validators.isNotEmpty(value), isFalse);
        expect(Validators.validateText(value), isNotNull);
      }
      expect(Validators.isNotEmpty('  hello  '), isTrue);
      expect(Validators.validateText('  hello  '), isNull);
    });

    test('supports module parameter names and Indonesian field errors', () {
      expect(Validators.validateText(null), 'Field wajib diisi.');
      expect(
        Validators.validateText(' ', fieldName: 'Nama'),
        'Nama wajib diisi.',
      );
      expect(
        Validators.validateText(
          ' ab ',
          fieldName: 'Nama',
          minLength: 2,
          maxLength: 2,
        ),
        isNull,
      );
      for (final value in ['a', 'abcd']) {
        expect(
          Validators.validateText(
            value,
            fieldName: 'Nama',
            minLength: 2,
            maxLength: 3,
          ),
          'Nama harus memiliki panjang 2 hingga 3 karakter.',
        );
      }
      expect(
        Validators.validateText('a', minLength: 3, maxLength: 2),
        isNotNull,
      );
      expect(
        Validators.validateText(
          'ab',
          minLength: 3,
          maxLength: 4,
          min: 2,
          max: 2,
        ),
        isNull,
      );
    });

    test('uses trimmed length and inclusive default and custom bounds', () {
      expect(Validators.hasValidLength(null), isFalse);
      expect(Validators.hasValidLength(' '), isFalse);
      expect(Validators.hasValidLength(' a '), isTrue);
      expect(Validators.hasValidLength(repeat('a', 100)), isTrue);
      expect(Validators.hasValidLength(repeat('a', 101)), isFalse);
      expect(Validators.hasValidLength(' ab ', min: 2, max: 2), isTrue);
      expect(Validators.hasValidLength('a', min: 2, max: 3), isFalse);
      expect(Validators.hasValidLength('abcd', min: 2, max: 3), isFalse);
      expect(Validators.hasValidLength('', min: 0, max: 0), isTrue);
      expect(Validators.hasValidLength('a', min: -1), isFalse);
      expect(Validators.hasValidLength('a', min: 3, max: 2), isFalse);
      expect(Validators.validateText(' ab ', min: 2, max: 2), isNull);
      expect(Validators.validateText('a', min: 2), isNotNull);
      expect(Validators.validateText(repeat('a', 101)), isNotNull);
      expect(Validators.validateText('a', min: 3, max: 2), isNotNull);
    });
  });

  group('HTML encoding', () {
    test('trims and escapes ampersands before brackets and both quotes', () {
      expect(
        Validators.sanitize('  <script a="x" b=\'y\'>&</script>  '),
        '&lt;script a=&quot;x&quot; b=&#39;y&#39;&gt;&amp;&lt;/script&gt;',
      );
      expect(Validators.sanitize(''), '');
      expect(Validators.sanitize('  plain text  '), 'plain text');
    });

    test('encodes existing and numeric entities rather than trusting them', () {
      expect(
        Validators.sanitize('&lt;&amp;&#39;&#x3c;'),
        '&amp;lt;&amp;amp;&amp;#39;&amp;#x3c;',
      );
      expect(Validators.sanitize(Validators.sanitize('<')), '&amp;lt;');
    });

    test('is encoding, not SQL protection or password normalization', () {
      expect(Validators.sanitize("' OR 1=1 --"), '&#39; OR 1=1 --');
      expect(Validators.validateText("' OR 1=1 --"), isNull);
      const password = ' Abcdef1& ';
      expect(Validators.validatePassword(password), isNull);
      expect(password, ' Abcdef1& ');
    });
  });

  group('phone', () {
    test('accepts only ASCII digits at inclusive 10 to 13 limits', () {
      for (var length = 10; length <= 13; length++) {
        expect(Validators.validatePhone(repeat('0', length)), isNull);
      }
      for (final value in <String?>[
        null,
        '',
        repeat('1', 9),
        repeat('1', 14),
        '+1234567890',
        '123 4567890',
        '123-4567890',
        '1234567890\n',
        ' 1234567890',
        '１２３４５６７８９０',
        '123456789a',
      ]) {
        expect(Validators.validatePhone(value), isNotNull, reason: '$value');
      }
    });
  });

  group('URL', () {
    test('accepts absolute HTTP and HTTPS with hosts and valid ports', () {
      for (final value in [
        'https://example.test',
        'http://localhost:8080/path?q=a%20b#fragment',
        'https://127.0.0.1:65535/',
        'http://[::1]/',
        'HTTPS://example.test/path',
        'https://example.test:1/',
      ]) {
        expect(Validators.validateUrl(value), isNull, reason: value);
      }
    });

    test('rejects missing hosts, credentials, controls, and invalid URIs', () {
      for (final value in <String?>[
        null,
        '',
        'example.test',
        '//example.test',
        '/relative',
        'ftp://example.test',
        'javascript:alert(1)',
        'https:',
        'https:///path',
        'https://',
        'https://user:password@example.test',
        'https://user@example.test',
        'https://@example.test',
        ' https://example.test',
        'https://example.test ',
        'https://example.test/\npath',
        'https://example.test/\x00',
        'https://example.test/\x7f',
        'https://example.test/%0a',
        'https://example.test/%0D',
        'https://example.test/%7f',
        'https://example.test\\@evil.test',
        'https://[invalid]/',
        'https://example.test:abc',
        'https://example.test:0',
        'https://example.test:65536',
      ]) {
        expect(Validators.validateUrl(value), isNotNull, reason: '$value');
      }
    });
  });

  group('password', () {
    test('requires length, uppercase, digit, and a nonwhitespace symbol', () {
      for (final value in <String?>[
        null,
        '',
        '        ',
        'Abcde1!',
        'abcdef1!',
        'Abcdefg!',
        'Abcdef12',
        'Abcdef1 ',
      ]) {
        expect(Validators.validatePassword(value), isNotNull, reason: '$value');
      }
      for (final value in [
        'Abcdef1!',
        'ABCDEFG1!',
        'Abcdef1&',
        'Abcdef1<',
        "Abcdef1'",
        ' Abcd1! ',
        'Abcdef1!\n',
        'A1!${repeat('a', 200)}',
      ]) {
        expect(Validators.validatePassword(value), isNull, reason: value);
      }
    });
  });
}
