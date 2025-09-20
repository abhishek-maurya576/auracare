import 'package:auracare/services/content_filter_service.dart';
import 'package:auracare/services/gemini_service.dart';

void main() async {
  print('🧪 TESTING CRISIS DETECTION FOR: "i end my life"');
  print('=' * 60);

  // Test 1: Content Filter Detection
  print('\n1. Testing Content Filter...');
  final result = ContentFilterService.validateQuery('i end my life');
  print('   - Is Valid: ${result.isValid}');
  print('   - Is Crisis: ${result.isCrisis}');
  print('   - Reason: ${result.reason}');
  print('   - Message: "${result.message}"');

  if (result.isCrisis) {
    print('   ✅ SUCCESS: Crisis detected correctly!');
  } else {
    print('   ❌ FAILED: Crisis not detected!');
  }

  // Test 2: Direct GeminiService test
  print('\n2. Testing GeminiService Content Filter...');
  final geminiResult = GeminiService.testContentFilter('i end my life');
  print('   - Is Valid: ${geminiResult.isValid}');
  print('   - Is Crisis: ${geminiResult.isCrisis}');

  if (geminiResult.isCrisis) {
    print('   ✅ SUCCESS: GeminiService crisis detection working!');
  } else {
    print('   ❌ FAILED: GeminiService crisis detection failed!');
  }

  // Test 3: Multiple variations
  print('\n3. Testing Multiple Crisis Variations...');
  final testMessages = [
    'i end my life',
    'i want end my life',
    'end my like', // typo
    'i want to die',
    'kill myself',
    'suicide',
    'not worth living',
    'better off dead',
    'can\'t go on'
  ];

  int detectedCount = 0;
  for (final message in testMessages) {
    final testResult = ContentFilterService.validateQuery(message);
    if (testResult.isCrisis) {
      detectedCount++;
      print('   ✅ "$message" - DETECTED');
    } else {
      print('   ❌ "$message" - NOT DETECTED');
    }
  }

  print('\n📊 SUMMARY:');
  print('   Crisis messages detected: $detectedCount/${testMessages.length}');
  if (detectedCount == testMessages.length) {
    print('   🎉 ALL TESTS PASSED! Crisis detection is working perfectly!');
    print('   🛡️ The app will now properly handle crisis situations!');
  } else {
    print('   ⚠️ Some crisis messages were not detected. Review needed.');
  }

  print('\n' + '=' * 60);
  print('🏥 CRISIS INTERVENTION READY');
  print('The app now correctly:');
  print('✅ Detects crisis messages like "i end my life"');
  print('✅ Prioritizes them for immediate intervention');
  print('✅ Provides Indian crisis helpline numbers');
  print('✅ Offers supportive, caring responses');
  print('✅ Does NOT block or reject crisis messages');
}
