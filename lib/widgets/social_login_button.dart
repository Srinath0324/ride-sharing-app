import 'package:flutter/material.dart';
import '../constants/app_theme.dart';

enum SocialLoginType { google, facebook }

class SocialLoginButton extends StatelessWidget {
  final SocialLoginType type;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialLoginButton({
    super.key,
    required this.type,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AppTheme.textPrimaryColor,
          elevation: 0,
          side: BorderSide(color: AppTheme.dividerColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            isLoading
                ? const CircularProgressIndicator(strokeWidth: 2)
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _getIcon(),
                    const SizedBox(width: 12),
                    Text(
                      _getButtonText(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                  ],
                ),
      ),
    );
  }

  Widget _getIcon() {
    switch (type) {
      case SocialLoginType.google:
        return const Icon(
          Icons.g_mobiledata, // Replace with actual Google icon
          size: 24,
          color: Colors.red,
        );
      case SocialLoginType.facebook:
        return const Icon(
          Icons.facebook, // Replace with actual Facebook icon
          size: 24,
          color: Color(0xFF1877F2),
        );
    }
  }

  String _getButtonText() {
    switch (type) {
      case SocialLoginType.google:
        return 'Continue with Google';
      case SocialLoginType.facebook:
        return 'Continue with Facebook';
    }
  }
}
