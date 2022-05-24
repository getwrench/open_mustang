import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class RouteRedirect extends StatelessWidget {
  const RouteRedirect({
    Key? key,
    required this.redirect,
    required this.targetRouteName,
    required this.child,
    this.pushReplace = true,
    this.loadingMsg = 'Redirecting...',
  }) : super(key: key);

  /// If [redirect] returns true, this widget redirects the app to the [targetRoute],
  /// otherwise returns [child]
  final bool Function() redirect;

  /// Route to go to when [redirect] is true
  final String targetRouteName;

  /// If [pushReplace] is true, [targetRoute] replaces all existing routes,
  /// otherwise [targetRoute] is pushed on top of the existing route
  final bool pushReplace;

  /// If [redirect] return false, child gets rendered
  final Widget child;

  /// Text to show while transitioning to the destination route
  final String loadingMsg;

  @override
  Widget build(BuildContext context) {
    if (redirect()) {
      SchedulerBinding.instance?.addPostFrameCallback((_) async {
        if (pushReplace) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            targetRouteName,
            (route) => false,
          );
        } else {
          Navigator.pushNamed(context, targetRouteName);
        }
      });

      return Container(
        decoration: const BoxDecoration(color: Color(0xFFFFFFFF)),
        child: Center(
          child: DefaultTextStyle(
            style: const TextStyle(),
            child: Text(loadingMsg),
          ),
        ),
      );
    }
    return child;
  }
}
