import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:mustang_codegen/src/aspect_visitor.dart';
import 'package:mustang_codegen/src/codegen_constants.dart';
import 'package:mustang_codegen/src/utils.dart';
import 'package:source_gen/source_gen.dart';

/// Visits all the methods of a service and generates appropriate code
/// for overriding parent methods. This visitor is called in
/// [ScreenServiceGenerator] to override methods that are annotated
class MethodOverrideGenerator extends SimpleElementVisitor {
  MethodOverrideGenerator({
    required this.overrides,
    required this.imports,
  });

  List<String> overrides;
  List<String> imports;

  @override
  visitMethodElement(MethodElement element) {
    List<ElementAnnotation> annotations = element.declaration.metadata.toList();
    // if there are no annotations skip this method
    if (annotations.isNotEmpty) {
      List<DartType> methodAnnotations = [];
      String methodWithExecutionArgs = Utils.methodWithExecutionArgs(
        element,
        imports,
      );
      List<String> aroundHooks = [];
      for (ElementAnnotation annotation in annotations) {
        DartType? type = annotation.computeConstantValue()?.type;
        _validateAnnotation(type, methodAnnotations, element);
        if (type != null) {
          // taken from [library.annotatedWith] implementation
          // finds the implementation for [annotation] and visits its
          // methods to look for the appropriate hook
          final DartObject? annotationObject =
              TypeChecker.fromStatic(type).firstAnnotationOfExact(element);
          _validateAnnotationImpl(element, type, annotationObject);
          if (annotationObject != null) {
            List<String> availableHooks = [];
            LibraryElement? lib = annotationObject.type?.element?.library;
            lib?.topLevelElements
                .firstWhere((element) => element.displayName.contains('\$\$'))
                .visitChildren(AspectVisitor(availableHooks));

            String annotationImport = type.element?.location?.encoding ?? '';
            if (annotationImport.isNotEmpty) {
              annotationImport = annotationImport.split(';').first;
              imports.add("import '$annotationImport';");
            }

            _validateHookImpl(element, availableHooks, type);

            String methodName = element.isAsynchronous
                ? CodeGenConstants.invokeOnAsync
                : CodeGenConstants.invokeOnSync;
            String await = element.isAsynchronous ? 'await' : '';
            aroundHooks.add('''
              $await \$\$${type.getDisplayString(withNullability: false)}().$methodName(
            ''');
          }
        }
      }
      String nestedAroundMethods = _nestAroundMethods(
          methodWithExecutionArgs, aroundHooks,
          isAsync: element.isAsynchronous);

      String declaration =
          element.declaration.getDisplayString(withNullability: false);
      String async = element.isAsynchronous ? 'async' : '';
      overrides.add('''
              @override
              $declaration $async {
                ${aroundHooks.isEmpty ? methodWithExecutionArgs : nestedAroundMethods};
              }
            ''');
      return super.visitMethodElement(element);
    }
  }

  String _nestAroundMethods(
    String methodWithExecutionArgs,
    List<String> aroundHooks, {
    bool isAsync = false,
  }) {
    String aroundHook = '''
      ${isAsync ? 'await' : ''} $methodWithExecutionArgs
      ''';
    for (String s in aroundHooks.reversed) {
      aroundHook = '''
          $s ${isAsync ? '() async {' : '() =>'} $aroundHook
        ''';
    }
    String closing =
        List.generate(aroundHooks.length, (index) => isAsync ? ';})' : ')')
            .join(isAsync ? '' : ',');
    aroundHook = '''
        $aroundHook$closing
      ''';
    return aroundHook;
  }

  void _validateAnnotation(
    DartType? type,
    List<DartType> methodAnnotations,
    MethodElement element,
  ) {
    if (type != null) {
      if (!methodAnnotations.contains(type)) {
        methodAnnotations.add(type);
      } else {
        throw InvalidGenerationSourceError(
            'methods should not have duplicate annotations',
            todo: 'Create new aspect if required',
            element: element);
      }
    } else {
      throw InvalidGenerationSourceError(
          'No valid implementation found for one or many aspects',
          todo: 'Make sure generated aspect files don\'t have errors',
          element: element);
    }
  }

  void _validateHookImpl(
    MethodElement element,
    List<String> availableHooks,
    DartType annotationType,
  ) {
    if (element.isAsynchronous &&
        !availableHooks.contains(CodeGenConstants.invokeOnAsync)) {
      throw InvalidGenerationSourceError(
          'No method annotated with @${CodeGenConstants.invokeOnAsync} in \$$annotationType',
          todo: 'Make sure generated aspect files don\'t have errors',
          element: element);
    }

    if (!element.isAsynchronous &&
        !availableHooks.contains(CodeGenConstants.invokeOnSync)) {
      throw InvalidGenerationSourceError(
          'No method annotated with @${CodeGenConstants.invokeOnSync} in \$$annotationType',
          todo: 'Make sure generated aspect files don\'t have errors',
          element: element);
    }
  }

  void _validateAnnotationImpl(
    MethodElement element,
    DartType annotationType,
    DartObject? annotationObject,
  ) {
    if (annotationObject == null) {
      throw InvalidGenerationSourceError(
        'No implementation found for \$$annotationType',
        todo: 'Make sure generated aspect files don\'t have errors',
        element: element,
      );
    }
  }
}
