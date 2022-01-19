import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
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
    String importAspect = p.basenameWithoutExtension(buildStep.inputId.path);

    String pkgName = buildStep.inputId.package;

    List<String> beforeHooks = [];
    List<String> afterHooks = [];
    List<String> aroundHooks = [];

    element.visitChildren(HookGenerator(
      beforeHooks,
      afterHooks,
      aroundHooks,
    ));

    String before = '''''';

    if (beforeHooks.isNotEmpty) {
      before = '''
      void before() {
        ${beforeHooks.join('\n')}
      }
      ''';
    }

    String after = '''''';

    if (afterHooks.isNotEmpty) {
      after = '''
      void after() {
        ${afterHooks.join('\n')}
      }
      ''';
    }

    String around = '''''';

    if (aroundHooks.isNotEmpty) {
      around = '''
      void around(void Function() sourceMethod) {
        ${aroundHooks.join('\n')}
      }
      ''';
    }

    return '''   
      import 'package:mustang_core/mustang_core.dart';
      import 'package:$pkgName/src/aspects/$importAspect.dart';
      
      class ${generatedAspectName}Hook extends $aspectName {
        $before
        
        $after
        
        $around
      }
      
      class $generatedAspectName {
        const $generatedAspectName({
          required this.jointPoint,
        });
        
        final JointPoint jointPoint;
      }
    ''';
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
