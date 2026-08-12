import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../../../core/widgets/app_text_view.dart';
import '../providers/kaizengram_controller.dart';

class KaizengramAuditMediaBottomSheet extends StatelessWidget {
  const KaizengramAuditMediaBottomSheet({
    super.key,
    required this.post,
    required this.threadItems,
    required this.onMediaTap,
  });

  final KaizengramFeedItem post;
  final List<KaizengramAuditMediaItem> threadItems;
  final ValueChanged<KaizengramAuditMediaItem> onMediaTap;

  String _sheetSeatName() {
    final seatName = post.title.trim();
    if (seatName.isNotEmpty) {
      return seatName;
    }

    return post.seatProfile;
  }

  @override
  Widget build(BuildContext context) {
    final mediaItems = post.auditMediaItems;
    final badCount = mediaItems
        .where((item) => item.rating == KaizengramAuditRating.bad)
        .length;
    final improvementCount = mediaItems
        .where((item) => item.rating == KaizengramAuditRating.needsImprovement)
        .length;
    final goodCount = mediaItems
        .where((item) => item.rating == KaizengramAuditRating.good)
        .length;

    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.8,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: 48,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppTextView.body1(
                    AppStrings.kaizengramLabelCheckInComments,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                  const SizedBox(height: 4),
                  AppTextView.body2(
                    _sheetSeatName(),
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  AppTextView.body3(
                    AppStrings.kaizengramLabelRatings,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      KaizengramRatingSummaryBlock(
                        count: badCount,
                        color: const Color(0xFFF04438),
                      ),
                      const SizedBox(width: 12),
                      KaizengramRatingSummaryBlock(
                        count: improvementCount,
                        color: const Color(0xFFFF8A4C),
                      ),
                      const SizedBox(width: 12),
                      KaizengramRatingSummaryBlock(
                        count: goodCount,
                        color: const Color(0xFF15B79F),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                itemCount: threadItems.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final item = threadItems[index];
                  return KaizengramAuditMediaListTile(
                    item: item,
                    onTap: () => onMediaTap(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class KaizengramRatingSummaryBlock extends StatelessWidget {
  const KaizengramRatingSummaryBlock({
    super.key,
    required this.count,
    required this.color,
  });

  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            AppTextView.body1(
              count.toString(),
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class KaizengramAuditMediaListTile extends StatelessWidget {
  const KaizengramAuditMediaListTile({
    super.key,
    required this.item,
    required this.onTap,
  });

  final KaizengramAuditMediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark3.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.textPrimary.withValues(alpha: 0.08),
              width: 0.8,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Stack(
                alignment: Alignment.center,
                children: <Widget>[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 64,
                      height: 64,
                      child: KaizengramNetworkPostImage(
                        imageUrl: item.hasThumbnail ? item.thumbnailUrl : null,
                      ),
                    ),
                  ),
                  if (item.hasVideo)
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.54),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    AppTextView.body1(
                      item.title,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
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
}

class KaizengramMetaLine extends StatelessWidget {
  const KaizengramMetaLine({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        SizedBox(
          width: 70,
          child: AppTextView.body2(
            label,
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Expanded(
          child: AppTextView.body2(
            value,
            color: AppColors.textPrimary,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class KaizengramStatusLine extends StatelessWidget {
  const KaizengramStatusLine({
    super.key,
    required this.status,
    required this.postCategory,
  });

  final String status;
  final KaizengramPostCategory postCategory;

  @override
  Widget build(BuildContext context) {
    final statusStyle = _resolveTrackStatusStyle(status, postCategory);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        SizedBox(
          width: 70,
          child: AppTextView.body2(
            AppStrings.kaizengramLabelStatus,
            color: AppColors.textSecondary,
            fontSize: 12,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 1.4),
          decoration: BoxDecoration(
            color: statusStyle.backgroundColor,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: statusStyle.borderColor, width: 1),
          ),
          child: AppTextView.body3(
            status,
            color: statusStyle.textColor,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class KaizengramNetworkPostImage extends StatelessWidget {
  const KaizengramNetworkPostImage({
    super.key,
    required this.imageUrl,
    this.emptyState,
  });

  final String? imageUrl;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    final normalizedImageUrl = imageUrl?.trim();
    if (normalizedImageUrl == null || normalizedImageUrl.isEmpty) {
      return emptyState ?? const KaizengramNoImageAvailableAsset();
    }

    return Image.network(
      normalizedImageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }

        return Container(
          color: AppColors.surfaceDark3,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(
            color: AppColors.secondaryColor,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return emptyState ?? const KaizengramNoImageAvailableAsset();
      },
    );
  }
}

class KaizengramNoImageAvailableAsset extends StatelessWidget {
  const KaizengramNoImageAvailableAsset({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      alignment: Alignment.center,
      child: Image.asset(
        '${AppStrings.imagePath}no_image.png',
        fit: BoxFit.contain,
      ),
    );
  }
}

class KaizengramPostTextMediaFallbackCard extends StatelessWidget {
  const KaizengramPostTextMediaFallbackCard({
    super.key,
    required this.text,
    this.onMoreTap,
  });

  final String text;
  final VoidCallback? onMoreTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blue,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.all(20),
      child: KaizengramPostTextMediaFallbackText(
        text: text,
        onMoreTap: onMoreTap,
      ),
    );
  }
}

class KaizengramPostTextMediaFallbackText extends StatefulWidget {
  const KaizengramPostTextMediaFallbackText({
    super.key,
    required this.text,
    this.onMoreTap,
  });

  final String text;
  final VoidCallback? onMoreTap;

  @override
  State<KaizengramPostTextMediaFallbackText> createState() =>
      _KaizengramPostTextMediaFallbackTextState();
}

class _KaizengramPostTextMediaFallbackTextState
    extends State<KaizengramPostTextMediaFallbackText> {
  TapGestureRecognizer? _moreTapRecognizer;

  @override
  void initState() {
    super.initState();
    _syncMoreTapRecognizer();
  }

  @override
  void didUpdateWidget(
    covariant KaizengramPostTextMediaFallbackText oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.onMoreTap != widget.onMoreTap) {
      _syncMoreTapRecognizer();
    }
  }

  @override
  void dispose() {
    _disposeMoreTapRecognizer();
    super.dispose();
  }

  void _syncMoreTapRecognizer() {
    if (widget.onMoreTap == null) {
      _disposeMoreTapRecognizer();
      return;
    }

    _moreTapRecognizer ??= TapGestureRecognizer();
    _moreTapRecognizer!.onTap = widget.onMoreTap;
  }

  void _disposeMoreTapRecognizer() {
    _moreTapRecognizer?.dispose();
    _moreTapRecognizer = null;
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(
      color: AppColors.textPrimary,
      fontSize: 18,
      height: 1.35,
      fontWeight: FontWeight.w700,
    );
    const moreStyle = TextStyle(
      color: AppColors.purple1,
      fontSize: 18,
      height: 1.35,
      fontWeight: FontWeight.w800,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final textDirection = Directionality.of(context);
        final textPainter = TextPainter(
          text: const TextSpan(),
          textDirection: textDirection,
          maxLines: 3,
        );
        textPainter.text = TextSpan(text: widget.text, style: textStyle);
        textPainter.layout(maxWidth: constraints.maxWidth);
        if (!textPainter.didExceedMaxLines) {
          return Text(
            widget.text,
            maxLines: 3,
            overflow: TextOverflow.clip,
            style: textStyle,
          );
        }

        final collapsedText = _collapsedMediaFallbackText(
          maxWidth: constraints.maxWidth,
          textDirection: textDirection,
          textStyle: textStyle,
          moreStyle: moreStyle,
        );

        if (collapsedText == null) {
          return Text(
            widget.text,
            maxLines: 3,
            overflow: TextOverflow.clip,
            style: textStyle,
          );
        }

        return RichText(
          maxLines: 3,
          overflow: TextOverflow.clip,
          text: TextSpan(
            style: textStyle,
            children: <InlineSpan>[
              if (collapsedText.isNotEmpty) TextSpan(text: '$collapsedText '),
              TextSpan(
                text: AppStrings.kaizengramMediaFallbackMore,
                style: moreStyle,
                recognizer: _moreTapRecognizer,
              ),
            ],
          ),
        );
      },
    );
  }

  String? _collapsedMediaFallbackText({
    required double maxWidth,
    required TextDirection textDirection,
    required TextStyle textStyle,
    required TextStyle moreStyle,
  }) {
    var low = 0;
    var high = widget.text.length;
    String? best;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      final candidate = widget.text.substring(0, mid).trimRight();
      final spans = <InlineSpan>[
        if (candidate.isNotEmpty) TextSpan(text: '$candidate '),
        TextSpan(
          text: AppStrings.kaizengramMediaFallbackMore,
          style: moreStyle,
        ),
      ];
      final painter = TextPainter(
        text: TextSpan(style: textStyle, children: spans),
        textDirection: textDirection,
        maxLines: 3,
      )..layout(maxWidth: maxWidth);

      if (painter.didExceedMaxLines) {
        high = mid - 1;
      } else {
        best = candidate;
        low = mid + 1;
      }
    }

    return best;
  }
}

class KaizengramUploadDocPlaceholder extends StatelessWidget {
  const KaizengramUploadDocPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surfaceDark3,
      alignment: Alignment.center,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const <Widget>[
          Icon(
            Icons.upload_file_rounded,
            color: AppColors.textSecondary,
            size: 36,
          ),
          SizedBox(height: 10),
          AppTextView.body1(
            AppStrings.kaizengramLabelUploadDoc,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ],
      ),
    );
  }
}

_TrackStatusStyle _resolveTrackStatusStyle(
  String status,
  KaizengramPostCategory postCategory,
) {
  final normalized = CustomFunctions.normalizedStatus(
    status,
  ).replaceAll('-', ' ');

  if (postCategory == KaizengramPostCategory.learningCompliance) {
    if (normalized == 'compliant') {
      return const _TrackStatusStyle(
        backgroundColor: Color(0xFFE3F8F4),
        borderColor: AppColors.green1,
        textColor: AppColors.green1,
      );
    }

    if (normalized == 'non compliance') {
      return const _TrackStatusStyle(
        backgroundColor: Color(0xFFFFE1E1),
        borderColor: AppColors.red,
        textColor: AppColors.red,
      );
    }

    if (normalized == 'in progress') {
      return const _TrackStatusStyle(
        backgroundColor: Color(0xFFF0E9FF),
        borderColor: AppColors.purple1,
        textColor: AppColors.purple1,
      );
    }
  }

  if (postCategory == KaizengramPostCategory.documentCompliance) {
    if (normalized == 'pending approval') {
      return const _TrackStatusStyle(
        backgroundColor: Color(0xFFF0E9FF),
        borderColor: AppColors.purple1,
        textColor: AppColors.purple1,
      );
    }

    if (normalized == 'pending submission') {
      return const _TrackStatusStyle(
        backgroundColor: Color(0xFFE8F2FF),
        borderColor: Color(0xFF2F80ED),
        textColor: Color(0xFF2F80ED),
      );
    }

    if (normalized == 'compliant') {
      return const _TrackStatusStyle(
        backgroundColor: Color(0xFFE3F8F4),
        borderColor: AppColors.green1,
        textColor: AppColors.green1,
      );
    }

    if (normalized == 'rejected') {
      return const _TrackStatusStyle(
        backgroundColor: Color(0xFFFFE1E1),
        borderColor: AppColors.red,
        textColor: AppColors.red,
      );
    }
  }

  if (normalized == 'excellent' ||
      normalized == 'good' ||
      CustomFunctions.isPassedStatus(normalized)) {
    return const _TrackStatusStyle(
      backgroundColor: Color(0xFFE3F8F4),
      borderColor: AppColors.green1,
      textColor: AppColors.green1,
    );
  }

  if (normalized == 'bad' ||
      normalized == 'rejected' ||
      normalized == 'non compliant' ||
      CustomFunctions.isFailedStatus(normalized) ||
      CustomFunctions.isCancelledStatus(normalized)) {
    return const _TrackStatusStyle(
      backgroundColor: Color(0xFFFFE1E1),
      borderColor: AppColors.red,
      textColor: AppColors.red,
    );
  }

  if (normalized == 'needs improvement' ||
      normalized == 'due' ||
      normalized == 'due by' ||
      normalized == 'pending submission' ||
      CustomFunctions.isPendingStatus(normalized) ||
      CustomFunctions.isPendingApprovalStatus(normalized) ||
      postCategory == KaizengramPostCategory.audit &&
          normalized == 'improvement needed') {
    return const _TrackStatusStyle(
      backgroundColor: Color(0xFFFFE8D9),
      borderColor: AppColors.orange1,
      textColor: AppColors.orange1,
    );
  }

  if (CustomFunctions.isNoLongerNeededStatus(normalized)) {
    return const _TrackStatusStyle(
      backgroundColor: Color(0xFFE4E7EC),
      borderColor: AppColors.grey1,
      textColor: AppColors.grey2,
    );
  }

  return const _TrackStatusStyle(
    backgroundColor: AppColors.textPrimary,
    borderColor: AppColors.secondaryColor,
    textColor: AppColors.secondaryColor,
  );
}

class _TrackStatusStyle {
  const _TrackStatusStyle({
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color borderColor;
  final Color textColor;
}
