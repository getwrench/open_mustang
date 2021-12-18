import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:mustang_codegen/src/utils.dart';
import 'package:mustang_core/mustang_core.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

class ScreenServiceGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    Iterable<AnnotatedElement> services =
        library.annotatedWith(const TypeChecker.fromRuntime(ScreenService));
    StringBuffer serviceBuffer = StringBuffer();
    if (services.isEmpty) {
      return '$serviceBuffer';
    }

    serviceBuffer.writeln(_generate(
      services.first.element,
      services.first.annotation,
      buildStep,
    ));

    return '$serviceBuffer';
  }

  String _generate(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    _validate(element, annotation);

    String serviceName = element.displayName;
    String importService = p.basenameWithoutExtension(buildStep.inputId.path);

    List<String> importStates = [];
    String screenState = annotation
            .read('screenState')
            .typeValue
            .element
            ?.displayName
            .replaceFirst(r'$', '') ??
        '';

    if (screenState.isEmpty) {
      return '';
    }

    importStates.add("import '${Utils.class2File(screenState)}.state.dart';");

    String pkgName = buildStep.inputId.package;
    String appSerializerAlias = 'app_serializer';

    String? customSerializerPackage = Utils.getCustomSerializerPackage();
    String customSerializer = '';
    String customSerializerAlias = '';
    if (customSerializerPackage != null) {
      customSerializerAlias = Utils.generateRandomString(10);
      customSerializer =
          "import '$customSerializerPackage' as $customSerializerAlias;";
    }

    return '''
      import 'package:mustang_core/mustang_core.dart';
      import '$importService.dart';
      import 'dart:convert';
      import 'dart:developer';
      import 'package:flutter/foundation.dart';
      import 'package:$pkgName/src/models/serializers.dart' as $appSerializerAlias;
      $customSerializer
      ${importStates.join('\n')}
      
      class \$${screenState}Cache<T> {
        const \$${screenState}Cache([this.t]);
      
        final T? t;
      }
        
      extension \$$serviceName on $serviceName {
        void updateState() {
          $screenState screenState = WrenchStore.get<$screenState>() ?? $screenState();
          if (screenState.mounted) {
            screenState.update();
          }
        }
        
        void updateState1<T>(T t, {
          reload = true,
        }) {
          $screenState screenState = WrenchStore.get<$screenState>() ?? $screenState();
          if (screenState.mounted) {
            WrenchStore.update(t);
            ${_generatePersistObjectTemplate('T', appSerializerAlias, customSerializerAlias)}
            if (kDebugMode) {
              postEvent('mustang', {
                '\$T': ${_generateCacheObjectJsonArg('T', appSerializerAlias, customSerializerAlias)},
              });
            }
            if (reload) {
              screenState.update();
            }
          }
        }
    
        void updateState2<T, S>(T t, S s, {
          reload = true,
        }) {
          $screenState screenState = WrenchStore.get<$screenState>() ?? $screenState();
          if (screenState.mounted) {
            WrenchStore.update2(t, s);
            ${_generatePersistObjectTemplate('T', appSerializerAlias, customSerializerAlias)}
            ${_generatePersistObjectTemplate('S', appSerializerAlias, customSerializerAlias)}
            if (kDebugMode) {
              postEvent('mustang', {
                '\$T': ${_generateCacheObjectJsonArg('T', appSerializerAlias, customSerializerAlias)},
              });
              postEvent('mustang', {
                '\$S': ${_generateCacheObjectJsonArg('S', appSerializerAlias, customSerializerAlias)},
              });
            }
            if (reload) {
              screenState.update();
            }
          }
        }
    
        void updateState3<T, S, U>(T t, S s, U u, {
          reload = true,
        }) {
          $screenState screenState = WrenchStore.get<$screenState>() ?? $screenState();
          if (screenState.mounted) {
            WrenchStore.update3(t, s, u);
            ${_generatePersistObjectTemplate('T', appSerializerAlias, customSerializerAlias)}
            ${_generatePersistObjectTemplate('S', appSerializerAlias, customSerializerAlias)}
            ${_generatePersistObjectTemplate('U', appSerializerAlias, customSerializerAlias)}
            if (kDebugMode) {
              postEvent('mustang', {
                '\$T': ${_generateCacheObjectJsonArg('T', appSerializerAlias, customSerializerAlias)},
              });
              postEvent('mustang', {
                '\$S': ${_generateCacheObjectJsonArg('S', appSerializerAlias, customSerializerAlias)},
              });
              postEvent('mustang', {
                '\$U': ${_generateCacheObjectJsonArg('U', appSerializerAlias, customSerializerAlias)},
              });
            }
            if (reload) {
              screenState.update();
            }
          }
        }
    
        void updateState4<T, S, U, V>(T t, S s, U u, V v, {
          reload = true,
        }) {
          $screenState screenState = WrenchStore.get<$screenState>() ?? $screenState();
          if (screenState.mounted) {
            WrenchStore.update4(t, s, u, v);
            ${_generatePersistObjectTemplate('T', appSerializerAlias, customSerializerAlias)}
            ${_generatePersistObjectTemplate('S', appSerializerAlias, customSerializerAlias)}
            ${_generatePersistObjectTemplate('U', appSerializerAlias, customSerializerAlias)}
            ${_generatePersistObjectTemplate('V', appSerializerAlias, customSerializerAlias)}
            if (kDebugMode) {
              postEvent('mustang', {
                '\$T': ${_generateCacheObjectJsonArg('T', appSerializerAlias, customSerializerAlias)},
              });
              postEvent('mustang', {
                '\$S': ${_generateCacheObjectJsonArg('S', appSerializerAlias, customSerializerAlias)},
              });
              postEvent('mustang', {
                '\$U': ${_generateCacheObjectJsonArg('U', appSerializerAlias, customSerializerAlias)},
              });
              postEvent('mustang', {
                '\$V': ${_generateCacheObjectJsonArg('V', appSerializerAlias, customSerializerAlias)},
              });
            }
            if (reload) {
              screenState.update();
            }
          }
        }
        
        T memoizeScreen<T>(T Function() service) {
          \$${screenState}Cache screenStateCache =
              WrenchStore.get<\$${screenState}Cache>() ?? const \$${screenState}Cache();
          $screenState screenState = WrenchStore.get<$screenState>() ?? $screenState();
          
          if (screenStateCache.t == null) {
            T t = service();
            screenStateCache = \$${screenState}Cache(t);
            WrenchStore.update(screenStateCache);
            if (t is Future) {
              t.whenComplete(() {
                if (!(screenState.mounted)) {
                  WrenchStore.delete<\$${screenState}Cache>();
                }
              });
            }
          }
          return screenStateCache.t;
        }
        
        void clearMemoizedScreen({
          reload = true,
        }) {
          WrenchStore.delete<\$${screenState}Cache>();
          $screenState screenState = WrenchStore.get<$screenState>() ?? $screenState();
          if (screenState.mounted) {
            if (reload) { 
              screenState.update();
            }    
          }
        }
        
        Future<void> addObjectToCache<T>(String key, T t) async {
          await WrenchCache.addObject(
            key,
            '\$T',
            ${_generateCacheObjectJsonArg('T', appSerializerAlias, customSerializerAlias)},
          );
        }
        
        Future<void> deleteObjectsFromCache(String key) async {
          await WrenchCache.deleteObjects(key);
        }
        
        bool itemExistsInCache(String key) {
          return WrenchCache.itemExists(key);
        }
  
    }
    ''';
  }

  String _generatePersistObjectTemplate(
    String type,
    String appSerializerAlias,
    String customSerializerAlias,
  ) {
    if (customSerializerAlias.isNotEmpty) {
      return '''WrenchStore.persistObject(
        '\$$type',
        jsonEncode(
          $appSerializerAlias.serializerNames.contains('\$$type')
              ? $appSerializerAlias.serializers.serialize(${type.toLowerCase()})
              : $customSerializerAlias.serializers.serialize(${type.toLowerCase()}),
        ),
      );''';
    } else {
      return '''WrenchStore.persistObject(
        '\$$type',
        jsonEncode($appSerializerAlias.serializers.serialize(${type.toLowerCase()})),
      );''';
    }
  }

  String _generateCacheObjectJsonArg(
    String type,
    String appSerializerAlias,
    String customSerializerAlias,
  ) {
    if (customSerializerAlias.isNotEmpty) {
      return '''
        jsonEncode($appSerializerAlias.serializerNames.contains('\$$type')
                  ? $appSerializerAlias.serializers.serialize(${type.toLowerCase()})
                  : $customSerializerAlias.serializers.serialize(${type.toLowerCase()}))
    ''';
    } else {
      return '''jsonEncode($appSerializerAlias.serializers.serialize(${type.toLowerCase()}))''';
    }
  }

  void _validate(Element element, ConstantReader annotation) {
    List<String> modelImports =
        Utils.getRawImports(element.library?.imports ?? []);
    if (modelImports
            .indexWhere((element) => element.contains('material.dart')) !=
        -1) {
      throw InvalidGenerationSourceError(
        'Error: Service class should not import flutter library',
        element: element,
      );
    }

    if (annotation.read('screenState').typeValue.element != null &&
        !annotation
            .read('screenState')
            .typeValue
            .element!
            .displayName
            .startsWith(r'$')) {
      throw InvalidGenerationSourceError(
        'Error: State class name should start with \$',
        todo: 'Missing \$ in the State class name',
        element: element,
      );
    }
  }
}
