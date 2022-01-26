import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:mustang_codegen/src/aspect_visitor.dart';
import 'package:mustang_codegen/src/codegen_constants.dart';
import 'package:mustang_codegen/src/utils.dart';
import 'package:mustang_core/mustang_core.dart';
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
      String methodWithExecutionArgs = Utils.methodWithExecutionArgs(
        element,
        imports,
      );
      List<String> beforeHooks = [];
      List<String> afterHooks = [];
      List<String> aroundHooks = [];
      List<String> onExceptionHooks = [];

      final DartObject? beforeAnnotationObject =
          TypeChecker.fromRuntime(Before).firstAnnotationOfExact(element);
      _generateBeforeHooks(beforeAnnotationObject, beforeHooks, imports);

      final DartObject? afterAnnotationObject =
          TypeChecker.fromRuntime(After).firstAnnotationOfExact(element);
      _generateAfterHooks(afterAnnotationObject, afterHooks, imports);

      final DartObject? aroundAnnotationObject =
          TypeChecker.fromRuntime(Around).firstAnnotationOfExact(element);
      _generateAroundHooks(aroundAnnotationObject, aroundHooks, imports);

      final DartObject? onExceptionAnnotationObject =
          TypeChecker.fromRuntime(OnException).firstAnnotationOfExact(element);
      _generateOnExceptionHooks(
        onExceptionAnnotationObject,
        onExceptionHooks,
        imports,
      );

      String nestedAroundMethods = _nestAroundMethods(
        methodWithExecutionArgs,
        aroundHooks,
        isAsync: element.isAsynchronous,
      );

      String declaration =
          element.declaration.getDisplayString(withNullability: false);
      String async = element.isAsynchronous ? 'async' : '';
      String await = element.isAsynchronous ? 'await' : '';
      if (onExceptionHooks.isNotEmpty) {
        overrides.add('''
          @override
          $declaration $async {
            try {
              ${beforeHooks.join('')}
              ${aroundHooks.isEmpty ? '$await $methodWithExecutionArgs' : nestedAroundMethods};
              ${afterHooks.join('')}
            } catch(e, stackTrace) {
              ${onExceptionHooks.join('')}
            }
          }
        ''');
      } else {
        overrides.add('''
          @override
          $declaration $async {
            ${beforeHooks.join('')}
            ${aroundHooks.isEmpty ? '$await $methodWithExecutionArgs' : nestedAroundMethods};
            ${afterHooks.join('')}
          }
        ''');
      }
      return super.visitMethodElement(element);
    }
  }

  void _generateBeforeHooks(
    DartObject? beforeAnnotationObject,
    List<String> beforeHooks,
    List<String> imports,
  ) {
    if (beforeAnnotationObject != null) {
      List<DartObject> aspects =
          beforeAnnotationObject.getField('aspects')?.toListValue() ?? [];
      // add validation for when its empty
      if (aspects.isNotEmpty) {
        for (DartObject aspect in aspects) {
          if (aspect.type?.getDisplayString(withNullability: false) != null) {
            List<ParameterElement> invokeParameters = [];
            Element? aspectExtensionObject = aspect
                .type?.element?.library?.topLevelElements
                .firstWhere((element) => element.displayName.contains('\$\$'));

            aspectExtensionObject?.visitChildren(
              AspectVisitor(invokeParameters),
            );
            _validateBeforeOrAfterAspectParameters(
              invokeParameters,
              aspect.type,
            );
            String annotationImport =
                aspect.type?.element?.location?.encoding ?? '';
            if (annotationImport.isNotEmpty) {
              annotationImport = annotationImport.split(';').first;
              imports.add("import '$annotationImport';");
            }
            String methodName = CodeGenConstants.invoke;
            String aspectName =
                '\$\$${aspect.type?.getDisplayString(withNullability: false)}';
            beforeHooks.add('''
              $aspectName().$methodName();
            ''');
          }
        }
      }
    }
  }

  void _generateAfterHooks(
    DartObject? afterAnnotationObject,
    List<String> afterHooks,
    List<String> imports,
  ) {
    if (afterAnnotationObject != null) {
      List<DartObject> aspects =
          afterAnnotationObject.getField('aspects')?.toListValue() ?? [];
      // add validation for when its empty
      if (aspects.isNotEmpty) {
        for (DartObject aspect in aspects) {
          if (aspect.type?.getDisplayString(withNullability: false) != null) {
            List<ParameterElement> invokeParameters = [];
            Element? aspectExtensionObject = aspect
                .type?.element?.library?.topLevelElements
                .firstWhere((element) => element.displayName.contains('\$\$'));

            aspectExtensionObject?.visitChildren(
              AspectVisitor(invokeParameters),
            );
            _validateBeforeOrAfterAspectParameters(
              invokeParameters,
              aspect.type,
            );
            String annotationImport =
                aspect.type?.element?.location?.encoding ?? '';
            if (annotationImport.isNotEmpty) {
              annotationImport = annotationImport.split(';').first;
              imports.add("import '$annotationImport';");
            }
            String methodName = CodeGenConstants.invoke;
            String aspectName =
                '\$\$${aspect.type?.getDisplayString(withNullability: false)}';
            afterHooks.add('''
              $aspectName().$methodName();
            ''');
          }
        }
      }
    }
  }

  void _generateAroundHooks(
    DartObject? aroundAnnotationObject,
    List<String> aroundHooks,
    List<String> imports, {
    bool isAsync = false,
  }) {
    if (aroundAnnotationObject != null) {
      DartObject? aspect = aroundAnnotationObject.getField('aspect');
      // add validation for when its empty
      if (aspect != null) {
        if (aspect.type?.getDisplayString(withNullability: false) != null) {
          List<ParameterElement> invokeParameters = [];
          Element? aspectExtensionObject = aspect
              .type?.element?.library?.topLevelElements
              .firstWhere((element) => element.displayName.contains('\$\$'));

          aspectExtensionObject?.visitChildren(AspectVisitor(invokeParameters));
          _validateAroundInvokeParameters(invokeParameters, aspect.type);
          String annotationImport =
              aspect.type?.element?.location?.encoding ?? '';
          if (annotationImport.isNotEmpty) {
            annotationImport = annotationImport.split(';').first;
            imports.add("import '$annotationImport';");
          }
          String methodName = CodeGenConstants.invoke;
          String await = isAsync ? 'await' : '';
          String aspectName =
              '\$\$${aspect.type?.getDisplayString(withNullability: false)}';
          aroundHooks.add('''
              $await $aspectName().$methodName(
            ''');
        }
      }
    }
  }

  void _generateOnExceptionHooks(DartObject? onExceptionAnnotationObject,
      List<String> onExceptionHooks, List<String> imports) {
    if (onExceptionAnnotationObject != null) {
      DartObject? aspect = onExceptionAnnotationObject.getField('aspect');
      // add validation for when its empty
      if (aspect != null) {
        if (aspect.type?.getDisplayString(withNullability: false) != null) {
          List<ParameterElement> invokeParameters = [];
          Element? aspectExtensionObject = aspect
              .type?.element?.library?.topLevelElements
              .firstWhere((element) => element.displayName.contains('\$\$'));

          aspectExtensionObject?.visitChildren(AspectVisitor(invokeParameters));
          _validateOnExceptionInvokeParameters(invokeParameters, aspect.type);
          String annotationImport =
              aspect.type?.element?.location?.encoding ?? '';
          if (annotationImport.isNotEmpty) {
            annotationImport = annotationImport.split(';').first;
            imports.add("import '$annotationImport';");
          }
          String methodName = CodeGenConstants.invoke;
          String aspectName =
              '\$\$${aspect.type?.getDisplayString(withNullability: false)}';
          onExceptionHooks.add('''
            $aspectName().$methodName(e, stackTrace);
          ''');
        }
      }
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

  void _validateOnExceptionInvokeParameters(
    List<ParameterElement> invokeParameters,
    DartType? annotationType,
  ) {
    if (invokeParameters.isEmpty ||
        ((invokeParameters.isNotEmpty && invokeParameters.length != 2))) {
      throw InvalidGenerationSourceError(
        '[\$$annotationType] OnException aspects must accept Object e and StackTrace stackTrace as arguments',
        todo: 'Make sure generated aspect files don\'t have errors',
      );
    }
  }

  void _validateAroundInvokeParameters(
    List<ParameterElement> invokeParameters,
    DartType? annotationType,
  ) {
    if (invokeParameters.isEmpty) {
      throw InvalidGenerationSourceError(
        '[\$$annotationType] Around aspects must accept Function sourceMethod as an argument',
        todo: 'Make sure generated aspect files don\'t have errors',
      );
    }

    if (invokeParameters.isNotEmpty &&
        invokeParameters.length > 1 &&
        !invokeParameters.first.type.isDartCoreFunction) {
      throw InvalidGenerationSourceError(
        '[\$$annotationType] Around aspects must only accept Function sourceMethod as an argument. ${invokeParameters.length} Found: $invokeParameters}',
        todo: 'Make sure generated aspect files don\'t have errors',
      );
    }
  }

  void _validateBeforeOrAfterAspectParameters(
    List<ParameterElement> invokeParameters,
    DartType? annotationType,
  ) {
    if (invokeParameters.isNotEmpty) {
      throw InvalidGenerationSourceError(
        '[\$$annotationType] Before or After aspect should not accept any arguments. ${invokeParameters.length} Found: $invokeParameters',
        todo: 'Make sure generated aspect files don\'t have errors',
      );
    }
  }
}
