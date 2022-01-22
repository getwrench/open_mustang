import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
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

        String annotationImport = type.element?.location?.encoding ?? '';
        if (annotationImport.isNotEmpty) {
          annotationImport = annotationImport.split(';').first;
          imports.add("import '$annotationImport';");
        }
        aroundHooks.add('''
            ${element.isAsynchronous ? 'await' : ''} \$\$${type.getDisplayString(withNullability: false)}().around(
          ''');
      }
      String nestedAroundMethods = _nestAroundMethods(
          methodWithExecutionArgs, aroundHooks,
          isAsync: element.isAsynchronous);

      String declaration =
          element.declaration.getDisplayString(withNullability: false);
      overrides.add('''
              @override
              $declaration  ${element.isAsynchronous ? "async" : ""} {
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
}
