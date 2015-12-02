library tekartik_dtk_transformer;

import 'package:tekartik_barback/transformer_barback.dart';
import 'src/dtk_transformer_impl.dart' as impl;

///
/// The main barback entry point
///
class DtkBarbackTransformer extends BarbackTransformer {
  //final BarbackSettings settings;
  final impl.DtkTransformer transformer;

  DtkBarbackTransformer.asPlugin([BarbackSettings settings])
      : transformer = new impl.DtkTransformer.asPlugin(settings);
}
