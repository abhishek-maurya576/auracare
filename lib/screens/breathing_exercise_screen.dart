import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../utils/app_colors.dart';

class BreathingExerciseScreen extends StatefulWidget {
  final BreathingPattern pattern;
  
  const BreathingExerciseScreen({
    super.key,
    required this.pattern,
  });

  @override
  State<BreathingExerciseScreen> createState() => _BreathingExerciseScreenState();
}

class _BreathingExerciseScreenState extends State<BreathingExerciseScreen> with TickerProviderStateMixin {
  late AnimationController _breathAnimationController;
  late Animation<double> _breathAnimation;
  
  Timer? _phaseTimer;
  BreathingPhase _currentPhase = BreathingPhase.inhale;
  int _remainingSeconds = 0;
  int _completedCycles = 0;
  bool _isActive = false;
  bool _isPaused = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize animation controller
    _breathAnimationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.pattern.inhaleSeconds),
    );
    
    // Initialize animation
    _updateBreathAnimation();
    
    // Start with a 3-second countdown
    _remainingSeconds = 3;
    _startCountdown();
  }
  
  void _updateBreathAnimation() {
    // Create appropriate animation based on current phase
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        _breathAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
          CurvedAnimation(parent: _breathAnimationController, curve: Curves.easeInOut),
        );
        _breathAnimationController.duration = Duration(seconds: widget.pattern.inhaleSeconds);
        break;
      case BreathingPhase.hold:
        _breathAnimation = Tween<double>(begin: 1.0, end: 1.0).animate(
          CurvedAnimation(parent: _breathAnimationController, curve: Curves.linear),
        );
        _breathAnimationController.duration = Duration(seconds: widget.pattern.holdSeconds);
        break;
      case BreathingPhase.exhale:
        _breathAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
          CurvedAnimation(parent: _breathAnimationController, curve: Curves.easeInOut),
        );
        _breathAnimationController.duration = Duration(seconds: widget.pattern.exhaleSeconds);
        break;
      case BreathingPhase.rest:
        _breathAnimation = Tween<double>(begin: 0.5, end: 0.5).animate(
          CurvedAnimation(parent: _breathAnimationController, curve: Curves.linear),
        );
        _breathAnimationController.duration = Duration(seconds: widget.pattern.restSeconds);
        break;
    }
    
    // Reset animation controller
    _breathAnimationController.reset();
    _breathAnimationController.forward();
  }
  
  void _startCountdown() {
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
        
        if (_remainingSeconds <= 0) {
          timer.cancel();
          _startBreathingExercise();
        }
      });
    });
  }
  
  void _startBreathingExercise() {
    _isActive = true;
    _currentPhase = BreathingPhase.inhale;
    _remainingSeconds = widget.pattern.inhaleSeconds;
    _updateBreathAnimation();
    _startPhaseTimer();
    
    // Provide haptic feedback at the start
    HapticFeedback.lightImpact();
  }
  
  void _startPhaseTimer() {
    _phaseTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPaused) return;
      
      setState(() {
        _remainingSeconds--;
        
        if (_remainingSeconds <= 0) {
          _moveToNextPhase();
        }
      });
    });
  }
  
  void _moveToNextPhase() {
    // Provide haptic feedback on phase change
    HapticFeedback.mediumImpact();
    
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        if (widget.pattern.holdSeconds > 0) {
          _currentPhase = BreathingPhase.hold;
          _remainingSeconds = widget.pattern.holdSeconds;
        } else {
          _currentPhase = BreathingPhase.exhale;
          _remainingSeconds = widget.pattern.exhaleSeconds;
        }
        break;
      case BreathingPhase.hold:
        _currentPhase = BreathingPhase.exhale;
        _remainingSeconds = widget.pattern.exhaleSeconds;
        break;
      case BreathingPhase.exhale:
        if (widget.pattern.restSeconds > 0) {
          _currentPhase = BreathingPhase.rest;
          _remainingSeconds = widget.pattern.restSeconds;
        } else {
          _currentPhase = BreathingPhase.inhale;
          _remainingSeconds = widget.pattern.inhaleSeconds;
          _completedCycles++;
        }
        break;
      case BreathingPhase.rest:
        _currentPhase = BreathingPhase.inhale;
        _remainingSeconds = widget.pattern.inhaleSeconds;
        _completedCycles++;
        break;
    }
    
    _updateBreathAnimation();
  }
  
  void _togglePause() {
    setState(() {
      _isPaused = !_isPaused;
      
      if (_isPaused) {
        _breathAnimationController.stop();
      } else {
        _breathAnimationController.forward();
      }
    });
    
    // Provide haptic feedback
    HapticFeedback.selectionClick();
  }
  
  void _resetExercise() {
    _phaseTimer?.cancel();
    _breathAnimationController.reset();
    
    setState(() {
      _isActive = false;
      _isPaused = false;
      _completedCycles = 0;
      _remainingSeconds = 3;
    });
    
    _startCountdown();
    
    // Provide haptic feedback
    HapticFeedback.heavyImpact();
  }
  
  @override
  void dispose() {
    _phaseTimer?.cancel();
    _breathAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary),
        ),
        title: GlassWidget(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              widget.pattern.name,
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
                // Pattern description
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GlassWidget(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            widget.pattern.description,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 8),
                          
                          Text(
                            '${widget.pattern.inhaleSeconds}-${widget.pattern.holdSeconds}-${widget.pattern.exhaleSeconds}-${widget.pattern.restSeconds} Pattern',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Breathing animation
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Phase indicator
                        AnimatedOpacity(
                          opacity: _isActive ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            _getPhaseText(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Breathing circle
                        AnimatedBuilder(
                          animation: _breathAnimationController,
                          builder: (context, child) {
                            return Container(
                              width: 200 * (_isActive ? _breathAnimation.value : 0.7),
                              height: 200 * (_isActive ? _breathAnimation.value : 0.7),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: AppColors.auraGradient1,
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accentTeal.withValues(alpha: 0.3),
                                    blurRadius: 30,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isActive
                                    ? Text(
                                        _remainingSeconds.toString(),
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      )
                                    : Text(
                                        _remainingSeconds.toString(),
                                        style: const TextStyle(
                                          fontSize: 48,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textPrimary,
                                        ),
                                      ).animate(
                                        onComplete: (controller) => controller.repeat(),
                                      ).scale(
                                        duration: const Duration(seconds: 1),
                                        begin: const Offset(1, 1),
                                        end: const Offset(1.2, 1.2),
                                      ),
                              ),
                            );
                          },
                        ),
                        
                        const SizedBox(height: 20),
                        
                        // Completed cycles
                        AnimatedOpacity(
                          opacity: _isActive ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Text(
                            'Completed Cycles: $_completedCycles',
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Controls
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_isActive)
                        GlassFloatingActionButton(
                          icon: _isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
                          tooltip: _isPaused ? 'Resume' : 'Pause',
                          onPressed: _togglePause,
                        ),
                      
                      const SizedBox(width: 20),
                      
                      GlassFloatingActionButton(
                        icon: _isActive ? Icons.refresh_rounded : Icons.play_arrow_rounded,
                        tooltip: _isActive ? 'Restart' : 'Start',
                        onPressed: _isActive ? _resetExercise : _startBreathingExercise,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  String _getPhaseText() {
    switch (_currentPhase) {
      case BreathingPhase.inhale:
        return 'Breathe In';
      case BreathingPhase.hold:
        return 'Hold';
      case BreathingPhase.exhale:
        return 'Breathe Out';
      case BreathingPhase.rest:
        return 'Rest';
    }
  }
}

enum BreathingPhase {
  inhale,
  hold,
  exhale,
  rest,
}

class BreathingPattern {
  final String id;
  final String name;
  final String description;
  final int inhaleSeconds;
  final int holdSeconds;
  final int exhaleSeconds;
  final int restSeconds;
  final String? iconPath;
  final Color accentColor;
  
  const BreathingPattern({
    required this.id,
    required this.name,
    required this.description,
    required this.inhaleSeconds,
    required this.holdSeconds,
    required this.exhaleSeconds,
    required this.restSeconds,
    this.iconPath,
    this.accentColor = AppColors.accentTeal,
  });
  
  int get totalCycleSeconds => inhaleSeconds + holdSeconds + exhaleSeconds + restSeconds;
  
  static const List<BreathingPattern> presetPatterns = [
    BreathingPattern(
      id: 'box',
      name: 'Box Breathing',
      description: 'A technique used to calm the nervous system. Inhale, hold, exhale, and rest for equal counts.',
      inhaleSeconds: 4,
      holdSeconds: 4,
      exhaleSeconds: 4,
      restSeconds: 4,
      accentColor: AppColors.accentTeal,
    ),
    BreathingPattern(
      id: '478',
      name: '4-7-8 Breathing',
      description: 'A relaxing pattern that helps reduce anxiety and aids sleep. Inhale for 4, hold for 7, exhale for 8.',
      inhaleSeconds: 4,
      holdSeconds: 7,
      exhaleSeconds: 8,
      restSeconds: 0,
      accentColor: AppColors.moodCalm,
    ),
    BreathingPattern(
      id: 'calm',
      name: 'Calming Breath',
      description: 'A simple pattern to quickly calm your mind. Long exhales help activate the parasympathetic nervous system.',
      inhaleSeconds: 4,
      holdSeconds: 0,
      exhaleSeconds: 6,
      restSeconds: 2,
      accentColor: AppColors.accentBlue,
    ),
    BreathingPattern(
      id: 'energizing',
      name: 'Energizing Breath',
      description: 'A pattern to increase alertness and energy. Shorter, more dynamic breathing with minimal holds.',
      inhaleSeconds: 2,
      holdSeconds: 1,
      exhaleSeconds: 2,
      restSeconds: 1,
      accentColor: AppColors.moodHappy,
    ),
    BreathingPattern(
      id: 'deep',
      name: 'Deep Relaxation',
      description: 'A deeply relaxing pattern with long exhales to promote a state of calm and prepare for meditation.',
      inhaleSeconds: 5,
      holdSeconds: 2,
      exhaleSeconds: 7,
      restSeconds: 0,
      accentColor: AppColors.moodCalm,
    ),
  ];
}
