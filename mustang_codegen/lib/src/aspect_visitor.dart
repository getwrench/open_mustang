import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:mustang_codegen/src/codegen_constants.dart';

/// Visits an generated aspect file and finds available hooks
class AspectVisitor extends SimpleElementVisitor {
  const AspectVisitor(this.availableHooks);

  final List<String> availableHooks;

  @override
  visitMethodElement(MethodElement element) {
    switch (element.displayName) {
      case CodeGenConstants.invokeOnAsync:
        availableHooks.add(CodeGenConstants.invokeOnAsync);
        break;
      case CodeGenConstants.invokeOnSync:
        availableHooks.add(CodeGenConstants.invokeOnSync);
        break;
    }
    super.visitMethodElement(element);
  }
}
