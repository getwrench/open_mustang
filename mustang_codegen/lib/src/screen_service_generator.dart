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
    String appSerializer = 'app_serializer';

    return '''
      import 'package:mustang_core/mustang_core.dart';
      import '$importService.dart';
      import 'dart:convert';
      import 'package:$pkgName/src/models/serializers.dart' as $appSerializer;
      ${importStates.join('\n')}
      
      class \$${screenState}Cache<T> {
        const \$${screenState}Cache(this.t);
      
        final T t;
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
            WrenchStore.persistObject(
              '\$T',
              jsonEncode($appSerializer.serializers.serialize(t)),
            );
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
            WrenchStore.persistObject(
              '\$T',
              jsonEncode($appSerializer.serializers.serialize(t)),
            );
            WrenchStore.persistObject(
              '\$S',
              jsonEncode($appSerializer.serializers.serialize(s)),
            );
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
            WrenchStore.persistObject(
              '\$T',
              jsonEncode($appSerializer.serializers.serialize(t)),
            );
            WrenchStore.persistObject(
              '\$S',
              jsonEncode($appSerializer.serializers.serialize(s)),
            );
            WrenchStore.persistObject(
              '\$U',
              jsonEncode($appSerializer.serializers.serialize(u)),
            );
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
            WrenchStore.persistObject(
              '\$T',
              jsonEncode($appSerializer.serializers.serialize(t)),
            );
            WrenchStore.persistObject(
              '\$S',
              jsonEncode($appSerializer.serializers.serialize(s)),
            );
            WrenchStore.persistObject(
              '\$U',
              jsonEncode($appSerializer.serializers.serialize(u)),
            );
            WrenchStore.persistObject(
              '\$V',
              jsonEncode($appSerializer.serializers.serialize(v)),
            );
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
                if (!(screenState?.mounted ?? false)) {
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
            jsonEncode($appSerializer.serializers.serialize(t)),
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
