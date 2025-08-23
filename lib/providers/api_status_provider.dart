import 'package:flutter/foundation.dart';
import '../services/gemini_service.dart';

class ApiStatusProvider extends ChangeNotifier {
  bool _isApiConfigured = false;
  String _apiStatusMessage = 'Initializing API...';
  bool _isValidating = false;

  bool get isApiConfigured => _isApiConfigured;
  String get apiStatusMessage => _apiStatusMessage;
  bool get isValidating => _isValidating;

  // Validate API configuration
  Future<bool> validateApiConfiguration() async {
    try {
      _isValidating = true;
      notifyListeners();

      final geminiService = GeminiService();
      final isValid = await geminiService.validateApiConfiguration();

      _isApiConfigured = isValid;
      _apiStatusMessage = isValid 
          ? 'API configured successfully' 
          : 'API configuration error - check API key and model name';
      
      _isValidating = false;
      notifyListeners();
      
      return isValid;
    } catch (e) {
      _isApiConfigured = false;
      _apiStatusMessage = 'API validation error: $e';
      _isValidating = false;
      notifyListeners();
      
      return false;
    }
  }

  // Update API status manually
  void updateApiStatus({required bool isConfigured, required String message}) {
    _isApiConfigured = isConfigured;
    _apiStatusMessage = message;
    notifyListeners();
  }
}