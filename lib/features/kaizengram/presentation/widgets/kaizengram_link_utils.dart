import 'package:url_launcher/url_launcher.dart';

class KaizengramDetectedLink {
  const KaizengramDetectedLink({
    required this.value,
    required this.trailingText,
    required this.consumedLength,
  });

  final String value;
  final String trailingText;
  final int consumedLength;
}

KaizengramDetectedLink? kaizengramLinkTokenAt(String text, int startIndex) {
  final match = _kaizengramLinkPattern.matchAsPrefix(text, startIndex);
  if (match == null) {
    return null;
  }

  final rawValue = match.group(0);
  if (rawValue == null || rawValue.isEmpty) {
    return null;
  }

  final trimmedValue = _trimKaizengramLinkTrailingPunctuation(rawValue);
  if (trimmedValue.isEmpty) {
    return null;
  }

  return KaizengramDetectedLink(
    value: trimmedValue,
    trailingText: rawValue.substring(trimmedValue.length),
    consumedLength: rawValue.length,
  );
}

String? kaizengramFirstLinkInText(String text) {
  final trimmedText = text.trim();
  if (trimmedText.isEmpty) {
    return null;
  }

  final match = _kaizengramLinkPattern.firstMatch(trimmedText);
  if (match == null) {
    return null;
  }

  final rawValue = match.group(0);
  if (rawValue == null || rawValue.isEmpty) {
    return null;
  }

  final trimmedValue = _trimKaizengramLinkTrailingPunctuation(rawValue);
  return trimmedValue.isEmpty ? null : trimmedValue;
}

String kaizengramNormalizeUrl(String rawUrl) {
  final normalizedUrl = rawUrl.trim();
  final lowerUrl = normalizedUrl.toLowerCase();
  if (lowerUrl.startsWith('http://') || lowerUrl.startsWith('https://')) {
    return normalizedUrl;
  }

  return 'https://$normalizedUrl';
}

Future<void> kaizengramOpenUrl(String rawUrl) async {
  final uri = Uri.tryParse(kaizengramNormalizeUrl(rawUrl));
  if (uri == null) {
    return;
  }

  final didLaunch = await launchUrl(uri, mode: LaunchMode.platformDefault);
  if (didLaunch) {
    return;
  }

  await launchUrl(uri, mode: LaunchMode.externalApplication);
}

String _trimKaizengramLinkTrailingPunctuation(String value) {
  var endIndex = value.length;
  while (endIndex > 0 &&
      _kaizengramLinkTrailingPunctuation.contains(value[endIndex - 1])) {
    endIndex--;
  }

  return value.substring(0, endIndex);
}

const Set<String> _kaizengramLinkTrailingPunctuation = <String>{
  '.',
  ',',
  '!',
  '?',
  ':',
  ';',
  ')',
  ']',
  '}',
};

final RegExp _kaizengramLinkPattern = RegExp(
  r'(?:https?:\/\/|www\.)[^\s<>()]+',
  caseSensitive: false,
);
