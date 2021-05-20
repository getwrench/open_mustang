import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'utils.dart';

class ScreenStateGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    StringBuffer stateBuffer = StringBuffer();
    Iterable<AnnotatedElement> states =
        library.annotatedWith(TypeChecker.fromRuntime(ScreenState));
    if (states.isEmpty) {
      return '${stateBuffer}';
    }

    stateBuffer.writeln(_generate(
      states.first.element,
      states.first.annotation,
      buildStep,
    ));

    return '${stateBuffer}';
  }

  String _generate(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    _validate(element);

    String stateName = element.displayName.replaceFirst(r'$', '');
    ClassElement stateClass = element as ClassElement;
    List<String> stateModelFields = [];

    stateClass.fields.forEach((fieldElement) {
      String fieldType = fieldElement.type
          .getDisplayString(withNullability: false)
          .replaceFirst(r'$', '');
      String fieldName = fieldElement.name;
      String declaration =
          '$fieldType get $fieldName => WrenchStore.get<$fieldType>();';
      stateModelFields.add(declaration);
    });
    List<String> stateImports = Utils.getImports(element.library.imports);
    if (!stateImports
        .any((import) => import.contains('wrench_flutter_common'))) {
      stateImports
          .add("import 'package:wrench_flutter_common/flutter_common.dart';");
    }

    return '''
      import 'package:flutter/foundation.dart';
      ${stateImports.join('\n')}
      
      class $stateName extends ChangeNotifier {
        $stateName() {
          mounted = true;
          WrenchStore.update(this);
        }
        
        bool mounted;
        
        ${stateModelFields.join('\n')}
        
        void update() {
          if (mounted) {
            notifyListeners(); 
          }
        }
        
        @override
        void dispose() {
          mounted = false;
          super.dispose();
        }
      }
    ''';
  }

  void _validate(Element element) {
    Utils.getRawImports(element.library.imports).forEach((import) {
      if (import.contains('\.model\.dart')) {
        throw InvalidGenerationSourceError(
            'Do not import generated Model class inside State: $import',
            todo: 'Import Model class annotated with @AppModel instead',
            element: element);
      }
    });

    if (!element.displayName.startsWith(r'$')) {
      throw InvalidGenerationSourceError(
          'State class name should start with \$',
          todo: 'Prefix class name with \$',
          element: element);
    }

    ClassElement stateClass = element as ClassElement;
    stateClass.fields.forEach((element) {
      if (element.type.element.displayName == 'dynamic') {
        throw InvalidGenerationSourceError(
          'Import is missing for the field',
          todo: 'Add import for the field',
          element: element,
        );
      }

      if (element.isSynthetic) {
        throw InvalidGenerationSourceError(
            'Explicit getter/setter is not allowed in State classes',
            todo: 'Remove getter/setter',
            element: element);
      }

      if (element.hasInitializer) {
        throw InvalidGenerationSourceError(
            'No need to initialize fields of the State class ',
            todo: 'Undo initialization',
            element: element);
      }

      if (element.isStatic || element.isConst || element.isFinal) {
        throw InvalidGenerationSourceError(
            'State fields should not be static or static const or final',
            todo: 'remove static/static const/final',
            element: element);
      }

      // List, Map are not allowed
      if (['List', 'Map'].contains(element.type.element.displayName)) {
        throw InvalidGenerationSourceError(
            'List/Map are not allowed for fields. Use BuiltList/BuiltMap instead',
            todo: 'Use BuiltList/BuiltMap',
            element: element);
      }

      // TODO
      // Fields can be only be
      // - Classes annotated with appModel
      // - Abstract subclass of Built class are allowed
      // print(element.type.element.thisOrAncestorOfType<T extends Built>());
    });
  }
}
