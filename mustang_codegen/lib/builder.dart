import 'package:build/build.dart';
import 'package:mustang_codegen/src/app_model_generator.dart';
import 'package:mustang_codegen/src/app_serializer_builder.dart';
import 'package:mustang_codegen/src/screen_generator.dart';
import 'package:mustang_codegen/src/screen_service_generator.dart';
import 'package:mustang_codegen/src/screen_state_generator.dart';
import 'package:source_gen/source_gen.dart';

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
