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
        library.annotatedWith(TypeChecker.fromRuntime(ScreenService));
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
        .displayName
        .replaceFirst(r'$', '');
    importStates.add("import '${Utils.class2File(screenState)}.state.dart';");

    // String rootStateUpdate = '';
    // if (annotation.read('rootState').isString) {
    //   String rootState = annotation.read('rootState').stringValue;
    //   String rootStateDir = annotation.read('rootStateDir')?.stringValue;
    //   if (rootStateDir != null) {
    //     importStates.add(
    //         "import '${rootStateDir}${Utils.class2File(rootState)}.state.dart';");
    //
    //     rootStateUpdate = '''
    //       $rootState rootState = WrenchStore.get<$rootState>();
    //           (rootState == null)
    //             ? print('$rootState not found in the store')
    //             : rootState.update();
    //     ''';
    //   }
    // }

    return '''
      import 'package:mustang_core/mustang_core.dart';
      import '$importService.dart';
      ${importStates.join('\n')}
      
      class \$${screenState}Cache<T> {
        const \$${screenState}Cache(this.t);
      
        final T t;
      }
        
      extension \$$serviceName on $serviceName {
        void updateState() {
          $screenState screenState = WrenchStore.get<$screenState>();
          if (screenState?.mounted ?? false) {
            screenState.update();
          }
        }
        
        void updateState1<T>(T t, {
          reload = true,
        }) {
          $screenState screenState = WrenchStore.get<$screenState>();
          if (screenState?.mounted ?? false) {
            WrenchStore.update(t);
            if (reload) {
              screenState.update();
            }
          }
        }
    
        void updateState2<T, S>(T t, S s, {
          reload = true,
        }) {
          $screenState screenState = WrenchStore.get<$screenState>();
          if (screenState?.mounted ?? false) {
            WrenchStore.update2(t, s);
            if (reload) {
              screenState.update();
            }
          }
        }
    
        void updateState3<T, S, U>(T t, S s, U u, {
          reload = true,
        }) {
          $screenState screenState = WrenchStore.get<$screenState>();
          if (screenState?.mounted ?? false) {
            WrenchStore.update3(t, s, u);
            if (reload) {
              screenState.update();
            }
          }
        }
    
        void updateState4<T, S, U, V>(T t, S s, U u, V v, {
          reload = true,
        }) {
          $screenState screenState = WrenchStore.get<$screenState>();
          if (screenState?.mounted ?? false) {
            WrenchStore.update4(t, s, u, v);
            if (reload) {
              screenState.update();
            }
          }
        }
        
        T memoize<T>(T Function() service) {
          \$${screenState}Cache screenStateCache =
              WrenchStore.get<\$${screenState}Cache>();
          $screenState screenState = WrenchStore.get<$screenState>();
          
          if (screenStateCache == null) {
            T t = service();
            screenStateCache = \$${screenState}Cache(t);
            WrenchStore.update(screenStateCache);
            if (t is Future) {
              t.whenComplete(() {
                if (!screenState.mounted ?? false) {
                  WrenchStore.delete<\$${screenState}Cache>();
                }
              });
            }
          }
          return screenStateCache.t;
        }
        
        void clearCache({
          reload = true,
        }) {
          WrenchStore.delete<\$${screenState}Cache>();
          $screenState screenState = WrenchStore.get<$screenState>();
          if (screenState?.mounted ?? false) {
            if (reload) { 
              screenState.update();
            }    
          }
        }
      }
    ''';
  }

  void _validate(Element element, ConstantReader annotation) {
    if (!annotation
        .read('screenState')
        .typeValue
        .element
        .displayName
        .startsWith(r'$')) {
      throw InvalidGenerationSourceError(
        'State class name should start with \$',
        todo: 'Missing \$ in the State class name',
        element: element,
      );
    }
  }
}
