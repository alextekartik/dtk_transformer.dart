library transformer_test;

import 'package:tekartik_html/html.dart';

import 'package:dev_test/test.dart';
import 'dart:async';
import 'package:tekartik_dtk_transformer/src/dtk_transformer_impl.dart';
import 'package:tekartik_barback/transformer_memory.dart';

String PACKAGE_NAME = "terkartik_html_transformer";

main() {
  defineTests(new MemoryTransformerContext());
}

defineTests(MemoryTransformerContext ctx) {
  group('dtk_transformer_impl', () {
    //_test.Context ctx;

    DtkTransformer transformer;

    setUp(() async {
      //ctx = await _test.Context.setUp();
      transformer = new DtkTransformer.asPlugin();
    });

    Future checkSingleContent(Transform transform,
        {String path, String content}) async {
      expect(ctx.outputs.length, 1);
      MemoryAsset output = ctx.outputs.first;
      if (path != null) {
        expect(output.id.path, path);
      }
      if (content != null) {
        String readContent = await transform.readInputAsString(output.id);
        expect(readContent, content);
      }
    }

    test('isPrimary', () async {
      AssetId id = new AssetId(null, "test.html");
      expect(await transformer.isPrimary(id), isTrue);
      id = new AssetId(null, "_test.html");
      expect(await transformer.isPrimary(id), isFalse);
      id = new AssetId(null, "test.part.html");
      expect(await transformer.isPrimary(id), isFalse);
    });
    test('read', () async {
      AssetId assetId = ctx.addStringAsset("test.html",
          "<!DOCTYPE html><html><head></head><body></body></html>");
      Transform transform = ctx.newTransform(assetId);
      expect(await transformer.isPrimary(assetId), isTrue);
      await transformer.apply(transform);
      await checkSingleContent(transform,
          path: "test.html",
          content: '<!DOCTYPE html>\n'
              '<html>\n'
              '<head>\n'
              '  <meta charset="utf-8">\n'
              '  <title></title>\n'
              '</head>\n'
              '<body></body>\n'
              '</html>');
    });

    test('basic', () async {
      String content = '<div></div>';
      AssetId assetId = ctx.addStringAsset('basic.html', content);
      Transform transform = ctx.newTransform(null);
      Element element = html.createElementHtml(content, noValidate: true);
      await transformer.handleElement(transform, assetId, element);
      expect(element.outerHtml, content);
    });

    test('include_no_parent', () async {
      String include = '<meta property="dtk-include" content="included.html">';

      AssetId assetId = ctx.addStringAsset('dtk-include.html', include);

      ctx.addStringAsset('included.html', '<p>Simple content</p>');
      Transform transform = ctx.newTransform(null);
      Element element = html.createElementHtml(include, noValidate: true);
      // Just to set the transform but not used!

      try {
        await transformer.handleElement(transform, assetId, element);
      } catch (_) {}
    });

    test('include', () async {
      String include =
          '<div><meta property="dtk-include" content="included.html"></div>';

      AssetId assetId = ctx.addStringAsset('dtk-include.html', include);

      ctx.addStringAsset('included.html', '<p>Simple content</p>');
      Transform transform = ctx.newTransform(null);
      Element element = html.createElementHtml(include, noValidate: true);
      // Just to set the transform but not used!

      await transformer.handleElement(transform, assetId, element);
      expect(element.outerHtml, '<div><p>Simple content</p></div>');
    });

    test('include_multi_element', () async {
      String include =
          '<div><meta property="dtk-include" content="included.html"></div>';

      AssetId assetId = ctx.addStringAsset('dtk-include.html', include);

      ctx.addStringAsset('included.html', '<p>element1</p><p>element2</p>');
      Transform transform = ctx.newTransform(null);
      Element element = html.createElementHtml(include, noValidate: true);
      // Just to set the transform but not used!

      await transformer.handleElement(transform, assetId, element);
      expect(element.outerHtml, '<div><p>element1</p><p>element2</p></div>');
    });

    test('include_sub_element', () async {
      String include =
          '<div><meta property="dtk-include" content="included.html"></div>';

      AssetId assetId = ctx.addStringAsset('dtk-include.html', include);

      ctx.addStringAsset('included.html',
          '<meta property="dtk-include" content="sub_included.html">');
      ctx.addStringAsset('sub_included.html', '<p>element</p>');
      Transform transform = ctx.newTransform(null);
      Element element = html.createElementHtml(include, noValidate: true);
      // Just to set the transform but not used!

      await transformer.handleElement(transform, assetId, element);
      expect(element.outerHtml, '<div><p>element</p></div>');
    });

    test('read_include', () async {
      AssetId assetId = ctx.addStringAsset("test.html",
          '<!DOCTYPE html><html><head><meta property="dtk-include" content="head_included.html"></head><body><meta property="dtk-include" content="body_included.html"></body></html>');
      ctx.addStringAsset(
          'head_included.html', '<meta property="name" content="Hello">');
      ctx.addStringAsset('body_included.html', "<p>World</p>");
      Transform transform = ctx.newTransform(assetId);
      expect(await transformer.isPrimary(assetId), isTrue);
      await transformer.apply(transform);
      await checkSingleContent(transform,
          path: "test.html",
          content: '<!DOCTYPE html>\n'
              '<html>\n'
              '<head>\n'
              '  <meta charset="utf-8">\n'
              '  <title></title>\n'
              '  <meta property="name" content="Hello">\n'
              '</head>\n'
              '<body>\n'
              '  <p>World</p>\n'
              '</body>\n'
              '</html>');
    });

    test('style_short', () async {
      String content = '<style>body{opacity:0}</style>';
      AssetId assetId = ctx.addStringAsset('basic.html', content);
      Transform transform = ctx.newTransform(null);
      Element element = html.createElementHtml(content, noValidate: true);
      await transformer.handleElement(transform, assetId, element);
      expect(element.outerHtml, '<style>body{opacity:0}</style>');
    });

    test('style_long', () async {
      String content = '<style>body {  opacity: 0;  }</style>';
      AssetId assetId = ctx.addStringAsset('basic.html', content);
      Transform transform = ctx.newTransform(null);
      Element element = html.createElementHtml(content, noValidate: true);
      await transformer.handleElement(transform, assetId, element);
      expect(element.outerHtml, '<style>body { opacity: 0; }</style>');
    });

    test('style_import', () async {
      String content = '<style>@import url(part.html)";</style>';
      AssetId assetId = ctx.addStringAsset('basic.html', content);
      ctx.addStringAsset('part.html', 'body{opacity:0}');
      Transform transform = ctx.newTransform(null);
      Element element = html.createElementHtml(content, noValidate: true);
      await transformer.handleElement(transform, assetId, element);
      expect(element.outerHtml, '<style>body { opacity: 0; }</style>');
    });
  });
  //useVMConfiguration();

/*
  group('Transform', () {
    HtmlTransformerImpl tsfmr = htmlTransformerImpl;
    String projectTopPath;
    TransformerContext context;
    setUp(() async {
      //clearOutDataPath();
      projectTopPath = await getPubPackageRoot(testScriptPath);
      context = new TransformerContext(projectTopPath);
    });


    Future checkTransformContent(String basename, String expectedContent) async {
      String path = prepareTestOutPath();
      Transform tsfm = new Transform(context, getAsset(basename));
      return tsfmr.apply(tsfm).then((_) {
        //print(builder.includesContent);
        //print(builder.outputs);
        return new File(join(path,
                HtmlBuilder.getAutoGenBasename(basename) + ".html"))
            .readAsString()
            .then((String content) {
          expect(content, expectedContent);
        });
      });
    }

    test('simple 2', () {
      return checkTransformContent('simple.html',
          '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body>\n</body></html>');
    });

    test('simple meta var', () {
      return checkTransformContent('meta_var.html',
          '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body>demo</body></html>');
    });

    test('dtk-include', () {
      return checkTransformContent('dtk-include.html',
          '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body><p>Simple content</p></body></html>');
    });

   solo_test('include', () {
      return checkTransformContent('include.html',
          '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body><p>Simple content</p></body></html>');
    });

    // This test failed, cannot include html
    test('include html', () {
      return checkTransformContent('include_html.html',
              '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body><p>Simple content</p></body></html>')
          .catchError((_) {});
    });
    test('include_in_head_bad', () {
      return checkTransformContent(
          'include_in_head_bad.html',
          '''
<!DOCTYPE html><html><head><meta charset="utf-8"><title></title>
</head><body><included src="included_in_head.html">\n
</included></body></html>''');
    });
    test('include_in_head_meta', () {
      return checkTransformContent(
          'include_in_head_meta.html',
          '''
<!DOCTYPE html><html><head><meta charset="utf-8"><title></title><meta name="description" content="simple content">\n
</head><body>
</body></html>''');
    });

    test('include_in_head_title', () {
      return checkTransformContent(
          'include_in_head_title.html',
          '''
<!DOCTYPE html><html><head><meta charset="utf-8"><title>included_in_head_title</title>\n
</head><body>\n
</body></html>''');
    });

    test('include_in_head_more', () {
      return checkTransformContent(
          'include_in_head_more.html',
          '''
<!DOCTYPE html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>test</title>\n
</head><body>
</body></html>''');
    });

    test('include_multi', () {
      return checkTransformContent('include_multi.html',
          '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body><p>Simple content</p><p>Simple content</p></body></html>');
    });

    test('multi_target_vars', () {
      Transform tsfm =
          new Transform(context, getAsset('multi_target_vars.html'));
      return tsfmr.apply(tsfm).then((_) {
        //print(builder.includesContent);
        //print(builder.outputs);
        return new File(outDataFilenamePath("target1_gen.html"))
            .readAsString()
            .then((String content) {
          expect(content,
              '<!DOCTYPE html><html><head><meta charset="utf-8">\n\n\n\n<title>demo1</title></head><body>\n</body></html>');

          return new File(outDataFilenamePath("target2_gen.html"))
              .readAsString()
              .then((String content) {
            expect(content,
                '<!DOCTYPE html><html><head><meta charset="utf-8">\n\n\n\n<title>demo2</title></head><body>\n</body></html>');
          });
        });
      });
    });

    test('include_notag', () {
      bool failed = false;
      return checkTransformContent('include_notag.html', '')
          .catchError((Exception e) {
        expect(e.toString().contains("external tag expect"), isTrue);
        failed = true;
      }).then((_) {
        expect(failed, isTrue);
      });
    });

    test('include_package', () {
      //return checkTransformContent('include_package.html', '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body><script type="application/dart" src="app.dart"></script><script src="packages/browser/dart.js"></script><script src="packages/browser/interop.js"></script></body></html>');
      return checkTransformContent('include_package.html',
          '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body><script type="application/dart" src="app.dart"></script><script src="packages/browser/dart.js"></script></body></html>');
    });

    test('include_attr_var', () {
      return checkTransformContent('include_attr_var.html',
          '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body><div><span class="hello yeap"></span></div></body></html>');
    });

    test('data_attr', () {
      return checkTransformContent(
          'simple_data_attr.html',
          '''
<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body><p class="hello"></p>
</body></html>''');
    });

    test('subinclude', () {
      return checkTransformContent('subinclude.html',
          '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body><div><p>Simple content</p></div></body></html>');
    });

    test('vars', () {
      return checkTransformContent('include_vars.html',
          '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body><div class="hello"><div><span class="hello yeap"></span></div></div>\n</body></html>');
    });

    test('merge', () {
      return checkTransformContent('merge.html',
          '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body><ul><li>choice 1</li><li>choice 2</li></ul>\n</body></html>');
    });

    //    test('demo', () {
    //
    //      return checkTransformContent('demo.html', '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body><ul><li>choice 1</li><li>choice 2</li></ul>\n</body></html>');
    //
    //    });

    test('multi_target', () {
      Transform tsfm = new Transform(context, getAsset('multi_target.html'));
      return tsfmr.apply(tsfm).then((_) {
        //print(builder.includesContent);
        //print(builder.outputs);
        return new File(outDataFilenamePath("target1_gen.html"))
            .readAsString()
            .then((String content) {
          expect(content,
              '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body>\n</body></html>');

          return new File(outDataFilenamePath("target2_gen.html"))
              .readAsString()
              .then((String content) {
            expect(content,
                '<!DOCTYPE html><html><head><meta charset="utf-8"><title></title></head><body>\n</body></html>');
          });
        });
      });
    });

    test('js', () {
      //debugQuickLogging(Level.FINEST);
      Transform tsfm = new Transform(context, getAsset('js.html'));
      return tsfmr.apply(tsfm).then((_) {
        //print(builder.includesContent);
        //print(builder.outputs);
        return new File(outDataFilenamePath("js_dart_gen.html"))
            .readAsString()
            .then((String content) {
          expect(
              content,
              '''
<!DOCTYPE html><html><head><meta charset="utf-8"><title></title><script type="application/dart" src="app.dart"></script><script src="packages/browser/dart.js"></script>
'''
//<script src="packages/browser/interop.js"></script>
              '''
\n</head><body>\n</body></html>'''
              '');

          return new File(outDataFilenamePath("js_gen.html"))
              .readAsString()
              .then((String content) {
            expect(
                content,
                '''
<!DOCTYPE html><html><head><meta charset="utf-8"><title></title><script>
(function() {
  var script = document.createElement("script");
  script.type = "text/javascript";
  script.src = app.js;
  document.getElementsByTagName("head")[0].appendChild(script);
}
</script>\n
</head><body>
</body></html>''');
          });
        });
      });
    });
      });
    */
}
