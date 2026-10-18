import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../screens/suspended_screen.dart';

/// Wraps every route. If a signed-in user is suspended, we overlay the
/// SuspendedScreen on top of whatever route is active. Signed-out state
/// is handled elsewhere (Sign Out button navigates to LoginScreen explicitly).
class SuspendedGuard extends StatelessWidget {
  final Widget child;
  const SuspendedGuard({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.isSignedIn && auth.suspended) {
      return const SuspendedScreen();
    }
    return child;
  }
}