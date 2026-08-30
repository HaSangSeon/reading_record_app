import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/book_model.dart';
import '../../data/models/note_model.dart';

/// 도서 및 독서 기록용 프리미엄 액션 모달 바텀시트 유틸리티
class ActionBottomSheet {
  /// 내 서재 도서 액션 바텀시트 (완독 토글 / 정보 수정 / 도서 삭제)
  static Future<void> showBookActions(
    BuildContext context, {
    required Book book,
    required VoidCallback onToggleComplete,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2332) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF2B384D) : const Color(0xFFCCD8E8),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 상단 전용 헤더 배너 (배경색 구분 + 드래그 핸들 + 도서 요약 정보)
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? AppTheme.headerGradientDark
                        : AppTheme.headerGradientLight,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? const Color(0xFF2E2749)
                          : const Color(0xFFDCD5F0),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // 상단 드래그 핸들
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3B485E)
                              : const Color(0xFFB8C7DC),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // 도서 요약 정보
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // 미니 표지
                        Container(
                          width: 42,
                          height: 58,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isDark
                                ? const Color(0xFF0B1017)
                                : Colors.white,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF2A374A)
                                  : const Color(0xFFCCD8E8),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.3 : 0.08,
                                ),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: _buildMiniCover(
                            book.coverUrl,
                            book.isCompleted,
                          ),
                        ),
                        const SizedBox(width: 14),
                        // 도서 정보 (제목 2줄 + 뱃지 및 저자)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                book.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15.5,
                                  fontWeight: FontWeight.w800,
                                  height: 1.3,
                                  letterSpacing: -0.3,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  // 상태 뱃지 (미니 칩)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: book.isCompleted
                                          ? AppTheme.successColor.withValues(
                                              alpha: isDark ? 0.25 : 0.15,
                                            )
                                          : (isDark
                                                    ? AppTheme.primaryLight
                                                    : AppTheme.primaryColor)
                                                .withValues(
                                                  alpha: isDark ? 0.25 : 0.12,
                                                ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          book.isCompleted
                                              ? Icons.check_circle_rounded
                                              : Icons.auto_stories_rounded,
                                          size: 11,
                                          color: book.isCompleted
                                              ? AppTheme.successColor
                                              : (isDark
                                                    ? AppTheme.primaryLight
                                                    : AppTheme.primaryColor),
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          book.isCompleted ? '완독' : '읽는 중',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w800,
                                            color: book.isCompleted
                                                ? AppTheme.successColor
                                                : (isDark
                                                      ? AppTheme.primaryLight
                                                      : AppTheme.primaryColor),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      book.author,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? AppTheme.darkTextSecondary
                                            : AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. 메뉴 리스트 (본문 배경)
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 8,
                  horizontal: 10,
                ),
                child: Column(
                  children: [
                    _buildActionTile(
                      context: ctx,
                      icon: book.isCompleted
                          ? Icons.remove_circle_outline_rounded
                          : Icons.check_circle_rounded,
                      iconColor: book.isCompleted
                          ? const Color(0xFFF59E0B)
                          : AppTheme.successColor,
                      iconBgColor:
                          (book.isCompleted
                                  ? const Color(0xFFF59E0B)
                                  : AppTheme.successColor)
                              .withValues(alpha: 0.15),
                      title: book.isCompleted ? '읽는 중으로 상태 변경' : '완독으로 상태 변경',
                      subtitle: book.isCompleted
                          ? '다시 읽기 상태로 전환합니다'
                          : '책을 다 읽으셨다면 완독으로 체크하세요',
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(ctx);
                        onToggleComplete();
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildActionTile(
                      context: ctx,
                      icon: Icons.edit_note_rounded,
                      iconColor: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                      iconBgColor:
                          (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.15),
                      title: '도서 정보 수정',
                      subtitle: '제목, 저자, 표지, 별점 등을 변경합니다',
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(ctx);
                        onEdit();
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildActionTile(
                      context: ctx,
                      icon: Icons.delete_outline_rounded,
                      iconColor: const Color(0xFFEF4444),
                      iconBgColor: const Color(
                        0xFFEF4444,
                      ).withValues(alpha: 0.12),
                      title: '도서 삭제',
                      subtitle: '이 책과 관련된 모든 기록이 삭제됩니다',
                      isDark: isDark,
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        onDelete();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 한줄 피드 및 도서 상세 독서 기록(노트) 액션 바텀시트
  static Future<void> showNoteActions(
    BuildContext context, {
    required Book book,
    required Note note,
    required VoidCallback onShare,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final displayText = note.quotation.isNotEmpty
        ? note.quotation
        : (note.content.isNotEmpty ? note.content : '독서 기록');

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => SafeArea(
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2332) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark ? const Color(0xFF2B384D) : const Color(0xFFE2E8F0),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 상단 전용 헤더 배너 (보랏빛 배경색 구분 + 드래그 핸들 + 기록 요약 정보)
              Container(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? AppTheme.headerGradientDark
                        : AppTheme.headerGradientLight,
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? const Color(0xFF2E2749)
                          : const Color(0xFFDCD5F0),
                      width: 1.0,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    // 상단 드래그 핸들
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF3B485E)
                              : const Color(0xFFB8C7DC),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    // 기록 요약 미니 헤더
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF8B5CF6,
                            ).withValues(alpha: isDark ? 0.25 : 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.format_quote_rounded,
                            color: Color(0xFF8B5CF6),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '“$displayText”',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w700,
                                  fontStyle: FontStyle.italic,
                                  height: 1.35,
                                  color: isDark
                                      ? AppTheme.darkTextPrimary
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '《${book.title}》 ${note.pageNumber > 0 ? '· p.${note.pageNumber}' : ''}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: isDark
                                      ? AppTheme.darkTextSecondary
                                      : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 2. 메뉴 리스트
              Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 10,
                ),
                child: Column(
                  children: [
                    _buildActionTile(
                      context: ctx,
                      icon: Icons.auto_awesome_rounded,
                      iconColor: const Color(0xFF8B5CF6),
                      iconBgColor: const Color(
                        0xFF8B5CF6,
                      ).withValues(alpha: 0.15),
                      title: '감성 문장 카드 공유',
                      subtitle: '인스타그램/SNS용 고화질 카드로 제작 및 공유',
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(ctx);
                        onShare();
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildActionTile(
                      context: ctx,
                      icon: Icons.edit_note_rounded,
                      iconColor: isDark
                          ? AppTheme.primaryLight
                          : AppTheme.primaryColor,
                      iconBgColor:
                          (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor)
                              .withValues(alpha: 0.15),
                      title: '독서 기록 수정',
                      subtitle: '발췌 문장, 생각 메모, 페이지 번호 수정',
                      isDark: isDark,
                      onTap: () {
                        Navigator.pop(ctx);
                        onEdit();
                      },
                    ),
                    const SizedBox(height: 4),
                    _buildActionTile(
                      context: ctx,
                      icon: Icons.delete_outline_rounded,
                      iconColor: const Color(0xFFEF4444),
                      iconBgColor: const Color(
                        0xFFEF4444,
                      ).withValues(alpha: 0.12),
                      title: '기록 삭제',
                      subtitle: '이 독서 기록을 영구히 삭제합니다',
                      isDark: isDark,
                      isDestructive: true,
                      onTap: () {
                        Navigator.pop(ctx);
                        onDelete();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      splashColor: iconColor.withValues(alpha: 0.1),
      highlightColor: Colors.transparent,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDestructive
                          ? const Color(0xFFEF4444)
                          : (isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark
                          ? AppTheme.darkTextSecondary
                          : AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              size: 20,
              color: isDark ? const Color(0xFF475569) : const Color(0xFF94A3B8),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildMiniCover(String? cover, bool isCompleted) {
    if (cover != null && cover.isNotEmpty) {
      if (cover.startsWith('http://') || cover.startsWith('https://')) {
        return Image.network(
          cover,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.book_rounded, size: 20),
        );
      } else {
        return Image.file(
          File(cover),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const Icon(Icons.book_rounded, size: 20),
        );
      }
    }
    return Icon(
      isCompleted ? Icons.auto_stories_rounded : Icons.menu_book_rounded,
      color: AppTheme.primaryColor,
      size: 18,
    );
  }
}
