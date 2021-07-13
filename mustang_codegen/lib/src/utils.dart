import 'package:analyzer/dart/element/element.dart';

class Utils {
  static String class2File(String className) {
    RegExp exp = RegExp(r'(?<=[0-9a-z])[A-Z]');
    return className
        .replaceAllMapped(exp, (Match m) => ('_' + m.group(0)))
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

  static List<String> getImports(List<ImportElement> elements) {
    List<String> importsList = [];
    elements.forEach((importElement) {
      String importedLib =
          '${importElement.importedLibrary.definingCompilationUnit.declaration}';
      if (!importedLib.contains('mustang_core')) {
        if (importedLib.startsWith('dart:')) {
          importsList.add("import '$importedLib';");
        } else if (importedLib.contains('/models/')) {
          importsList.add(
              "import 'package:${importedLib.substring(1).replaceAll('/lib/', '/').replaceFirst('\.dart', '\.model.dart')}';");
        } else {
          importsList.add(
              "import 'package:${importedLib.substring(1).replaceAll('/lib/', '/')}';");
        }
      }
    });
    return importsList;
  }

  static List<String> getRawImports(List<ImportElement> elements) {
    return elements
        .map((importElement) =>
            '${importElement.importedLibrary.definingCompilationUnit.declaration}')
        .toList();
  }

  static String defaultGeneratorComment =
      '// GENERATED CODE - DO NOT MODIFY BY HAND';
}
