import 'package:flutter/material.dart';

/// 5) 하단 공유 액션 버튼 세트 (카카오톡 공유 & 기타 공유)
class QuoteCardShareActions extends StatelessWidget {
  final bool isSharingKakao;
  final bool isSharingOther;
  final bool isDialog;
  final VoidCallback onShareKakao;
  final VoidCallback onShareOther;

  const QuoteCardShareActions({
    super.key,
    required this.isSharingKakao,
    required this.isSharingOther,
    required this.isDialog,
    required this.onShareKakao,
    required this.onShareOther,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: ElevatedButton.icon(
            onPressed: isSharingKakao ? null : onShareKakao,
            icon: isSharingKakao
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.black54,
                    ),
                  )
                : const Icon(Icons.chat_bubble_rounded, size: 16),
            label: Text(
              isSharingKakao ? '생성 중...' : '카카오톡',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: isDialog ? 15 : 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEE500),
              foregroundColor: Colors.black87,
              padding: EdgeInsets.symmetric(
                vertical: isDialog ? 18 : 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isDialog ? 16 : 14),
              ),
              elevation: 0,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 1,
          child: ElevatedButton.icon(
            onPressed: isSharingOther ? null : onShareOther,
            icon: isSharingOther
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.share_rounded, size: 16),
            label: Text(
              isSharingOther ? '생성 중...' : '기타 공유',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isDialog ? 15 : 13,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(
                vertical: isDialog ? 18 : 14,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(isDialog ? 16 : 14),
              ),
              elevation: 2,
            ),
          ),
        ),
      ],
    );
  }
}
