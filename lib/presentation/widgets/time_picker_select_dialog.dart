import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_theme.dart';

/// 고급스러운 클래식 셀렉트박스(드롭다운) 기반 독서 알림 시간 선택 다이얼로그
/// - 시계 다이얼 방식의 번거로움을 해소하고 직관적인 [오전/오후] [시간] [분] 셀렉트박스 제공
/// - 상단 실시간 프리뷰 카드 및 독서 루틴 추천 시간 퀵 칩 지원
class TimePickerSelectDialog extends StatefulWidget {
  final TimeOfDay initialTime;
  final String title;

  const TimePickerSelectDialog({
    super.key,
    required this.initialTime,
    this.title = '독서 알림 시간 설정',
  });

  /// 다이얼로그 띄우기 헬퍼 함수
  static Future<TimeOfDay?> show({
    required BuildContext context,
    required TimeOfDay initialTime,
    String title = '독서 알림 시간 설정',
  }) {
    return showDialog<TimeOfDay>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => TimePickerSelectDialog(
        initialTime: initialTime,
        title: title,
      ),
    );
  }

  @override
  State<TimePickerSelectDialog> createState() => _TimePickerSelectDialogState();
}

class _TimePickerSelectDialogState extends State<TimePickerSelectDialog> {
  late bool _isPm;
  late int _hour12;
  late int _minute;

  @override
  void initState() {
    super.initState();
    final hour24 = widget.initialTime.hour;
    _minute = widget.initialTime.minute;

    if (hour24 >= 12) {
      _isPm = true;
      _hour12 = (hour24 == 12) ? 12 : (hour24 - 12);
    } else {
      _isPm = false;
      _hour12 = (hour24 == 0) ? 12 : hour24;
    }
  }

  /// 24시간제 TimeOfDay로 변환
  TimeOfDay get _currentTimeOfDay {
    int hour24;
    if (!_isPm) {
      hour24 = (_hour12 == 12) ? 0 : _hour12;
    } else {
      hour24 = (_hour12 == 12) ? 12 : (_hour12 + 12);
    }
    return TimeOfDay(hour: hour24, minute: _minute);
  }

  /// 24시간제 'HH:mm' 문자열
  String get _formatted24h {
    final t = _currentTimeOfDay;
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// 퀵 시간 프리셋 적용
  void _setPreset(int hour24, int minute) {
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
    setState(() {
      _minute = minute;
      if (hour24 >= 12) {
        _isPm = true;
        _hour12 = (hour24 == 12) ? 12 : (hour24 - 12);
      } else {
        _isPm = false;
        _hour12 = (hour24 == 0) ? 12 : hour24;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dialogBg = isDark ? AppTheme.darkSurface : Colors.white;
    final cardBg = isDark ? AppTheme.darkBackground : const Color(0xFFF8FAFC);
    final borderColor = isDark ? AppTheme.darkBorder : AppTheme.borderColor;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;
    final textMuted = isDark ? AppTheme.darkTextLight : AppTheme.textLight;

    return Dialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor, width: 1.2),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      elevation: 12,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. 헤더 (타이틀 및 닫기 아이콘)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.access_time_rounded,
                        color: AppTheme.primaryLight,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 16.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: textMuted, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  splashRadius: 18,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 2. 대형 실시간 프리뷰 카드
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: isDark ? 0.15 : 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _isPm ? '오후' : '오전',
                      style: const TextStyle(
                        color: AppTheme.primaryLight,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${_hour12.toString().padLeft(2, '0')} : ${_minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: isDark ? Colors.white : AppTheme.primaryDark,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '($_formatted24h)',
                    style: TextStyle(
                      color: textMuted,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. 직관적인 3구 셀렉트박스 (오전/오후, 시간, 분)
            Row(
              children: [
                // 3-1. 오전 / 오후 셀렉트박스
                Expanded(
                  flex: 11,
                  child: _buildDropdownContainer(
                    context: context,
                    isDark: isDark,
                    label: '구분',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<bool>(
                        value: _isPm,
                        isExpanded: true,
                        dropdownColor: dialogBg,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                        borderRadius: BorderRadius.circular(14),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: false,
                            child: Text('오전 (AM)'),
                          ),
                          DropdownMenuItem(
                            value: true,
                            child: Text('오후 (PM)'),
                          ),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            try {
                              HapticFeedback.selectionClick();
                            } catch (_) {}
                            setState(() => _isPm = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 3-2. 시간 (01시 ~ 12시) 셀렉트박스
                Expanded(
                  flex: 10,
                  child: _buildDropdownContainer(
                    context: context,
                    isDark: isDark,
                    label: '시간',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _hour12,
                        isExpanded: true,
                        dropdownColor: dialogBg,
                        menuMaxHeight: 280,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                        borderRadius: BorderRadius.circular(14),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        items: List.generate(12, (i) {
                          final h = i + 1;
                          return DropdownMenuItem(
                            value: h,
                            child: Text('${h.toString().padLeft(2, '0')}시'),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            try {
                              HapticFeedback.selectionClick();
                            } catch (_) {}
                            setState(() => _hour12 = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // 3-3. 분 (00분 ~ 59분) 셀렉트박스
                Expanded(
                  flex: 10,
                  child: _buildDropdownContainer(
                    context: context,
                    isDark: isDark,
                    label: '분',
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _minute,
                        isExpanded: true,
                        dropdownColor: dialogBg,
                        menuMaxHeight: 280,
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                        borderRadius: BorderRadius.circular(14),
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                        items: List.generate(60, (m) {
                          return DropdownMenuItem(
                            value: m,
                            child: Text('${m.toString().padLeft(2, '0')}분'),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) {
                            try {
                              HapticFeedback.selectionClick();
                            } catch (_) {}
                            setState(() => _minute = val);
                          }
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 4. 빠른 시간 선택 프리셋 칩 (독서 루틴 추천 시간)
            Text(
              '독서 추천 시간 퀵 선택',
              style: TextStyle(
                color: textMuted,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildQuickChip(
                  context: context,
                  label: '아침 독서 07:00',
                  hour24: 7,
                  minute: 0,
                ),
                _buildQuickChip(
                  context: context,
                  label: '출근길 08:30',
                  hour24: 8,
                  minute: 30,
                ),
                _buildQuickChip(
                  context: context,
                  label: '점심 독서 12:30',
                  hour24: 12,
                  minute: 30,
                ),
                _buildQuickChip(
                  context: context,
                  label: '퇴근길 18:30',
                  hour24: 18,
                  minute: 30,
                ),
                _buildQuickChip(
                  context: context,
                  label: '저녁 독서 21:00',
                  hour24: 21,
                  minute: 0,
                ),
                _buildQuickChip(
                  context: context,
                  label: '취침 전 23:00',
                  hour24: 23,
                  minute: 0,
                ),
              ],
            ),
            const SizedBox(height: 22),

            // 5. 하단 액션 버튼 (취소 / 설정 완료)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      side: BorderSide(color: borderColor),
                    ),
                    child: Text(
                      '취소',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: () {
                      try {
                        HapticFeedback.mediumImpact();
                      } catch (_) {}
                      Navigator.pop(context, _currentTimeOfDay);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 18),
                        SizedBox(width: 6),
                        Text(
                          '시간 설정 완료',
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 셀렉트박스 감싸는 라벨형 컨테이너
  Widget _buildDropdownContainer({
    required BuildContext context,
    required bool isDark,
    required String label,
    required Widget child,
  }) {
    final textMuted = isDark ? AppTheme.darkTextLight : AppTheme.textLight;
    final boxBg = isDark ? AppTheme.darkBackground : const Color(0xFFF1F5F9);
    final boxBorder = isDark ? AppTheme.darkBorder : const Color(0xFFCBD5E1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: textMuted,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: boxBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: boxBorder, width: 1.0),
          ),
          alignment: Alignment.center,
          child: child,
        ),
      ],
    );
  }

  /// 빠른 선택 칩 버튼
  Widget _buildQuickChip({
    required BuildContext context,
    required String label,
    required int hour24,
    required int minute,
  }) {
    final isSelected =
        _currentTimeOfDay.hour == hour24 && _currentTimeOfDay.minute == minute;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary;

    return InkWell(
      onTap: () => _setPreset(hour24, minute),
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.20)
              : (isDark ? AppTheme.darkBackground : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : (isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0)),
            width: isSelected ? 1.4 : 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected
                ? (isDark ? const Color(0xFFDDD6FE) : AppTheme.primaryColor)
                : textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
