import '../../../../core/constants/app_strings.dart';
import '../../../../core/utils/custom_functions.dart';
import '../../domain/entities/audit_member.dart';
import '../../domain/entities/audit_member_status.dart';
import '../../domain/entities/audit_profile.dart';
import '../../domain/entities/performance_report.dart';

class PerformanceReportModel extends PerformanceReport {
  const PerformanceReportModel({
    required super.profile,
    super.createdAt,
    super.personalityAvatarImagePath,
    super.hasPersonalityData,
    super.isCertified,
    super.certifiedAt,
    super.employeeSignatureName,
    super.selectedProfileSignatureUuid,
    super.selectedProfileSignatureUrl,
    super.facilitatorSignatureUrl,
    super.facilitatorName,
    required super.reportSnapshot,
    required super.rawPersonalityDescription,
    required super.overallPerformanceScore,
    required super.confidenceLevel,
    required super.archetypeTitle,
    required super.archetypeSubtitle,
    required super.archetypeSummary,
    required super.guidanceParagraphs,
    required super.categoryTabs,
    required super.selectedCategoryIndex,
    required super.ratingRows,
    required super.paygradePipeline,
    required super.currentPaygrade,
    required super.paygradeUnit,
    super.coreValues,
    super.remarkVersion,
  });

  factory PerformanceReportModel.fromApiJson(
    Map<String, dynamic> json, {
    required AuditProfile fallbackProfile,
  }) {
    final selectedProfile = _map(json['selected_profile']);
    final job = _map(json['job']);
    final personalityValue = json['personality'];
    final paygrades = _listOfMaps(json['paygrades']);
    final availableProfiles = _listOfMaps(json['profiles']);
    final categories = _listOfMaps(json['categories']);
    final coreValueEntries = _firstNonEmptyListOfMaps(<dynamic>[
      json['core_values'],
      json['coreValues'],
      _map(json['data'])['core_values'],
      _map(personalityValue)['core_values'],
    ]);
    final personality = _map(personalityValue);
    final hasPersonalityData =
        personalityValue is Map && personality.isNotEmpty;
    final isOpenSeatResponse =
        selectedProfile.isEmpty && availableProfiles.isEmpty;
    final personalityAvatar = CustomFunctions.getPersonalityAvatar(
      _nullableStringFromMaps([personality], ['type_code']),
      _nullableStringFromMaps([selectedProfile, json], ['gender']),
    );

    final assignedPaygrade = paygrades.cast<Map<String, dynamic>?>().firstWhere(
      (item) => item?['is_assigned'] == true,
      orElse: () => paygrades.isNotEmpty ? paygrades.first : null,
    );

    final roleTitle = _stringFromMaps(
      [job, json],
      ['title'],
      fallback: fallbackProfile.roleTitle,
    );
    final profile = AuditProfile(
      uuid: _stringFromMaps(
        [selectedProfile, json],
        ['uuid'],
        fallback: fallbackProfile.uuid,
      ),
      profileJob: _stringFromMaps(
        [json],
        ['profile_job'],
        fallback: fallbackProfile.profileJob,
      ),
      profileUuid: _stringFromMaps(
        [selectedProfile, json],
        ['uuid', 'profile_uuid', 'user_uuid'],
        fallback: fallbackProfile.profileUuid,
      ),
      email: _stringFromMaps(
        [selectedProfile],
        ['email'],
        fallback: fallbackProfile.email,
      ),
      imageUrl: isOpenSeatResponse
          ? null
          : _nullableStringFromMaps([selectedProfile], ['image']),
      isFavorite: fallbackProfile.isFavorite,
      lastAuditDates: fallbackProfile.lastAuditDates,
      roleTitle: roleTitle,
      name: isOpenSeatResponse
          ? 'No Profile'
          : _stringFromMaps(
              [selectedProfile],
              ['name'],
              fallback: fallbackProfile.name,
            ),
      lastAuditLabel: CustomFunctions.formatDate(
        _stringFromMaps([json], ['created_at']),
      ),
      yearQuarter: fallbackProfile.yearQuarter,
      seatProfile: isOpenSeatResponse ? 'Open Seat' : roleTitle,
      overallScore: _numFromMaps(
        [_map(json['performance'])],
        ['overall_score'],
      ).toDouble(),
      confidenceLevel: _resolveConfidenceLevel(
        _numFromMaps([_map(json['performance'])], ['confidence_level']),
      ),
      status: AuditMemberStatus.active,
      reviewerInitials: fallbackProfile.reviewerInitials,
      avatarLabel: fallbackProfile.avatarLabel,
      profiles: availableProfiles
          .map(_mapAuditMemberProfile)
          .toList(growable: false),
      avatarImageUrl: isOpenSeatResponse
          ? null
          : _nullableStringFromMaps([selectedProfile], ['image']),
    );

    final categoryTabs = categories
        .map((category) {
          final rows = _listOfMaps(category['descriptions'])
              .map((description) {
                final stats = _map(description['stats']);
                return PerformanceReportRatingRow(
                  descriptionUuid: _stringFromMaps(
                    [description],
                    ['uuid', 'description_uuid'],
                  ),
                  title: _stringFromMaps(
                    [description],
                    ['description'],
                    fallback: 'Description',
                  ),
                  passCount: _numFromMaps([stats], ['total_great']).round(),
                  partialCount: _numFromMaps(
                    [stats],
                    ['total_almost_there'],
                  ).round(),
                  failCount: _numFromMaps(
                    [stats],
                    ['total_needs_improvement'],
                  ).round(),
                  ratingPercent: _numFromMaps(
                    [stats],
                    ['total_percentage'],
                  ).round(),
                  remarks: _nullableStringFromMaps(
                    [description],
                    ['remarks', 'remark'],
                  ),
                );
              })
              .toList(growable: false);

          return PerformanceReportCategoryTab(
            label: _stringFromMaps(
              [category],
              ['category_title'],
              fallback: 'Category',
            ),
            score: _numFromMaps(
              [category],
              ['average_weighted_score'],
            ).toDouble(),
            rows: rows,
          );
        })
        .toList(growable: false);
    final ratingRows = categoryTabs.isNotEmpty
        ? categoryTabs.first.rows
        : const <PerformanceReportRatingRow>[];

    final paygradePipeline = paygrades
        .asMap()
        .entries
        .map(
          (entry) => PerformanceReportPaygradeStep(
            label: _paygradeStepLabel(roleTitle, entry.key + 1),
            caption: _paygradeCaption(entry.value),
            title: _stringFromMaps([entry.value], ['title'], fallback: '--'),
            payRateAmount: _numFromMaps([entry.value], ['pay_rate']).toDouble(),
            payRateDisplay: _paygradeRateDisplay(entry.value),
            promotionRequirement: _stringFromMaps(
              [entry.value],
              ['promotion_requirement'],
              fallback: '-',
            ),
            isCurrent: entry.value['is_assigned'] == true,
          ),
        )
        .toList(growable: false);
    final coreValues = coreValueEntries
        .map(_mapCoreValue)
        .whereType<PerformanceReportCoreValue>()
        .toList(growable: false);

    return PerformanceReportModel(
      profile: profile,
      createdAt: _nullableStringFromMaps([json], ['created_at', 'createdAt']),
      personalityAvatarImagePath: personalityAvatar,
      hasPersonalityData: hasPersonalityData,
      isCertified: false,
      certifiedAt: null,
      employeeSignatureName: profile.name,
      selectedProfileSignatureUuid: _nullableStringFromMaps(
        [_map(selectedProfile['signature'])],
        ['uuid'],
      ),
      selectedProfileSignatureUrl: _nullableStringFromMaps(
        [_map(selectedProfile['signature'])],
        ['image'],
      ),
      facilitatorSignatureUrl: null,
      facilitatorName: null,
      reportSnapshot: Map<String, dynamic>.from(json),
      rawPersonalityDescription: _stringFromMaps(
        [personality],
        ['description'],
        fallback: '',
      ),
      overallPerformanceScore: _numFromMaps(
        [_map(json['performance'])],
        ['overall_score'],
      ).toDouble(),
      confidenceLevel: _normalizeConfidenceDisplay(
        _numFromMaps(
          [_map(json['performance'])],
          ['confidence_level'],
        ).toDouble(),
      ),
      archetypeTitle: _stringFromMaps(
        [personality],
        ['archetype_name', 'title'],
        fallback: 'Performance Overview',
      ),
      archetypeSubtitle: _stringFromMaps(
        [personality],
        ['type_code', 'subtitle', 'type', 'name'],
        fallback: roleTitle,
      ),
      archetypeSummary: _stringFromMaps(
        [personality],
        ['title', 'summary', 'description'],
        fallback: 'Performance data for this quarter is shown below.',
      ),
      guidanceParagraphs: _guidanceParagraphs(personality),
      categoryTabs: categoryTabs,
      selectedCategoryIndex: 0,
      ratingRows: ratingRows,
      paygradePipeline: paygradePipeline,
      currentPaygrade: assignedPaygrade == null
          ? '--'
          : _paygradeLabel(assignedPaygrade),
      paygradeUnit: _stringFromMaps([job], ['unit'], fallback: '--'),
      coreValues: coreValues,
    );
  }

  static List<String> _guidanceParagraphs(Map<String, dynamic> personality) {
    final raw =
        personality['guidance'] ??
        personality['guidance_paragraphs'] ??
        personality['paragraphs'];
    if (raw is List) {
      final values = raw
          .whereType<String>()
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (values.isNotEmpty) {
        return values;
      }
    }

    final description = _stringFromMaps([personality], ['description']);
    if (description.isNotEmpty) {
      final paragraphs = description
          .split(RegExp(r'\n\s*\n'))
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (paragraphs.isNotEmpty) {
        return paragraphs;
      }
    }

    return const <String>[
      'This report summarizes the employee performance data recorded for the selected quarter.',
    ];
  }

  static AuditMemberProfile _mapAuditMemberProfile(Map<String, dynamic> json) {
    return AuditMemberProfile(
      uuid: _stringFromMaps([json], ['uuid']),
      name: _stringFromMaps([json], ['name'], fallback: 'Profile'),
      email: _stringFromMaps([json], ['email']),
      imageUrl: _nullableStringFromMaps([json], ['image']),
      onboarded: json['onboarded'] == true,
    );
  }

  static String _paygradeLabel(Map<String, dynamic> paygrade) {
    final payRate = _numFromMaps([paygrade], ['pay_rate']);
    if (payRate <= 0) {
      return AppStrings.paygradesUnavailableDisplay;
    }

    final formattedRate = payRate % 1 == 0
        ? payRate.toInt().toString()
        : payRate.toString();
    return '\$$formattedRate/hr';
  }

  static String _paygradeCaption(Map<String, dynamic> paygrade) {
    return _paygradeRateDisplay(paygrade);
  }

  static String _paygradeRateDisplay(Map<String, dynamic> paygrade) {
    final payRate = _numFromMaps([paygrade], ['pay_rate']);
    if (payRate <= 0) {
      return AppStrings.paygradesUnavailableDisplay;
    }

    final formattedRate = payRate % 1 == 0
        ? payRate.toInt().toString()
        : payRate.toString();
    final unit = _stringFromMaps([paygrade], ['unit'], fallback: 'unit');
    return '\$$formattedRate/$unit';
  }

  static String _paygradeStepLabel(String title, int index) {
    final words = title
        .split(RegExp(r'\s+'))
        .map((word) => word.trim())
        .where((word) => word.isNotEmpty)
        .where((word) => !RegExp(r'^\d+$').hasMatch(word))
        .toList(growable: false);

    final initials = words.isEmpty
        ? 'P'
        : words.map((word) => word[0].toUpperCase()).join();

    return '$initials $index';
  }

  static PerformanceReportCoreValue? _mapCoreValue(Map<String, dynamic> json) {
    final title = _stringFromMaps(
      [json],
      ['title', 'name', 'label', 'core_value', 'value'],
    );
    final description = _nullableStringFromMaps(
      [json],
      ['description', 'detail', 'summary', 'remarks', 'remark'],
    );
    final details = _buildCoreValueDetails(json);

    if (title.isEmpty && description == null && details.isEmpty) {
      return null;
    }

    return PerformanceReportCoreValue(
      title: title.isEmpty ? 'Core Value' : title,
      description: description,
      iconKey: _nullableStringFromMaps([json], ['icon', 'icon_key', 'key']),
      colorHex: _nullableStringFromMaps(
        [json],
        ['color_hex', 'colorHex', 'hex_color', 'hexCode', 'hex_code'],
      ),
      details: details,
      rawData: Map<String, dynamic>.from(json),
    );
  }

  static List<PerformanceReportCoreValueDetail> _buildCoreValueDetails(
    Map<String, dynamic> json,
  ) {
    const ignoredKeys = <String>{
      'title',
      'name',
      'label',
      'core_value',
      'value',
      'description',
      'detail',
      'summary',
      'remarks',
      'remark',
      'icon',
      'icon_key',
      'key',
      'uuid',
      'id',
    };

    final details = <PerformanceReportCoreValueDetail>[];
    for (final entry in json.entries) {
      if (_shouldHideCoreValueDetailKey(entry.key, ignoredKeys)) {
        continue;
      }

      final value = _formatCoreValueDetailValue(entry.value);
      if (value == null || value.isEmpty) {
        continue;
      }

      details.add(
        PerformanceReportCoreValueDetail(
          label: _formatCoreValueDetailLabel(entry.key),
          value: value,
        ),
      );
    }

    return details;
  }

  static String? _formatCoreValueDetailValue(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is String) {
      final trimmedValue = value.trim();
      return trimmedValue.isEmpty ? null : trimmedValue;
    }

    if (value is num || value is bool) {
      return value.toString();
    }

    if (value is List) {
      final items = value
          .map(_stringifyCoreValueListItem)
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (items.isEmpty) {
        return null;
      }
      return items.map((item) => '• $item').join('\n');
    }

    if (value is Map) {
      final mapValue = _map(value);
      final preferredValue = _stringFromMaps(
        [mapValue],
        ['title', 'name', 'label', 'description', 'detail', 'summary'],
      );
      if (preferredValue.isNotEmpty) {
        return preferredValue;
      }

      final pairs = mapValue.entries
          .map((entry) {
            if (_shouldHideCoreValueDetailKey(entry.key, const <String>{})) {
              return null;
            }
            final nestedValue = _formatCoreValueDetailValue(entry.value);
            if (nestedValue == null || nestedValue.isEmpty) {
              return null;
            }

            return '${_formatCoreValueDetailLabel(entry.key)}: ${nestedValue.replaceAll('\n', ' ')}';
          })
          .whereType<String>()
          .toList(growable: false);
      if (pairs.isEmpty) {
        return null;
      }

      return pairs.join('\n');
    }

    final fallbackValue = value.toString().trim();
    return fallbackValue.isEmpty ? null : fallbackValue;
  }

  static String _stringifyCoreValueListItem(dynamic item) {
    final value = _formatCoreValueDetailValue(item);
    return value?.replaceAll('\n', ' ').trim() ?? '';
  }

  static String _formatCoreValueDetailLabel(String key) {
    return key
        .split(RegExp(r'[_\-\s]+'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .map(
          (segment) =>
              '${segment[0].toUpperCase()}${segment.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static bool _shouldHideCoreValueDetailKey(
    String key,
    Set<String> ignoredKeys,
  ) {
    final normalizedKey = key.trim().toLowerCase();
    if (ignoredKeys.contains(normalizedKey)) {
      return true;
    }

    final compactKey = normalizedKey.replaceAll(RegExp(r'[^a-z0-9]'), '');
    return compactKey == 'colorhex' ||
        compactKey == 'colorcode' ||
        compactKey == 'hexcolor' ||
        compactKey == 'hexcode';
  }

  static int _resolveConfidenceLevel(num value) {
    final normalized = _normalizeConfidenceDisplay(value.toDouble());
    return normalized.round();
  }

  static double _normalizeConfidenceDisplay(double value) {
    if (value <= 1) {
      return value * 100;
    }
    return value;
  }

  static Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) {
      return value;
    }
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }
    return const <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _listOfMaps(dynamic value) {
    if (value is! List) {
      return const <Map<String, dynamic>>[];
    }

    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList(growable: false);
  }

  static List<Map<String, dynamic>> _firstNonEmptyListOfMaps(
    List<dynamic> values,
  ) {
    for (final value in values) {
      final mappedList = _listOfMaps(value);
      if (mappedList.isNotEmpty) {
        return mappedList;
      }
    }

    return const <Map<String, dynamic>>[];
  }

  static String _stringFromMaps(
    List<Map<String, dynamic>> sources,
    List<String> keys, {
    String fallback = '',
  }) {
    for (final source in sources) {
      for (final key in keys) {
        final value = source[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }
    return fallback;
  }

  static String? _nullableStringFromMaps(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    final value = _stringFromMaps(sources, keys);
    return value.isEmpty ? null : value;
  }

  static num _numFromMaps(
    List<Map<String, dynamic>> sources,
    List<String> keys,
  ) {
    for (final source in sources) {
      for (final key in keys) {
        final value = source[key];
        if (value is num) {
          return value;
        }
        if (value is String) {
          final parsed = num.tryParse(value);
          if (parsed != null) {
            return parsed;
          }
        }
      }
    }
    return 0;
  }
}
