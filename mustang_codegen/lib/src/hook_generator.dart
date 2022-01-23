import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:mustang_codegen/src/codegen_constants.dart';
import 'package:source_gen/source_gen.dart';

/// Visits all the methods for the aspect and generates appropriate hooks.
/// It is used by [AppAspectGenerator] to find methods annotated with
/// @invoke in user written aspect
class HookGenerator extends SimpleElementVisitor {
  const HookGenerator(
    this.aroundOnSync,
    this.aroundOnAsync,
  );

  final List<String> aroundOnAsync;

  final List<String> aroundOnSync;

  @override
  visitMethodElement(MethodElement element) {
    // if there are no annotations skip this method
    if (element.metadata.isNotEmpty) {
      DartType? type = element.metadata.first.computeConstantValue()?.type;
      if (type != null) {
        _validation(
          element,
          aroundOnAsync,
          aroundOnSync,
          type.getDisplayString(withNullability: false),
        );
        switch (type.getDisplayString(withNullability: false)) {
          case 'InvokeOnAsync':
            aroundOnAsync.add('''
                super.${element.displayName}(sourceMethod);
              ''');
            break;
          case 'InvokeOnSync':
            aroundOnSync.add('''
                ${element.isAsynchronous ? 'await' : ''} super.${element.displayName}(sourceMethod);
              ''');
            break;
        }
      }
    }

    super.visitMethodElement(element);
  }

  void _validation(
    MethodElement element,
    List<String> aroundOnAsync,
    List<String> aroundOnSync,
    String type,
  ) {
    if (element.isAsynchronous && !element.returnType.isDartAsyncFuture) {
      throw InvalidGenerationSourceError(
        'async method must return a future ',
        todo: 'use Future<T> as return type',
        element: element,
      );
    }

    if (aroundOnAsync.isNotEmpty && type == 'InvokeOnAsync') {
      throw InvalidGenerationSourceError(
        'Only 1 @${CodeGenConstants.invokeOnAsync} annotation allowed per aspect ',
        todo: 'Use @${CodeGenConstants.invokeOnAsync} for only 1 method',
        element: element,
      );
    }

    if (aroundOnSync.isNotEmpty && type == 'InvokeOnSync') {
      throw InvalidGenerationSourceError(
        'Only 1 @${CodeGenConstants.invokeOnSync} annotation allowed per aspect ',
        todo: 'Use @${CodeGenConstants.invokeOnSync} for only 1 method',
        element: element,
      );
    }
  }
}
