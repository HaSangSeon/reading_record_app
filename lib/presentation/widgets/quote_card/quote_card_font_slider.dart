import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

/// 4) 폰트 크기 조절 슬라이더
class QuoteCardFontSizeSlider extends StatelessWidget {
  final double fontSizeScale;
  final ValueChanged<double> onChanged;

  const QuoteCardFontSizeSlider({
    super.key,
    required this.fontSizeScale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      children: [
        Icon(
          Icons.format_size_rounded,
          size: 16,
          color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
        ),
        const SizedBox(width: 6),
        Text(
          '글자 크기',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
          ),
        ),
        Expanded(
          child: Slider(
            value: fontSizeScale,
            min: 0.5,
            max: 1.3,
            divisions: 16,
            activeColor: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
            inactiveColor: isDark ? Colors.white12 : Colors.black12,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
