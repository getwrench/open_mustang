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
        library.annotatedWith(const TypeChecker.fromRuntime(ScreenState));
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
    _validate(element, buildStep);

    String stateName = element.displayName.replaceFirst(r'$', '');
    ClassElement stateClass = element as ClassElement;
    List<String> stateModelFields = [];

    String importGenService =
        "import '${Utils.stateClassToGenServiceFile(stateName)}';";
    String genServiceClass = Utils.stateClassToGenServiceClass(stateName);

    for (FieldElement fieldElement in stateClass.fields) {
      String fieldType = fieldElement.type
          .getDisplayString(withNullability: false)
          .replaceFirst(r'$', '');
      String fieldName = fieldElement.name;
      String declaration =
          '$fieldType get $fieldName => MustangStore.get<$fieldType>() ?? $fieldType();';
      stateModelFields.add(declaration);
    }
    List<String> stateImports = Utils.getImports(
      element.library.imports,
      buildStep.inputId.package,
    );

    return '''
      import 'dart:async';
      import 'dart:developer';
      import 'package:flutter/foundation.dart';
      import 'package:flutter/widgets.dart';
      import 'package:mustang_core/mustang_core.dart';
      import 'package:mustang_core/mustang_widgets.dart';
      ${stateImports.join('\n')}
      
      $importGenService
      
      class $stateName extends ChangeNotifier implements RouteAware {
        late final BuildContext context;
        
        $stateName({
          required this.context,
        }) {
          MustangStore.update(this);
          MustangRouteObserver.getInstance().subscribe(this, ModalRoute.of(context)!);
          if (kDebugMode) {
            postEvent('${Utils.debugEventKind}', {
              'modelName': '\$$stateName', 
              'modelStr': 'active',
            });
          }
        }
        
        ${stateModelFields.join('\n')}
        
        void update() {
          notifyListeners(); 
        }
        
        @override
        void dispose() {
          if (kDebugMode) {
            postEvent('${Utils.debugEventKind}', {
              'modelName': '\$$stateName', 
              'modelStr': 'disposed',
            });
          }
          super.dispose();
        }
        
        /// Called when the screen associated with this state has been popped off.
        @override
        void didPop() {
          MustangRouteObserver.getInstance().unsubscribe(this);
          MustangStore.delete<$stateName>();
          Timer(const Duration(seconds: 1000), () {
            dispose();
          });
        }
      
        /// Called when the top route has been popped off, and the screen associated with 
        /// this state shows up.
        @override
        void didPopNext() {
          $genServiceClass().subscribeToEventStream();
        }
      
        /// Called when the screen associated with this state has been pushed.
        @override
        void didPush() {
          $genServiceClass().subscribeToEventStream();
        }
      
        /// Called when a new route has been pushed, and the screen associated with 
        /// this state is no longer visible.
        @override
        void didPushNext() {
          // TODO: implement didPushNext
        }
      }
    ''';
  }

  void _validate(Element element, BuildStep buildStep) {
    String currentPkgName = buildStep.inputId.package;

    Utils.getRawImports(element.library?.imports ?? []).forEach((import) {
      // Fields of State should be models from the same package i.e. from **/src/models
      // directory, unless there is a dependent package with it's own models
      // and those models need to be used in the State class
      if (!import.contains('$currentPkgName/lib/src/models') &&
          !import.contains('built_collection.dart') &&
          !import.contains('mustang_core.dart') &&
          !import.contains('dart:core')) {
        String? customSerializerPackage = Utils.getCustomSerializerPackage();
        List<String> importTokens = import.split('/');
        String importPackage = '';
        if (importTokens.length > 1) {
          importPackage = importTokens.elementAt(1);
        }
        if (customSerializerPackage == null ||
            (importPackage.isNotEmpty &&
                !customSerializerPackage
                    .startsWith('package:$importPackage'))) {
          throw InvalidGenerationSourceError(
              'Invalid import $import. Only models src/models directory are allowed as fields in State class',
              todo: 'Import Model class annotated with @AppModel instead',
              element: element);
        }
      }

      if (import.contains('.model.dart')) {
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
    // class annotated with screenState should be abstract
    if (!stateClass.isAbstract) {
      throw InvalidGenerationSourceError(
          'Error: class annotated with screenState should be abstract',
          todo: 'Make the class abstract',
          element: element);
    }

    for (FieldElement element in stateClass.fields) {
      if (element.type.element?.displayName == 'dynamic') {
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

      if (element.type.element != null &&
          element.type.element!.metadata.isEmpty &&
          !element.type.element!.declaration
              .toString()
              .contains('implements Built')) {
        throw InvalidGenerationSourceError(
            'Error: Only models are allowed as fields in State class',
            todo: 'Use only Models as fields',
            element: element);
      }

      if (element.type.element != null &&
          !element.type.element!.declaration
              .toString()
              .contains('implements Built') &&
          !_hasAppModelAnnotation(element)) {
        throw InvalidGenerationSourceError(
            'Error: Only models are allowed as fields in State class',
            todo: 'Use only Models as fields',
            element: element);
      }
    }
  }

  bool _hasAppModelAnnotation(FieldElement element) {
    return element.type.element!.metadata.any((elementAnnotation) {
      return (elementAnnotation.element!.name?.toLowerCase() ?? '') ==
          '$AppModel'.toLowerCase();
    });
  }
}
