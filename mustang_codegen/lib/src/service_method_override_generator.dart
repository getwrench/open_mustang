import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:mustang_codegen/src/codegen_constants.dart';
import 'package:mustang_codegen/src/utils.dart';
import 'package:mustang_codegen/src/visitors/generated_aspect_visitor.dart';
import 'package:mustang_core/mustang_core.dart';
import 'package:source_gen/source_gen.dart';

/// Visits all the methods of a service and generates appropriate code
/// for overriding parent methods. This visitor is called in
/// [ScreenServiceGenerator] to override methods that are annotated
class ServiceMethodOverrideGenerator extends SimpleElementVisitor {
  ServiceMethodOverrideGenerator({
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

      final DartObject? beforeAnnotationObject =
          TypeChecker.fromRuntime(Before).firstAnnotationOfExact(element);
      _generateBeforeHooks(
        element,
        beforeAnnotationObject,
        beforeHooks,
        imports,
      );

      final DartObject? afterAnnotationObject =
          TypeChecker.fromRuntime(After).firstAnnotationOfExact(element);
      _generateAfterHooks(
        element,
        afterAnnotationObject,
        afterHooks,
        imports,
      );

      final DartObject? aroundAnnotationObject =
          TypeChecker.fromRuntime(Around).firstAnnotationOfExact(element);
      _generateAroundHooks(
        element,
        aroundAnnotationObject,
        aroundHooks,
        imports,
        isSourceMethodAsync: element.isAsynchronous,
      );

      if (beforeAnnotationObject != null ||
          afterAnnotationObject != null ||
          aroundAnnotationObject != null) {
        _validateSourceMethodAsync(element);
      }

      String nestedAroundMethods = _nestAroundMethods(
        methodWithExecutionArgs,
        aroundHooks,
        isAsync: element.isAsynchronous,
      );

      String declaration =
          element.declaration.getDisplayString(withNullability: false);
      String async = element.isAsynchronous ? 'async' : '';
      String await = element.isAsynchronous ? 'await' : '';

      if (aroundHooks.isNotEmpty) {
        overrides.add('''
          @override
          $declaration $async {
            ${beforeHooks.join('')}
            $await ${aroundHooks.isEmpty ? methodWithExecutionArgs : nestedAroundMethods};
            ${afterHooks.join('')}
          }
        ''');
      }
      return super.visitMethodElement(element);
    }
  }

  void _generateBeforeHooks(
    MethodElement element,
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
              GeneratedAspectVisitor(
                invokeParameters,
              ),
            );
            _validateBeforeOrAfterAspectParameters(
              element,
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
              await $aspectName().$methodName();
            ''');
          }
        }
      }
    }
  }

  void _generateAfterHooks(
    MethodElement element,
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
              GeneratedAspectVisitor(
                invokeParameters,
              ),
            );
            _validateBeforeOrAfterAspectParameters(
              element,
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
              await $aspectName().$methodName();
            ''');
          }
        }
      }
    }
  }

  void _generateAroundHooks(
    MethodElement element,
    DartObject? aroundAnnotationObject,
    List<String> aroundHooks,
    List<String> imports, {
    isSourceMethodAsync = false,
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
          aspectExtensionObject?.visitChildren(GeneratedAspectVisitor(
            invokeParameters,
          ));
          _validateAroundInvokeParameters(
            element,
            invokeParameters,
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
          aroundHooks.add('''
              $aspectName().$methodName(
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

  void _validateSourceMethodAsync(MethodElement element) {
    if (!element.returnType.isDartAsyncFuture) {
      throw InvalidGenerationSourceError(
        '''Error: Annotated methods must be async and return a Future. 
  example: 
      @Before([sampleAspect])
      Future<void> sourceMethod() async {
        print('Source method -> run'); 
      }''',
        todo: 'Make sure generated aspect files don\'t have errors',
        element: element,
      );
    }
  }

  void _validateAroundInvokeParameters(
    MethodElement element,
    List<ParameterElement> invokeParameters,
  ) {
    if (invokeParameters.isEmpty) {
      throw InvalidGenerationSourceError(
        '''Error: Around aspects must accept sourceMethod as an argument.
  example:
    @invoke 
    Future<void> run(Function sourceMethod) async {
      print('before sourceMethod');
      await sourceMethod();
      print('after sourceMethod');
    }''',
        todo: 'Make sure generated aspect files don\'t have errors',
        element: element,
      );
    }

    if (invokeParameters.length > 1 ||
        !invokeParameters.first.type.isDartCoreFunction) {
      throw InvalidGenerationSourceError(
        '''Error: Around aspects must only accept sourceMethod as an argument.
  example: 
    @invoke 
    Future<void> run(Function sourceMethod) async {
      print('before sourceMethod ');
      await sourceMethod();
      print('after sourceMethod');
    }
    
 ${invokeParameters.length} Found: ${invokeParameters.join(', ')}''',
        todo: 'Make sure generated aspect files don\'t have errors',
      );
    }
  }

  void _validateBeforeOrAfterAspectParameters(
    MethodElement element,
    List<ParameterElement> invokeParameters,
    DartType? annotationType,
  ) {
    if (invokeParameters.isNotEmpty) {
      throw InvalidGenerationSourceError(
        'Error: Method annotated with @invoke in \$$annotationType expects ${invokeParameters.join(', ')} as argument\nbut Before or After aspect should not accept any.',
        todo: 'Make sure generated aspect files don\'t have errors',
        element: element,
      );
    }
  }
}
