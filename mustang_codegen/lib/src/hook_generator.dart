import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:source_gen/source_gen.dart';

/// Visits all the methods for the aspect and generates appropriate hooks
class HookGenerator extends SimpleElementVisitor {
  const HookGenerator(
    this.before,
    this.after,
    this.around,
  );

  final List<String> before;

  final List<String> around;

  final List<String> after;

  @override
  visitMethodElement(MethodElement element) {
    // if there are no annotations skip this method
    if (element.metadata.isNotEmpty) {
      DartType? type = element.metadata.first.computeConstantValue()?.type;
      if (type != null) {
        switch (type.getDisplayString(withNullability: false)) {
          case ('Around'):
            if (around.isEmpty) {
              around.add('''
            super.${element.displayName}(sourceMethod);
          ''');
            } else {
              throw InvalidGenerationSourceError(
                  'Only 1 @around annotation allowed per aspect ',
                  todo: 'Use @around for only 1 method',
                  element: element);
            }
            break;
          case ('Before'):
            if (before.isEmpty) {
              before.add('''
            super.${element.displayName}();
          ''');
            } else {
              throw InvalidGenerationSourceError(
                  'Only 1 @before annotation allowed per aspect',
                  todo: 'Use @before for only 1 method',
                  element: element);
            }
            break;
          case ('After'):
            if (after.isEmpty) {
              after.add('''
            super.${element.displayName}();
          ''');
            } else {
              throw InvalidGenerationSourceError(
                  'Only 1 @after annotation allowed per aspect ',
                  todo: 'Use @after for only 1 method',
                  element: element);
            }
            break;
        }
      }
    }
    super.visitMethodElement(element);
  }
}
