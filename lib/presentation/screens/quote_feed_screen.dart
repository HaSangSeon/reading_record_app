import "dart:io";
import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:intl/intl.dart";
import "../../core/theme/app_theme.dart";
import "../../data/models/book_model.dart";
import "../../data/models/note_model.dart";
import "../../providers/repository_providers.dart";
import "../controllers/note_controller.dart";
import "../controllers/theme_controller.dart";
import "../widgets/action_bottom_sheet.dart";
import "../widgets/custom_confirm_dialog.dart";
import "../widgets/note_form_dialog.dart";
import "../widgets/shareable_quote_card_dialog.dart";
import "book_detail_screen.dart";

class QuoteFeedScreen extends ConsumerStatefulWidget {
  const QuoteFeedScreen({super.key});

  @override
  ConsumerState<QuoteFeedScreen> createState() => _QuoteFeedScreenState();
}

class _QuoteFeedScreenState extends ConsumerState<QuoteFeedScreen> {
  bool _isSearching = false;
  bool _isSyncing = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _syncData() async {
    if (_isSyncing) return;
    setState(() => _isSyncing = true);
    try {
      final hiveService = ref.read(hiveServiceProvider);
      final firebaseService = ref.read(firebaseServiceProvider);
      final success = await firebaseService.syncWithCloud(hiveService);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    success
                        ? '클라우드와 최신 데이터로 동기화되었습니다.'
                        : '동기화 중 오류가 발생했습니다.',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor:
                success ? const Color(0xFF10B981) : Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSyncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final feedAsync = ref.watch(filteredQuoteFeedProvider);
    final allBooksAsync = ref.watch(allBooksStreamProvider);
    final allNotesAsync = ref.watch(allNotesWithBookProvider);
    final selectedBookId = ref.watch(quoteFeedSelectedBookIdProvider);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0C0E17) : const Color(0xFFF7F6FA),
      appBar: AppBar(
        flexibleSpace: AppTheme.buildAppBarFlexibleSpace(isDark),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  hintText: "문장, 생각, 도서명으로 검색...",
                  hintStyle: TextStyle(
                    color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) {
                  ref.read(quoteFeedSearchQueryProvider.notifier).state = val;
                },
              )
            : Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF4C3A93), const Color(0xFF6B4BC8)]
                            : [AppTheme.primaryColor, const Color(0xFF818CF8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                              .withValues(alpha: 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.format_quote_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "한줄 피드",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(width: 8),
                  allNotesAsync.when(
                    data: (items) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                              .withValues(alpha: 0.25),
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        "${items.length}",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                        ),
                      ),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, _) => const SizedBox.shrink(),
                  ),
                ],
              ),
        actions: [
          // 클라우드 동기화 (새로고침) 버튼 - 맨 왼쪽
          IconButton(
            icon: _isSyncing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTheme.primaryColor,
                    ),
                  )
                : Icon(
                    Icons.sync_rounded,
                    color: isDark
                        ? AppTheme.darkTextSecondary
                        : AppTheme.textSecondary,
                  ),
            tooltip: '클라우드 동기화',
            onPressed: _isSyncing ? null : _syncData,
          ),
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close_rounded : Icons.search_rounded,
              color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              size: 22,
            ),
            tooltip: _isSearching ? "검색 닫기" : "기록 검색",
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  ref.read(quoteFeedSearchQueryProvider.notifier).state = "";
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_outlined,
              color: isDark ? Colors.amberAccent : AppTheme.textSecondary,
              size: 22,
            ),
            tooltip: isDark ? "라이트 모드로 전환" : "다크 모드로 전환",
            onPressed: () {
              ref.read(themeControllerProvider.notifier).toggleTheme(context);
            },
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 도서별 수평 필터 칩 바 (프리미엄 캡슐형 + 미니 썸네일 + 개수 배지)
          allBooksAsync.when(
            data: (books) {
              if (books.isEmpty) return const SizedBox.shrink();
              final allNotes = allNotesAsync.value ?? [];
              final totalNotesCount = allNotes.length;

              return Container(
                height: 56,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF0F121E).withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.95),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark
                          ? const Color(0xFF1E2235)
                          : const Color(0xFFE9EAF0),
                      width: 0.8,
                    ),
                  ),
                ),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: books.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = selectedBookId == null;
                      return _buildFilterChip(
                        label: "전체 기록",
                        isSelected: isSelected,
                        isDark: isDark,
                        icon: Icons.auto_stories_rounded,
                        count: totalNotesCount,
                        onTap: () {
                          ref.read(quoteFeedSelectedBookIdProvider.notifier).state = null;
                        },
                      );
                    }

                    final book = books[index - 1];
                    final isSelected = selectedBookId == book.id;
                    final bookNotesCount =
                        allNotes.where((item) => item.book.id == book.id).length;

                    return _buildFilterChip(
                      label: book.title,
                      isSelected: isSelected,
                      isDark: isDark,
                      coverUrl: book.coverUrl,
                      count: bookNotesCount,
                      onTap: () {
                        ref.read(quoteFeedSelectedBookIdProvider.notifier).state =
                            isSelected ? null : book.id;
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),

          // 피드 본문 리스트 (당겨서 새로고침 지원)
          Expanded(
            child: feedAsync.when(
              data: (items) {
                if (items.isEmpty) {
                  return RefreshIndicator(
                    color: AppTheme.primaryColor,
                    backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
                    onRefresh: _syncData,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _buildEmptyState(context, isDark),
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppTheme.primaryColor,
                  backgroundColor: isDark ? AppTheme.darkSurface : Colors.white,
                  onRefresh: _syncData,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.only(
                      top: 14,
                      left: 16,
                      right: 16,
                      bottom: 110, // 하단 AdMob 배너 및 탭바 높이 대응
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildFeedCard(
                        context,
                        ref,
                        item.book,
                        item.note,
                        isDark,
                      );
                    },
                  ),
                );
              },
              loading: () => Center(
                child: CircularProgressIndicator(
                  color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
                ),
              ),
              error: (err, _) => Center(
                child: Text(
                  "기록을 불러오는 중 오류가 발생했습니다: $err",
                  style: TextStyle(
                    color: isDark ? AppTheme.darkTextSecondary : AppTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 수평 필터 칩 빌더 (프리미엄 캡슐형 + 미니 북커버 + 카운트 배지) ──
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
    IconData? icon,
    String? coverUrl,
    int? count,
  }) {
    final activeGradient = LinearGradient(
      colors: isDark
          ? const [Color(0xFF5B45B2), Color(0xFF433096)]
          : const [Color(0xFF6366F1), Color(0xFF4F46E5)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final primary = isDark ? AppTheme.primaryLight : AppTheme.primaryColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        splashColor: primary.withValues(alpha: 0.15),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            gradient: isSelected ? activeGradient : null,
            color: isSelected
                ? null
                : (isDark ? const Color(0xFF161926) : Colors.white),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF818CF8).withValues(alpha: 0.6)
                  : (isDark ? const Color(0xFF262C40) : const Color(0xFFE2E4EE)),
              width: isSelected ? 1.2 : 0.9,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                      blurRadius: 4,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 도서 썸네일 또는 아이콘
              if (coverUrl != null && coverUrl.isNotEmpty)
                Container(
                  width: 16,
                  height: 22,
                  margin: const EdgeInsets.only(right: 7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 3,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: coverUrl.startsWith('http')
                        ? Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.book_rounded,
                              size: 13,
                              color: isSelected ? Colors.white70 : primary,
                            ),
                          )
                        : Image.file(
                            File(coverUrl),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              Icons.book_rounded,
                              size: 13,
                              color: isSelected ? Colors.white70 : primary,
                            ),
                          ),
                  ),
                )
              else if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Icon(
                    icon,
                    size: 15,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppTheme.primaryLight : AppTheme.primaryColor),
                  ),
                ),

              // 2. 도서명 / 텍스트
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    letterSpacing: -0.3,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary),
                  ),
                ),
              ),

              // 3. 기록 개수 배지
              if (count != null && count > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.24)
                        : (isDark
                            ? AppTheme.primaryLight.withValues(alpha: 0.15)
                            : AppTheme.primaryColor.withValues(alpha: 0.08)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? AppTheme.primaryLight : AppTheme.primaryColor),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── 고급스러운 피드 카드 ──
  Widget _buildFeedCard(
    BuildContext context,
    WidgetRef ref,
    Book book,
    Note note,
    bool isDark,
  ) {
    final dateFormat = DateFormat("yyyy.MM.dd HH:mm");
    final formattedDate = dateFormat.format(note.createdAt);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceCard : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isDark
            ? [
                const BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: AppTheme.primaryColor.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : const Color(0xFFF1F5F9),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 상단 헤더 (책 표지 + 도서명/저자 + 페이지 태그 + 메뉴)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161B28) : const Color(0xFFF8FAFC),
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? AppTheme.darkBorder : const Color(0xFFE2E8F0),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 미니 책 표지 썸네일 (그림자 효과)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookDetailScreen(bookId: book.id),
                      ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 50,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      color: (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                          .withValues(alpha: 0.1),
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF2C3249)
                            : const Color(0xFFE2E4EE),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildMiniCover(book.coverUrl),
                  ),
                ),
                const SizedBox(width: 12),

                // 책 제목 & 저자 & 페이지 태그
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BookDetailScreen(bookId: book.id),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                            color: isDark
                                ? AppTheme.darkTextPrimary
                                : AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                book.author,
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
                            ),
                            if (note.pageNumber > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 1.5,
                                ),
                                decoration: BoxDecoration(
                                  color: (isDark
                                          ? AppTheme.primaryLight
                                          : AppTheme.primaryColor)
                                      .withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "p.${note.pageNumber}",
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? AppTheme.primaryLight
                                        : AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // 더보기 메뉴 버튼
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: Icon(
                    Icons.more_vert_rounded,
                    size: 19,
                    color: isDark ? AppTheme.darkTextLight : AppTheme.textLight,
                  ),
                  tooltip: "더보기",
                  onPressed: () {
                    ActionBottomSheet.showNoteActions(
                      context,
                      book: book,
                      note: note,
                      onShare: () {
                        ShareableQuoteCardDialog.show(
                          context,
                          book: book,
                          note: note,
                        );
                      },
                      onEdit: () {
                        NoteFormDialog.show(context, book: book, note: note);
                      },
                      onDelete: () {
                        _showDeleteDialog(context, ref, note);
                      },
                    );
                  },
                ),
              ],
            ),
          ),

            // 2. 인상 깊은 구절 (발췌문) 박스 (문학적 감성 레이아웃)
            if (note.quotation.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 12, right: 16, top: 6, bottom: 4),
                child: Stack(
                children: [
                  Positioned(
                    top: -10,
                    left: -2,
                    child: Icon(
                      Icons.format_quote_rounded,
                      size: 56,
                      color: isDark
                          ? AppTheme.primaryLight.withValues(alpha: 0.1)
                          : AppTheme.primaryColor.withValues(alpha: 0.04),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 18, top: 10, bottom: 4),
                    child: Text(
                      note.quotation,
                      style: TextStyle(
                        fontSize: 15.5,
                        color: isDark ? AppTheme.darkTextPrimary : const Color(0xFF1E293B),
                        height: 1.6,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 3. 나의 생각 / 메모 본문
            if (note.content.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 6, bottom: 8),
                child: Text(
                  note.content,
                  style: TextStyle(
                    fontSize: 14.5,
                    color: isDark ? AppTheme.darkTextSecondary : const Color(0xFF475569),
                    height: 1.65,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),

            // 4. 하단 액션 바: 작성일자 & 카드 공유 버튼
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
              child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: isDark
                          ? AppTheme.darkTextLight
                          : AppTheme.textLight,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? AppTheme.darkTextLight
                            : AppTheme.textLight,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => ShareableQuoteCardDialog.show(
                      context,
                      book: book,
                      note: note,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark
                                ? AppTheme.primaryLight
                                : AppTheme.primaryColor)
                            .withValues(alpha: isDark ? 0.18 : 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor)
                              .withValues(alpha: isDark ? 0.35 : 0.22),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.ios_share_rounded,
                            size: 13,
                            color: isDark
                                ? AppTheme.primaryLight
                                : AppTheme.primaryColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '카드 공유',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: isDark
                                  ? AppTheme.primaryLight
                                  : AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniCover(String? coverUrl) {
    if (coverUrl == null || coverUrl.isEmpty) {
      return const Center(
        child: Icon(Icons.book_rounded, size: 18, color: Colors.grey),
      );
    }
    if (coverUrl.startsWith("http://") || coverUrl.startsWith("https://")) {
      return Image.network(
        coverUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => const Center(
          child: Icon(Icons.book_rounded, size: 18, color: Colors.grey),
        ),
      );
    }
    return Image.file(
      File(coverUrl),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.book_rounded, size: 18, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                        .withValues(alpha: 0.2),
                    (isDark ? AppTheme.primaryLight : AppTheme.primaryColor)
                        .withValues(alpha: 0.04),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.format_quote_rounded,
                size: 34,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryColor,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              "아직 남겨진 한줄 기록이 없습니다 ✍️",
              style: TextStyle(
                fontSize: 16.5,
                fontWeight: FontWeight.w800,
                color: isDark ? AppTheme.darkTextPrimary : AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "책을 읽으며 마음을 울린 구절이나\n스쳐 지나간 생각을 자유롭게 남겨보세요.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? AppTheme.darkTextSecondary
                    : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Note note,
  ) async {
    final displayText = note.quotation.isNotEmpty
        ? note.quotation
        : (note.content.isNotEmpty ? note.content : "독서 기록");

    final confirmed = await CustomConfirmDialog.show(
      context,
      title: "독서 기록을 삭제하시겠습니까?",
      highlightedTarget: displayText,
      message: "이 독서 기록과 발췌문이 피드 및 서재에서 영구히 삭제됩니다.",
      confirmText: "기록 삭제",
      isDestructive: true,
      icon: Icons.delete_forever_rounded,
    );

    if (confirmed == true && context.mounted) {
      await ref.read(noteControllerProvider.notifier).deleteNote(note.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("독서 기록이 삭제되었습니다."),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }
}
