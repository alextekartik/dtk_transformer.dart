library tekartik_dtk_transformer.src.dtk_transformer_impl;

import 'package:tekartik_barback/transformer.dart';
import 'dart:async';
import 'package:path/path.dart';
import 'package:tekartik_html/html_html5lib.dart';
import 'package:tekartik_html/html.dart';
import 'package:tekartik_html/util/html_tidy.dart';
import 'package:csslib/parser.dart';
import 'package:csslib/visitor.dart';

HtmlProvider html = htmlProviderHtml5Lib;

class DtkTransformer extends Object
    with TransformerMixin
    implements Transformer {
  BarbackSettings settings;
// Any markdown file with one of the following extensions is
// converted to HTML.
  @override
  String get allowedExtensions => ".html";

  // ctr
  DtkTransformer.asPlugin([this.settings]);

  handleElement(Transform transform, AssetId assetId, Element element) async {
    // handle styles
    // Resolve css
    _handleStyle(Element element) async {
      //print(element.text);
      String existingCss = element.text;
      StyleSheet styleSheet = compile(existingCss, polyfill: true);
      CssPrinter printer = new CssPrinter();
      bool hasImport = false;
      _resolveImport(AssetId assetId, StyleSheet styleSheet) async {
        List<TreeNode> childNodes = new List.from(styleSheet.topLevels);
        for (TreeNode node in childNodes) {
          if (node is ImportDirective) {
            hasImport = true;
            String path =
                posix.normalize(join(posix.dirname(assetId.path), node.import));
            AssetId importedAssetId = new AssetId(assetId.package, path);
            if (await transform.hasInput(importedAssetId)) {
              StyleSheet importedStyleSheet = compile(
                  await transform.readInputAsString(importedAssetId),
                  polyfill: true);

              await _resolveImport(importedAssetId, importedStyleSheet);

              int index = styleSheet.topLevels.indexOf(node);
              styleSheet.topLevels
                ..removeAt(index)
                ..insertAll(index, importedStyleSheet.topLevels);
            }
          }
        }
      }
      await _resolveImport(assetId, styleSheet);
      printer.visitTree(styleSheet, pretty: false);
      String newCss = printer.toString();
      if (hasImport || newCss.length < existingCss.length) {
        element.text = newCss;
      }
    }
    if (element.tagName == 'style') {
      await _handleStyle(element);
    }
    ElementList styleElements = element.queryAll(byTag: 'style');
    for (Element element in styleElements) {
      await _handleStyle(element);
    }

    _handleDtkInclude(Element element) async {
      if (element.attributes['property'] == 'dtk-include') {
        String included = element.attributes['content'];
        //print(included);
        // go relative
        // TODO handle other package
        AssetId includedAssetId = new AssetId(assetId.package,
            posix.normalize(join(posix.dirname(assetId.path), included)));
        String includedContent =
            await transform.readInputAsString(includedAssetId);

        bool multiElement = false;
        Element includedElement;

        // where to include
        int index = element.childIndex;

        // try to parse if it fails, wrap it
        try {
          includedElement =
              html.createElementHtml(includedContent, noValidate: true);
        } catch (e) {
          multiElement = true;
          includedElement = html.createElementHtml(
              '<tekartik-dtk-merge>${includedContent}</tekartik-dtk-merge>',
              noValidate: true);
        }

        // Save parent (as element will be removed
        Element parent = element.parent;

        // Insert first so that it has a parent
        parent.children
          ..removeAt(index)
          ..insert(index, includedElement);

        // handle recursively first
        await handleElement(transform, includedAssetId, includedElement);

        // multi element 'un-merge'
        if (multiElement) {
          // save a copy
          List<Element> children = new List.from(includedElement.children);

          parent.children..removeAt(index);
          for (Element child in children) {
            parent.children..insert(index++, child);
          }
        }
      }
    }
    if (element.tagName == 'meta') {
      await _handleDtkInclude(element);
      //throw 'meta not supported as main element';
    } else {
      ElementList list = element.queryAll(byTag: 'meta');
      for (Element element in list) {
        await _handleDtkInclude(element);
      }
    }
  }

  Future apply(Transform transform) async {
    String content = await transform.readPrimaryInputAssetAsString();
    // Parse document as a whole without parsing first
    // to meta content
    Document doc = html.createDocument(html: content);

    await handleElement(transform, transform.primaryInputId, doc.head);
    await handleElement(transform, transform.primaryInputId, doc.body);

    transform.logger.info("in ${transform.primaryInputId}");
    transform.logger.info("in $content");
    // The extension of the output is changed to ".html".
    var id = transform.primaryInputId;

    var output = htmlTidyDocument(doc, new HtmlTidyOption()..indent = '  ');
    String newContent = output.join('\n');
    //transform.consumePrimary();

    //print(newContent);

    transform.addOutputFromString(id, newContent);

    transform.logger.fine("out ${id}");
    transform.logger.fine("out ${newContent}");
  }

  bool isPrimaryPath(String path) {
    return _isPrimaryPath(path);
  }

  // ignore _file.html and _file.part.html
  bool isPrivatePath(String path) {
    String basename = posix.basename(path);
    return (basename.startsWith('_') ||
        (withoutExtension(basename).endsWith('.part')));
  }

  bool _isGeneratedFile(String path) {
    return posix.basenameWithoutExtension(path).endsWith("_gen");
  }

  bool _isPrimaryPath(String path) {
    //print('path :$path');

    String extension = posix.extension(path);
    if (extension != '.html') {
      return false;
    }

    // We handle gen files anywhere
    if (_isGeneratedFile(path)) {
      // ok
      return false;
    } else if (isPrivatePath(path)) {
      // ok
      return false;
    }

    //log.finest('isPrimary: $path');
    return true;
  }

  @override
  Future<bool> isPrimary(AssetId id) async {
    return _isPrimaryPath(id.path);
  }
}
