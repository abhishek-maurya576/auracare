import 'package:flutter/material.dart';
import 'dart:async';
import '../widgets/aura_background.dart';
import '../widgets/glass_widgets.dart';
import '../utils/app_colors.dart';
import '../models/meditation_session.dart';

class GuidedMeditationScreen extends StatefulWidget {
  final MeditationSession session;

  const GuidedMeditationScreen({
    super.key,
    required this.session,
  });

  @override
  State<GuidedMeditationScreen> createState() => _GuidedMeditationScreenState();
}

class _GuidedMeditationScreenState extends State<GuidedMeditationScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _currentSeconds = 0;
  bool _isPlaying = false;
  // bool _isCompleted = false; // Removed unused field
  
  late AnimationController _pulseController;
  late AnimationController _progressController;
  late Animation<double> _pulseAnimation;
  // late Animation<double> _progressAnimation; // Removed unused field

  // Text segments for guided meditation
  List<String> _textSegments = [];
  int _currentSegmentIndex = 0;
  String _currentText = '';

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _prepareTextSegments();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: Duration(minutes: widget.session.durationMinutes),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Removed unused _progressAnimation

    _pulseController.repeat(reverse: true);
  }

  void _prepareTextSegments() {
    // Split the meditation script into segments
    final sentences = widget.session.script
        .split('.')
        .where((sentence) => sentence.trim().isNotEmpty)
        .map((sentence) => '${sentence.trim()}.')
        .toList();
    
    _textSegments = sentences;
    if (_textSegments.isNotEmpty) {
      _currentText = _textSegments[0];
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
    });

    if (_isPlaying) {
      _startMeditation();
    } else {
      _pauseMeditation();
    }
  }

  void _startMeditation() {
    _progressController.forward();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _currentSeconds++;
      });

      // Update text segments based on time
      final totalDuration = widget.session.durationMinutes * 60;
      final segmentDuration = totalDuration / _textSegments.length;
      final newSegmentIndex = (_currentSeconds / segmentDuration).floor();
      
      if (newSegmentIndex < _textSegments.length && newSegmentIndex != _currentSegmentIndex) {
        setState(() {
          _currentSegmentIndex = newSegmentIndex;
          _currentText = _textSegments[_currentSegmentIndex];
        });
      }

      // Check if meditation is complete
      if (_currentSeconds >= totalDuration) {
        _completeMeditation();
      }
    });
  }

  void _pauseMeditation() {
    _timer?.cancel();
    _progressController.stop();
  }

  void _stopMeditation() {
    _timer?.cancel();
    _progressController.reset();
    setState(() {
      _isPlaying = false;
      _currentSeconds = 0;
      _currentSegmentIndex = 0;
      _currentText = _textSegments.isNotEmpty ? _textSegments[0] : '';
      // _isCompleted = false; // Removed unused field
    });
  }

  void _completeMeditation() {
    _timer?.cancel();
    _progressController.forward();
    setState(() {
      _isPlaying = false;
      // _isCompleted = true; // Removed unused field
    });

    // Show completion dialog
    _showCompletionDialog();
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.celebration_rounded, color: AppColors.accentTeal, size: 28),
            SizedBox(width: 12),
            Text(
              'Well Done!',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ],
        ),
        content: Text(
          'You\'ve completed the ${widget.session.title} meditation session. Take a moment to notice how you feel.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to meditation screen
            },
            child: const Text(
              'Finish',
              style: TextStyle(color: AppColors.accentTeal, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  double get _progress {
    final totalSeconds = widget.session.durationMinutes * 60;
    return totalSeconds > 0 ? _currentSeconds / totalSeconds : 0.0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.session.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AuraBackground(),
          SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const SizedBox(height: 20),
                
                // Session info
                GlassWidget(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.session.category,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: widget.session.accentColor,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.session.formattedDuration,
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _formatTime(_currentSeconds),
                            style: const TextStyle(
                              fontSize: 24,
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Progress bar
                      LinearProgressIndicator(
                        value: _progress,
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(widget.session.accentColor),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Meditation visualization
                Expanded(
                  child: Center(
                    child: AnimatedBuilder(
                      animation: _pulseAnimation,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _isPlaying ? _pulseAnimation.value : 1.0,
                          child: Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  widget.session.accentColor.withValues(alpha: 0.3),
                                  widget.session.accentColor.withValues(alpha: 0.1),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Center(
                              child: Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: widget.session.accentColor.withValues(alpha: 0.2),
                                  border: Border.all(
                                    color: widget.session.accentColor.withValues(alpha: 0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                  size: 48,
                                  color: widget.session.accentColor,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Meditation text
                GlassWidget(
                  padding: const EdgeInsets.all(24),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: Text(
                      _currentText,
                      key: ValueKey(_currentSegmentIndex),
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textPrimary,
                        height: 1.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Control buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Stop button
                    GestureDetector(
                      onTap: _stopMeditation,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.stop_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    
                    // Play/Pause button
                    GestureDetector(
                      onTap: _togglePlayPause,
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: widget.session.accentColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.session.accentColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                    
                    // Settings button (placeholder)
                    GestureDetector(
                      onTap: () {
                        // TODO: Show meditation settings
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.settings_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
        ],
      ),
    );
  }
}