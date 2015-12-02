library tekartik_dtk_transformer.test.io_test_common;

import 'dart:mirrors';
export 'package:dev_test/test.dart';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get testScriptPath => _TestUtils.scriptPath;
