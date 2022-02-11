import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:mustang_codegen/src/model_generator/app_model_field.dart';
import 'package:mustang_codegen/src/utils.dart';
import 'package:mustang_core/mustang_core.dart';
import 'package:source_gen/source_gen.dart';

class AppModelGenerator extends Generator {
  @override
  String generate(LibraryReader library, BuildStep buildStep) {
    Iterable<AnnotatedElement> appModels =
        library.annotatedWith(const TypeChecker.fromRuntime(AppModel));
    Iterable<AnnotatedElement> appEvents =
        library.annotatedWith(const TypeChecker.fromRuntime(AppEvent));

    StringBuffer appModelBuffer = StringBuffer();

    if (appModels.isEmpty) {
      return '$appModelBuffer';
    }

    appModelBuffer.writeln(_generate(
      appModels.first.element,
      appModels.first.annotation,
      buildStep,
      appEvents.isNotEmpty,
    ));

    return '$appModelBuffer';
  }

  String _generate(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
    bool isAppEvent,
  ) {
    _validate(element);

    String appModelName = element.displayName.replaceFirst(r'$', '');
    ClassElement appModelClass = element as ClassElement;

    // Create an instance of AppModelField for each field in the model class
    List<AppModelField> appModelFields = _parseFields(appModelClass);

    // Create field declarations in the built_value abstract class
    List<String> fieldDeclarations =
        _generateFields(appModelFields, appModelClass);

    // Create initializer method in the built_value abstract class
    String initializer = _generateInitializer(appModelFields, appModelName);

    String appModelFilename = '${Utils.class2File(appModelName)}.model';
    String appModelVarName = Utils.class2Var(appModelName);

    List<String> modelImports = Utils.getImports(
      element.library.imports,
      buildStep.inputId.package,
    );

    List<String> appEventImports = [];
    if (isAppEvent) {
      appEventImports.add("import 'package:mustang_core/mustang_core.dart';");
    }

    String modelClassStr = isAppEvent
        ? 'abstract class $appModelName implements Built<$appModelName, ${appModelName}Builder>, AppEvent'
        : 'abstract class $appModelName implements Built<$appModelName, ${appModelName}Builder>';

    return '''
      import 'package:built_value/built_value.dart';
      import 'package:built_value/serializer.dart';
      ${modelImports.join('\n')}
      ${appEventImports.join('\n')}
      
      part '$appModelFilename.g.dart';
      
      $modelClassStr {
        $appModelName._();
        factory $appModelName([void Function(${appModelName}Builder) updates]) = _\$$appModelName;
      
        ${fieldDeclarations.join('\n')}
      
        static Serializer<$appModelName> get serializer => _\$${appModelVarName}Serializer;
      
        $initializer
      }
    ''';
  }

  void _validate(Element element) {
    if (!element.displayName.startsWith(r'$')) {
      throw InvalidGenerationSourceError(
          'Model class name should start with \$',
          todo: 'Prefix class name with \$',
          element: element);
    }

    ClassElement appModelClass = element as ClassElement;
    // class annotated with appModel should be abstract
    if (!appModelClass.isAbstract) {
      throw InvalidGenerationSourceError(
          'Error: class annotated with appModel should be abstract',
          todo: 'Make the class abstract',
          element: element);
    }

    for (FieldElement element in appModelClass.fields) {
      // No getter/setter
      if (element.isSynthetic) {
        throw InvalidGenerationSourceError(
            'Error: Explicit getter/setter not allowed in Models. Use method instead',
            todo: 'Convert getter/setter to a method',
            element: element);
      }

      // No static/const/final fields
      if (element.isStatic || element.isConst || element.isFinal) {
        throw InvalidGenerationSourceError(
            'Error: Models fields should not be static or static const or final',
            todo: 'remove static/static const/final',
            element: element);
      }

      // List/Map fields are not allowed
      if (element.type.element != null &&
          ['List', 'Map'].contains(element.type.element!.displayName)) {
        throw InvalidGenerationSourceError(
            'Error: List/Map are not allowed for fields. Use BuiltList/BuiltMap instead',
            todo: 'Use BuiltList/BuiltMap',
            element: element);
      }
    }
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

        Object? initValue;
        List<Object?>? initListValue;
        Map<Object, Object?>? initMapValue;
        final Iterable annotations = const TypeChecker.fromRuntime(InitField)
            .annotationsOf(fieldElement);
        final Iterable serializeAnnotation =
            const TypeChecker.fromRuntime(SerializeField)
                .annotationsOf(fieldElement);

        if (annotations.isNotEmpty) {
          switch (typeToMatch) {
            case 'String':
              if (annotations.single.getField('object') != null) {
                initValue =
                    "'${annotations.single.getField('object')!.toStringValue()}'";
              }
              break;
            case 'int':
              if (annotations.single.getField('object') != null) {
                initValue =
                    '${annotations.single.getField('object')!.toIntValue()}';
              }
              break;
            case 'double':
              if (annotations.single.getField('object') != null) {
                initValue =
                    '${annotations.single.getField('object')!.toDoubleValue()}';
              }
              break;
            case 'bool':
              if (annotations.single.getField('object') != null) {
                initValue =
                    '${annotations.single.getField('object')!.toBoolValue()}';
              }
              break;
            case 'BuiltMap':
              if (annotations.single.getField('object') != null) {
                if (annotations.single.getField('object')!.toMapValue() !=
                    null) {
                  initMapValue = {};
                  annotations.single
                      .getField('object')!
                      .toMapValue()!
                      .entries
                      .forEach((entry) {
                    if (ConstantReader(entry.key).literalValue != null) {
                      initMapValue!.putIfAbsent(
                          ConstantReader(entry.key).literalValue!,
                          () => ConstantReader(entry.value).literalValue);
                    }
                  });
                }
              }
              break;
            case 'BuiltList':
              if (annotations.single.getField('object') != null) {
                if (annotations.single.getField('object')!.toListValue() !=
                    null) {
                  initListValue = annotations.single
                      .getField('object')!
                      .toListValue()!
                      .map((e) {
                    if (e.type?.isDartCoreString ?? false) {
                      return "'${ConstantReader(e).literalValue}'";
                    }
                    return ConstantReader(e).literalValue;
                  }).toList();
                }
              }
              break;
            default:
              print(fieldType);
          }
        }

        bool? serializeField;
        if (serializeAnnotation.isNotEmpty) {
          serializeField = serializeAnnotation.single
                  .getField('serializeField')
                  ?.toBoolValue() ??
              true;
        }

        return AppModelField(
          name: fieldName,
          type: fieldType,
          initValue: initValue,
          initListValue: initListValue,
          initMapValue: initMapValue,
          serializeField: serializeField,
        );
      },
    ).toList();
  }

  List<String> _generateFields(
    List<AppModelField> appModelFields,
    ClassElement appModelClass,
  ) {
    return appModelFields.map(
      (field) {
        if (field.initValue == null &&
            field.initListValue == null &&
            field.initMapValue == null) {
          String declaration =
              '${field.type.replaceFirst('\$', '')}? get ${field.name};\n';
          if (field.serializeField != null && !field.serializeField!) {
            return '''
            @BuiltValueField(serialize: ${field.serializeField})
            $declaration
          ''';
          } else {
            return '''
            $declaration
          ''';
          }
        } else {
          String declaration =
              '${field.type.replaceFirst('\$', '')} get ${field.name};\n';
          if (field.serializeField != null && !field.serializeField!) {
            return '''
            @BuiltValueField(serialize: ${field.serializeField})
            $declaration
            ''';
          } else {
            return declaration;
          }
        }
      },
    ).toList();
  }

  String _generateInitializer(
    List<AppModelField> appModelFields,
    String appModelName,
  ) {
    String initializer =
        'static void _initializeBuilder(${appModelName}Builder builder) => builder\n';
    List<String?> initFields = appModelFields.map((field) {
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
