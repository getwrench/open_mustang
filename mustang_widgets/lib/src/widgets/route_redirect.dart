import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class RouteRedirect extends StatelessWidget {
  const RouteRedirect({
    Key? key,
    required this.test,
    required this.targetRouteName,
    required this.child,
    this.pushReplace = true,
    this.loadingMsg = 'Redirecting...',
  }) : super(key: key);

  /// If [test] returns true, this widget redirects the app to the [targetRoute],
  /// otherwise noop
  final bool Function() test;

  /// Route to go to when [test] is true
  final String targetRouteName;

  /// If [pushReplace] is true, [targetRoute] replaces all existing routes,
  /// otherwise [targetRoute] is pushed on top of the existing route
  final bool pushReplace;

  /// If [test] return false, child gets rendered
  final Widget child;

  /// Text to show while transitioning to the destination route
  final String loadingMsg;

  @override
  Widget build(BuildContext context) {
    if (test()) {
      if (pushReplace) {
        SchedulerBinding.instance?.addPostFrameCallback((_) async {
          Navigator.pushNamedAndRemoveUntil(
            context,
            targetRouteName,
            (route) => false,
          );
        });
      } else {
        SchedulerBinding.instance?.addPostFrameCallback((_) async {
          Navigator.pushNamed(context, targetRouteName);
        });
      }
      return Scaffold(
        body: Center(
          child: Text(loadingMsg),
        ),
      );
    }
    return child;
  }
}
