import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_overlay_close_button.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../../../../core/widgets/fast_circular_progress.dart';

const Rect _fullCropRect = Rect.fromLTWH(0, 0, 1, 1);
const double _minCropExtent = 0.18;
const double _cropHandleHitRadius = 28;

Future<DescriptionMediaImageMarkupSession?>
showDescriptionMediaImageMarkupSheet(
  BuildContext context, {
  required File imageFile,
  DescriptionMediaImageMarkupSession? initialSession,
}) {
  return showModalBottomSheet<DescriptionMediaImageMarkupSession>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _DescriptionMediaImageMarkupSheet(
        imageFile: imageFile,
        initialSession: initialSession,
      );
    },
  );
}

class DescriptionMediaImageMarkupSession {
  DescriptionMediaImageMarkupSession({
    required this.sourceImageFile,
    required List<DescriptionMediaImageMarkupStroke> strokes,
    Rect cropRect = _fullCropRect,
    File? previewImageFile,
  }) : strokes = List<DescriptionMediaImageMarkupStroke>.unmodifiable(
         strokes.map((stroke) => stroke.copy()),
       ),
       cropRect = _normalizeCropRect(cropRect),
       previewImageFile = previewImageFile ?? sourceImageFile;

  final File sourceImageFile;
  final List<DescriptionMediaImageMarkupStroke> strokes;
  final Rect cropRect;
  final File previewImageFile;

  bool get hasMarkup => strokes.isNotEmpty;
  bool get hasCrop => !_isFullCropRect(cropRect);
  bool get hasEdits => hasMarkup || hasCrop;
  File get displayImageFile => previewImageFile;
}

class DescriptionMediaImageMarkupStroke {
  DescriptionMediaImageMarkupStroke({
    required this.color,
    required List<Offset> points,
  }) : points = List<Offset>.unmodifiable(points);

  final Color color;
  final List<Offset> points;

  DescriptionMediaImageMarkupStroke copy() {
    return DescriptionMediaImageMarkupStroke(color: color, points: points);
  }
}

enum _DescriptionMediaImageEditorMode { draw, crop }

enum _CropHandle { move, topLeft, topRight, bottomLeft, bottomRight }

class _CropInteraction {
  const _CropInteraction({
    required this.handle,
    required this.startCropRect,
    required this.startPointNormalized,
  });

  final _CropHandle handle;
  final Rect startCropRect;
  final Offset startPointNormalized;
}

class _DescriptionMediaImageMarkupSheet extends StatefulWidget {
  const _DescriptionMediaImageMarkupSheet({
    required this.imageFile,
    required this.initialSession,
  });

  final File imageFile;
  final DescriptionMediaImageMarkupSession? initialSession;

  @override
  State<_DescriptionMediaImageMarkupSheet> createState() =>
      _DescriptionMediaImageMarkupSheetState();
}

class _DescriptionMediaImageMarkupSheetState
    extends State<_DescriptionMediaImageMarkupSheet> {
  late final _DescriptionMediaImageMarkupController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _DescriptionMediaImageMarkupController(
      imageFile: widget.initialSession?.sourceImageFile ?? widget.imageFile,
      initialStrokes: widget.initialSession?.strokes ?? const [],
      initialCropRect: _fullCropRect,
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveMarkup() async {
    final navigator = Navigator.of(context);
    try {
      final markupSession = await _controller.buildSession();
      if (!mounted) {
        return;
      }
      navigator.pop(markupSession);
    } catch (error) {
      debugPrint('Unable to save marked image: $error');
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.auditMarkupImageSaveError)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.94;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return SafeArea(
          top: false,
          bottom: false,
          child: Container(
            height: sheetHeight,
            margin: EdgeInsets.only(top: topPadding),
            padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding + 20),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              border: Border.all(
                color: AppColors.grey2.withValues(alpha: 0.55),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AppOverlayCloseButton(
                      onTap: _controller.isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          AppTextView.body1(
                            AppStrings.auditMarkupImageTitle,
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          SizedBox(height: 2),
                          AppTextView.body3(
                            AppStrings.auditMarkupImageHint,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: AppColors.surfaceDark3,
                      child: _buildCanvasBody(),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _MarkupColorPicker(
                  colors: _DescriptionMediaImageMarkupController.palette,
                  selectedColor: _controller.selectedColor,
                  onColorSelected: _controller.isBusy
                      ? null
                      : _controller.selectColor,
                ),
                const SizedBox(height: 12),
                _buildDrawActions(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCanvasBody() {
    if (_controller.isLoading) {
      return Center(
        child: SizedBox(
          width: 28,
          height: 28,
          child: FastCircularProgressIndicator(),
        ),
      );
    }

    final loadError = _controller.loadErrorMessage;
    if (loadError != null && loadError.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: AppTextView.body2(
            loadError,
            color: AppColors.textSecondary,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return _MarkupCanvas(controller: _controller);
  }

  Widget _buildDrawActions() {
    return Row(
      children: [
        Expanded(
          child: AppButton(
            text: AppStrings.auditMarkupUndo,
            onPressed: _controller.canUndo && !_controller.isBusy
                ? _controller.undo
                : null,
            backgroundColor: AppColors.surfaceDark3,
            textColor: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton(
            text: AppStrings.auditMarkupClear,
            onPressed: _controller.canClear && !_controller.isBusy
                ? _controller.clear
                : null,
            backgroundColor: AppColors.surfaceDark3,
            textColor: AppColors.textPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: AppButton(
            text: AppStrings.auditSave,
            onPressed: _controller.canSave ? _saveMarkup : null,
            isLoading: _controller.isSaving,
          ),
        ),
      ],
    );
  }
}

class _DescriptionMediaImageMarkupController extends ChangeNotifier {
  _DescriptionMediaImageMarkupController({
    required this.imageFile,
    List<DescriptionMediaImageMarkupStroke> initialStrokes = const [],
    Rect initialCropRect = _fullCropRect,
  }) : _strokes = initialStrokes
           .map(_MarkupStroke.fromSessionStroke)
           .toList(growable: true),
       _cropRect = _normalizeCropRect(initialCropRect);

  static const double _strokeWidthFactor = 0.0085;
  static const List<Color> palette = <Color>[
    AppColors.red,
    AppColors.yellow,
    AppColors.green1,
    AppColors.blue,
    Colors.white,
  ];

  final File imageFile;
  final List<_MarkupStroke> _strokes;
  Rect _cropRect;
  _MarkupStroke? _activeStroke;
  _CropInteraction? _activeCropInteraction;
  ui.Image? _image;
  Color _selectedColor = palette.first;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadErrorMessage;
  final _DescriptionMediaImageEditorMode _mode =
      _DescriptionMediaImageEditorMode.draw;

  ui.Image? get image => _image;
  Color get selectedColor => _selectedColor;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get isBusy => _isLoading || _isSaving;
  bool get isCropMode => _mode == _DescriptionMediaImageEditorMode.crop;
  bool get canUndo => _activeStroke != null || _strokes.isNotEmpty;
  bool get canClear => _activeStroke != null || _strokes.isNotEmpty;
  bool get canSave => !_isLoading && !_isSaving && _image != null;
  String? get loadErrorMessage => _loadErrorMessage;
  Rect get visibleSourceRectNormalized => _fullCropRect;

  List<_MarkupStroke> get strokes => List<_MarkupStroke>.unmodifiable(_strokes);
  _MarkupStroke? get activeStroke => _activeStroke;

  Future<void> load() async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      _image = frame.image;
      _loadErrorMessage = null;
    } catch (error) {
      debugPrint('Unable to decode markup image: $error');
      _loadErrorMessage = AppStrings.auditMarkupImageLoadError;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectColor(Color color) {
    if (_selectedColor == color || isBusy) {
      return;
    }

    _selectedColor = color;
    notifyListeners();
  }

  void startStroke(Offset position, Size canvasSize) {
    if (isBusy || _image == null || isCropMode) {
      return;
    }

    final normalizedPoint = _normalizeOffsetForVisibleRect(
      position,
      canvasSize,
      visibleSourceRectNormalized,
    );
    if (normalizedPoint == null) {
      return;
    }

    _activeStroke = _MarkupStroke(
      color: _selectedColor,
      points: <Offset>[normalizedPoint],
    );
    notifyListeners();
  }

  void appendStrokePoint(Offset position, Size canvasSize) {
    final activeStroke = _activeStroke;
    if (activeStroke == null || isBusy || isCropMode) {
      return;
    }

    final normalizedPoint = _normalizeOffsetForVisibleRect(
      position,
      canvasSize,
      visibleSourceRectNormalized,
    );
    if (normalizedPoint == null) {
      return;
    }

    final points = activeStroke.points;
    if (points.isNotEmpty &&
        (points.last - normalizedPoint).distanceSquared < 0.000001) {
      return;
    }

    points.add(normalizedPoint);
    notifyListeners();
  }

  void endStroke() {
    final activeStroke = _activeStroke;
    if (activeStroke == null) {
      return;
    }

    if (activeStroke.points.isNotEmpty) {
      _strokes.add(activeStroke);
    }
    _activeStroke = null;
    notifyListeners();
  }

  void undo() {
    if (isBusy) {
      return;
    }

    if (_activeStroke != null) {
      _activeStroke = null;
      notifyListeners();
      return;
    }

    if (_strokes.isEmpty) {
      return;
    }

    _strokes.removeLast();
    notifyListeners();
  }

  void clear() {
    if (isBusy || (_strokes.isEmpty && _activeStroke == null)) {
      return;
    }

    _strokes.clear();
    _activeStroke = null;
    notifyListeners();
  }

  void beginCropInteraction(Offset position, Size canvasSize) {
    if (isBusy || _image == null || !isCropMode) {
      return;
    }

    final cropCanvasRect = cropRectForCanvas(canvasSize);
    final imageRect = _imageRectForCanvas(
      canvasSize,
      visibleSourceRectNormalized: _fullCropRect,
    );
    if (imageRect.isEmpty || !imageRect.contains(position)) {
      return;
    }

    final normalizedPoint = _normalizeOffsetForVisibleRect(
      position,
      canvasSize,
      _fullCropRect,
    );
    if (normalizedPoint == null) {
      return;
    }

    final handle = _resolveCropHandle(position, cropCanvasRect);
    if (handle == null) {
      return;
    }

    _activeCropInteraction = _CropInteraction(
      handle: handle,
      startCropRect: _cropRect,
      startPointNormalized: normalizedPoint,
    );
  }

  void updateCropInteraction(Offset position, Size canvasSize) {
    final activeCropInteraction = _activeCropInteraction;
    if (activeCropInteraction == null || isBusy || !isCropMode) {
      return;
    }

    final normalizedPoint = _normalizeOffsetForVisibleRect(
      position,
      canvasSize,
      _fullCropRect,
    );
    if (normalizedPoint == null) {
      return;
    }

    final startCropRect = activeCropInteraction.startCropRect;
    late Rect nextCropRect;
    switch (activeCropInteraction.handle) {
      case _CropHandle.move:
        final delta =
            normalizedPoint - activeCropInteraction.startPointNormalized;
        nextCropRect = _shiftRectInsideUnit(startCropRect.shift(delta));
      case _CropHandle.topLeft:
        nextCropRect = Rect.fromLTRB(
          _clampDouble(
            normalizedPoint.dx,
            0,
            startCropRect.right - _minCropExtent,
          ),
          _clampDouble(
            normalizedPoint.dy,
            0,
            startCropRect.bottom - _minCropExtent,
          ),
          startCropRect.right,
          startCropRect.bottom,
        );
      case _CropHandle.topRight:
        nextCropRect = Rect.fromLTRB(
          startCropRect.left,
          _clampDouble(
            normalizedPoint.dy,
            0,
            startCropRect.bottom - _minCropExtent,
          ),
          _clampDouble(
            normalizedPoint.dx,
            startCropRect.left + _minCropExtent,
            1,
          ),
          startCropRect.bottom,
        );
      case _CropHandle.bottomLeft:
        nextCropRect = Rect.fromLTRB(
          _clampDouble(
            normalizedPoint.dx,
            0,
            startCropRect.right - _minCropExtent,
          ),
          startCropRect.top,
          startCropRect.right,
          _clampDouble(
            normalizedPoint.dy,
            startCropRect.top + _minCropExtent,
            1,
          ),
        );
      case _CropHandle.bottomRight:
        nextCropRect = Rect.fromLTRB(
          startCropRect.left,
          startCropRect.top,
          _clampDouble(
            normalizedPoint.dx,
            startCropRect.left + _minCropExtent,
            1,
          ),
          _clampDouble(
            normalizedPoint.dy,
            startCropRect.top + _minCropExtent,
            1,
          ),
        );
    }

    final normalizedCropRect = _normalizeCropRect(nextCropRect);
    if (normalizedCropRect == _cropRect) {
      return;
    }

    _cropRect = normalizedCropRect;
    notifyListeners();
  }

  void endCropInteraction() {
    if (_activeCropInteraction == null) {
      return;
    }

    _activeCropInteraction = null;
    notifyListeners();
  }

  Future<DescriptionMediaImageMarkupSession> buildSession() async {
    final image = _image;
    if (_isSaving || image == null) {
      throw StateError('Markup image is not ready to save.');
    }

    _isSaving = true;
    notifyListeners();

    try {
      final sessionStrokes = <DescriptionMediaImageMarkupStroke>[
        ..._strokes.map((stroke) => stroke.toSessionStroke()),
        if (_activeStroke != null) _activeStroke!.toSessionStroke(),
      ];

      if (sessionStrokes.isEmpty && _isFullCropRect(_cropRect)) {
        return DescriptionMediaImageMarkupSession(
          sourceImageFile: imageFile,
          strokes: const <DescriptionMediaImageMarkupStroke>[],
          cropRect: _fullCropRect,
          previewImageFile: imageFile,
        );
      }

      final previewImageFile = await _renderEditedImage(
        image: image,
        sessionStrokes: sessionStrokes,
      );
      return DescriptionMediaImageMarkupSession(
        sourceImageFile: imageFile,
        strokes: sessionStrokes,
        cropRect: _cropRect,
        previewImageFile: previewImageFile,
      );
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  Rect imageRectForCanvas(Size canvasSize) {
    return _imageRectForCanvas(
      canvasSize,
      visibleSourceRectNormalized: visibleSourceRectNormalized,
    );
  }

  Rect cropRectForCanvas(Size canvasSize) {
    final imageRect = _imageRectForCanvas(
      canvasSize,
      visibleSourceRectNormalized: _fullCropRect,
    );
    return Rect.fromLTRB(
      imageRect.left + (_cropRect.left * imageRect.width),
      imageRect.top + (_cropRect.top * imageRect.height),
      imageRect.left + (_cropRect.right * imageRect.width),
      imageRect.top + (_cropRect.bottom * imageRect.height),
    );
  }

  Rect sourceImageRectForVisibleArea() {
    final image = _image;
    if (image == null) {
      return Rect.zero;
    }

    return _normalizedRectToImageRect(visibleSourceRectNormalized, image);
  }

  @override
  void dispose() {
    _image?.dispose();
    super.dispose();
  }

  Rect _imageRectForCanvas(
    Size canvasSize, {
    required Rect visibleSourceRectNormalized,
  }) {
    final image = _image;
    if (image == null || canvasSize.isEmpty) {
      return Rect.zero;
    }

    final sourceSize = Size(
      image.width * visibleSourceRectNormalized.width,
      image.height * visibleSourceRectNormalized.height,
    );
    final fittedSizes = applyBoxFit(BoxFit.contain, sourceSize, canvasSize);
    return Alignment.center.inscribe(
      fittedSizes.destination,
      Offset.zero & canvasSize,
    );
  }

  Offset? _normalizeOffsetForVisibleRect(
    Offset position,
    Size canvasSize,
    Rect visibleSourceRectNormalized,
  ) {
    final imageRect = _imageRectForCanvas(
      canvasSize,
      visibleSourceRectNormalized: visibleSourceRectNormalized,
    );
    if (imageRect.isEmpty || !imageRect.contains(position)) {
      return null;
    }

    final relativeDx = (position.dx - imageRect.left) / imageRect.width;
    final relativeDy = (position.dy - imageRect.top) / imageRect.height;
    return Offset(
      visibleSourceRectNormalized.left +
          (relativeDx * visibleSourceRectNormalized.width),
      visibleSourceRectNormalized.top +
          (relativeDy * visibleSourceRectNormalized.height),
    );
  }

  Future<File> _renderEditedImage({
    required ui.Image image,
    required List<DescriptionMediaImageMarkupStroke> sessionStrokes,
  }) async {
    final sourceCropRect = _normalizedRectToImageRect(_cropRect, image);
    final outputWidth = math.max(1, sourceCropRect.width.round());
    final outputHeight = math.max(1, sourceCropRect.height.round());
    final outputRect = Rect.fromLTWH(
      0,
      0,
      outputWidth.toDouble(),
      outputHeight.toDouble(),
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    canvas.drawImageRect(
      image,
      sourceCropRect,
      outputRect,
      Paint()..filterQuality = FilterQuality.high,
    );
    canvas.save();
    canvas.clipRect(outputRect);
    for (final stroke in sessionStrokes) {
      _paintSessionStroke(
        canvas,
        imageRect: outputRect,
        visibleSourceRectNormalized: _cropRect,
        stroke: stroke,
      );
    }
    canvas.restore();

    final renderedImage = await recorder.endRecording().toImage(
      outputWidth,
      outputHeight,
    );
    final pngBytes = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    renderedImage.dispose();
    if (pngBytes == null) {
      throw StateError('Marked image bytes were empty.');
    }

    return _writeAnnotatedFile(pngBytes.buffer.asUint8List());
  }

  Future<File> _writeAnnotatedFile(Uint8List imageBytes) async {
    final tempDirectory = await getTemporaryDirectory();
    final sourceFileName = CustomFunctions.fileNameFromPath(
      imageFile.path,
      fallback: 'audit-image',
    );
    final extensionIndex = sourceFileName.lastIndexOf('.');
    final baseName = extensionIndex > 0
        ? sourceFileName.substring(0, extensionIndex)
        : sourceFileName;
    final outputFile = File(
      '${tempDirectory.path}/${baseName}_markup_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await outputFile.writeAsBytes(imageBytes, flush: true);
    return outputFile;
  }

  void _paintSessionStroke(
    Canvas canvas, {
    required Rect imageRect,
    required Rect visibleSourceRectNormalized,
    required DescriptionMediaImageMarkupStroke stroke,
  }) {
    if (stroke.points.isEmpty ||
        imageRect.isEmpty ||
        visibleSourceRectNormalized.isEmpty) {
      return;
    }

    final strokeWidth = imageRect.shortestSide * _strokeWidthFactor;
    final strokePaint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fillPaint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.fill;

    final resolvedPoints = stroke.points
        .map(
          (point) => Offset(
            imageRect.left +
                (((point.dx - visibleSourceRectNormalized.left) /
                        visibleSourceRectNormalized.width) *
                    imageRect.width),
            imageRect.top +
                (((point.dy - visibleSourceRectNormalized.top) /
                        visibleSourceRectNormalized.height) *
                    imageRect.height),
          ),
        )
        .toList(growable: false);

    if (resolvedPoints.length == 1) {
      canvas.drawCircle(resolvedPoints.first, strokeWidth / 2, fillPaint);
      return;
    }

    final path = Path()
      ..moveTo(resolvedPoints.first.dx, resolvedPoints.first.dy);
    for (final point in resolvedPoints.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(path, strokePaint);
  }

  _CropHandle? _resolveCropHandle(Offset position, Rect cropCanvasRect) {
    if ((position - cropCanvasRect.topLeft).distance <= _cropHandleHitRadius) {
      return _CropHandle.topLeft;
    }
    if ((position - cropCanvasRect.topRight).distance <= _cropHandleHitRadius) {
      return _CropHandle.topRight;
    }
    if ((position - cropCanvasRect.bottomLeft).distance <=
        _cropHandleHitRadius) {
      return _CropHandle.bottomLeft;
    }
    if ((position - cropCanvasRect.bottomRight).distance <=
        _cropHandleHitRadius) {
      return _CropHandle.bottomRight;
    }
    if (cropCanvasRect.contains(position)) {
      return _CropHandle.move;
    }
    return null;
  }
}

class _MarkupCanvas extends StatelessWidget {
  const _MarkupCanvas({required this.controller});

  final _DescriptionMediaImageMarkupController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onPanStart: controller.isBusy
              ? null
              : (details) {
                  if (controller.isCropMode) {
                    controller.beginCropInteraction(
                      details.localPosition,
                      canvasSize,
                    );
                    return;
                  }
                  controller.startStroke(details.localPosition, canvasSize);
                },
          onPanUpdate: controller.isBusy
              ? null
              : (details) {
                  if (controller.isCropMode) {
                    controller.updateCropInteraction(
                      details.localPosition,
                      canvasSize,
                    );
                    return;
                  }
                  controller.appendStrokePoint(
                    details.localPosition,
                    canvasSize,
                  );
                },
          onPanEnd: controller.isBusy
              ? null
              : (_) {
                  if (controller.isCropMode) {
                    controller.endCropInteraction();
                    return;
                  }
                  controller.endStroke();
                },
          onPanCancel: controller.isBusy
              ? null
              : () {
                  if (controller.isCropMode) {
                    controller.endCropInteraction();
                    return;
                  }
                  controller.endStroke();
                },
          child: CustomPaint(
            size: canvasSize,
            painter: _MarkupPainter(controller: controller),
          ),
        );
      },
    );
  }
}

class _MarkupPainter extends CustomPainter {
  const _MarkupPainter({required this.controller});

  final _DescriptionMediaImageMarkupController controller;

  @override
  void paint(Canvas canvas, Size size) {
    final image = controller.image;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = AppColors.surfaceDark3,
    );

    if (image == null) {
      return;
    }

    final destinationRect = controller.imageRectForCanvas(size);
    final sourceRect = controller.sourceImageRectForVisibleArea();
    canvas.drawImageRect(
      image,
      sourceRect,
      destinationRect,
      Paint()..filterQuality = FilterQuality.high,
    );

    canvas.save();
    canvas.clipRect(destinationRect);
    for (final stroke in controller.strokes) {
      controller._paintSessionStroke(
        canvas,
        imageRect: destinationRect,
        visibleSourceRectNormalized: controller.visibleSourceRectNormalized,
        stroke: stroke.toSessionStroke(),
      );
    }

    final activeStroke = controller.activeStroke;
    if (activeStroke != null) {
      controller._paintSessionStroke(
        canvas,
        imageRect: destinationRect,
        visibleSourceRectNormalized: controller.visibleSourceRectNormalized,
        stroke: activeStroke.toSessionStroke(),
      );
    }
    canvas.restore();

    if (!controller.isCropMode) {
      return;
    }

    final cropCanvasRect = controller.cropRectForCanvas(size);
    final overlayPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(destinationRect)
      ..addRect(cropCanvasRect);
    canvas.drawPath(
      overlayPath,
      Paint()..color = Colors.black.withValues(alpha: 0.45),
    );

    final borderPaint = Paint()
      ..color = AppColors.secondaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(cropCanvasRect, borderPaint);
    _paintHandle(canvas, cropCanvasRect.topLeft);
    _paintHandle(canvas, cropCanvasRect.topRight);
    _paintHandle(canvas, cropCanvasRect.bottomLeft);
    _paintHandle(canvas, cropCanvasRect.bottomRight);
  }

  @override
  bool shouldRepaint(covariant _MarkupPainter oldDelegate) {
    return true;
  }

  void _paintHandle(Canvas canvas, Offset center) {
    canvas.drawCircle(center, 8, Paint()..color = AppColors.secondaryColor);
    canvas.drawCircle(
      center,
      8,
      Paint()
        ..color = AppColors.textPrimary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }
}

class _MarkupColorPicker extends StatelessWidget {
  const _MarkupColorPicker({
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  });

  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color>? onColorSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = color == selectedColor;

          return GestureDetector(
            onTap: onColorSelected == null
                ? null
                : () => onColorSelected!(color),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.fieldBorder.withValues(alpha: 0.35),
                  width: isSelected ? 3 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MarkupStroke {
  _MarkupStroke({required this.color, required List<Offset> points})
    : points = List<Offset>.from(points);

  factory _MarkupStroke.fromSessionStroke(
    DescriptionMediaImageMarkupStroke stroke,
  ) {
    return _MarkupStroke(color: stroke.color, points: stroke.points);
  }

  final Color color;
  final List<Offset> points;

  DescriptionMediaImageMarkupStroke toSessionStroke() {
    return DescriptionMediaImageMarkupStroke(color: color, points: points);
  }
}

Rect _normalizeCropRect(Rect rect) {
  final normalizedLeft = _clampDouble(rect.left, 0, 1 - _minCropExtent);
  final normalizedTop = _clampDouble(rect.top, 0, 1 - _minCropExtent);
  final normalizedRight = _clampDouble(
    rect.right,
    normalizedLeft + _minCropExtent,
    1,
  );
  final normalizedBottom = _clampDouble(
    rect.bottom,
    normalizedTop + _minCropExtent,
    1,
  );

  return Rect.fromLTRB(
    normalizedLeft,
    normalizedTop,
    normalizedRight,
    normalizedBottom,
  );
}

Rect _shiftRectInsideUnit(Rect rect) {
  var horizontalDelta = 0.0;
  var verticalDelta = 0.0;
  if (rect.left < 0) {
    horizontalDelta = -rect.left;
  } else if (rect.right > 1) {
    horizontalDelta = 1 - rect.right;
  }

  if (rect.top < 0) {
    verticalDelta = -rect.top;
  } else if (rect.bottom > 1) {
    verticalDelta = 1 - rect.bottom;
  }

  return rect.shift(Offset(horizontalDelta, verticalDelta));
}

Rect _normalizedRectToImageRect(Rect normalizedRect, ui.Image image) {
  return Rect.fromLTRB(
    normalizedRect.left * image.width,
    normalizedRect.top * image.height,
    normalizedRect.right * image.width,
    normalizedRect.bottom * image.height,
  );
}

bool _isFullCropRect(Rect rect) {
  const epsilon = 0.0001;
  return (rect.left - _fullCropRect.left).abs() < epsilon &&
      (rect.top - _fullCropRect.top).abs() < epsilon &&
      (rect.right - _fullCropRect.right).abs() < epsilon &&
      (rect.bottom - _fullCropRect.bottom).abs() < epsilon;
}

double _clampDouble(num value, double min, double max) {
  return value.clamp(min, max).toDouble();
}
