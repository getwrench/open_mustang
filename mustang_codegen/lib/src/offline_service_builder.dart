import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:mustang_codegen/src/utils.dart';
import 'package:source_gen/source_gen.dart';

class OfflineServiceBuilder extends Builder {
  static const String _sharedServicePath = 'src/shared_services';
  static const String _offlineServicePathFromRoot = 'lib/$_sharedServicePath';
  static const String _offlineServicePath = 'offline_service.dart';

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['$_sharedServicePath/$_offlineServicePath'],
    };
  }

  @override
  FutureOr<void> build(BuildStep buildStep) async {
    List<String> screens = Utils.getOfflinePreFetchScreens();
    _validate(buildStep, screens);
    List<String> imports = [];
    List<String> getDataForScreens = [];
    if (screens.isNotEmpty) {
      for (String screen in screens) {
        await for (AssetId assetId
            in buildStep.findAssets(Glob('lib/src/screens/**/*_screen.dart'))) {
          LibraryElement library = await buildStep.resolver.libraryFor(assetId);
          String screenName = library.topLevelElements.first.name ?? '';
          if (library.source.uri.path.contains('/$screen.dart')) {
            String screenUri = '${library.source.uri}';
            String servicePath = screenUri.replaceFirst(
              screen,
              '${Utils.screenFile2GenServiceFile(screen)}.service',
            );
            imports.add("import '$servicePath';");
            getDataForScreens.add(
                'await ${Utils.screenClass2GenServiceClass(screenName)}().memoizedGetData();');
          }
        }
      }
    }

    if (getDataForScreens.isNotEmpty) {
      // get the current app package
      String pkgName = buildStep.inputId.package;
      AssetId outFile =
          AssetId(pkgName, '$_offlineServicePathFromRoot/$_offlineServicePath');

      String out = _generate(imports, getDataForScreens);

      await buildStep.writeAsString(outFile, out);
    }
  }

  static String _generate(
    List<String> imports,
    List<String> getDataForScreens,
  ) {
    return '''
${imports.join('\n')}

class OfflineService {
  static Future<void> preFetch() async {
    ${getDataForScreens.join('\n    ')}
  }
}
    ''';
  }

  Future<void> _validate(BuildStep buildStep, List<String> screens) async {
    List<String> existingScreens = [];
    await for (AssetId assetId
        in buildStep.findAssets(Glob('lib/src/screens/**/*_screen.dart'))) {
      LibraryElement library = await buildStep.resolver.libraryFor(assetId);
      String screenName =
          library.source.uri.path.split('/').last.split('.').first;
      existingScreens.add(screenName);
    }

    List<String> incorrectScreenNames =
        screens.where((element) => !existingScreens.contains(element)).toList();
    if (incorrectScreenNames.isNotEmpty) {
      throw InvalidGenerationSourceError(
        'Could not find the following screens: $incorrectScreenNames\nHint: Fix the name in mustang.yaml \$',
        todo: 'Prefix class name with \$',
      );
    }
  }
}
