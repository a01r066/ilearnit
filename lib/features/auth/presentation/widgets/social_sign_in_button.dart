import 'package:flutter/material.dart';

/// Outlined "Continue with X" button used for OAuth providers on the
/// Login / Signup pages.
///
/// Use the named factories — they encode each provider's brand guidelines
/// (Google = white bg + multicolor G; Apple = black bg + white Apple logo).
class SocialSignInButton extends StatelessWidget {
  const SocialSignInButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.loading = false,
  });

  /// Google brand button. Per Google's identity guidelines this is a white
  /// surface with the multicolor "G" mark.
  factory SocialSignInButton.google({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SocialSignInButton(
      key: key,
      label: label,
      onPressed: onPressed,
      loading: loading,
      icon: const _GoogleGLogo(size: 20),
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF1F1F1F),
      borderColor: const Color(0xFFDADCE0),
    );
  }

  /// Apple brand button. Per Apple's HIG this is a solid black surface with
  /// the white Apple glyph.
  factory SocialSignInButton.apple({
    Key? key,
    required String label,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SocialSignInButton(
      key: key,
      label: label,
      onPressed: onPressed,
      loading: loading,
      icon: const Icon(Icons.apple, size: 22, color: Colors.white),
      backgroundColor: Colors.black,
      foregroundColor: Colors.white,
      borderColor: Colors.black,
    );
  }

  final String label;
  final Widget icon;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: loading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: borderColor ?? Colors.transparent),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: loading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: foregroundColor,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  icon,
                  const SizedBox(width: 12),
                  Text(label),
                ],
              ),
      ),
    );
  }
}

/// Minimal multi-color "G" mark drawn as text so we don't need an asset.
///
/// Note: Google's brand guidelines technically require their official SVG.
/// If you ship to production, swap this for the asset at
/// `assets/icons/google_g.svg`.
class _GoogleGLogo extends StatelessWidget {
  const _GoogleGLogo({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: ShaderMask(
        shaderCallback: (rect) => const LinearGradient(
          colors: [
            Color(0xFF4285F4), // blue
            Color(0xFF34A853), // green
            Color(0xFFFBBC04), // yellow
            Color(0xFFEA4335), // red
          ],
          stops: [0.0, 0.33, 0.66, 1.0],
        ).createShader(rect),
        child: Text(
          'G',
          style: TextStyle(
            fontSize: size,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1,
          ),
        ),
      ),
    );
  }
}
