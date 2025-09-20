import 'package:flutter_test/flutter_test.dart';
import 'package:auracare/services/content_filter_service.dart';

void main() {
  group('Content Filter - Less Restrictive Tests', () {
    test('Should allow social withdrawal expressions', () {
      final testCases = [
        'i dont want to talk any one',
        'i want to be alone',
        'dont want to talk',
        'feeling ignored',
        'nobody understands me',
        'avoid people',
      ];
      
      for (final testCase in testCases) {
        final result = ContentFilterService.validateQuery(testCase);
        print('✅ "$testCase" -> Valid: ${result.isValid}, Crisis: ${result.isCrisis}');
        expect(result.isValid, true, 
          reason: 'Social withdrawal expression "$testCase" should be allowed');
      }
    });
    
    test('Should still detect crisis messages', () {
      final crisisCases = [
        'i end my life',
        'want to die',
        'kill myself',
        'suicide',
        'not worth living',
      ];
      
      for (final testCase in crisisCases) {
        final result = ContentFilterService.validateQuery(testCase);
        print('🆘 "$testCase" -> Valid: ${result.isValid}, Crisis: ${result.isCrisis}');
        expect(result.isValid, true, reason: 'Crisis message should be valid for intervention');
        expect(result.isCrisis, true, reason: 'Crisis message should be detected');
      }
    });
    
    test('Should still block clearly irrelevant topics', () {
      final irrelevantCases = [
        'weather forecast today',
        'cryptocurrency prices',
        'recipe for pasta',
        'sports scores',
      ];
      
      for (final testCase in irrelevantCases) {
        final result = ContentFilterService.validateQuery(testCase);
        print('❌ "$testCase" -> Valid: ${result.isValid}');
        expect(result.isValid, false, 
          reason: 'Irrelevant topic "$testCase" should still be blocked');
      }
    });
    
    test('Should allow short emotional responses', () {
      final shortCases = [
        'no',
        'yes',
        'okay',
        'fine',
        'sad',
        'tired',
        'angry',
      ];
      
      for (final testCase in shortCases) {
        final result = ContentFilterService.validateQuery(testCase);
        print('🔄 "$testCase" -> Valid: ${result.isValid}');
        expect(result.isValid, true, 
          reason: 'Short emotional response "$testCase" should be allowed');
      }
    });
  });
}