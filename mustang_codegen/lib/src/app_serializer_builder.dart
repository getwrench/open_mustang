import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:mustang_codegen/src/utils.dart';

class AppSerializerBuilder implements Builder {
  static const String modelsPath = 'src/models';
  static const String serializerPath = 'lib/$modelsPath';
  static const String serializerFile = 'serializers.dart';

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['$modelsPath/$serializerFile'],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    final List<String> modelNames = [];
    final List<String> modelStrNames = [];
    final List<String> imports = [];
    final StringBuffer deserializerCases = StringBuffer();

    await for (AssetId assetId
        in buildStep.findAssets(Glob('$serializerPath/*.model.dart'))) {
      LibraryElement library = await buildStep.resolver.libraryFor(assetId);
      String modelName = library.topLevelElements.first.name ?? '';
      if (modelName.isNotEmpty) {
        modelNames.add(modelName);
        modelStrNames.add("'$modelName'");
        imports.add("import '${assetId.uri}';");
      }
    }

    // get the current app package
    String pkgName = buildStep.inputId.package;
    AssetId outFile = AssetId(pkgName, '$serializerPath/$serializerFile');

    // If an app has 2nd serializer (usually the case when there is a
    // separate repo with it's own models and serializer for all those models,
    // say repo A), then the consumer of repo A needs to have an `import A`
    // in the generated serializer.dart
    String? customSerializerPackage = await Utils.getCustomSerializerPackage();
    if (customSerializerPackage != null &&
        !customSerializerPackage.startsWith('package:$pkgName')) {
      imports.add("import '$customSerializerPackage';");
    }

    modelNames.sort();
    modelStrNames.sort();
    for (String modelName in modelNames) {
      deserializerCases.writeln(_deserializeForModel(modelName));
    }

    String out = _generate(
      imports.join('\n'),
      modelNames.join(',\n  '),
      modelStrNames.join(',\n  '),
      deserializerCases.toString(),
    );
    await buildStep.writeAsString(outFile, out);
  }

  static String _generate(
    String imports,
    String models,
    String strModels,
    String deserializers,
  ) {
    return '''
${Utils.defaultGeneratorComment} 

// **************************************************************************
// AppSerializerBuilder
// **************************************************************************
   
import 'dart:convert';    
import 'package:built_collection/built_collection.dart';
import 'package:built_value/serializer.dart';
import 'package:built_value/standard_json_plugin.dart';
$imports

part 'serializers.g.dart';

@SerializersFor([
  $models
])
final Serializers serializers = (_\$serializers.toBuilder()
      ..addPlugin(
        StandardJsonPlugin(),
      ))
    .build();

final List<String> serializerNames = [
  $strModels
];
    
void json2Type(void Function<T>(T t) update, String modelName, String jsonStr) {
  switch (modelName) {
  $deserializers
  }
}''';
  }

  static String _deserializeForModel(String modelName) {
    return '''
    case '$modelName':
      var model = serializers.deserializeWith(
        $modelName.serializer,
        json.decode(jsonStr),
      );
      if (model != null) {
        update(model);
      }
      return;''';
  }
}
