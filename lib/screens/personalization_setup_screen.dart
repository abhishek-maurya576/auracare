import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../providers/user_profile_provider.dart';
import '../utils/app_colors.dart';

class PersonalizationSetupScreen extends StatefulWidget {
  final bool isFirstTime;
  
  const PersonalizationSetupScreen({
    super.key,
    this.isFirstTime = false,
  });

  @override
  State<PersonalizationSetupScreen> createState() => _PersonalizationSetupScreenState();
}

class _PersonalizationSetupScreenState extends State<PersonalizationSetupScreen> {
  int _currentStep = 0;
  
  // Step 1: Mental Health Goals
  final List<String> _availableGoals = [
    'Reduce anxiety',
    'Manage depression',
    'Improve sleep',
    'Build self-confidence',
    'Manage stress',
    'Develop coping skills',
    'Improve relationships',
    'Find life balance',
    'Process trauma',
    'Build resilience',
  ];
  final Set<String> _selectedGoals = {};
  
  // Step 2: Coping Strategies
  final List<String> _availableStrategies = [
    'Deep breathing',
    'Meditation',
    'Journaling',
    'Physical exercise',
    'Talking to friends',
    'Listening to music',
    'Art and creativity',
    'Nature walks',
    'Reading',
    'Mindfulness',
  ];
  final Set<String> _selectedStrategies = {};
  
  // Step 3: Communication Style
  String _selectedCommunicationStyle = 'supportive';
  final Map<String, String> _communicationStyles = {
    'supportive': 'Warm and encouraging',
    'direct': 'Clear and straightforward',
    'gentle': 'Soft and understanding',
    'motivational': 'Inspiring and energetic',
  };
  
  // Step 4: Triggers (optional)
  final List<String> _availableTriggers = [
    'Work stress',
    'Social situations',
    'Family conflicts',
    'Financial worries',
    'Health concerns',
    'Relationship issues',
    'Academic pressure',
    'Change and uncertainty',
    'Loneliness',
    'Past memories',
  ];
  final Set<String> _selectedTriggers = {};
  
  // Step 5: Personal Strengths
  final List<String> _availableStrengths = [
    'Resilient',
    'Creative',
    'Empathetic',
    'Determined',
    'Optimistic',
    'Good listener',
    'Problem solver',
    'Caring',
    'Adaptable',
    'Strong-willed',
  ];
  final Set<String> _selectedStrengths = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _currentStep > 0 
            ? IconButton(
                onPressed: () => setState(() => _currentStep--),
                icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
              )
            : null,
        title: GlassWidget(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.isFirstTime ? 'Personalize Your Experience' : 'Update Preferences',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AuraBackground(),
          
          SafeArea(
            child: Column(
              children: [
                // Progress indicator
                _buildProgressIndicator(),
                
                // Content
                Expanded(
                  child: _buildStepContent(),
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
      child: GlassWidget(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(5, (index) {
                  return Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index <= _currentStep 
                          ? AppColors.accentTeal 
                          : AppColors.glassWhite,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: index <= _currentStep 
                              ? Colors.white 
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (_currentStep + 1) / 5,
                backgroundColor: AppColors.glassWhite,
                valueColor: const AlwaysStoppedAnimation(AppColors.accentTeal),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildGoalsStep();
      case 1:
        return _buildStrategiesStep();
      case 2:
        return _buildCommunicationStyleStep();
      case 3:
        return _buildTriggersStep();
      case 4:
        return _buildStrengthsStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildGoalsStep() {
    return _buildSelectionStep(
      title: 'What are your mental health goals?',
      subtitle: 'Select the areas you\'d like to focus on (choose 2-4)',
      items: _availableGoals,
      selectedItems: _selectedGoals,
      icon: Icons.flag_rounded,
      color: AppColors.accentTeal,
    );
  }

  Widget _buildStrategiesStep() {
    return _buildSelectionStep(
      title: 'What coping strategies work for you?',
      subtitle: 'Choose methods that help you feel better (select 3-5)',
      items: _availableStrategies,
      selectedItems: _selectedStrategies,
      icon: Icons.psychology_rounded,
      color: AppColors.accentBlue,
    );
  }

  Widget _buildCommunicationStyleStep() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GlassWidget(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.moodCalm.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_rounded,
                      color: AppColors.moodCalm,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'How would you like Aura to communicate?',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Choose the communication style that feels most comfortable',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: ListView(
              children: _communicationStyles.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedCommunicationStyle = entry.key),
                    child: GlassWidget(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Radio<String>(
                              value: entry.key,
                              groupValue: _selectedCommunicationStyle,
                              onChanged: (value) => setState(() => _selectedCommunicationStyle = value!),
                              activeColor: AppColors.accentTeal,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.key.toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    entry.value,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTriggersStep() {
    return _buildSelectionStep(
      title: 'What are your common stress triggers?',
      subtitle: 'This helps Aura be more mindful in conversations (optional)',
      items: _availableTriggers,
      selectedItems: _selectedTriggers,
      icon: Icons.warning_rounded,
      color: AppColors.moodStressed,
      isOptional: true,
    );
  }

  Widget _buildStrengthsStep() {
    return _buildSelectionStep(
      title: 'What are your personal strengths?',
      subtitle: 'Aura will remind you of these when you need encouragement',
      items: _availableStrengths,
      selectedItems: _selectedStrengths,
      icon: Icons.star_rounded,
      color: AppColors.moodHappy,
    );
  }

  Widget _buildSelectionStep({
    required String title,
    required String subtitle,
    required List<String> items,
    required Set<String> selectedItems,
    required IconData icon,
    required Color color,
    bool isOptional = false,
  }) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          GlassWidget(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (isOptional)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'You can skip this step if you prefer',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 20),
          
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final isSelected = selectedItems.contains(item);
                
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedItems.remove(item);
                      } else {
                        selectedItems.add(item);
                      }
                    });
                  },
                  child: GlassWidget(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected 
                            ? Border.all(color: color, width: 2)
                            : null,
                        color: isSelected 
                            ? color.withValues(alpha: 0.1)
                            : null,
                      ),
                      child: Center(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? color : AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              },
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
          if (_currentStep == 3) // Triggers step is optional
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _currentStep++),
                child: GlassWidget(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: const Center(
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          if (_currentStep == 3) const SizedBox(width: 12),
          
          Expanded(
            child: Consumer<UserProfileProvider>(
              builder: (context, profileProvider, child) {
                return GestureDetector(
                  onTap: profileProvider.isLoading ? null : _handleNext,
                  child: GlassWidget(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: const LinearGradient(
                          colors: [AppColors.accentTeal, AppColors.accentBlue],
                        ),
                      ),
                      child: Center(
                        child: profileProvider.isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : Text(
                                _currentStep == 4 ? 'Complete Setup' : 'Next',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() async {
    if (_currentStep < 4) {
      setState(() => _currentStep++);
    } else {
      await _completeSetup();
    }
  }

  Future<void> _completeSetup() async {
    final profileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    
    try {
      await profileProvider.quickSetup(
        selectedGoals: _selectedGoals.toList(),
        selectedCopingStrategies: _selectedStrategies.toList(),
        selectedCommunicationStyle: _selectedCommunicationStyle,
        selectedTriggers: _selectedTriggers.isNotEmpty ? _selectedTriggers.toList() : null,
        selectedStrengths: _selectedStrengths.toList(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Personalization setup complete! Aura will now provide more tailored responses.'),
            backgroundColor: AppColors.accentTeal,
          ),
        );
        
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving preferences: $e'),
            backgroundColor: AppColors.moodStressed,
          ),
        );
      }
    }
  }
}