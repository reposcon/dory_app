import 'dart:ui';
import 'package:flutter/material.dart';
import 'colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding,
    this.width,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(22.0),
          decoration: BoxDecoration(
            color: DoryColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: DoryColors.border,
              width: 1.0,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

