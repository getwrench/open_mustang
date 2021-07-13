import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:mustang_codegen/src/utils.dart';
import 'package:mustang_core/mustang_core.dart';
import 'package:source_gen/source_gen.dart';

class ScreenStateGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    StringBuffer stateBuffer = StringBuffer();
    Iterable<AnnotatedElement> states =
        library.annotatedWith(TypeChecker.fromRuntime(ScreenState));
    if (states.isEmpty) {
      return '$stateBuffer';
    }

    stateBuffer.writeln(_generate(
      states.first.element,
      states.first.annotation,
      buildStep,
    ));

    return '$stateBuffer';
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

    return '''
      import 'package:flutter/foundation.dart';
      import 'package:mustang_core/mustang_core.dart';
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
            'Error: Do not import generated Model class inside State: $import',
            todo: 'Import Model class annotated with @AppModel instead',
            element: element);
      }

      if (import.contains('material.dart')) {
        throw InvalidGenerationSourceError(
          'Error: State class should not import flutter library',
          element: element,
        );
      }
    });

    if (!element.displayName.startsWith(r'$')) {
      throw InvalidGenerationSourceError(
          'Error: State class name should start with \$',
          todo: 'Prefix class name with \$',
          element: element);
    }

    ClassElement stateClass = element as ClassElement;
    stateClass.fields.forEach((element) {
      if (element.type.element.displayName == 'dynamic') {
        throw InvalidGenerationSourceError(
          'Error: Import is missing for the field',
          todo: 'Add import for the field',
          element: element,
        );
      }

      if (element.isSynthetic) {
        throw InvalidGenerationSourceError(
            'Error: Explicit getter/setter is not allowed in State classes',
            todo: 'Remove getter/setter',
            element: element);
      }

      if (element.hasInitializer) {
        throw InvalidGenerationSourceError(
            'Error: No need to initialize fields of the State class ',
            todo: 'Undo initialization',
            element: element);
      }

      if (element.isStatic || element.isConst || element.isFinal) {
        throw InvalidGenerationSourceError(
            'Error: State fields should not be static or static const or final',
            todo: 'remove static/static const/final',
            element: element);
      }

      if (element.type.element.metadata.isEmpty &&
          !element.type.element.declaration
              .toString()
              .contains('implements Built')) {
        throw InvalidGenerationSourceError(
            'Error: Only models are allowed as fields in State class',
            todo: 'Use only Models as fields',
            element: element);
      }

      if (element.type.element.metadata.isNotEmpty &&
          element.type.element.metadata.first.element.name.toLowerCase() !=
              '$AppModel'.toLowerCase()) {
        throw InvalidGenerationSourceError(
            'Error: Only models are allowed as fields in State class',
            todo: 'Use only Models as fields',
            element: element);
      }
    });
  }
}
