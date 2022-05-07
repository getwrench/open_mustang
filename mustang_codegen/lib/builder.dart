import 'package:build/build.dart';
import 'package:mustang_codegen/src/app_serializer_builder.dart';
import 'package:mustang_codegen/src/aspect_generator/app_aspect_generator.dart';
import 'package:mustang_codegen/src/model_generator/app_model_generator.dart';
import 'package:mustang_codegen/src/screen_generator/screen_generator.dart';
import 'package:mustang_codegen/src/service_generator/screen_service_generator.dart';
import 'package:mustang_codegen/src/state_generator/screen_state_generator.dart';
import 'package:source_gen/source_gen.dart';

/// Generates code for @Around, @Before, @After annotations
Builder appAspectLibraryBuilder(BuilderOptions options) => LibraryBuilder(
      AppAspectGenerator(),
      generatedExtension: '.aspect.dart',
    );

/// Generates [built_value] class for @appModel annotation
Builder appModelLibraryBuilder(BuilderOptions options) => LibraryBuilder(
      AppModelGenerator(),
      generatedExtension: '.model.dart',
    );

/// Generates code for @State annotation
Builder screenStateLibraryBuilder(BuilderOptions options) => LibraryBuilder(
      ScreenStateGenerator(),
      generatedExtension: '.state.dart',
    );

/// Generates code for @ScreenService annotation
Builder screenServiceLibraryBuilder(BuilderOptions options) => LibraryBuilder(
      ScreenServiceGenerator(),
      generatedExtension: '.service.dart',
    );

/// Validates screens
Builder screenLibraryBuilder(BuilderOptions options) => LibraryBuilder(
      ScreenGenerator(),
      generatedExtension: '.screen.dart',
    );

/// Generates built_value serializer
Builder appSerializerBuilder(BuilderOptions options) => AppSerializerBuilder();
