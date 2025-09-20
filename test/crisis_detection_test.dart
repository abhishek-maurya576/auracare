import 'package:flutter_test/flutter_test.dart';
import 'package:auracare/services/content_filter_service.dart';
import 'package:auracare/services/gemini_service.dart';

void main() {
  group('Crisis Detection Tests', () {
    test('Should detect crisis in "i end my life" message', () {
      // Test the exact message from user
      final result = ContentFilterService.validateQuery('i end my life');

      expect(result.isValid, true,
          reason: 'Crisis messages should be valid for intervention');
      expect(result.isCrisis, true,
          reason: '"i end my life" should be detected as crisis');
      expect(result.reason, QueryRejectionReason.none);

      print('✅ Crisis detection test passed: "${result.isCrisis}"');
    });

    test('Should detect crisis in "i want end my life" message', () {
      final result = ContentFilterService.validateQuery('i want end my life');

      expect(result.isValid, true);
      expect(result.isCrisis, true);
      expect(result.reason, QueryRejectionReason.none);
    });

    test('Should detect crisis in "end my like" typo', () {
      // Test common typo "like" instead of "life"
      final result = ContentFilterService.validateQuery('end my like');

      expect(result.isValid, true);
      expect(result.isCrisis, true);
      expect(result.reason, QueryRejectionReason.none);
    });

    test('Should detect multiple crisis keywords', () {
      final crisisMessages = [
        'suicide',
        'kill myself',
        'want to die',
        'not worth living',
        'hurt myself',
        'self harm',
        'can\'t go on',
        'better off dead',
        'no point living',
        'life is pointless',
        'ending it',
        'taking my life',
      ];

      for (final message in crisisMessages) {
        final result = ContentFilterService.validateQuery(message);
        expect(result.isValid, true,
            reason: 'Crisis message "$message" should be valid');
        expect(result.isCrisis, true,
            reason: 'Crisis message "$message" should be detected');
      }
    });

    test('Should allow normal mental health messages', () {
      final normalMessages = [
        'i feel anxious',
        'i am stressed',
        'feeling sad today',
        'need help with anxiety',
        'how to manage stress',
      ];

      for (final message in normalMessages) {
        final result = ContentFilterService.validateQuery(message);
        expect(result.isValid, true,
            reason: 'Mental health message "$message" should be valid');
        expect(result.isCrisis, false,
            reason: 'Normal message "$message" should not be crisis');
      }
    });

    test('Should reject irrelevant messages', () {
      final irrelevantMessages = [
        'what is the weather today',
        'tell me about sports',
        'how to cook pasta',
        'cryptocurrency prices',
      ];

      for (final message in irrelevantMessages) {
        final result = ContentFilterService.validateQuery(message);
        expect(result.isValid, false,
            reason: 'Irrelevant message "$message" should be rejected');
        expect(result.isCrisis, false,
            reason: 'Irrelevant message "$message" should not be crisis');
      }
    });
  });

  group('Gemini Service Crisis Handling', () {
    test('Test content filter function directly', () {
      // Test the public testing method
      final result = GeminiService.testContentFilter('i end my life');

      expect(result.isValid, true);
      expect(result.isCrisis, true);

      print('✅ Direct content filter test passed');
    });

    test('Run bulk content filter tests', () {
      // This will run the built-in test suite
      expect(() => GeminiService.runContentFilterTests(), returnsNormally);

      print('✅ Bulk content filter tests completed');
    });
  });
}
