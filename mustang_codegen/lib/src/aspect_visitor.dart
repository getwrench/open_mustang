import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:mustang_codegen/src/codegen_constants.dart';

/// Visits an generated aspect file and finds all parameters
/// for an aspect
class AspectVisitor extends SimpleElementVisitor {
  const AspectVisitor(
    this.invokeParameters,
    this.isInvokeAsync,
  );

  final List<ParameterElement> invokeParameters;

  final List<bool> isInvokeAsync;

  @override
  visitMethodElement(MethodElement element) {
    switch (element.displayName) {
      case CodeGenConstants.invoke:
        if (element.returnType.isDartAsyncFuture) {
          isInvokeAsync.add(true);
        }
        invokeParameters.addAll(element.parameters.toList());
        break;
    }
    super.visitMethodElement(element);
  }
}
