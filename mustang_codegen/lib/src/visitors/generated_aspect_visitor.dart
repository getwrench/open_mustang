import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:mustang_codegen/src/codegen_constants.dart';

/// Visits an generated aspect file and finds all parameters
/// for an aspect
class GeneratedAspectVisitor extends SimpleElementVisitor {
  const GeneratedAspectVisitor(
    this.invokeParameters,
  );

  final List<ParameterElement> invokeParameters;


  @override
  visitMethodElement(MethodElement element) {
    switch (element.displayName) {
      case CodeGenConstants.invoke:
        invokeParameters.addAll(element.parameters.toList());
        break;
    }
    super.visitMethodElement(element);
  }
}
