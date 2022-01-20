import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:mustang_core/mustang_core.dart';

/// Visits a generated aspect file and finds available hooks.
/// Used in [HookOverrideGenerator] to find which hooks are available
/// for a generated aspect
class AspectVisitor extends SimpleElementVisitor {
  const AspectVisitor(this.availableMethods);

  final List<JointPoint> availableMethods;

  @override
  visitMethodElement(MethodElement element) {
    switch(element.displayName) {
      case('before'):
        availableMethods.add(JointPoint.before);
        break;
      case('after'):
        availableMethods.add(JointPoint.after);
        break;
      case('around'):
        availableMethods.add(JointPoint.around);
        break;
    }
    super.visitMethodElement(element);
  }
}