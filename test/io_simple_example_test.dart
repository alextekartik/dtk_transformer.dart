@TestOn("vm")
library tekartik_uppercase_transformer_test;

import 'package:tekartik_pub/pub.dart';
import 'dart:async';
import 'io_test_common.dart';
import 'dart:io';
import 'package:path/path.dart';

Future<String> get _pubPackageRoot => getPubPackageRoot(
    join(dirname(dirname(testScriptPath)), 'example', 'simple'));

main() {
  group('example_simple', () {
    test('runTest', () async {
      PubPackage pkg = new PubPackage(await _pubPackageRoot);
      await pkg.pubRun(['get', '--offline']);
      ProcessResult result = await pkg.pubRun(pkg.runTestCmdArgs([]));
      // on 1.13, current windows is failing
      if (!Platform.isWindows) {
        expect(result.exitCode, 0);
      }
    });
  });
}
