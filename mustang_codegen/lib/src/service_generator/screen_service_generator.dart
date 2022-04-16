import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:mustang_codegen/src/service_generator/service_method_override_visitor.dart';
import 'package:mustang_codegen/src/utils.dart';
import 'package:mustang_core/mustang_core.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

class ScreenServiceGenerator extends Generator {
  static const String appModelsDir = 'lib/src/models';

  @override
  Future<String> generate(LibraryReader library, BuildStep buildStep) async {
    Iterable<AnnotatedElement> services =
        library.annotatedWith(const TypeChecker.fromRuntime(ScreenService));
    StringBuffer serviceBuffer = StringBuffer();
    if (services.isEmpty) {
      return '$serviceBuffer';
    }

    serviceBuffer.writeln(await _generate(
      services.first.element,
      services.first.annotation,
      buildStep,
    ));

    return '$serviceBuffer';
  }

  Future<String> _generate(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    _validate(element, annotation);

    String serviceName = element.displayName;
    String generatedServiceName = element.displayName.replaceFirst(r'$', '');
    String importService = p.basenameWithoutExtension(buildStep.inputId.path);

    String screenState = Utils.serviceClass2GenStateClass(generatedServiceName);
    if (screenState.isEmpty) {
      return '';
    }

    List<String> overriders = [];
    List<String> imports = [];
    element.visitChildren(
      ServiceMethodOverrideVisitor(
        overrides: overriders,
        imports: imports,
      ),
    );
    imports.add(
        "import '${Utils.serviceClassToGenStateFile(generatedServiceName)}';");
    imports = imports.toSet().toList();

    String statePath = buildStep.inputId.uri
        .toString()
        .replaceFirst('_service.dart', '_state.dart');
    AssetId stateAssetId = AssetId.resolve(Uri.parse(statePath));
    LibraryElement stateLibraryElement =
        await buildStep.resolver.libraryFor(stateAssetId);
    ClassElement stateClassElement =
        LibraryReader(stateLibraryElement).classes.first;
    List<String> stateFieldsTypes =
        stateClassElement.fields.map((e) => e.type.toString()).toList();

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

    List<String> appEventModels = [];
    List<String> appEventModelImports = [];
    await for (AssetId assetId
        in buildStep.findAssets(Glob('$appModelsDir/[!.model]*'))) {
      LibraryElement appModelLibrary =
          await buildStep.resolver.libraryFor(assetId);
      Iterable<AnnotatedElement> appEvents = LibraryReader(appModelLibrary)
          .annotatedWith(const TypeChecker.fromRuntime(AppEvent));
      if (appEvents.isNotEmpty) {
        appEventModels.add(appEvents.first.element.name!);
        String importPath =
            assetId.uri.toString().replaceFirst('dart', 'model.dart');
        appEventModelImports.add("import '$importPath';");
      }
    }

    return '''
      import 'package:mustang_core/mustang_core.dart';
      import '$importService.dart';
      import 'dart:convert';
      import 'dart:developer';
      import 'package:flutter/foundation.dart';
      import 'package:$pkgName/src/models/serializers.dart' as $appSerializerAlias;
      $customSerializer
      ${appEventModelImports.join('\n')}
      ${imports.join('\n')}
      
      class _\$${screenState}Cache<T> {
        const _\$${screenState}Cache([this.t]);
        
        Map<String, dynamic> toJson() {
          return {
            '\$T': '\$t',
          };
        }
      
        final T? t;
      }
      
      class $generatedServiceName extends $serviceName {
        Future<void> subscribeToEventStream() async {
          ${_generateEventSubscription(appEventModels, stateFieldsTypes)}
        }
        
        ${overriders.join('\n')}
      }
        
      extension \$$serviceName on $serviceName {
        void updateState() {
          $screenState screenState = MustangStore.get<$screenState>()!;
          screenState.update();
        }
        
        void updateState1<T>(T t, {
          reload = true,
        }) {
          $screenState screenState = MustangStore.get<$screenState>()!;
          MustangStore.update(t);
          ${_generatePersistObjectTemplate('T', appSerializerAlias, customSerializerAlias)}
          if (kDebugMode) {
            postEvent('${Utils.debugEventKind}', {
              'modelName': '\$T',
              'modelStr': ${_generateCacheObjectJsonArg('T', appSerializerAlias, customSerializerAlias)},
            });
          }
          if (reload) {
            screenState.update();
          }
        }
    
        void updateState2<T, S>(T t, S s, {
          reload = true,
        }) {
          $screenState screenState = MustangStore.get<$screenState>()!;
          MustangStore.update2(t, s);
          ${_generatePersistObjectTemplate('T', appSerializerAlias, customSerializerAlias)}
          ${_generatePersistObjectTemplate('S', appSerializerAlias, customSerializerAlias)}
          if (kDebugMode) {
            postEvent('${Utils.debugEventKind}', {
              'modelName': '\$T',
              'modelStr': ${_generateCacheObjectJsonArg('T', appSerializerAlias, customSerializerAlias)},
            });
            postEvent('${Utils.debugEventKind}', {
              'modelName': '\$S',
              'modelStr': ${_generateCacheObjectJsonArg('S', appSerializerAlias, customSerializerAlias)},
            });
          }
          if (reload) {
            screenState.update();
          }
        }
    
        void updateState3<T, S, U>(T t, S s, U u, {
          reload = true,
        }) {
          $screenState screenState = MustangStore.get<$screenState>()!;
          MustangStore.update3(t, s, u);
          ${_generatePersistObjectTemplate('T', appSerializerAlias, customSerializerAlias)}
          ${_generatePersistObjectTemplate('S', appSerializerAlias, customSerializerAlias)}
          ${_generatePersistObjectTemplate('U', appSerializerAlias, customSerializerAlias)}
          if (kDebugMode) {
            postEvent('${Utils.debugEventKind}', {
              'modelName': '\$T',
              'modelStr': ${_generateCacheObjectJsonArg('T', appSerializerAlias, customSerializerAlias)},
            });
            postEvent('${Utils.debugEventKind}', {
              'modelName': '\$S',
              'modelStr': ${_generateCacheObjectJsonArg('S', appSerializerAlias, customSerializerAlias)},
            });
            postEvent('${Utils.debugEventKind}', {
              'modelName': '\$U',
              'modelStr': ${_generateCacheObjectJsonArg('U', appSerializerAlias, customSerializerAlias)},
            });
          }
          if (reload) {
            screenState.update();
          }
        }
    
        void updateState4<T, S, U, V>(T t, S s, U u, V v, {
          reload = true,
        }) {
          $screenState screenState = MustangStore.get<$screenState>()!;
          MustangStore.update4(t, s, u, v);
          ${_generatePersistObjectTemplate('T', appSerializerAlias, customSerializerAlias)}
          ${_generatePersistObjectTemplate('S', appSerializerAlias, customSerializerAlias)}
          ${_generatePersistObjectTemplate('U', appSerializerAlias, customSerializerAlias)}
          ${_generatePersistObjectTemplate('V', appSerializerAlias, customSerializerAlias)}
          if (kDebugMode) {
            postEvent('${Utils.debugEventKind}', {
              'modelName': '\$T',
              'modelStr': ${_generateCacheObjectJsonArg('T', appSerializerAlias, customSerializerAlias)},
            });
            postEvent('${Utils.debugEventKind}', {
              'modelName': '\$S',
              'modelStr': ${_generateCacheObjectJsonArg('S', appSerializerAlias, customSerializerAlias)},
            });
            postEvent('${Utils.debugEventKind}', {
              'modelName': '\$U',
              'modelStr': ${_generateCacheObjectJsonArg('U', appSerializerAlias, customSerializerAlias)},
            });
            postEvent('${Utils.debugEventKind}', {
              'modelName': '\$V',
              'modelStr': ${_generateCacheObjectJsonArg('V', appSerializerAlias, customSerializerAlias)},
            });
          }
          if (reload) {
            screenState.update();
          }
        }
        
        T memoizeScreen<T>(T Function() service) {
          _\$${screenState}Cache screenStateCache =
              MustangStore.get<_\$${screenState}Cache>() ?? const _\$${screenState}Cache();
          
          if (screenStateCache.t == null) {
            T t = service();
            screenStateCache = _\$${screenState}Cache(t);
            MustangStore.update(screenStateCache);
            if (kDebugMode) {
              postEvent('${Utils.debugEventKind}', {
                'modelName': '\${_\$${screenState}Cache}',
                'modelStr': jsonEncode(screenStateCache.toJson()),
              });
            }
          }
          return screenStateCache.t;
        }
        
        void clearMemoizedScreen({
          reload = true,
        }) {
          if(!MustangStore.getOfflineStatus) {
            MustangStore.delete<_\$${screenState}Cache>();
            if (kDebugMode) {
              postEvent('${Utils.debugEventKind}', {
                'modelName': '\${_\$${screenState}Cache}',
                'modelStr': '{}',
              });
            }
            $screenState screenState = MustangStore.get<$screenState>()!;
            if (reload) { 
                screenState.update();
            }
          }    
        }
        
        Future<void> addObjectToCache<T>(String key, T t) async {
          await MustangCache.addObject(
            key,
            '\$T',
            ${_generateCacheObjectJsonArg('T', appSerializerAlias, customSerializerAlias)},
          );
        }
        
        Future<void> deleteObjectsFromCache(String key) async {
          await MustangCache.deleteObjects(key);
        }
        
        bool itemExistsInCache(String key) {
          return MustangCache.itemExists(key);
        }
  
    }
    ''';
  }

  String _generateEventSubscription(
    List<String> appModelEvents,
    List<String> stateFieldsTypes,
  ) {
    // check if the event model is defined in the state
    if (appModelEvents.isEmpty ||
        !appModelEvents.any((e) => stateFieldsTypes.contains(e))) {
      return '';
    }

    String instanceCheckStr = '';
    for (String appEventModel in appModelEvents) {
      String modelName = appEventModel.replaceFirst('\$', '');
      instanceCheckStr += '''
        if (event is $modelName) {
          $modelName m = event;
          updateState1(m);
        }
      ''';
    }
    return '''
      Stream<AppEvent> appEventStream = await EventStream.getStream();
      await for (AppEvent event in appEventStream) {
        $instanceCheckStr
    }''';
  }

  String _generatePersistObjectTemplate(
    String type,
    String appSerializerAlias,
    String customSerializerAlias,
  ) {
    if (customSerializerAlias.isNotEmpty) {
      return '''MustangStore.persistObject(
        '\$$type',
        jsonEncode(
          $appSerializerAlias.serializerNames.contains('\$$type')
              ? $appSerializerAlias.serializers.serialize(${type.toLowerCase()})
              : $customSerializerAlias.serializers.serialize(${type.toLowerCase()}),
        ),
      );''';
    } else {
      return '''MustangStore.persistObject(
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
    if (!element.displayName.startsWith(r'$')) {
      throw InvalidGenerationSourceError(
          'ScreenService class name should start with \$',
          todo: 'Prefix class name with \$',
          element: element);
    }

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

    // class annotated with ScreenService should be abstract
    ClassElement appServiceClass = element as ClassElement;
    if (!appServiceClass.isAbstract) {
      throw InvalidGenerationSourceError(
          'Error: class annotated with ScreenService should be abstract',
          todo: 'Make the class abstract',
          element: element);
    }
  }
}
