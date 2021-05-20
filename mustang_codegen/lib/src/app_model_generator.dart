import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:core/core.dart';
import 'package:mustang_codegen/src/app_model_field.dart';
import 'package:mustang_codegen/src/utils.dart';
import 'package:source_gen/source_gen.dart';

import 'app_model_method.dart';

class AppModelGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    Iterable<AnnotatedElement> appModels =
        library.annotatedWith(TypeChecker.fromRuntime(AppModel));
    StringBuffer appModelBuffer = StringBuffer();

    if (appModels.isEmpty) {
      return '$appModelBuffer';
    }

    appModelBuffer.writeln(_generate(
      appModels.first.element,
      appModels.first.annotation,
      buildStep,
    ));

    return '${appModelBuffer}';
  }

  String _generate(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    _validate(element);

    String appModelName = element.displayName.replaceFirst(r'$', '');
    ClassElement appModelClass = element as ClassElement;

    // Create an instance of AppModelField for each field in the model class
    List<AppModelField> appModelFields = _parseFields(appModelClass);

    // Create an instance of AppModelMethod for each method in the model class
    List<AppModelMethod> appModelMethods = _parseMethods(appModelClass);

    // Create field declarations in the built_value abstract class
    List<String> fieldDeclarations =
        _generateFields(appModelFields, appModelClass);

    // Create method definitions in the built_value abstract class
    List<String> methodDefinitions =
        _generateMethods(appModelMethods, appModelClass);

    // Create initializer method in the built_value abstract class
    String initializer = _generateInitializer(appModelFields, appModelName);

    String appModelFilename = '${Utils.class2File(appModelName)}.model';
    String appModelVarName = Utils.class2Var(appModelName);

    List<String> modelImports = Utils.getImports(element.library.imports);

    return '''
      import 'package:built_value/built_value.dart';
      import 'package:built_value/serializer.dart';
      ${modelImports.join('\n')}
      
      part '${appModelFilename}.g.dart';
      
      abstract class $appModelName implements Built<$appModelName, ${appModelName}Builder> {
        $appModelName._();
        factory $appModelName([void Function(${appModelName}Builder) updates]) = _\$$appModelName;
      
        ${fieldDeclarations.join('\n')}
      
        static Serializer<$appModelName> get serializer => _\$${appModelVarName}Serializer;
      
        $initializer
        
        ${methodDefinitions.join('\n')}
      }
    ''';
  }

  void _validate(Element element) {
    Utils.getRawImports(element.library.imports).forEach((import) {
      if (import.contains('\.model\.dart')) {
        throw InvalidGenerationSourceError(
            'It is not recommended to use model inside another model: $import',
            todo: 'Treat each Model as independent object',
            element: element);
      }
    });

    if (!element.displayName.startsWith(r'$')) {
      throw InvalidGenerationSourceError(
          'Model class name should start with \$',
          todo: 'Prefix class name with \$',
          element: element);
    }

    ClassElement appModelClass = element as ClassElement;
    appModelClass.fields.forEach((element) {
      // No getter/setter
      if (element.isSynthetic) {
        throw InvalidGenerationSourceError(
            'Explicit getter/setter not allowed in Models. Use method instead',
            todo: 'Convert getter/setter to a method',
            element: element);
      }

      // No static/const/final fields
      if (element.isStatic || element.isConst || element.isFinal) {
        throw InvalidGenerationSourceError(
            'Models fields should not be static or static const or final',
            todo: 'remove static/static const/final',
            element: element);
      }

      // List, Map are not allowed
      if (['List', 'Map'].contains(element.type.element.displayName)) {
        throw InvalidGenerationSourceError(
            'List/Map are not allowed for fields. Use BuiltList/BuiltMap instead',
            todo: 'Use BuiltList/BuiltMap',
            element: element);
      }
    });
  }

  List<AppModelField> _parseFields(ClassElement appModelClass) {
    return appModelClass.fields.map(
      (fieldElement) {
        String fieldName = fieldElement.name;
        String fieldType =
            fieldElement.type.getDisplayString(withNullability: false);
        String typeToMatch = fieldType;
        if (fieldType.startsWith('BuiltList')) {
          typeToMatch = 'BuiltList';
        }
        if (fieldType.startsWith('BuiltMap')) {
          typeToMatch = 'BuiltMap';
        }

        Object initValue;
        List<Object> initListValue;
        Map<Object, Object> initMapValue;
        final annotations =
            TypeChecker.fromRuntime(InitField).annotationsOf(fieldElement);
        if (annotations.isNotEmpty) {
          switch (typeToMatch) {
            case 'String':
              initValue =
                  "'${annotations.single.getField('object').toStringValue()}'";
              break;
            case 'int':
              initValue =
                  '${annotations.single.getField('object').toIntValue()}';
              break;
            case 'double':
              initValue =
                  '${annotations.single.getField('object').toDoubleValue()}';
              break;
            case 'bool':
              initValue =
                  '${annotations.single.getField('object').toBoolValue()}';
              break;
            case 'BuiltMap':
              initMapValue = Map();
              annotations.single
                  .getField('object')
                  .toMapValue()
                  .entries
                  .forEach((entry) {
                initMapValue[ConstantReader(entry.key).literalValue] =
                    ConstantReader(entry.value).literalValue;
              });
              break;
            case 'BuiltList':
              initListValue =
                  annotations.single.getField('object').toListValue().map((e) {
                if (e.type.isDartCoreString) {
                  return "'${ConstantReader(e).literalValue}'";
                }
                return ConstantReader(e).literalValue;
              }).toList();
              break;
            default:
              print(fieldType);
          }
        }

        return AppModelField(
          name: fieldName,
          type: fieldType,
          initValue: initValue,
          initListValue: initListValue,
          initMapValue: initMapValue,
        );
      },
    ).toList();
  }

  // TODO Brittle code
  List<AppModelMethod> _parseMethods(ClassElement appModelClass) {
    List<AppModelMethod> appModelMethods = appModelClass.methods.map(
      (methodElement) {
        return AppModelMethod(
          name: methodElement.name,
          type: methodElement.returnType.element.displayName,
          sourceOffset: methodElement.nameOffset,
        );
      },
    ).toList();

    // update sourceLength of for each field
    // Type method1 body1 ... Type method2 body2
    appModelMethods.asMap().forEach((index, field) {
      if (index == 0) return;
      if (index <= appModelMethods.length - 1) {
        AppModelMethod prevField = appModelMethods.elementAt(index - 1);
        prevField.sourceLength = (prevField.sourceOffset - 1) +
            (field.sourceOffset - prevField.sourceOffset);
        prevField.sourceLength -= field.type.length;
      }
    });
    return appModelMethods;
  }

  List<String> _generateFields(
    List<AppModelField> appModelFields,
    ClassElement appModelClass,
  ) {
    return appModelFields.map(
      (field) {
        String declaration = '${field.type} get ${field.name};\n';
        if (field.initValue == null &&
            field.initListValue == null &&
            field.initMapValue == null) {
          return '''
            @nullable
            $declaration
          ''';
        } else {
          return declaration;
        }
      },
    ).toList();
  }

  List<String> _generateMethods(
    List<AppModelMethod> appModelMethods,
    ClassElement appModelClass,
  ) {
    String source = appModelClass.source.contents.data;
    return appModelMethods.map((element) {
      String methodDefinition = element.sourceLength == null
          ? source.substring(element.sourceOffset).replaceFirst('}', '')
          : source.substring(element.sourceOffset, element.sourceLength);
      return '${element.type} $methodDefinition';
    }).toList();
  }

  String _generateInitializer(
    List<AppModelField> appModelFields,
    String appModelName,
  ) {
    String initializer =
        'static void _initializeBuilder(${appModelName}Builder builder) => builder\n';
    List<String> initFields = appModelFields.map((field) {
      if (field.initValue != null ||
          field.initListValue != null ||
          field.initMapValue != null) {
        if (field.type.startsWith('BuiltList')) {
          return '..${field.name}.addAll(${field.initListValue})';
        }

        if (field.type.startsWith('BuiltMap')) {
          return '..${field.name}.addAll(${field.initMapValue})';
        }

        return '..${field.name} = ${field.initValue}';
      }
    }).toList();
    initFields.removeWhere((element) => element == null);

    if (initFields.isEmpty) {
      initializer = '';
    } else {
      initializer += '${initFields.join('\n')};';
    }

    return initializer;
  }
}
