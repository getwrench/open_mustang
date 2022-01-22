import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Visits all the methods for the aspect and generates appropriate hooks.
/// It is used by [AppAspectGenerator] to find methods annotated with
/// @invoke in user written aspect
class HookGenerator extends SimpleElementVisitor {
  const HookGenerator(
    this.around,
  );

  final List<String> around;

  @override
  visitMethodElement(MethodElement element) {
    // if there are no annotations skip this method
    if (element.metadata.isNotEmpty) {
      DartType? type = element.metadata.first.computeConstantValue()?.type;
      if (type != null) {
        if (element.isAsynchronous) {
          if (!element.returnType.isDartAsyncFuture) {
            throw InvalidGenerationSourceError(
              'async method must return a future ',
              todo: 'Use @invoke for only 1 method',
              element: element,
            );
          }
        }
        switch (type.getDisplayString(withNullability: false)) {
          case ('Invoke'):
            if (around.isEmpty) {
              around.add('''
            ${element.isAsynchronous ? 'await' : ''} super.${element.displayName}(sourceMethod);
          ''');
            } else {
              throw InvalidGenerationSourceError(
                  'Only 1 @invoke annotation allowed per aspect ',
                  todo: 'Use @invoke for only 1 method',
                  element: element);
            }
            break;
        }
      }
    }
    super.visitMethodElement(element);
  }
}
