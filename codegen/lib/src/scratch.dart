// import 'dart:async';
//
// import 'package:analyzer/dart/element/element.dart';
// import 'package:build/build.dart';
// import 'package:source_gen/source_gen.dart';
// import 'package:wrench_annotations/wrench_annotations.dart';
// import 'package:wrench_generators/src/code_gen.dart';
//
// class ScreenStateGenerator extends GeneratorForAnnotation<ScreenState> {
//   @override
//   FutureOr<String> generateForAnnotatedElement(
//     Element element,
//     ConstantReader annotation,
//     BuildStep buildStep,
//   ) {
//     return CodeGen.screenState(element, annotation, buildStep);
//   }
// }

// import 'dart:async';
//
// import 'package:analyzer/dart/element/element.dart';
// import 'package:build/build.dart';
// import 'package:source_gen/source_gen.dart';
// import 'package:wrench_annotations/wrench_annotations.dart';
// import 'package:wrench_generators/src/code_gen.dart';
//
// class ScreenServiceGenerator extends GeneratorForAnnotation<ScreenService> {
//   @override
//   FutureOr<String> generateForAnnotatedElement(
//     Element element,
//     ConstantReader annotation,
//     BuildStep buildStep,
//   ) {
//     return CodeGen.screenService(element, annotation, buildStep);
//   }
// }

// ######### build.yaml ##########
// screen_state:
// import: 'package:wrench_generators/builder.dart'
// builder_factories: [ 'screenStateBuilder' ]
// build_extensions: { '.dart': ['.screen_state.g.part'] }
// auto_apply: dependents
// build_to: cache
// applies_builders: ['source_gen|combining_builder']
//
// screen_service:
// import: 'package:wrench_generators/builder.dart'
// builder_factories: [ 'screenServiceBuilder' ]
// build_extensions: { '.dart': [ '.screen_service.g.part' ] }
// auto_apply: dependents
// build_to: cache
// applies_builders: [ 'source_gen|combining_builder' ]
