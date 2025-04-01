import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'filterable_generator.dart';

Builder filterableBuilder(BuilderOptions options) =>
    PartBuilder([FilterableGenerator()], '.filterable.g.dart');
