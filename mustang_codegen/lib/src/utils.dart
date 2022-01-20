import 'dart:io';
import 'dart:math';

import 'package:analyzer/dart/element/element.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

class Utils {
  static const String debugEventKind = 'mustang';

  // mustang config file
  static const String configFile = 'mustang.yaml';

  // Keys in mustang-cli.yaml
  static const String serializerKey = 'serializer';
  static const String screenKey = 'screen';
  static const String screenImportsKey = 'imports';

  static String class2File(String className) {
    RegExp exp = RegExp(r'(?<=[0-9a-z])[A-Z]');
    return className
        .replaceAllMapped(exp, (Match m) => ('_' + (m.group(0) ?? '')))
        .toLowerCase();
  }

  static String class2Var(String className) {
    String firstLetter = className.substring(0, 1).toLowerCase();
    return '$firstLetter${className.substring(1)}';
  }

  static String capitalizeFirst(String str) {
    String firstLetter = str.substring(0, 1).toUpperCase();
    return '$firstLetter${str.substring(1)}';
  }

  static String pkg2Var(String pkgName) {
    return class2Var(
        pkgName.split('_').map((e) => capitalizeFirst(e)).toList().join(''));
  }

  static List<String> getImports(List<ImportElement> elements, String package) {
    List<String> importsList = [];
    for (ImportElement importElement in elements) {
      String importedLib =
          '${importElement.importedLibrary?.definingCompilationUnit.declaration ?? ''}';
      if (importedLib.isNotEmpty && !importedLib.contains('mustang_core')) {
        if (importedLib.startsWith('dart:')) {
          importsList.add("import '$importedLib';");
        } else if (importedLib.contains('/models/')) {
          if (importedLib.contains('.model.dart')) {
            // Supports the case where some of the models inside Model classes
            // are built_value classes but are not generated using
            // @appModel annotation
            importsList.add(
                "import 'package:${importedLib.substring(1).replaceAll('/lib/', '/')}';");
          } else {
            importsList.add(
                "import 'package:${importedLib.substring(1).replaceAll('/lib/', '/').replaceFirst('.dart', '.model.dart')}';");
          }
        } else {
          importsList.add(
              "import 'package:${importedLib.substring(1).replaceAll('/lib/', '/')}';");
        }
      }
    }
    return importsList;
  }

  static List<String> getRawImports(List<ImportElement> elements) {
    return elements
        .map((importElement) =>
            '${importElement.importedLibrary?.definingCompilationUnit.declaration ?? ''}')
        .toList();
  }

  static String? getCustomSerializerPackage() {
    String? userHomeDir = homeDir();
    String configFilePath = '';
    if (userHomeDir != null) {
      configFilePath = p.join(userHomeDir, configFile);
    }
    if (configFilePath.isNotEmpty && File(configFilePath).existsSync()) {
      File configFile = File(configFilePath);
      String rawConfig = configFile.readAsStringSync();

      dynamic yamlConfig = loadYaml(rawConfig);
      if (yamlConfig[serializerKey] != null) {
        return yamlConfig[serializerKey];
      }
    }
    return null;
  }

  /// Input: MethodElement
  /// Output: Method with all its input arguments
  /// Example Output: validateToken(userId: userId, token: token)
  static String methodWithExecutionArgs(
    MethodElement element,
    List<String> imports,
  ) {
    String methodName = 'super.${element.displayName}(';
    if (element.parameters.isNotEmpty) {
      element.parameters.toList().forEach((parameter) {
        String import = parameter.type.element?.location?.encoding ?? '';
        if (parameter.declaration.isOptional) {
          methodName =
              '$methodName${parameter.displayName}: ${parameter.displayName}, ';
        } else {
          methodName = '$methodName${parameter.displayName}, ';
        }
        if (import.isNotEmpty) {
          import = import.split(';').first;
          imports.add("import '$import';");
        }
      });
    }
    methodName = '$methodName)';
    return methodName;
  }

  static String? homeDir() {
    Map<String, String> envVars = Platform.environment;
    if (Platform.isMacOS) {
      return envVars['HOME'];
    }

    if (Platform.isLinux) {
      return envVars['HOME'];
    }

    if (Platform.isWindows) {
      return envVars['UserProfile'];
    }
  }

  static String generateRandomString(int len) {
    Random random = Random();
    const chars = 'abcdefghijklmnopqrstuvwxyz';
    return List.generate(len, (index) => chars[random.nextInt(chars.length)])
        .join();
  }

  static String defaultGeneratorComment =
      '// GENERATED CODE - DO NOT MODIFY BY HAND';
}
