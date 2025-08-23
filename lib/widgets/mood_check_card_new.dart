import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'glass_widgets.dart';
import 'api_status_indicator.dart';
import '../utils/app_colors.dart';
import '../services/gemini_service.dart';
import '../providers/mood_provider.dart';
import '../providers/api_status_provider.dart';

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
  
  final List<MoodOption> moods = [
    MoodOption(emoji: '😄', label: 'Happy', color: AppColors.moodHappy),
    MoodOption(emoji: '🙂', label: 'Calm', color: AppColors.moodCalm),
    MoodOption(emoji: '😐', label: 'Neutral', color: AppColors.moodNeutral),
    MoodOption(emoji: '😔', label: 'Sad', color: AppColors.moodSad),
    MoodOption(emoji: '😣', label: 'Stressed', color: AppColors.moodStressed),
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
          backgroundColor: const Color(0xFF1A2235), // Dark blue/navy background
          borderRadius: BorderRadius.circular(20),
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
                    color: Colors.white, // White text for better contrast
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'Select your current mood to get personalized support',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70, // Light gray text for better contrast
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Mood options
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: moods.map((mood) => _buildMoodOption(mood)).toList(),
                ),
                
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
                
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: selectedMood != null && !moodProvider.isLoading 
                            ? () => _analyzeWithAI(moodProvider) 
                            : null,
                        icon: const Icon(Icons.psychology_rounded, size: 20),
                        label: const Text('Analyze with AI'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentTeal.withAlpha((255 * 0.85).toInt()),
                          disabledBackgroundColor: AppColors.textMuted.withAlpha((255 * 0.3).toInt()),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 12),
                    
                    // Toggle note field
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _showNoteField = !_showNoteField;
                        });
                      },
                      icon: Icon(
                        _showNoteField ? Icons.note_rounded : Icons.note_add_rounded,
                        color: _showNoteField ? AppColors.accentTeal : AppColors.textSecondary,
                      ),
                      tooltip: _showNoteField ? 'Hide note' : 'Add note',
                    ),
                    
                    const SizedBox(width: 8),
                    
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Navigate to journal
                      },
                      icon: const Icon(Icons.edit_note_rounded, size: 20),
                      label: const Text('Journal'),
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
              ? Colors.white.withOpacity(0.2)
              : Colors.white.withOpacity(0.1),
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

  void _analyzeWithAI(MoodProvider moodProvider) async {
    if (selectedMood == null) return;
    
    // Check API status before analyzing
    final apiStatus = Provider.of<ApiStatusProvider>(context, listen: false);
    if (!apiStatus.isApiConfigured) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('AI service is not available. Trying to reconnect...'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              apiStatus.validateApiConfiguration().then((isValid) {
                if (isValid) {
                  _analyzeWithAI(moodProvider);
                }
              });
            },
            textColor: Colors.white,
          ),
        ),
      );
      
      // Try to validate API configuration
      apiStatus.validateApiConfiguration();
      return;
    }
    
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
      
      _aiAnalysis = await _geminiService.analyzeMood(
        prompt,
        additionalContext: 'User selected mood: $selectedMood with emoji: ${selectedMoodOption.emoji}'
      );
      
      debugPrint('AI analysis completed: $_aiAnalysis');
      
      // Save mood data using the provider
      await moodProvider.saveMoodEntry(
        mood: selectedMood!,
        emoji: selectedMoodOption.emoji,
        note: note.isNotEmpty ? note : null,
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

  MoodOption({
    required this.emoji,
    required this.label,
    required this.color,
  });
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
              if (aiAnalysis?['suggestedActions'] != null) ...[
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
                ...((aiAnalysis!['suggestedActions'] as List).take(3).map((action) => 
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
