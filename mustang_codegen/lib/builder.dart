import 'package:build/build.dart';
import 'package:mustang_codegen/src/app_serializer_builder.dart';
import 'package:mustang_codegen/src/aspect_generator/app_aspect_generator.dart';
import 'package:mustang_codegen/src/model_generator/app_model_generator.dart';
import 'package:mustang_codegen/src/screen_generator/screen_generator.dart';
import 'package:mustang_codegen/src/service_generator/screen_service_generator.dart';
import 'package:mustang_codegen/src/state_generator/screen_state_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder appAspectLibraryBuilder(BuilderOptions options) => LibraryBuilder(
      AppAspectGenerator(),
      generatedExtension: '.aspect.dart',
    );

Builder appModelLibraryBuilder(BuilderOptions options) => LibraryBuilder(
      AppModelGenerator(),
      generatedExtension: '.model.dart',
    );

Builder screenStateLibraryBuilder(BuilderOptions options) => LibraryBuilder(
      ScreenStateGenerator(),
      generatedExtension: '.state.dart',
    );

Builder screenServiceLibraryBuilder(BuilderOptions options) => LibraryBuilder(
      ScreenServiceGenerator(),
      generatedExtension: '.service.dart',
    );

Builder screenLibraryBuilder(BuilderOptions options) => LibraryBuilder(
      ScreenGenerator(),
      generatedExtension: '.screen.dart',
    );

Builder appSerializerBuilder(BuilderOptions options) => AppSerializerBuilder();
