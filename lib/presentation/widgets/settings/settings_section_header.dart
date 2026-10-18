import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class SettingsSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isDark;

  const SettingsSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 10),
      child: Row(
        children: [
          Icon(
            icon,
            size: 17,
            color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
          ),
          const SizedBox(width: 7),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
