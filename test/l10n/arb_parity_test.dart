import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

Set<String> keys(String path) => (jsonDecode(File(path).readAsStringSync()) as Map<String, dynamic>)
    .keys
    .where((k) => !k.startsWith('@'))
    .toSet();

void main() {
  test('en and id have the same message keys', () {
    final en = keys('lib/l10n/app_en.arb');
    final id = keys('lib/l10n/app_id.arb');
    expect(id.difference(en), isEmpty, reason: 'only in id');
    expect(en.difference(id), isEmpty, reason: 'only in en');
  });
}
