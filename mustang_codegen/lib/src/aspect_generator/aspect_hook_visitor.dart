import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:mustang_codegen/src/codegen_constants.dart';
import 'package:mustang_core/mustang_core.dart';
import 'package:source_gen/source_gen.dart';

/// Visits all the methods for the aspect and generates appropriate hooks.
/// It is used by [AppAspectGenerator] to find method annotated with
/// @invoke in user written aspect
class AspectHookVisitor extends SimpleElementVisitor<void> {
  const AspectHookVisitor(
    this.invokeHooks,
  );

  final List<MethodElement> invokeHooks;

  @override
  void visitMethodElement(MethodElement element) {
    // if there are no annotations skip this method
    if (element.metadata.isNotEmpty) {
      final DartObject? invokeAnnotationObject =
          TypeChecker.fromRuntime(Invoke).firstAnnotationOfExact(element);
      _validate(element, invokeHooks);
      if (invokeAnnotationObject != null) {
        invokeHooks.add(element);
      }
    }

    super.visitMethodElement(element);
  }

  void _validate(MethodElement element, List<MethodElement> invokeHooks) {
    if (invokeHooks.length > 1) {
      throw InvalidGenerationSourceError(
        'Error: Only 1 @${CodeGenConstants.invoke} annotation allowed per aspect. ${invokeHooks.length} Found: ${invokeHooks.join(', ')}',
        todo: 'Use @${CodeGenConstants.invoke} for only 1 method',
        element: element,
      );
    }

    if (!element.returnType.isDartAsyncFuture) {
      throw InvalidGenerationSourceError(
        '''Error: All aspects must be async and return a Future
  Example:
    @invoke 
    Future<void> run(Map<String, dynamic> args) async {
      print('sample aspect');
    }''',
        todo: 'use Future<T> as return type',
        element: element,
      );
    }

    if (element.parameters.isEmpty) {
      throw InvalidGenerationSourceError(
        '''Error: Aspects should not have empty arguments
  Example:
    @invoke 
    Future<void> run(Map<String, dynamic> args) async {
      print('sample aspect');
    }''',
        todo: 'Add missing arguments',
        element: element,
      );
    }

    if (element.parameters.length == 1 &&
        element.parameters.first.type.isDartCoreFunction) {
      throw InvalidGenerationSourceError(
        '''Error: When there is only 1 argument, it should be a Map.
  Example:
    @invoke
    Future<void> run(Map<String, dynamic> args) async {
    }
    
${element.parameters.length} Found: ${element.parameters.join(', ')}''',
        todo: 'annotate a method with @${CodeGenConstants.invoke}',
        element: element,
      );
    }

    if (element.parameters.length > 1 &&
        !element.parameters.last.type.isDartCoreFunction) {
      throw InvalidGenerationSourceError(
        '''Error: Methods annotated with @invoke can only accept sourceMethod as argument.
  Example:
    @invoke
    Future<void> run(Map<String, dynamic> args, Function sourceMethod) async {
      print('before sourceMethod');
      await sourceMethod();
      print('after sourceMethod');
    }
    
${element.parameters.length} Found: ${element.parameters.join(', ')}''',
        todo: 'annotate a method with @${CodeGenConstants.invoke}',
        element: element,
      );
    }
  }
}
