import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../widgets/ocr_text_picker_sheet.dart';

enum ScanFrameMode {
  singleLine, // 1~2줄 문장 스캔 (높이 ~90dp)
  paragraph, // 3~6줄 문단 스캔 (높이 ~210dp)
}

class LiveOcrScanScreen extends StatefulWidget {
  const LiveOcrScanScreen({super.key});

  static Future<String?> show(BuildContext context) {
    return Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const LiveOcrScanScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  @override
  State<LiveOcrScanScreen> createState() => _LiveOcrScanScreenState();
}

class _LiveOcrScanScreenState extends State<LiveOcrScanScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;
  String? _errorMessage;

  ScanFrameMode _frameMode = ScanFrameMode.singleLine;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pulseController.dispose();
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController? cameraController = _controller;
    if (cameraController == null || !cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.paused) {
      _controller?.dispose();
      _controller = null;
      if (mounted) {
        setState(() {
          _isCameraInitialized = false;
        });
      }
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        if (mounted) {
          setState(() {
            _errorMessage = '사용 가능한 카메라를 찾을 수 없습니다.';
          });
        }
        return;
      }

      // 후면 카메라 우선 선택 (없으면 첫 번째 카메라)
      final camera = _cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.veryHigh,
        enableAudio: false,
        imageFormatGroup:
            Platform.isAndroid
                ? ImageFormatGroup.jpeg
                : ImageFormatGroup.bgra8888,
      );

      await controller.initialize();
      if (!mounted) return;

      setState(() {
        _controller = controller;
        _isCameraInitialized = true;
        _errorMessage = null;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = '카메라를 초기화할 수 없습니다.\n$e';
        });
      }
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      final newFlash = !_isFlashOn;
      await _controller!.setFlashMode(
        newFlash ? FlashMode.torch : FlashMode.off,
      );
      setState(() {
        _isFlashOn = newFlash;
      });
    } catch (_) {}
  }

  Future<void> _captureAndScan(Rect guideRect, Size viewportSize) async {
    if (_controller == null ||
        !_controller!.value.isInitialized ||
        _isProcessing) {
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _isProcessing = true;
    });

    try {
      // 1. 카메라 사진 촬영
      final XFile photo = await _controller!.takePicture();
      final bytes = await photo.readAsBytes();

      // 2. 백그라운드 이미지 디코딩 및 회전 보정
      img.Image? decoded = img.decodeImage(bytes);
      if (decoded == null) {
        throw Exception('이미지를 읽어올 수 없습니다.');
      }
      decoded = img.bakeOrientation(decoded);

      final imgW = decoded.width.toDouble();
      final imgH = decoded.height.toDouble();
      final viewW = viewportSize.width;
      final viewH = viewportSize.height;

      // 3. BoxFit.cover 뷰포트 기준 가이드 영역 정확한 이미지 좌표 산출
      final scale = math.max(viewW / imgW, viewH / imgH);
      final renderedW = imgW * scale;
      final renderedH = imgH * scale;
      final offsetX = (renderedW - viewW) / 2.0;
      final offsetY = (renderedH - viewH) / 2.0;

      final cropX = ((guideRect.left + offsetX) / scale).clamp(0.0, imgW - 10);
      final cropY = ((guideRect.top + offsetY) / scale).clamp(0.0, imgH - 10);
      final cropW = (guideRect.width / scale).clamp(
        10.0,
        imgW - cropX,
      );
      final cropH = (guideRect.height / scale).clamp(
        10.0,
        imgH - cropY,
      );

      // 4. 가이드 박스 영역만 고속 크롭
      final cropped = img.copyCrop(
        decoded,
        x: cropX.round(),
        y: cropY.round(),
        width: cropW.round(),
        height: cropH.round(),
      );

      final tempDir = await getTemporaryDirectory();
      final croppedFile = File(
        '${tempDir.path}/live_scan_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      await croppedFile.writeAsBytes(img.encodeJpg(cropped, quality: 92));

      if (!mounted) return;

      // 5. OCR 텍스트 피커 시트 호출
      final scannedText = await OcrTextPickerSheet.show(
        context,
        imageFile: croppedFile,
      );

      if (scannedText != null && scannedText.trim().isNotEmpty && mounted) {
        Navigator.pop(context, scannedText.trim());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('스캔 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (picked == null || !mounted) return;

      final scannedText = await OcrTextPickerSheet.show(
        context,
        imageFile: File(picked.path),
      );

      if (scannedText != null && scannedText.trim().isNotEmpty && mounted) {
        Navigator.pop(context, scannedText.trim());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('사진 선택 오류: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    final bottomPadding = mediaQuery.padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0B0E),
      body:
          _errorMessage != null
              ? _buildErrorView()
              : !_isCameraInitialized || _controller == null
              ? _buildLoadingView()
              : LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(
                    constraints.maxWidth,
                    constraints.maxHeight,
                  );

                  // 가이드 박스 크기 산출
                  final guideWidth = math.min(size.width * 0.88, 420.0);
                  final guideHeight =
                      _frameMode == ScanFrameMode.singleLine ? 96.0 : 220.0;
                  final guideLeft = (size.width - guideWidth) / 2.0;
                  // 살짝 위쪽에 배치하여 책을 볼 때 안정적인 시야 확보
                  final guideTop = (size.height - guideHeight) / 2.0 - 50.0;
                  final guideRect = Rect.fromLTWH(
                    guideLeft,
                    guideTop,
                    guideWidth,
                    guideHeight,
                  );

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // 1. 전체 화면 카메라 프리뷰 (BoxFit.cover)
                      _buildCameraPreview(size),

                      // 2. 가이드 박스 외 영역 반투명 딤 & 스캔 프레임 오버레이
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, _) {
                          return CustomPaint(
                            painter: _ScanGuidePainter(
                              guideRect: guideRect,
                              pulseAlpha: _pulseAnimation.value,
                            ),
                          );
                        },
                      ),

                      // 3. 가이드 안내 텍스트 & 모드 토글 바
                      Positioned(
                        left: 20,
                        right: 20,
                        top: guideTop + guideHeight + 20,
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.15),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.auto_awesome,
                                    color: const Color(0xFF818CF8),
                                    size: 15,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _frameMode == ScanFrameMode.singleLine
                                        ? '가이드 안에 1~2줄 문장을 맞춰주세요'
                                        : '가이드 안에 문단을 맞춰주세요',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: -0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            // 한 줄 / 문단 모드 토글
                            _buildModeSelector(),
                          ],
                        ),
                      ),

                      // 4. 상단 헤더 툴바 (닫기, 타이틀, 플래시)
                      Positioned(
                        top: topPadding + 8,
                        left: 16,
                        right: 16,
                        child: _buildTopBar(),
                      ),

                      // 5. 하단 셔터 및 갤러리 컨트롤 바
                      Positioned(
                        bottom: bottomPadding + 20,
                        left: 0,
                        right: 0,
                        child: _buildBottomControls(guideRect, size),
                      ),

                      // 6. 스캔 분석 중 로딩 오버레이
                      if (_isProcessing) _buildProcessingOverlay(),
                    ],
                  );
                },
              ),
    );
  }

  Widget _buildCameraPreview(Size size) {
    final camera = _controller!;
    final previewSize = camera.value.previewSize!;
    // 세로 모드 대응: width/height 뒤집힘
    final isPortrait = camera.value.deviceOrientation.name.contains('portrait');
    final double camW =
        isPortrait ? previewSize.height : previewSize.width;
    final double camH =
        isPortrait ? previewSize.width : previewSize.height;

    final scale = math.max(size.width / camW, size.height / camH);

    return ClipRect(
      child: OverflowBox(
        alignment: Alignment.center,
        maxWidth: camW * scale,
        maxHeight: camH * scale,
        child: SizedBox(
          width: camW * scale,
          height: camH * scale,
          child: CameraPreview(camera),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // 닫기 버튼
        _buildCircleButton(
          icon: Icons.close_rounded,
          onTap: () => Navigator.pop(context),
        ),

        // 타이틀 뱃지
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF111318).withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 8,
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.crop_free_rounded, color: Color(0xFF818CF8), size: 18),
              SizedBox(width: 7),
              Text(
                '문장 조준 스캐너',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),

        // 플래시 토글
        _buildCircleButton(
          icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
          iconColor: _isFlashOn ? Colors.amberAccent : Colors.white70,
          onTap: _toggleFlash,
        ),
      ],
    );
  }

  Widget _buildCircleButton({
    required IconData icon,
    Color iconColor = Colors.white,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111318).withValues(alpha: 0.8),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: IconButton(
        icon: Icon(icon, color: iconColor, size: 22),
        onPressed: onTap,
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF111318).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeTab(
            title: '한 줄 구절',
            icon: Icons.view_headline_rounded,
            mode: ScanFrameMode.singleLine,
          ),
          _buildModeTab(
            title: '문단 발췌',
            icon: Icons.view_agenda_rounded,
            mode: ScanFrameMode.paragraph,
          ),
        ],
      ),
    );
  }

  Widget _buildModeTab({
    required String title,
    required IconData icon,
    required ScanFrameMode mode,
  }) {
    final isSelected = _frameMode == mode;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _frameMode = mode;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6366F1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : Colors.white54,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white54,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls(Rect guideRect, Size viewportSize) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // 앨범에서 선택 버튼
          GestureDetector(
            onTap: _isProcessing ? null : _pickFromGallery,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E222D).withValues(alpha: 0.85),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                color: Colors.white70,
                size: 24,
              ),
            ),
          ),

          // 메인 조준 촬영 셔터 버튼
          GestureDetector(
            onTap:
                _isProcessing
                    ? null
                    : () => _captureAndScan(guideRect, viewportSize),
            child: Container(
              width: 82,
              height: 82,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF818CF8).withValues(alpha: 0.6),
                  width: 3,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.35),
                    blurRadius: 18,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Container(
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF818CF8), Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
            ),
          ),

          // 균형 맞추기용 빈 공간
          const SizedBox(width: 52),
        ],
      ),
    );
  }

  Widget _buildProcessingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF161821),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF818CF8).withValues(alpha: 0.3)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  color: Color(0xFF818CF8),
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                '조준 문장 스캔 & AI 인식 중...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: Color(0xFF818CF8)),
          SizedBox(height: 16),
          Text(
            '카메라를 준비하고 있습니다...',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              color: Colors.redAccent,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '오류가 발생했습니다.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _initCamera,
              icon: const Icon(Icons.refresh),
              label: const Text('다시 시도'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 가이드 박스 외 영역 반투명 딤 & 4개 코너 브래킷을 그리는 커스텀 페인터
class _ScanGuidePainter extends CustomPainter {
  final Rect guideRect;
  final double pulseAlpha;

  _ScanGuidePainter({required this.guideRect, required this.pulseAlpha});

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint =
        Paint()..color = Colors.black.withValues(alpha: 0.52);

    // 1. 가이드 박스 바깥 영역만 딤 처리 (Path combination)
    final path =
        Path()
          ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
          ..addRRect(
            RRect.fromRectAndRadius(guideRect, const Radius.circular(16)),
          )
          ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, backgroundPaint);

    // 2. 가이드 프레임 얇은 테두리
    final borderPaint =
        Paint()
          ..color = const Color(0xFF818CF8).withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(guideRect, const Radius.circular(16)),
      borderPaint,
    );

    // 3. 4개 코너 브래킷 (강조선)
    final cornerPaint =
        Paint()
          ..color = const Color(0xFF818CF8).withValues(alpha: pulseAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.5
          ..strokeCap = StrokeCap.round;

    const cornerLength = 24.0;
    final r = guideRect;

    // 좌측 상단
    canvas.drawLine(
      Offset(r.left, r.top + cornerLength),
      Offset(r.left, r.top + 12),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(r.left, r.top, 24, 24),
      math.pi,
      math.pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(r.left + 12, r.top),
      Offset(r.left + cornerLength, r.top),
      cornerPaint,
    );

    // 우측 상단
    canvas.drawLine(
      Offset(r.right - cornerLength, r.top),
      Offset(r.right - 12, r.top),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(r.right - 24, r.top, 24, 24),
      -math.pi / 2,
      math.pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(r.right, r.top + 12),
      Offset(r.right, r.top + cornerLength),
      cornerPaint,
    );

    // 좌측 하단
    canvas.drawLine(
      Offset(r.left, r.bottom - cornerLength),
      Offset(r.left, r.bottom - 12),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(r.left, r.bottom - 24, 24, 24),
      math.pi / 2,
      math.pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(r.left + 12, r.bottom),
      Offset(r.left + cornerLength, r.bottom),
      cornerPaint,
    );

    // 우측 하단
    canvas.drawLine(
      Offset(r.right - cornerLength, r.bottom),
      Offset(r.right - 12, r.bottom),
      cornerPaint,
    );
    canvas.drawArc(
      Rect.fromLTWH(r.right - 24, r.bottom - 24, 24, 24),
      0,
      math.pi / 2,
      false,
      cornerPaint,
    );
    canvas.drawLine(
      Offset(r.right, r.bottom - 12),
      Offset(r.right, r.bottom - cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ScanGuidePainter oldDelegate) {
    return oldDelegate.guideRect != guideRect ||
        oldDelegate.pulseAlpha != pulseAlpha;
  }
}
