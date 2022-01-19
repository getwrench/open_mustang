import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:mustang_codegen/src/aspect_visitor.dart';
import 'package:mustang_codegen/src/utils.dart';
import 'package:mustang_core/mustang_core.dart';
import 'package:source_gen/source_gen.dart';

/// Visits all the methods of a service and generates appropriate code
/// for overriding parent method(s)
class HookOverrideGenerator extends SimpleElementVisitor {
  HookOverrideGenerator({
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
      String methodWithExecutionArgs = Utils.methodWithExecutionArgs(element);
      List<String> beforeHooks = [];
      List<String> afterHooks = [];
      List<String> aroundHooks = [];
      for (ElementAnnotation annotation in annotations) {
        DartType? type = annotation.computeConstantValue()?.type;

        if (type != null) {
          if (!methodAnnotations.contains(type)) {
            methodAnnotations.add(type);
          } else {
            throw InvalidGenerationSourceError(
                'methods may not have duplicate annotations',
                todo: 'Create new aspect if required',
                element: element);
          }
        } else {
          throw InvalidGenerationSourceError(
              'No valid implementation found for one or many aspects',
              todo: 'Make sure generated aspect files don\'t have errors',
              element: element);
        }

        // taken from [library.annotatedWith] implementation
        // finds the implementation for [annotation] and visits its
        // methods to look for the appropriate hook
        final DartObject? annotationObject =
            TypeChecker.fromStatic(type).firstAnnotationOfExact(element);
        if (annotationObject != null) {
          LibraryElement? lib = annotationObject.type?.element?.library;
          List<JointPoint> generatedMethodNames = [];
          lib?.topLevelElements
              .firstWhere((element) => element.displayName.contains('Hook'))
              .visitChildren(
                AspectVisitor(
                  generatedMethodNames,
                ),
              );
          AnnotatedElement annotatedElement = AnnotatedElement(
            ConstantReader(annotationObject),
            element,
          );
          int? index = annotatedElement.annotation
                  .read('jointPoint')
                  .objectValue
                  .getField('index')
                  ?.toIntValue() ??
              0;
          JointPoint jointPoint = JointPoint.values[index];
          if (generatedMethodNames.contains(jointPoint)) {
            String annotationImport = type.element?.location?.encoding ?? '';
            annotationImport = annotationImport.split(';').first;
            imports.add("import '$annotationImport';");
            switch (jointPoint) {
              case JointPoint.before:
                beforeHooks.add('''
                ${type.getDisplayString(withNullability: false)}Hook().before();
              ''');
                break;
              case JointPoint.after:
                afterHooks.add('''
                ${type.getDisplayString(withNullability: false)}Hook().after();
              ''');
                break;
              case JointPoint.around:
                aroundHooks.add('''
            ${type.getDisplayString(withNullability: false)}Hook().around(
          ''');
            }
          } else {
            switch (jointPoint) {
              case JointPoint.around:
                throw InvalidGenerationSourceError(
                    'No method annotated with @around in \$$type',
                    todo: 'Add @around to a method',
                    element: element);
              case JointPoint.before:
                throw InvalidGenerationSourceError(
                    'No method annotated with @before in \$$type',
                    todo: 'Add @before to a method',
                    element: element);
              case JointPoint.after:
                throw InvalidGenerationSourceError(
                    'No method annotated with @after in \$$type',
                    todo: 'Add @after to a method',
                    element: element);
            }
          }
        }
      }
      String nestedAroundMethods = _nestAroundMethods(
        methodWithExecutionArgs,
        aroundHooks,
      );

      String declaration =
          element.declaration.getDisplayString(withNullability: false);
      overrides.add('''
              @override
              $declaration  ${element.isAsynchronous ? "async" : ""} {
                ${beforeHooks.join('')}
                ${aroundHooks.isEmpty ? methodWithExecutionArgs : nestedAroundMethods};
                ${afterHooks.join('')}
              }
            ''');
      overrides = overrides.toSet().toList();
      return super.visitMethodElement(element);
    }
  }

  String _nestAroundMethods(
    String methodWithExecutionArgs,
    List<String> aroundHooks,
  ) {
    String aroundHook = '''
      $methodWithExecutionArgs
      ''';
    for (String s in aroundHooks.reversed) {
      aroundHook = '''
          $s() => $aroundHook
        ''';
    }
    String closing =
        List.generate(aroundHooks.length, (index) => ')').join(',');
    aroundHook = '''
        $aroundHook,$closing
      ''';
    return aroundHook;
  }
}
