import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class GlassScaffold extends StatelessWidget {
  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNav;
  final bool useSafeArea;

  const GlassScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNav,
    this.useSafeArea = true,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: GlassColors.bgTop,
      appBar: appBar,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              GlassColors.bgTop,
              GlassColors.bgMid,
              GlassColors.bgBottom,
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: useSafeArea
            ? SafeArea(bottom: false, child: child)
            : child,
      ),
      bottomNavigationBar: bottomNav,
    );
  }
}