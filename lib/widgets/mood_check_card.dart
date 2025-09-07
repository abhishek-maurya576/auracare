import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'glass_widgets.dart';
import '../utils/app_colors.dart';
import '../services/gemini_service.dart';
import '../providers/mood_provider.dart';

class MoodCheckCard extends StatefulWidget {
  const MoodCheckCard({super.key});

  @override
  State<MoodCheckCard> createState() => _MoodCheckCardState();
}

class _MoodCheckCardState extends State<MoodCheckCard> {
  String? selectedMood;
  final TextEditingController _noteController = TextEditingController();
  final GeminiService _geminiService = GeminiService();
  Map<String, dynamic>? _aiAnalysis;
  bool _showNoteField = false;
  
  int _intensity = 5; // 1-10 scale
  final List<String> _selectedTriggers = [];
  final List<String> _selectedTags = [];
  bool _showAdvancedOptions = false;
  
  final List<MoodOption> moods = [
    MoodOption(emoji: '😄', label: 'Happy', color: AppColors.moodHappy),
    MoodOption(emoji: '🙂', label: 'Calm', color: AppColors.moodCalm),
    MoodOption(emoji: '😐', label: 'Neutral', color: AppColors.moodNeutral),
    MoodOption(emoji: '😔', label: 'Sad', color: AppColors.moodSad),
    MoodOption(emoji: '😣', label: 'Stressed', color: AppColors.moodStressed),
  ];
  
  final List<String> commonTriggers = [
    'Work stress',
    'Relationship issues',
    'Health concerns',
    'Financial worries',
    'Lack of sleep',
    'Weather',
    'Social media',
    'Family problems',
    'Academic pressure',
    'Uncertainty',
  ];
  
  final List<String> moodTags = [
    'Morning',
    'Afternoon',
    'Evening',
    'Night',
    'Before work',
    'After work',
    'Weekend',
    'Exercise',
    'Meditation',
    'Social',
    'Alone time',
    'Creative',
    'Productive',
    'Relaxed',
    'Energetic',
    'Tired',
  ];

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MoodProvider>(
      builder: (context, moodProvider, child) {
        return GlassWidget(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How are you feeling today?',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Select your current mood to get personalized support',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Mood options
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: moods.map((mood) => _buildMoodOption(mood)).toList(),
                ),
                
                // Intensity slider
                if (selectedMood != null) ...[
                  const SizedBox(height: 20),
                  
                  const Text(
                    'How intense is this feeling?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Row(
                    children: [
                      const Text('1', style: TextStyle(color: AppColors.textMuted)),
                      Expanded(
                        child: SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: AppColors.accentTeal,
                            inactiveTrackColor: AppColors.glassBorder,
                            thumbColor: AppColors.accentTeal,
                            overlayColor: AppColors.accentTeal.withAlpha((255 * 0.2).toInt()),
                          ),
                          child: Slider(
                            value: _intensity.toDouble(),
                            min: 1,
                            max: 10,
                            divisions: 9,
                            onChanged: (value) {
                              setState(() {
                                _intensity = value.round();
                              });
                            },
                          ),
                        ),
                      ),
                      const Text('10', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                  
                  Center(
                    child: Text(
                      'Intensity: $_intensity/10',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
                
                // Advanced options toggle
                if (selectedMood != null) ...[
                  const SizedBox(height: 16),
                  
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showAdvancedOptions = !_showAdvancedOptions;
                      });
                    },
                    icon: Icon(
                      _showAdvancedOptions ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.accentTeal,
                    ),
                    label: Text(
                      _showAdvancedOptions ? 'Less options' : 'More options',
                      style: const TextStyle(color: AppColors.accentTeal),
                    ),
                  ),
                ],
                
                // Advanced options
                if (_showAdvancedOptions && selectedMood != null) ...[
                  const SizedBox(height: 16),
                  
                  // Triggers selection
                  const Text(
                    'What triggered this feeling?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: commonTriggers.map((trigger) => 
                      _buildTriggerChip(trigger)
                    ).toList(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Tags selection
                  const Text(
                    'Add context tags:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: moodTags.map((tag) => 
                      _buildTagChip(tag)
                    ).toList(),
                  ),
                ],
                
                // Optional note field
                if (_showNoteField) ...[
                  const SizedBox(height: 16),
                  
                  TextField(
                    controller: _noteController,
                    style: const TextStyle(color: AppColors.textPrimary),
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Add a note about how you feel...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.glassWhite,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.glassBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.glassBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.accentTeal, width: 2),
                      ),
                    ),
                  ),
                ],
                
                const SizedBox(height: 24),
                
                // Action buttons - Responsive layout
                Column(
                  children: [
                    // Main action buttons row
                    Row(
                      children: [
                        Flexible(
                          flex: 1,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: selectedMood != null && !moodProvider.isLoading 
                                  ? () => _analyzeWithAI(moodProvider) 
                                  : null,
                              icon: const Icon(Icons.psychology_rounded, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Analyze with AI',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentTeal.withAlpha((255 * 0.85).toInt()),
                                disabledBackgroundColor: AppColors.textMuted.withAlpha((255 * 0.3).toInt()),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),

                        Flexible(
                          flex: 1,
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: selectedMood != null && !moodProvider.isLoading
                                  ? () => _saveMoodEntry(moodProvider)
                                  : null,
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: const FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'Save Mood',
                                  style: TextStyle(fontSize: 13),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accentBlue.withAlpha((255 * 0.85).toInt()),
                                disabledBackgroundColor: AppColors.textMuted.withAlpha((255 * 0.3).toInt()),
                                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ),
                        
                        const SizedBox(width: 8),
                        
                        // Toggle note field
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.glassWhite,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _showNoteField ? AppColors.accentTeal : AppColors.glassBorder,
                              width: 1,
                            ),
                          ),
                          child: IconButton(
                            onPressed: () {
                              setState(() {
                                _showNoteField = !_showNoteField;
                              });
                            },
                            icon: Icon(
                              _showNoteField ? Icons.note_rounded : Icons.note_add_rounded,
                              color: _showNoteField ? AppColors.accentTeal : AppColors.textSecondary,
                              size: 20,
                            ),
                            tooltip: _showNoteField ? 'Hide note' : 'Add note',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoodOption(MoodOption mood) {
    final isSelected = selectedMood == mood.label;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMood = mood.label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected 
              ? Colors.white.withValues(alpha: 51)
              : Colors.white.withValues(alpha: 26),
          border: isSelected 
              ? Border.all(color: Colors.white, width: 2)
              : null,
        ),
        child: Center(
          child: Text(
            mood.emoji,
            style: const TextStyle(fontSize: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildTriggerChip(String trigger) {
    final isSelected = _selectedTriggers.contains(trigger);
    
    return FilterChip(
      label: Text(
        trigger.replaceAll('_', ' ').capitalize(),
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTriggers.add(trigger);
          } else {
            _selectedTriggers.remove(trigger);
          }
        });
      },
      backgroundColor: AppColors.glassWhite,
      selectedColor: AppColors.accentTeal.withAlpha((255 * 0.8).toInt()),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.accentTeal : AppColors.glassBorder,
      ),
    );
  }

  Widget _buildTagChip(String tag) {
    final isSelected = _selectedTags.contains(tag);
    
    return FilterChip(
      label: Text(
        tag.capitalize(),
        style: TextStyle(
          color: isSelected ? Colors.white : AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            _selectedTags.add(tag);
          } else {
            _selectedTags.remove(tag);
          }
        });
      },
      backgroundColor: AppColors.glassWhite,
      selectedColor: AppColors.moodSad.withAlpha((255 * 0.8).toInt()),
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? AppColors.moodSad : AppColors.glassBorder,
      ),
    );
  }

  void _analyzeWithAI(MoodProvider moodProvider) async {
    if (selectedMood == null) return;
    
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const _AnalyzingDialog(),
    );
    
    try {
      // Get AI analysis from Gemini
      final selectedMoodOption = moods.firstWhere((m) => m.label == selectedMood);
      final note = _noteController.text.trim();
      
      debugPrint('Starting AI mood analysis...');      
      // Include note in analysis if provided
      String prompt = 'I am feeling ${selectedMood!.toLowerCase()} today';
      if (note.isNotEmpty) {
        prompt += '. $note';
      }
      
      final response = await _geminiService.analyzeMood(
        prompt,
        additionalContext: 'User selected mood: $selectedMood with emoji: ${selectedMoodOption.emoji}'
      );
      
      debugPrint('AI analysis completed: $response');      
      // Ensure response is properly formatted as Map<String, dynamic>
      Map<String, dynamic> parsedResponse;

      parsedResponse = response;
      
      _aiAnalysis = parsedResponse;
      
      // Save mood data using the provider with enhanced fields
      await moodProvider.saveMoodEntry(
        mood: selectedMood!,
        emoji: selectedMoodOption.emoji,
        note: note.isNotEmpty ? note : null,
        intensity: _intensity,
        triggers: _selectedTriggers,
        tags: _selectedTags,
        aiAnalysis: _aiAnalysis?['supportiveMessage']?.toString(),
        aiInsights: _aiAnalysis?['suggestedActions'] is Map 
            ? Map<String, dynamic>.from(_aiAnalysis?['suggestedActions'])
            : null,
        stressLevel: _intensity * 0.7, // Calculate stress level based on intensity
        location: 'User location', // TODO: Add actual location
        additionalData: {
          'color': '${(255 * selectedMoodOption.color.a).toInt().toRadixString(16).padLeft(2, '0')}'
                     '${(255 * selectedMoodOption.color.r).toInt().toRadixString(16).padLeft(2, '0')}'
                     '${(255 * selectedMoodOption.color.g).toInt().toRadixString(16).padLeft(2, '0')}'
                     '${(255 * selectedMoodOption.color.b).toInt().toRadixString(16).padLeft(2, '0')}',
          'analysisRequested': true,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'aiAnalysis': _aiAnalysis,
        },
      );
      
      if (mounted) {
        Navigator.of(context).pop();
        _showMoodResult();
        
        // Clear note field after saving
        _noteController.clear();
        setState(() {
          _showNoteField = false;
        });
      }
    } catch (e) {
      debugPrint('Error during mood analysis: $e');
      if (mounted) {
        Navigator.of(context).pop();
        _showErrorSnackBar('AI analysis failed: $e');
        
        // Still save basic mood data even if AI fails
        try {
          final selectedMoodOption = moods.firstWhere((m) => m.label == selectedMood);
          final note = _noteController.text.trim();
          
          await moodProvider.saveMoodEntry(
            mood: selectedMood!,
            emoji: selectedMoodOption.emoji,
            note: note.isNotEmpty ? note : null,
            intensity: _intensity,
            triggers: _selectedTriggers,
            tags: _selectedTags,
            stressLevel: _intensity * 0.7,
            location: 'User location',
            additionalData: {
              'color': '${(255 * selectedMoodOption.color.a).toInt().toRadixString(16).padLeft(2, '0')}'
                          '${(255 * selectedMoodOption.color.r).toInt().toRadixString(16).padLeft(2, '0')}'
                          '${(255 * selectedMoodOption.color.g).toInt().toRadixString(16).padLeft(2, '0')}'
                          '${(255 * selectedMoodOption.color.b).toInt().toRadixString(16).padLeft(2, '0')}',
              'analysisRequested': true,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
              'aiAnalysisError': e.toString(),
            },
          );
          
          // Clear note field after saving
          _noteController.clear();
          setState(() {
            _showNoteField = false;
          });
        } catch (saveError) {
          debugPrint('Failed to save basic mood data: $saveError');
        }
      }
    }
  }



  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _saveMoodEntry(MoodProvider moodProvider) async {
    if (selectedMood == null) return;

    try {
      final selectedMoodOption = moods.firstWhere((m) => m.label == selectedMood);
      final note = _noteController.text.trim();

      await moodProvider.saveMoodEntry(
        mood: selectedMood!,
        emoji: selectedMoodOption.emoji,
        note: note.isNotEmpty ? note : null,
        intensity: _intensity,
        triggers: _selectedTriggers,
        tags: _selectedTags,
        stressLevel: _intensity * 0.7,
        location: 'User location', // TODO: Add actual location
        additionalData: {
          'color': '${(255 * selectedMoodOption.color.a).toInt().toRadixString(16).padLeft(2, '0')}'
                     '${(255 * selectedMoodOption.color.r).toInt().toRadixString(16).padLeft(2, '0')}'
                     '${(255 * selectedMoodOption.color.g).toInt().toRadixString(16).padLeft(2, '0')}'
                     '${(255 * selectedMoodOption.color.b).toInt().toRadixString(16).padLeft(2, '0')}',
          'analysisRequested': false, // No AI analysis for this entry
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mood saved successfully!'),
            backgroundColor: AppColors.accentTeal,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        // Clear fields after saving
        _noteController.clear();
        setState(() {
          selectedMood = null;
          _intensity = 5;
          _selectedTriggers.clear();
          _selectedTags.clear();
          _showNoteField = false;
          _showAdvancedOptions = false;
        });
      }
    } catch (e) {
      debugPrint('Error saving mood entry: $e');
      if (mounted) {
        _showErrorSnackBar('Failed to save mood: $e');
      }
    }
  }

  void _showMoodResult() {
    showDialog(
      context: context,
      builder: (context) => _MoodResultDialog(
        mood: selectedMood!,
        selectedMoodOption: moods.firstWhere((m) => m.label == selectedMood),
        aiAnalysis: _aiAnalysis,
        note: _noteController.text.trim(),
      ),
    );
  }


}

class MoodOption {
  final String emoji;
  final String label;
  final Color color;

  MoodOption({required this.emoji, required this.label, required this.color});
}

class _AnalyzingDialog extends StatelessWidget {
  const _AnalyzingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassWidget(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(AppColors.accentTeal),
              ),
              const SizedBox(height: 16),
              const Text(
                'Analyzing your mood...',
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Our AI is understanding your emotional state',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return isEmpty ? this : this[0].toUpperCase() + substring(1);
  }
}

class _MoodResultDialog extends StatelessWidget {
  final String mood;
  final MoodOption selectedMoodOption;
  final Map<String, dynamic>? aiAnalysis;
  final String? note;

  const _MoodResultDialog({
    required this.mood,
    required this.selectedMoodOption,
    this.aiAnalysis,
    this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: GlassWidget(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selectedMoodOption.color.withAlpha((255 * 0.2).toInt()),
                ),
                child: Text(
                  selectedMoodOption.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
              ),
              
              const SizedBox(height: 16),
              
              Text(
                'You\'re feeling $mood',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              
              if (note != null && note!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.glassWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Text(
                    note!,
                    style: const TextStyle(
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
              
              const SizedBox(height: 16),
              
              // AI Analysis Message
              Text(
                aiAnalysis?['supportiveMessage'] ?? _getMoodMessage(mood),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              
              // Show AI suggested actions if available
              if (aiAnalysis?['suggestedActions'] != null && aiAnalysis!['suggestedActions'] is List) ...[
                const SizedBox(height: 16),
                const Text(
                  'AI Suggestions:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                ...(List.from(aiAnalysis!['suggestedActions'] ?? []).take(3).map((action) => 
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        const Icon(Icons.lightbulb_outline, size: 16, color: AppColors.accentTeal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            action.toString(),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                )),
              ],
              
              const SizedBox(height: 20),
              
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Close'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        // TODO: Navigate to suggested action
                      },
                      child: Text(_getActionText(mood)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getMoodMessage(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return 'That\'s wonderful! Let\'s keep this positive energy flowing.';
      case 'calm':
        return 'Perfect state of mind. You\'re in a great place right now.';
      case 'neutral':
        return 'A balanced state. Would you like to explore some uplifting activities?';
      case 'sad':
        return 'It\'s okay to feel sad sometimes. Let\'s work through this together.';
      case 'stressed':
        return 'I understand you\'re feeling overwhelmed. Let\'s find some relief.';
      default:
        return 'Thank you for sharing your feelings with me.';
    }
  }

  String _getActionText(String mood) {
    switch (mood.toLowerCase()) {
      case 'happy':
        return 'Share Joy';
      case 'calm':
        return 'Meditate';
      case 'neutral':
        return 'Explore';
      case 'sad':
        return 'Feel Better';
      case 'stressed':
        return 'Relax Now';
      default:
        return 'Continue';
    }
  }
}
