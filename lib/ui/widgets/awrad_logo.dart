import 'package:flutter/material.dart';

/// Displays the Awrad "Oasis Star" brand mark inside a rounded squircle.
class AwradLogo extends StatelessWidget {
  final double size;

  const AwradLogo({super.key, this.size = 56});

  static const String assetPath = 'assets/branding/app_icon_1024.png';

  @override
  Widget build(BuildContext context) {
    final radius = size * 0.23;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: size * 0.18,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.asset(
          assetPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
