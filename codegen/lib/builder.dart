import 'package:build/build.dart';
import 'package:codegen/src/app_model_generator.dart';
import 'package:codegen/src/screen_service_generator.dart';
import 'package:codegen/src/screen_state_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder appModelLibraryBuilder(BuilderOptions options) =>
    LibraryBuilder(AppModelGenerator(), generatedExtension: '.model.dart');

Builder screenStateLibraryBuilder(BuilderOptions options) =>
    LibraryBuilder(ScreenStateGenerator(), generatedExtension: '.state.dart');

Builder screenServiceLibraryBuilder(BuilderOptions options) =>
    LibraryBuilder(ScreenServiceGenerator(),
        generatedExtension: '.service.dart');

// Builder screenStateBuilder(BuilderOptions options) =>
//     SharedPartBuilder([ScreenStateGenerator()], 'screen_state');
//
// Builder screenServiceBuilder(BuilderOptions options) =>
//     SharedPartBuilder([ScreenServiceGenerator()], 'screen_service');
