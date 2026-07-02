import 'package:flutter/material.dart';
import 'package:sparrowkaizen/features/compliance/presentation/pages/training/next_quiz_video_screen.dart';

import '../features/audit/domain/entities/audit_member_status.dart';
import '../features/audit/domain/entities/audit_profile.dart';
import '../features/audit/presentation/pages/audit_detail_screen.dart';
import '../features/audit/presentation/pages/audit_report.dart';
import '../features/audit/presentation/pages/audit_screen.dart';
import '../features/audit/presentation/pages/performance_report_screen.dart';
import '../features/audit/presentation/pages/performance_snapshot_screen.dart';
import '../features/audit/presentation/pages/single_audit_details_screen.dart';
import '../features/compliance/domain/entities/compliance_tab_type.dart';
import '../features/compliance/domain/entities/learning_module_detail_track.dart';
import '../features/compliance/presentation/pages/compliance_screen.dart';
import '../features/compliance/presentation/pages/compliance_tracks_screen.dart';
import '../features/compliance/presentation/pages/training/compliance_training_screen.dart';
import '../features/kaizen_gpt/presentation/pages/kaizen_gpt.dart';
import '../features/kaizengram/presentation/pages/kaizengram_screen.dart';
import '../features/login/presentation/pages/login_screen.dart';
import '../features/onboarding/presentation/pages/set_password_screen.dart';
import '../features/onboarding/presentation/pages/set_profile_image_screen.dart';
import '../features/organizations/presentation/pages/organizations_screen.dart';
import '../features/paygrades/presentation/pages/paygrade_detail_screen.dart';
import '../features/paygrades/presentation/pages/paygrades_screen.dart';
import '../features/profile/presentation/pages/profile_screen.dart';
import '../features/seat_profile/domain/entities/seat_profile_detail.dart';
import '../features/seat_profile/presentation/pages/seat_profile_descriptions_screen.dart';
import '../features/seat_profile/presentation/pages/seat_profile_detail_screen.dart';
import '../features/seat_profile/presentation/pages/seat_profile_screen.dart';
import '../features/splash/presentation/pages/splash_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String onboardingPassword = '/onboarding/password';
  static const String learningTracks = '/learning-tracks';
  static const String compliance = '/compliance';
  static const String audit = '/audit';
  static const String performanceSnapshot = '/performance-snapshot';
  static const String reports = '/reports';
  static const String seatProfiles = '/seat-profiles';
  static const String paygrades = '/paygrades';
  static const String paygradeDetail = '/paygrades/detail';
  static const String organizations = '/organizations';
  static const String seatProfileDetail = '/seat-profiles/detail';
  static const String seatProfileDescriptions = '/seat-profiles/descriptions';
  static const String kaizenGpt = '/kaizen-gpt';
  static const String kaizengram = '/kaizengram';
  static const String profile = '/profile';
  static const String auditDetails = '/audit-details';
  static const String singleAuditDetails = '/audit-details/single';
  static const String auditReport = '/audit-report';
  static const String complianceDetail = '/compliance/detail';
  static const String complianceTracks = '/compliance/tracks';
  static const String complianceTraining = '/compliance/training';
  static const String complianceNextVideoQuiz =
      '/compliance/training/next-quiz-video';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
      case login:
        return _buildRoute(
          settings: settings,
          builder: (_) => const LoginScreen(),
        );
      case onboarding:
        return _buildRoute(
          settings: settings,
          builder: (_) => const SetProfileImageScreen(),
        );
      case onboardingPassword:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => SetPasswordScreen(
            initialProfileImagePath: args is OnboardingPasswordRouteArgs
                ? args.profileImagePath
                : null,
            initialEmail: args is OnboardingPasswordRouteArgs
                ? args.email
                : null,
          ),
        );
      case learningTracks:
        return _buildRoute(
          settings: settings,
          builder: (_) =>
              const ComplianceScreen(module: ComplianceTabType.learningTrack),
        );
      case compliance:
        return _buildRoute(
          settings: settings,
          builder: (_) =>
              const ComplianceScreen(module: ComplianceTabType.document),
        );
      case audit:
        return _buildRoute(
          settings: settings,
          builder: (_) => const AuditScreen(),
        );
      case performanceSnapshot:
        return _buildRoute(
          settings: settings,
          builder: (_) => const PerformanceSnapshotScreen(),
        );
      case reports:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => PerformanceReportScreen(
            profile: args is PerformanceReportRouteArgs
                ? args.profile
                : const AuditProfile(
                    uuid: '',
                    profileJob: '',
                    profileUuid: '',
                    email: '',
                    imageUrl: null,
                    isFavorite: false,
                    lastAuditDates: <String?>[],
                    roleTitle: '',
                    name: '',
                    lastAuditLabel: '',
                    yearQuarter: '',
                    seatProfile: '',
                    overallScore: 0,
                    confidenceLevel: 0,
                    status: AuditMemberStatus.active,
                    reviewerInitials: <String>[],
                    avatarLabel: '',
                  ),
            isMyReport: args is PerformanceReportRouteArgs
                ? args.isMyReport
                : false,
          ),
        );
      case seatProfiles:
        return _buildRoute(
          settings: settings,
          builder: (_) => const SeatProfileScreen(),
        );
      case paygrades:
        return _buildRoute(
          settings: settings,
          builder: (_) => const PaygradesScreen(),
        );
      case organizations:
        return _buildRoute(
          settings: settings,
          builder: (_) => const OrganizationsScreen(),
        );
      case paygradeDetail:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => PaygradeDetailScreen(
            paygradeId: args is PaygradeDetailRouteArgs ? args.paygradeId : '',
          ),
        );
      case seatProfileDetail:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => SeatProfileDetailScreen(
            seatId: args is SeatProfileDetailRouteArgs ? args.seatId : '',
          ),
        );
      case seatProfileDescriptions:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => SeatProfileDescriptionsScreen(
            category: args is SeatProfileDescriptionsRouteArgs
                ? args.category
                : const SeatProfileCategory(
                    id: '',
                    title: '',
                    weightPercent: 0,
                    descriptions: <SeatProfileDescription>[],
                  ),
          ),
        );
      case kaizenGpt:
        return _buildRoute(
          settings: settings,
          builder: (_) => const KaizenGptScreen(),
        );
      case kaizengram:
        return _buildRoute(
          settings: settings,
          builder: (_) => const KaizenGramScreen(),
        );
      case profile:
        return _buildRoute(settings: settings, builder: (_) => ProfileScreen());
      case auditDetails:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => AuditDetailsScreen(
            profileJobId: args is AuditDetailsRouteArgs
                ? args.profileJobId
                : '',
          ),
        );
      case singleAuditDetails:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => SingleAuditDetailsScreen(
            quarterlyAuditId: args is SingleAuditDetailsRouteArgs
                ? args.quarterlyAuditId
                : '',
            date: args is SingleAuditDetailsRouteArgs ? args.date : '',
            lastAuditDate: args is SingleAuditDetailsRouteArgs
                ? args.lastAuditDate
                : '',
          ),
        );
      case auditReport:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => AuditReportScreen(
            profileJobId: args is AuditReportRouteArgs ? args.profileJobId : '',
            initialYear: args is AuditReportRouteArgs ? args.initialYear : null,
            initialQuarter: args is AuditReportRouteArgs
                ? args.initialQuarter
                : null,
          ),
        );
      case complianceTracks:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => ComplianceTracksScreen(
            trackAssignmentUuid: args is ComplianceTracksRouteArgs
                ? args.trackAssignmentUuid
                : '',
            title: args is ComplianceTracksRouteArgs ? args.title : '',
          ),
        );
      case complianceTraining:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => ComplianceTrainingScreen(
            // track: args is ComplianceTrainingRouteArgs ? args.track : null,
            trackAssignmentUuid: args is ComplianceTrainingRouteArgs
                ? args.trackAssignmentUuid
                : '',
            itemUuid: args is ComplianceTrainingRouteArgs ? args.itemUuid : '',
          ),
        );
      case complianceNextVideoQuiz:
        return _buildRoute(
          settings: settings,
          builder: (_) => NextQuizVideoScreen(),
        );
      default:
        return _buildRoute(
          settings: settings,
          builder: (_) => const SplashScreen(),
        );
    }
  }

  static MaterialPageRoute<dynamic> _buildRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    return MaterialPageRoute<dynamic>(settings: settings, builder: builder);
  }

  static Future<T?> pushNamed<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);
  }

  static Future<T?> pushReplacementNamed<T, TO>(
    BuildContext context,
    String routeName, {
    Object? arguments,
    TO? result,
  }) {
    return Navigator.of(context).pushReplacementNamed<T, TO>(
      routeName,
      arguments: arguments,
      result: result,
    );
  }

  static Future<void> resetToLogin() async {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(login, (route) => false);
  }
}

class ComplianceDetailRouteArgs {
  const ComplianceDetailRouteArgs({required this.track});

  final LearningTrackModuleDetail track;
}

class ComplianceTracksRouteArgs {
  const ComplianceTracksRouteArgs({
    required this.trackAssignmentUuid,
    required this.title,
  });

  final String trackAssignmentUuid;
  final String title;
}

class AuditDetailsRouteArgs {
  const AuditDetailsRouteArgs({required this.profileJobId});

  final String profileJobId;
}

class SeatProfileDetailRouteArgs {
  const SeatProfileDetailRouteArgs({required this.seatId});

  final String seatId;
}

class SeatProfileDescriptionsRouteArgs {
  const SeatProfileDescriptionsRouteArgs({required this.category});

  final SeatProfileCategory category;
}

class PaygradeDetailRouteArgs {
  const PaygradeDetailRouteArgs({required this.paygradeId});

  final String paygradeId;
}

class SingleAuditDetailsRouteArgs {
  const SingleAuditDetailsRouteArgs({
    required this.quarterlyAuditId,
    required this.date,
    required this.lastAuditDate,
  });

  final String quarterlyAuditId;
  final String date;
  final String lastAuditDate;
}

class AuditReportRouteArgs {
  const AuditReportRouteArgs({
    required this.profileJobId,
    this.initialYear,
    this.initialQuarter,
  });

  final String profileJobId;
  final int? initialYear;
  final int? initialQuarter;
}

class PerformanceReportRouteArgs {
  const PerformanceReportRouteArgs({
    required this.profile,
    this.isMyReport = false,
  });

  final AuditProfile profile;
  final bool isMyReport;
}

class ComplianceTrainingRouteArgs {
  const ComplianceTrainingRouteArgs({
    required this.trackAssignmentUuid,
    required this.itemUuid,
  });

  final String trackAssignmentUuid;
  final String itemUuid;
}

class OnboardingPasswordRouteArgs {
  const OnboardingPasswordRouteArgs({this.profileImagePath, this.email});

  final String? profileImagePath;
  final String? email;
}
