import 'package:flutter/material.dart';
import 'package:sparrowkaizen/features/compliance/presentation/pages/training/next_quiz_video_screen.dart';

import '../core/preference/app_preference.dart';
import '../features/auth/presentation/pages/forgot_password_screen.dart';
import '../features/auth/presentation/pages/set_password_screen.dart'
    as auth_reset;
import '../features/check_in/domain/entities/audit_member_status.dart';
import '../features/check_in/domain/entities/audit_profile.dart';
import '../features/check_in/presentation/pages/check_in_details_screen.dart';
import '../features/check_in/presentation/pages/check_in_report.dart';
import '../features/check_in/presentation/pages/check_in_screen.dart';
import '../features/check_in/presentation/pages/performance_report_screen.dart';
import '../features/check_in/presentation/pages/performance_snapshot_screen.dart';
import '../features/check_in/presentation/pages/check_in_descriptions_list_screen.dart';
import '../features/compliance/domain/entities/compliance_tab_type.dart';
import '../features/compliance/domain/entities/learning_module_detail_track.dart';
import '../features/compliance/presentation/pages/compliance_screen.dart';
import '../features/compliance/presentation/pages/compliance_tracks_screen.dart';
import '../features/compliance/presentation/pages/training/compliance_training_screen.dart';
import '../features/departments/presentation/pages/departments_screen.dart';
import '../features/kaizen_gpt/presentation/pages/kaizen_gpt.dart';
import '../features/kaizengram/presentation/pages/kaizengram_screen.dart';
import '../features/login/presentation/pages/login_screen.dart';
import '../features/onboarding/presentation/pages/set_password_screen.dart'
    as onboarding_flow;
import '../features/onboarding/presentation/pages/set_profile_image_screen.dart';
import '../features/organizations/presentation/pages/organizations_screen.dart';
import '../features/paygrades/presentation/pages/paygrade_detail_screen.dart';
import '../features/paygrades/presentation/pages/paygrades_screen.dart';
import '../features/profile/presentation/pages/profile_screen.dart';
import '../features/seat_profile/domain/entities/department.dart';
import '../features/seat_profile/domain/entities/seat_profile_detail.dart';
import '../features/seat_profile/presentation/models/seat_profile_form_initial_data.dart';
import '../features/seat_profile/presentation/pages/seat_profile_create_screen.dart';
import '../features/seat_profile/presentation/pages/seat_profile_descriptions_screen.dart';
import '../features/seat_profile/presentation/pages/seat_profile_detail_screen.dart';
import '../features/seat_profile/presentation/pages/seat_profile_screen.dart';
import '../features/splash/presentation/pages/splash_screen.dart';
import '../features/training/presentation/pages/setup_training_screen.dart';
import '../features/training/presentation/pages/training_library_screen.dart';

class AppRouter {
  AppRouter._();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String splash = '/';
  static const String login = '/login';
  static const String forgotPassword = '/login/forgot-password';
  static const String loginSetPassword = '/login/set-password';
  static const String onboarding = '/onboarding';
  static const String onboardingPassword = '/onboarding/password';
  static const String learningTracks = '/learning-tracks';
  static const String compliance = '/compliance';
  static const String checkIn = '/check-in';
  static const String performanceSnapshot = '/performance-snapshot';
  static const String reports = '/reports';
  static const String seatProfiles = '/seat-profiles';
  static const String seatProfileCreate = '/seat-profiles/create';
  static const String paygrades = '/paygrades';
  static const String departments = '/departments';
  static const String paygradeDetail = '/paygrades/detail';
  static const String organizations = '/organizations';
  static const String seatProfileDetail = '/seat-profiles/detail';
  static const String seatProfileDescriptions = '/seat-profiles/descriptions';
  static const String seatProfileTrainingSetup =
      '/seat-profiles/training-setup';
  static const String trainingLibrary = '/training/library';
  static const String kaizenGpt = '/kaizen-gpt';
  static const String kaizengram = '/kaizengram';
  static const String profile = '/profile';
  static const String checkInDetails = '/check-in-details';
  static const String checkInDescriptionsList = '/check-in-details/single';
  static const String checkInReport = '/check-in-report';
  static const String complianceDetail = '/compliance/detail';
  static const String complianceTracks = '/compliance/tracks';
  static const String complianceTraining = '/compliance/training';
  static const String complianceNextVideoQuiz =
      '/compliance/training/next-quiz-video';

  static String get defaultAuthenticatedRouteName {
    return AppPreference.getUseParentApiEndpoints()
        ? trainingLibrary
        : compliance;
  }

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
      case forgotPassword:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => ForgotPasswordScreen(
            initialEmail: args is LoginSetPasswordRouteArgs ? args.email : null,
          ),
        );
      case loginSetPassword:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => auth_reset.SetPasswordScreen(
            initialEmail: args is LoginSetPasswordRouteArgs ? args.email : null,
            initialToken: args is LoginSetPasswordRouteArgs ? args.token : null,
          ),
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
          builder: (_) => onboarding_flow.SetPasswordScreen(
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
      case checkIn:
        return _buildRoute(
          settings: settings,
          builder: (_) => const CheckInScreen(),
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
      case seatProfileCreate:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => SeatProfileCreateScreen(
            initialData: args is SeatProfileCreateRouteArgs && args.isEditMode
                ? SeatProfileFormInitialData(
                    seatId: args.seatId ?? '',
                    actualId: args.actualId,
                    name: args.initialName ?? '',
                    department: args.initialDepartment,
                    paygradeUnit: args.initialPaygradeUnit,
                    initialCategory: args.initialCategory,
                  )
                : null,
          ),
        );
      case paygrades:
        return _buildRoute(
          settings: settings,
          builder: (_) => const PaygradesScreen(),
        );
      case departments:
        return _buildRoute(
          settings: settings,
          builder: (_) => const DepartmentsScreen(),
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
      case seatProfileTrainingSetup:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => SetupTrainingScreen(
            initialSeatProfileId: args is SeatProfileTrainingSetupRouteArgs
                ? args.initialSeatProfileId
                : null,
            initialCategoryId: args is SeatProfileTrainingSetupRouteArgs
                ? args.initialCategoryId
                : null,
            initialDescriptionId: args is SeatProfileTrainingSetupRouteArgs
                ? args.initialDescriptionId
                : null,
          ),
        );
      case trainingLibrary:
        return _buildRoute(
          settings: settings,
          builder: (_) => const TrainingLibraryScreen(),
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
      case checkInDetails:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => CheckInDetailsScreen(
            profileJobId: args is CheckInDetailsRouteArgs
                ? args.profileJobId
                : '',
            year: args is CheckInDetailsRouteArgs ? args.year : null,
            quarter: args is CheckInDetailsRouteArgs ? args.quarter : null,
            selectedProfileUuid: args is CheckInDetailsRouteArgs
                ? args.selectedProfileUuid
                : null,
          ),
        );
      case checkInDescriptionsList:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => CheckInDescriptionsListScreen(
            quarterlyAuditId: args is CheckInDescriptionsListRouteArgs
                ? args.quarterlyAuditId
                : '',
            date: args is CheckInDescriptionsListRouteArgs ? args.date : '',
            lastAuditDate: args is CheckInDescriptionsListRouteArgs
                ? args.lastAuditDate
                : '',
            year: args is CheckInDescriptionsListRouteArgs ? args.year : null,
            quarter: args is CheckInDescriptionsListRouteArgs
                ? args.quarter
                : null,
            requireDescriptionSelection:
                args is CheckInDescriptionsListRouteArgs
                ? args.requireDescriptionSelection
                : false,
          ),
        );
      case checkInReport:
        final args = settings.arguments;
        return _buildRoute(
          settings: settings,
          builder: (_) => CheckInReportScreen(
            profileJobId: args is CheckInReportRouteArgs
                ? args.profileJobId
                : '',
            initialYear: args is CheckInReportRouteArgs
                ? args.initialYear
                : null,
            initialQuarter: args is CheckInReportRouteArgs
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

class CheckInDetailsRouteArgs {
  const CheckInDetailsRouteArgs({
    required this.profileJobId,
    this.year,
    this.quarter,
    this.selectedProfileUuid,
  });

  final String profileJobId;
  final int? year;
  final int? quarter;
  final String? selectedProfileUuid;
}

class SeatProfileDetailRouteArgs {
  const SeatProfileDetailRouteArgs({required this.seatId});

  final String seatId;
}

class SeatProfileCreateRouteArgs {
  const SeatProfileCreateRouteArgs({
    this.seatId,
    this.actualId,
    this.initialName,
    this.initialDepartment,
    this.initialPaygradeUnit,
    this.initialCategory,
  });

  const SeatProfileCreateRouteArgs.edit({
    required this.seatId,
    this.actualId,
    required this.initialName,
    this.initialDepartment,
    this.initialPaygradeUnit,
    this.initialCategory,
  });

  final String? seatId;
  final String? actualId;
  final String? initialName;
  final Department? initialDepartment;
  final String? initialPaygradeUnit;
  final SeatProfileCategory? initialCategory;

  bool get isEditMode => (seatId?.trim().isNotEmpty ?? false);
}

class SeatProfileDescriptionsRouteArgs {
  const SeatProfileDescriptionsRouteArgs({required this.category});

  final SeatProfileCategory category;
}

class SeatProfileTrainingSetupRouteArgs {
  const SeatProfileTrainingSetupRouteArgs({
    this.initialSeatProfileId,
    this.initialCategoryId,
    this.initialDescriptionId,
  });

  final String? initialSeatProfileId;
  final String? initialCategoryId;
  final String? initialDescriptionId;
}

class PaygradeDetailRouteArgs {
  const PaygradeDetailRouteArgs({required this.paygradeId});

  final String paygradeId;
}

class CheckInDescriptionsListRouteArgs {
  const CheckInDescriptionsListRouteArgs({
    required this.quarterlyAuditId,
    required this.date,
    required this.lastAuditDate,
    this.year,
    this.quarter,
    this.requireDescriptionSelection = false,
  });

  final String quarterlyAuditId;
  final String date;
  final String lastAuditDate;
  final int? year;
  final int? quarter;
  final bool requireDescriptionSelection;
}

class CheckInReportRouteArgs {
  const CheckInReportRouteArgs({
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

class LoginSetPasswordRouteArgs {
  const LoginSetPasswordRouteArgs({this.email, this.token});

  final String? email;
  final String? token;
}
