import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../providers/auth_provider.dart';
import '../utils/app_colors.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  // Quiz data
  final Map<String, dynamic> _quizData = {
    'mood_baseline': null,
    'stress_level': null,
    'preferred_activities': <String>[],
    'notification_preferences': <String>[],
    'goals': <String>[],
  };

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const AuraBackground(),
          
          SafeArea(
            child: Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(),
                
                // Page content
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      _buildWelcomePage(),
                      _buildMoodBaselinePage(),
                      _buildStressLevelPage(),
                      _buildActivitiesPage(),
                      _buildNotificationsPage(),
                      _buildGoalsPage(),
                      _buildCompletePage(),
                    ],
                  ),
                ),
                
                // Navigation buttons
                _buildNavigationButtons(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: List.generate(7, (index) {
          return Expanded(
            child: Container(
              height: 4,
              margin: EdgeInsets.only(right: index < 6 ? 8 : 0),
              decoration: BoxDecoration(
                color: index <= _currentPage 
                    ? AppColors.accentTeal 
                    : AppColors.glassBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildWelcomePage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.auraGradient1,
            ),
            child: const Icon(
              Icons.favorite_rounded,
              size: 60,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'Welcome to AuraCare!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Let\'s take a moment to understand your mental wellness needs. This quick assessment will help us personalize your experience.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 24),
          
          GlassWidget(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(
                    Icons.privacy_tip_rounded,
                    color: AppColors.accentTeal,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Your responses are private and secure',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBaselinePage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'How would you describe your overall mood lately?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          GlassWidget(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildMoodOption('Very Happy', '😄', AppColors.moodHappy),
                  _buildMoodOption('Good', '😊', AppColors.moodCalm),
                  _buildMoodOption('Neutral', '😐', AppColors.textSecondary),
                  _buildMoodOption('Low', '😔', AppColors.moodSad),
                  _buildMoodOption('Very Low', '😞', AppColors.moodStressed),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStressLevelPage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'What\'s your current stress level?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          GlassWidget(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildStressOption('Very Low', 1),
                  _buildStressOption('Low', 2),
                  _buildStressOption('Moderate', 3),
                  _buildStressOption('High', 4),
                  _buildStressOption('Very High', 5),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitiesPage() {
    final activities = [
      'Meditation & Mindfulness',
      'Breathing Exercises',
      'Journaling',
      'Physical Exercise',
      'Music & Sound Therapy',
      'Reading & Learning',
      'Creative Activities',
      'Social Connection',
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'Which activities help you feel better?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Select all that apply',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          
          const SizedBox(height: 24),
          
          Expanded(
            child: GlassWidget(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: activities.length,
                  itemBuilder: (context, index) {
                    final activity = activities[index];
                    final isSelected = _quizData['preferred_activities'].contains(activity);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _quizData['preferred_activities'].remove(activity);
                          } else {
                            _quizData['preferred_activities'].add(activity);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.accentTeal.withValues(alpha: 0.3)
                              : AppColors.glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? AppColors.accentTeal 
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Text(
                          activity,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsPage() {
    final options = [
      'Daily mood check-ins',
      'Breathing reminders',
      'Gratitude prompts',
      'Motivational quotes',
      'Hydration reminders',
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'What reminders would help you?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          Expanded(
            child: GlassWidget(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: options.map((option) {
                    final isSelected = _quizData['notification_preferences'].contains(option);
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _quizData['notification_preferences'].remove(option);
                            } else {
                              _quizData['notification_preferences'].add(option);
                            }
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? AppColors.accentTeal.withValues(alpha: 0.2)
                                : AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? AppColors.accentTeal 
                                  : AppColors.glassBorder,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected 
                                    ? Icons.check_circle_rounded 
                                    : Icons.circle_outlined,
                                color: isSelected 
                                    ? AppColors.accentTeal 
                                    : AppColors.textSecondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsPage() {
    final goals = [
      'Reduce stress and anxiety',
      'Improve mood stability',
      'Build healthy habits',
      'Better sleep quality',
      'Increase self-awareness',
      'Enhance emotional regulation',
      'Find inner peace',
      'Build resilience',
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const Text(
            'What are your wellness goals?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          Expanded(
            child: GlassWidget(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final isSelected = _quizData['goals'].contains(goal);
                    
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _quizData['goals'].remove(goal);
                          } else {
                            _quizData['goals'].add(goal);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected 
                              ? AppColors.accentTeal.withValues(alpha: 0.3)
                              : AppColors.glassWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected 
                                ? AppColors.accentTeal 
                                : AppColors.glassBorder,
                          ),
                        ),
                        child: Text(
                          goal,
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletePage() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.auraGradient1,
            ),
            child: const Icon(
              Icons.celebration_rounded,
              size: 60,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 32),
          
          const Text(
            'You\'re all set!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Thank you for sharing! We\'ve personalized AuraCare based on your preferences. Your journey to better mental wellness starts now.',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          GlassWidget(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const Text(
                    'Your personalized features are ready:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildFeatureItem('🎯', 'Tailored mood tracking'),
                  _buildFeatureItem('🧘', 'Personalized activities'),
                  _buildFeatureItem('💬', 'AI companion ready'),
                  _buildFeatureItem('📊', 'Progress insights'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodOption(String label, String emoji, Color color) {
    final isSelected = _quizData['mood_baseline'] == label;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _quizData['mood_baseline'] = label;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.2) : AppColors.glassWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.accentTeal,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStressOption(String label, int level) {
    final isSelected = _quizData['stress_level'] == level;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {
          setState(() {
            _quizData['stress_level'] = level;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accentTeal.withValues(alpha: 0.2) : AppColors.glassWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.accentTeal : AppColors.glassBorder,
            ),
          ),
          child: Row(
            children: [
              Row(
                children: List.generate(5, (index) {
                  return Container(
                    width: 12,
                    height: 12,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index < level 
                          ? AppColors.accentTeal 
                          : AppColors.glassBorder,
                    ),
                  );
                }),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.accentTeal,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          if (_currentPage > 0)
            Expanded(
              child: TextButton(
                onPressed: () {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: const Text('Back'),
              ),
            ),
          
          if (_currentPage > 0) const SizedBox(width: 16),
          
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _currentPage == 6 ? _completeOnboarding : _nextPage,
              child: Text(_currentPage == 6 ? 'Get Started' : 'Next'),
            ),
          ),
        ],
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < 6) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Save onboarding data to user preferences
    final authProvider = provider.Provider.of<AuthProvider>(context, listen: false);
    await authProvider.updateUserProfile(preferences: _quizData);

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }
}
