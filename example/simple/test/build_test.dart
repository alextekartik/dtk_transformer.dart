@TestOn("vm")
library tekartik_uppercase_transformer_test;

import 'package:tekartik_transformer/transformer_memory.dart';
//import 'package:barback/barback.dart' show Asset, AssetSet, AssetId;
import 'package:tekartik_pub/pub.dart';
//import 'package:tekartik_common/project_utils.dart';
//import 'transformer_test.dart' as _test;
import 'dart:async';
import 'package:dev_test/test.dart';
import 'package:process_run/process_run.dart';
import 'package:process_run/dartbin.dart';
import 'dart:io';
import 'package:path/path.dart';
import 'dart:mirrors';

class _TestUtils {
  static final String scriptPath =
      (reflectClass(_TestUtils).owner as LibraryMirror).uri.toFilePath();
}

String get testScriptPath => _TestUtils.scriptPath;

Future<String> get _pubPackageRoot => getPubPackageRoot(testScriptPath);

main() {
  group('build', () {
    //_test.Context ctx;
    test('runBuild', () async {
      PubPackage pkg = new PubPackage(await _pubPackageRoot);
      //print(pkg);
      ProcessResult result = await pkg.pubRun(['build', 'example']);

      stdout.writeln(result.stdout);
      stderr.writeln(result.stderr);
      // on 1.13, current windows is failing
      if (!Platform.isWindows) {
        expect(result.exitCode, 0);
      }

      // expect to find the result in build
      String outPath = join(pkg.path, 'build', 'example');
      expect(
          new File(join(outPath, 'simple.html')).readAsStringSync(),
          '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <title></title>
</head>
<body>
</body>
</html>''');
    });
  });
}
