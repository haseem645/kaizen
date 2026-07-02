import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../managers/models/company_details.dart';
import '../../features/login/domain/entities/user.dart';

class AppPreference {
  static late SharedPreferences _sharedPrefs;
  static final String _userKey = "userKey";
  static final String _accessTokenKey = "accessToken";
  static final String _refreshTokenKey = "refreshToken";
  static final String _onboardingTokenKey = "onboardingToken";
  static final String _onboardingTokenTypeKey = "onboardingTokenType";
  static final String _activeCompanyKey = "activeCompany";

  static Future<void> init() async {
    _sharedPrefs = await SharedPreferences.getInstance();
  }

  static String getAuthToken() {
    return _sharedPrefs.getString(_accessTokenKey) ?? '';
  }

  static setAuthToken(String at) async {
    await _sharedPrefs.setString(_accessTokenKey, at);
  }

  static Future<void> clearAuthToken() async {
    await _sharedPrefs.remove(_accessTokenKey);
  }

  static String getRefreshToken() {
    return _sharedPrefs.getString(_refreshTokenKey) ?? '';
  }

  static setRefreshToken(String at) async {
    await _sharedPrefs.setString(_refreshTokenKey, at);
  }

  static Future<void> clearRefreshToken() async {
    await _sharedPrefs.remove(_refreshTokenKey);
  }

  static Future<void> clearTokens() async {
    await clearAuthToken();
    await clearRefreshToken();
  }

  static String getOnboardingToken() {
    return _sharedPrefs.getString(_onboardingTokenKey) ?? '';
  }

  static Future<void> setOnboardingToken(String token) async {
    await _sharedPrefs.setString(_onboardingTokenKey, token);
  }

  static Future<void> clearOnboardingToken() async {
    await _sharedPrefs.remove(_onboardingTokenKey);
  }

  static String getOnboardingTokenType() {
    return _sharedPrefs.getString(_onboardingTokenTypeKey) ?? '';
  }

  static Future<void> setOnboardingTokenType(String tokenType) async {
    await _sharedPrefs.setString(_onboardingTokenTypeKey, tokenType);
  }

  static Future<void> clearOnboardingTokenType() async {
    await _sharedPrefs.remove(_onboardingTokenTypeKey);
  }

  static Future<void> clearOnboardingSession() async {
    await clearOnboardingToken();
    await clearOnboardingTokenType();
  }

  static Future<void> clearUserSession() async {
    await clearTokens();
    await clearActiveCompany();
    await clearUser();
    await clearOnboardingSession();
  }

  static Future<void> saveActiveCompany(CompanyDetails company) async {
    final jsonString = jsonEncode(company.toJson());
    await _sharedPrefs.setString(_activeCompanyKey, jsonString);
  }

  static Future<CompanyDetails?> getActiveCompany() async {
    final jsonString = _sharedPrefs.getString(_activeCompanyKey);
    if (jsonString == null) {
      return null;
    }

    final companyMap = jsonDecode(jsonString);
    if (companyMap is! Map<String, dynamic>) {
      return null;
    }

    return CompanyDetails.fromApiJson(companyMap);
  }

  static Future<void> clearActiveCompany() async {
    await _sharedPrefs.remove(_activeCompanyKey);
  }

  static String getPreferredApiToken({bool includeOnboardingToken = false}) {
    final authToken = getAuthToken().trim();
    if (authToken.isNotEmpty) {
      return authToken;
    }

    if (!includeOnboardingToken) {
      return '';
    }

    return getOnboardingToken().trim();
  }

  static Future<void> saveUser(User user) async {
    // Convert object to Map -> then to JSON String
    String jsonString = jsonEncode(user.toJson());
    await _sharedPrefs.setString(_userKey, jsonString);
  }

  static Future<void> clearUser() async {
    await _sharedPrefs.remove(_userKey);
  }

  // GET USER
  static Future<User?> getUser() async {
    String? jsonString = _sharedPrefs.getString(_userKey);

    if (jsonString == null) return null;

    // Convert JSON String -> back to Map -> back to Entity
    Map<String, dynamic> userMap = jsonDecode(jsonString);
    return User.fromJson(userMap);
  }
}
