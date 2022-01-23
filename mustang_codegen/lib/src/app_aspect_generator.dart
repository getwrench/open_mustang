import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:mustang_codegen/src/codegen_constants.dart';
import 'package:mustang_codegen/src/hook_generator.dart';
import 'package:mustang_core/mustang_core.dart';
import 'package:path/path.dart' as p;
import 'package:source_gen/source_gen.dart';

class AppAspectGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    Iterable<AnnotatedElement> aspects =
        library.annotatedWith(const TypeChecker.fromRuntime(Aspect));
    StringBuffer serviceBuffer = StringBuffer();
    if (aspects.isEmpty) {
      return '$serviceBuffer';
    }

    serviceBuffer.writeln(_generate(
      aspects.first.element,
      aspects.first.annotation,
      buildStep,
    ));

    return '$serviceBuffer';
  }

  String _generate(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    _validate(element, annotation);

    String aspectName = element.displayName;
    String generatedAspectName = element.displayName.replaceFirst(r'$', '');
    String generatedAspectNameWithLowerCase =
        '${generatedAspectName[0].toLowerCase()}${generatedAspectName.substring(1)}';
    String importAspect = p.basenameWithoutExtension(buildStep.inputId.path);

    String pkgName = buildStep.inputId.package;

    List<String> aroundOnSyncHooks = [];
    List<String> aroundOnAsyncHooks = [];

    element.visitChildren(HookGenerator(
      aroundOnSyncHooks,
      aroundOnAsyncHooks,
    ));

    _validateHooksPresent(
      element,
      aroundOnSyncHooks,
      aroundOnAsyncHooks,
    );

    String aroundOnSyncMethod = '''''';

    if (aroundOnSyncHooks.isNotEmpty) {
      aroundOnSyncMethod = '''
        void ${CodeGenConstants.invokeOnSync}(Function sourceMethod) {
           ${aroundOnSyncHooks.join('\n')}
        }
      ''';
    }

    String aroundOnAsyncMethod = '''''';

    if (aroundOnAsyncHooks.isNotEmpty) {
      aroundOnAsyncMethod = '''
        Future<void> ${CodeGenConstants.invokeOnAsync}(Function sourceMethod) async {
           ${aroundOnAsyncHooks.join('\n')}
        }
      ''';
    }

    return '''   
      import 'package:mustang_core/mustang_core.dart';
      import 'package:$pkgName/src/aspects/$importAspect.dart';
      
      class \$\$$generatedAspectName extends $aspectName {        
        $aroundOnSyncMethod
        
        $aroundOnAsyncMethod
      }
      
      class $generatedAspectName {
        const $generatedAspectName();
      }
      
      const $generatedAspectNameWithLowerCase = $generatedAspectName();
    ''';
  }

  void _validateHooksPresent(
    Element element,
    List<String> aroundOnSyncHooks,
    List<String> aroundOnAsyncHooks,
  ) {
    if (aroundOnSyncHooks.isEmpty && aroundOnAsyncHooks.isEmpty) {
      throw InvalidGenerationSourceError(
        'Error: could not find any method annotated with @${CodeGenConstants.invokeOnSync} or @${CodeGenConstants.invokeOnAsync}',
        todo:
            'annotate a method with @${CodeGenConstants.invokeOnSync} or @${CodeGenConstants.invokeOnAsync}',
        element: element,
      );
    }
  }

  void _validate(Element element, ConstantReader annotation) {
    if (!element.displayName.startsWith(r'$')) {
      throw InvalidGenerationSourceError(
          'Aspect class name should start with \$',
          todo: 'Prefix class name with \$',
          element: element);
    }

    // class annotated with @aspect should be abstract
    ClassElement appServiceClass = element as ClassElement;
    if (!appServiceClass.isAbstract) {
      throw InvalidGenerationSourceError(
          'Error: class annotated with aspect should be abstract',
          todo: 'Make the class abstract',
          element: element);
    }
  }
}
