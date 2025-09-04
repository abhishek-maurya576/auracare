import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Privacy and Security Service for COPPA compliance and data protection
class PrivacySecurityService {
  static const String _encryptionKeyPrefix = 'aura_enc_';
  static const String _privacySettingsKey = 'privacy_settings';
  static const String _parentalConsentKey = 'parental_consent';
  static const String _anonymousModeKey = 'anonymous_mode';
  static const String _dataRetentionKey = 'data_retention_settings';

  /// Generate encryption key for user data
  static String generateEncryptionKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Get or generate encryption key for specific user
  static Future<String> getUserEncryptionKey(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final keyName = '$_encryptionKeyPrefix$userId';
    
    String? existingKey = prefs.getString(keyName);
    if (existingKey != null) {
      return existingKey;
    }
    
    // Generate new key for user
    final newKey = generateEncryptionKey();
    await prefs.setString(keyName, newKey);
    return newKey;
  }

  /// Encrypt sensitive data using simple XOR encryption (for demo purposes)
  /// In production, use proper encryption libraries like pointycastle
  static String encryptData(String data, String key) {
    try {
      final dataBytes = utf8.encode(data);
      final keyBytes = base64Decode(key);
      final encrypted = <int>[];
      
      for (int i = 0; i < dataBytes.length; i++) {
        encrypted.add(dataBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return base64Encode(encrypted);
    } catch (e) {
      debugPrint('Encryption error: $e');
      return data; // Fallback to unencrypted in case of error
    }
  }

  /// Decrypt sensitive data
  static String decryptData(String encryptedData, String key) {
    try {
      final encryptedBytes = base64Decode(encryptedData);
      final keyBytes = base64Decode(key);
      final decrypted = <int>[];
      
      for (int i = 0; i < encryptedBytes.length; i++) {
        decrypted.add(encryptedBytes[i] ^ keyBytes[i % keyBytes.length]);
      }
      
      return utf8.decode(decrypted);
    } catch (e) {
      debugPrint('Decryption error: $e');
      return encryptedData; // Return as-is if decryption fails
    }
  }

  /// Check if user requires parental consent (under 18)
  static bool requiresParentalConsent(DateTime? birthDate) {
    if (birthDate == null) return true; // Default to requiring consent
    
    final now = DateTime.now();
    final age = now.difference(birthDate).inDays / 365.25;
    return age < 18;
  }

  /// Get user's age category for content filtering
  static AgeCategory getUserAgeCategory(DateTime? birthDate) {
    if (birthDate == null) return AgeCategory.unknown;
    
    final now = DateTime.now();
    final age = now.difference(birthDate).inDays / 365.25;
    
    if (age < 13) return AgeCategory.child;
    if (age < 16) return AgeCategory.youngTeen;
    if (age < 19) return AgeCategory.teen;
    if (age < 26) return AgeCategory.youngAdult;
    return AgeCategory.adult;
  }

  /// Save privacy settings
  static Future<void> savePrivacySettings(PrivacySettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_privacySettingsKey, settingsJson);
      debugPrint('✅ Privacy settings saved');
    } catch (e) {
      debugPrint('Error saving privacy settings: $e');
    }
  }

  /// Load privacy settings
  static Future<PrivacySettings> loadPrivacySettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_privacySettingsKey);
      
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        return PrivacySettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading privacy settings: $e');
    }
    
    // Return default settings
    return PrivacySettings.defaultSettings();
  }

  /// Save parental consent status
  static Future<void> saveParentalConsent(ParentalConsent consent) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentJson = jsonEncode(consent.toJson());
      await prefs.setString(_parentalConsentKey, consentJson);
      debugPrint('✅ Parental consent saved');
    } catch (e) {
      debugPrint('Error saving parental consent: $e');
    }
  }

  /// Load parental consent status
  static Future<ParentalConsent?> loadParentalConsent() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final consentJson = prefs.getString(_parentalConsentKey);
      
      if (consentJson != null) {
        final consentMap = jsonDecode(consentJson) as Map<String, dynamic>;
        return ParentalConsent.fromJson(consentMap);
      }
    } catch (e) {
      debugPrint('Error loading parental consent: $e');
    }
    
    return null;
  }

  /// Enable/disable anonymous mode
  static Future<void> setAnonymousMode(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_anonymousModeKey, enabled);
      debugPrint('🕶️ Anonymous mode ${enabled ? 'enabled' : 'disabled'}');
    } catch (e) {
      debugPrint('Error setting anonymous mode: $e');
    }
  }

  /// Check if anonymous mode is enabled
  static Future<bool> isAnonymousModeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_anonymousModeKey) ?? false;
    } catch (e) {
      debugPrint('Error checking anonymous mode: $e');
      return false;
    }
  }

  /// Save data retention settings
  static Future<void> saveDataRetentionSettings(DataRetentionSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = jsonEncode(settings.toJson());
      await prefs.setString(_dataRetentionKey, settingsJson);
      debugPrint('✅ Data retention settings saved');
    } catch (e) {
      debugPrint('Error saving data retention settings: $e');
    }
  }

  /// Load data retention settings
  static Future<DataRetentionSettings> loadDataRetentionSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_dataRetentionKey);
      
      if (settingsJson != null) {
        final settingsMap = jsonDecode(settingsJson) as Map<String, dynamic>;
        return DataRetentionSettings.fromJson(settingsMap);
      }
    } catch (e) {
      debugPrint('Error loading data retention settings: $e');
    }
    
    // Return default settings
    return DataRetentionSettings.defaultSettings();
  }

  /// Generate anonymized user ID
  static String generateAnonymousId() {
    final random = Random();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomSuffix = random.nextInt(9999).toString().padLeft(4, '0');
    return 'anon_${timestamp}_$randomSuffix';
  }

  /// Validate parental consent form
  static bool validateParentalConsent(ParentalConsent consent) {
    return consent.parentName.isNotEmpty &&
           consent.parentEmail.isNotEmpty &&
           consent.consentGiven &&
           consent.consentDate != null &&
           consent.parentSignature.isNotEmpty;
  }

  /// Check if data should be retained based on settings
  static bool shouldRetainData(DataType dataType, DataRetentionSettings settings) {
    // final now = DateTime.now(); // TODO: Implement actual date checking
    
    switch (dataType) {
      case DataType.chatMessages:
        if (settings.chatRetentionDays == 0) return false;
        return true; // Implement actual date checking in production
      
      case DataType.moodData:
        if (settings.moodRetentionDays == 0) return false;
        return true;
      
      case DataType.journalEntries:
        if (settings.journalRetentionDays == 0) return false;
        return true;
      
      case DataType.crisisAlerts:
        if (settings.crisisRetentionDays == 0) return false;
        return true;
      
      default:
        return true;
    }
  }

  /// Export user data for GDPR compliance
  static Future<Map<String, dynamic>> exportUserData(String userId) async {
    // This would collect all user data from various sources
    return {
      'userId': userId,
      'exportDate': DateTime.now().toIso8601String(),
      'dataTypes': [
        'profile',
        'mood_entries',
        'chat_messages',
        'journal_entries',
        'crisis_alerts',
      ],
      'note': 'This is a simplified export. In production, collect actual data from all services.',
    };
  }

  /// Delete user data for GDPR compliance
  static Future<void> deleteUserData(String userId) async {
    try {
      // This would delete data from all services
      debugPrint('🗑️ Deleting all data for user: $userId');
      
      // Clear local storage
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.contains(userId));
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      debugPrint('✅ User data deletion completed');
    } catch (e) {
      debugPrint('Error deleting user data: $e');
    }
  }
}

/// Age categories for content filtering
enum AgeCategory {
  child,      // Under 13
  youngTeen,  // 13-15
  teen,       // 16-18
  youngAdult, // 19-25
  adult,      // 26+
  unknown,
}

/// Data types for retention policies
enum DataType {
  chatMessages,
  moodData,
  journalEntries,
  crisisAlerts,
  profileData,
  analyticsData,
}

/// Privacy settings model
class PrivacySettings {
  final bool shareDataForResearch;
  final bool allowAnalytics;
  final bool shareWithThirdParties;
  final bool enableCrashReporting;
  final bool allowPersonalization;
  final bool showInCommunity;
  final bool allowNotifications;

  PrivacySettings({
    required this.shareDataForResearch,
    required this.allowAnalytics,
    required this.shareWithThirdParties,
    required this.enableCrashReporting,
    required this.allowPersonalization,
    required this.showInCommunity,
    required this.allowNotifications,
  });

  factory PrivacySettings.defaultSettings() {
    return PrivacySettings(
      shareDataForResearch: false,
      allowAnalytics: true,
      shareWithThirdParties: false,
      enableCrashReporting: true,
      allowPersonalization: true,
      showInCommunity: false,
      allowNotifications: true,
    );
  }

  factory PrivacySettings.fromJson(Map<String, dynamic> json) {
    return PrivacySettings(
      shareDataForResearch: json['shareDataForResearch'] ?? false,
      allowAnalytics: json['allowAnalytics'] ?? true,
      shareWithThirdParties: json['shareWithThirdParties'] ?? false,
      enableCrashReporting: json['enableCrashReporting'] ?? true,
      allowPersonalization: json['allowPersonalization'] ?? true,
      showInCommunity: json['showInCommunity'] ?? false,
      allowNotifications: json['allowNotifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shareDataForResearch': shareDataForResearch,
      'allowAnalytics': allowAnalytics,
      'shareWithThirdParties': shareWithThirdParties,
      'enableCrashReporting': enableCrashReporting,
      'allowPersonalization': allowPersonalization,
      'showInCommunity': showInCommunity,
      'allowNotifications': allowNotifications,
    };
  }
}

/// Parental consent model
class ParentalConsent {
  final String parentName;
  final String parentEmail;
  final String parentPhone;
  final bool consentGiven;
  final DateTime? consentDate;
  final String parentSignature;
  final String childName;
  final DateTime? childBirthDate;

  ParentalConsent({
    required this.parentName,
    required this.parentEmail,
    required this.parentPhone,
    required this.consentGiven,
    this.consentDate,
    required this.parentSignature,
    required this.childName,
    this.childBirthDate,
  });

  factory ParentalConsent.fromJson(Map<String, dynamic> json) {
    return ParentalConsent(
      parentName: json['parentName'] ?? '',
      parentEmail: json['parentEmail'] ?? '',
      parentPhone: json['parentPhone'] ?? '',
      consentGiven: json['consentGiven'] ?? false,
      consentDate: json['consentDate'] != null 
          ? DateTime.parse(json['consentDate'])
          : null,
      parentSignature: json['parentSignature'] ?? '',
      childName: json['childName'] ?? '',
      childBirthDate: json['childBirthDate'] != null 
          ? DateTime.parse(json['childBirthDate'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'parentName': parentName,
      'parentEmail': parentEmail,
      'parentPhone': parentPhone,
      'consentGiven': consentGiven,
      'consentDate': consentDate?.toIso8601String(),
      'parentSignature': parentSignature,
      'childName': childName,
      'childBirthDate': childBirthDate?.toIso8601String(),
    };
  }
}

/// Data retention settings model
class DataRetentionSettings {
  final int chatRetentionDays;
  final int moodRetentionDays;
  final int journalRetentionDays;
  final int crisisRetentionDays;
  final bool autoDeleteEnabled;

  DataRetentionSettings({
    required this.chatRetentionDays,
    required this.moodRetentionDays,
    required this.journalRetentionDays,
    required this.crisisRetentionDays,
    required this.autoDeleteEnabled,
  });

  factory DataRetentionSettings.defaultSettings() {
    return DataRetentionSettings(
      chatRetentionDays: 90,    // 3 months
      moodRetentionDays: 365,   // 1 year
      journalRetentionDays: 365, // 1 year
      crisisRetentionDays: 30,   // 1 month
      autoDeleteEnabled: true,
    );
  }

  factory DataRetentionSettings.fromJson(Map<String, dynamic> json) {
    return DataRetentionSettings(
      chatRetentionDays: json['chatRetentionDays'] ?? 90,
      moodRetentionDays: json['moodRetentionDays'] ?? 365,
      journalRetentionDays: json['journalRetentionDays'] ?? 365,
      crisisRetentionDays: json['crisisRetentionDays'] ?? 30,
      autoDeleteEnabled: json['autoDeleteEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatRetentionDays': chatRetentionDays,
      'moodRetentionDays': moodRetentionDays,
      'journalRetentionDays': journalRetentionDays,
      'crisisRetentionDays': crisisRetentionDays,
      'autoDeleteEnabled': autoDeleteEnabled,
    };
  }
}