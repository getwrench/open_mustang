import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:mustang_codegen/src/codegen_constants.dart';
import 'package:mustang_codegen/src/utils.dart';
import 'package:source_gen/source_gen.dart';

/// Visits all the methods for the aspect and generates appropriate hooks.
/// It is used by [AppAspectGenerator] to find method annotated with
/// @invoke in user written aspect
class HookGenerator extends SimpleElementVisitor {
  const HookGenerator(
    this.invokeHooks,
    this.imports,
  );

  final List<String> invokeHooks;

  final List<String> imports;

  @override
  visitMethodElement(MethodElement element) {
    // if there are no annotations skip this method
    if (element.metadata.isNotEmpty) {
      DartType? type = element.metadata.first.computeConstantValue()?.type;
      if (type != null) {
        _validation(
          element,
          invokeHooks,
          type.getDisplayString(withNullability: false),
        );
        switch (type.getDisplayString(withNullability: false)) {
          case 'Invoke':
            String methodWithExecutionArgs = Utils.methodWithExecutionArgs(
              element,
              imports,
            );
            String params = element.parameters.join(',');
            invokeHooks.add('''
              void ${CodeGenConstants.invoke}($params) ${element.isAsynchronous ? 'async' : ''} {         
                ${element.isAsynchronous ? 'await' : ''} $methodWithExecutionArgs;
              }
            ''');
            break;
        }
      }
    }

    super.visitMethodElement(element);
  }

  void _validation(
    MethodElement element,
    List<String> invokeHooks,
    String type,
  ) {
    if (element.isAsynchronous && !element.returnType.isDartAsyncFuture) {
      throw InvalidGenerationSourceError(
        'async method must return a future ',
        todo: 'use Future<T> as return type',
        element: element,
      );
    }

    if (invokeHooks.isNotEmpty && type == 'Invoke') {
      throw InvalidGenerationSourceError(
        'Only 1 @${CodeGenConstants.invoke} annotation allowed per aspect ',
        todo: 'Use @${CodeGenConstants.invoke} for only 1 method',
        element: element,
      );
    }
  }
}
