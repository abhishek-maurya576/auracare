import 'package:flutter_test/flutter_test.dart';
import 'package:auracare/services/content_filter_service.dart';

void main() {
  test('Test specific user case: "i dont want to talk any one"', () {
    final result = ContentFilterService.validateQuery('i dont want to talk any one');
    
    print('Query: "i dont want to talk any one"');
    print('Is Valid: ${result.isValid}');
    print('Is Crisis: ${result.isCrisis}');
    print('Reason: ${result.reason}');
    print('Message: "${result.message}"');
    
    // This should be allowed as it's a mental health related expression of social withdrawal
    expect(result.isValid, true, 
      reason: 'User expressing social withdrawal should be allowed for mental health support');
  });
}