// Copyright 2013 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in_web/google_sign_in_web.dart';
import 'package:web/web.dart' as web;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Registering the plugin does not request the GIS SDK', () async {
    GoogleSignInPlugin();
    // Give any fire-and-forget SDK load a chance to append its script.
    await Future<void>.delayed(Duration.zero);
    expect(
      web.document.querySelector(
        'script[src="https://accounts.google.com/gsi/client"]',
      ),
      isNull,
    );
  });
}
