import 'package:flutter/material.dart';

class ResponsiveWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    double maxWidth = width < 600
        ? width
        : width < 1100
        ? 600
        : 900;

    return Center(
      child: SizedBox(
        width: maxWidth,
        child: child,
      ),
    );
  }
}
