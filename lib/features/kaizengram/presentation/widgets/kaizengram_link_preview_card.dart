import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_text_view.dart';
import 'kaizengram_link_utils.dart';

class KaizengramTextLinkPreview extends StatelessWidget {
  const KaizengramTextLinkPreview({
    super.key,
    required this.text,
    this.topSpacing = 8,
  });

  final String text;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    final firstLink = kaizengramFirstLinkInText(text);
    if (firstLink == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.only(top: topSpacing),
      child: KaizengramLinkPreviewCard(url: firstLink),
    );
  }
}

class KaizengramLinkPreviewCard extends StatelessWidget {
  const KaizengramLinkPreviewCard({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final fallbackPreview =
        _KaizengramLinkPreviewResolver.fallbackPreviewForUrl(url);

    return FutureBuilder<KaizengramLinkPreviewData>(
      future: _KaizengramLinkPreviewResolver.instance.resolve(url),
      builder: (context, snapshot) {
        final preview = snapshot.data ?? fallbackPreview;
        final isLoading =
            snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => kaizengramOpenUrl(preview.url),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF24283D),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.textPrimary.withValues(alpha: 0.08),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _LinkPreviewImage(preview: preview, isLoading: isLoading),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Expanded(
                                child: AppTextView.body4(
                                  preview.hostLabel,
                                  color: AppColors.secondaryColor,
                                  fontWeight: FontWeight.w700,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isLoading)
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          AppTextView.body2(
                            preview.title,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (preview.hasDescription) ...<Widget>[
                            const SizedBox(height: 4),
                            AppTextView.body4(
                              preview.description!,
                              color: AppColors.textSecondary,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 6),
                          AppTextView.body4(
                            preview.urlLabel,
                            color: AppColors.textSecondary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LinkPreviewImage extends StatelessWidget {
  const _LinkPreviewImage({required this.preview, required this.isLoading});

  final KaizengramLinkPreviewData preview;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final imageUrl = preview.imageUrl;
    return ClipRRect(
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(14)),
      child: SizedBox(
        width: 88,
        height: 88,
        child: imageUrl == null
            ? Container(
                color: AppColors.surfaceDark3.withValues(alpha: 0.92),
                alignment: Alignment.center,
                child: Icon(
                  isLoading ? Icons.language_rounded : Icons.link_rounded,
                  color: AppColors.textSecondary,
                  size: 26,
                ),
              )
            : Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: AppColors.surfaceDark3.withValues(alpha: 0.92),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class KaizengramLinkPreviewData {
  const KaizengramLinkPreviewData({
    required this.url,
    required this.urlLabel,
    required this.hostLabel,
    required this.title,
    this.description,
    this.imageUrl,
  });

  final String url;
  final String urlLabel;
  final String hostLabel;
  final String title;
  final String? description;
  final String? imageUrl;

  bool get hasDescription => description?.trim().isNotEmpty == true;
}

class _KaizengramLinkPreviewResolver {
  _KaizengramLinkPreviewResolver._();

  static final _KaizengramLinkPreviewResolver instance =
      _KaizengramLinkPreviewResolver._();

  final Map<String, Future<KaizengramLinkPreviewData>> _cachedPreviews =
      <String, Future<KaizengramLinkPreviewData>>{};

  Future<KaizengramLinkPreviewData> resolve(String rawUrl) {
    final normalizedUrl = kaizengramNormalizeUrl(rawUrl);
    return _cachedPreviews.putIfAbsent(
      normalizedUrl,
      () => _load(normalizedUrl),
    );
  }

  static KaizengramLinkPreviewData fallbackPreviewForUrl(String rawUrl) {
    final normalizedUrl = kaizengramNormalizeUrl(rawUrl);
    final uri = Uri.tryParse(normalizedUrl);
    final hostLabel = _hostLabelFor(uri);
    final urlLabel = _urlLabelFor(uri);
    return KaizengramLinkPreviewData(
      url: normalizedUrl,
      urlLabel: urlLabel,
      hostLabel: hostLabel,
      title: hostLabel,
    );
  }

  Future<KaizengramLinkPreviewData> _load(String normalizedUrl) async {
    final fallbackPreview = fallbackPreviewForUrl(normalizedUrl);
    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null) {
      return fallbackPreview;
    }

    try {
      final response = await http
          .get(
            uri,
            headers: const <String, String>{
              'User-Agent': 'Kaizen Link Preview',
            },
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode >= 400) {
        return fallbackPreview;
      }

      final effectiveUri = response.request?.url ?? uri;
      final document = utf8.decode(response.bodyBytes, allowMalformed: true);
      final metaTags = _metaTagsFromDocument(document);
      final title =
          _firstMetaContent(metaTags, const <String>[
            'og:title',
            'twitter:title',
          ]) ??
          _documentTitle(document) ??
          fallbackPreview.title;
      final description = _firstMetaContent(metaTags, const <String>[
        'og:description',
        'twitter:description',
        'description',
      ]);
      final imageUrl = _resolvedPreviewImageUrl(
        effectiveUri,
        _firstMetaContent(metaTags, const <String>[
          'og:image',
          'twitter:image',
        ]),
      );

      return KaizengramLinkPreviewData(
        url: effectiveUri.toString(),
        urlLabel: _urlLabelFor(effectiveUri),
        hostLabel: _hostLabelFor(effectiveUri),
        title: title,
        description: description,
        imageUrl: imageUrl,
      );
    } catch (_) {
      return fallbackPreview;
    }
  }
}

List<Map<String, String>> _metaTagsFromDocument(String document) {
  final tagMatches = RegExp(
    r'<meta\s+[^>]*>',
    caseSensitive: false,
  ).allMatches(document);
  final tags = <Map<String, String>>[];

  for (final match in tagMatches) {
    final tag = match.group(0);
    if (tag == null || tag.isEmpty) {
      continue;
    }

    final attributes = <String, String>{};
    final attributeMatches = RegExp(
      r"""([a-zA-Z:_-]+)\s*=\s*(?:"([^"]*)"|'([^']*)'|([^\s>]+))""",
      caseSensitive: false,
    ).allMatches(tag);

    for (final attributeMatch in attributeMatches) {
      final key = attributeMatch.group(1)?.toLowerCase();
      final value =
          attributeMatch.group(2) ??
          attributeMatch.group(3) ??
          attributeMatch.group(4);
      if (key == null || value == null || value.trim().isEmpty) {
        continue;
      }

      attributes[key] = _decodeHtml(value.trim());
    }

    if (attributes.isNotEmpty) {
      tags.add(attributes);
    }
  }

  return tags;
}

String? _firstMetaContent(
  List<Map<String, String>> metaTags,
  List<String> keys,
) {
  for (final attributes in metaTags) {
    final property = attributes['property']?.toLowerCase();
    final name = attributes['name']?.toLowerCase();
    final content = attributes['content']?.trim();
    if (content == null || content.isEmpty) {
      continue;
    }

    if ((property != null && keys.contains(property)) ||
        (name != null && keys.contains(name))) {
      return content;
    }
  }

  return null;
}

String? _documentTitle(String document) {
  final match = RegExp(
    r'<title[^>]*>(.*?)</title>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(document);
  final title = match?.group(1)?.trim();
  if (title == null || title.isEmpty) {
    return null;
  }

  return _decodeHtml(title.replaceAll(RegExp(r'\s+'), ' '));
}

String? _resolvedPreviewImageUrl(Uri effectiveUri, String? rawImageUrl) {
  final normalizedImageUrl = rawImageUrl?.trim();
  if (normalizedImageUrl == null || normalizedImageUrl.isEmpty) {
    return null;
  }

  if (normalizedImageUrl.startsWith('//')) {
    return '${effectiveUri.scheme}:$normalizedImageUrl';
  }

  final imageUri = Uri.tryParse(normalizedImageUrl);
  if (imageUri == null) {
    return null;
  }

  if (imageUri.hasScheme) {
    return imageUri.toString();
  }

  return effectiveUri.resolveUri(imageUri).toString();
}

String _hostLabelFor(Uri? uri) {
  final host = uri?.host.trim();
  if (host == null || host.isEmpty) {
    return '';
  }

  return host.replaceFirst(RegExp(r'^www\.', caseSensitive: false), '');
}

String _urlLabelFor(Uri? uri) {
  if (uri == null) {
    return '';
  }

  final path = uri.path.trim();
  if (path.isEmpty || path == '/') {
    return _hostLabelFor(uri);
  }

  return '${_hostLabelFor(uri)}$path';
}

String _decodeHtml(String value) {
  return value
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', '\'')
      .replaceAll('&apos;', '\'')
      .replaceAll('&nbsp;', ' ');
}
