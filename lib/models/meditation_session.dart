import 'package:flutter/material.dart';

class MeditationSession {
  final String id;
  final String title;
  final String description;
  final String category;
  final int durationMinutes;
  final String? audioUrl;
  final String? imageUrl;
  final String instructor;
  final List<String> tags;
  final Color accentColor;
  final String script;
  final bool isPremium;
  final double rating;
  final int completions;

  const MeditationSession({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.durationMinutes,
    this.audioUrl,
    this.imageUrl,
    required this.instructor,
    required this.tags,
    required this.accentColor,
    required this.script,
    this.isPremium = false,
    this.rating = 0.0,
    this.completions = 0,
  });

  // Get formatted duration
  String get formattedDuration {
    if (durationMinutes < 60) {
      return '${durationMinutes}min';
    } else {
      final hours = durationMinutes ~/ 60;
      final minutes = durationMinutes % 60;
      return minutes > 0 ? '${hours}h ${minutes}min' : '${hours}h';
    }
  }

  // Get difficulty level based on duration
  String get difficultyLevel {
    if (durationMinutes <= 5) return 'Beginner';
    if (durationMinutes <= 15) return 'Intermediate';
    return 'Advanced';
  }

  // Predefined meditation sessions
  static const List<MeditationSession> presetSessions = [
    MeditationSession(
      id: 'mindful_breathing',
      title: 'Mindful Breathing',
      description: 'A gentle introduction to mindfulness through focused breathing. Perfect for beginners.',
      category: 'Mindfulness',
      durationMinutes: 5,
      instructor: 'Aura Guide',
      tags: ['breathing', 'mindfulness', 'beginner'],
      accentColor: Color(0xFF06B6D4),
      script: '''
Welcome to this mindful breathing meditation. Find a comfortable position and gently close your eyes.

Take a moment to notice your natural breath. Don't try to change it, just observe.

Now, let's begin with three deep breaths. Inhale slowly through your nose... and exhale gently through your mouth.

Again, breathe in deeply... feeling your chest and belly expand... and breathe out, releasing any tension.

One more deep breath in... and out, settling into this moment.

Now return to your natural breathing rhythm. Simply notice each breath as it comes and goes.

If your mind wanders, that's perfectly normal. Gently bring your attention back to your breath.

Feel the air entering your nostrils... the pause between breaths... and the gentle release as you exhale.

Continue breathing naturally, staying present with each breath for the remaining time.

When you're ready, slowly open your eyes and take a moment to notice how you feel.
''',
    ),
    
    MeditationSession(
      id: 'body_scan',
      title: 'Body Scan Relaxation',
      description: 'Release tension and stress by systematically relaxing each part of your body.',
      category: 'Relaxation',
      durationMinutes: 10,
      instructor: 'Aura Guide',
      tags: ['relaxation', 'body scan', 'stress relief'],
      accentColor: Color(0xFF8B5CF6),
      script: '''
Welcome to this body scan relaxation. Lie down comfortably and close your eyes.

Take three deep breaths to begin. Inhale... and exhale. Again, breathe in... and out. One more time, in... and out.

Now, bring your attention to the top of your head. Notice any sensations there. Imagine warm, golden light flowing over your scalp, releasing any tension.

Move your attention to your forehead. Let the muscles around your eyes soften. Release any furrows in your brow.

Notice your jaw. Let it drop slightly, creating space between your teeth. Feel your tongue relax in your mouth.

Bring awareness to your neck and shoulders. These areas often hold stress. Imagine the tension melting away like warm honey.

Focus on your arms. Feel them heavy and relaxed against the surface beneath you. Let your hands soften, fingers gently curled.

Notice your chest. Feel it rising and falling with each natural breath. Let your heart rate slow and steady.

Bring attention to your back. Feel it supported and relaxed. Release any tightness along your spine.

Focus on your abdomen. Let it soften and expand with each breath. Release any holding or tension.

Notice your hips and pelvis. Let them sink into relaxation, feeling heavy and supported.

Bring awareness to your thighs. Feel them completely relaxed and heavy.

Focus on your knees, calves, and shins. Let any tension flow away.

Finally, notice your feet and toes. Let them completely relax and soften.

Take a moment to feel your entire body in this state of deep relaxation.

When you're ready, slowly wiggle your fingers and toes, and gently open your eyes.
''',
    ),
    
    MeditationSession(
      id: 'loving_kindness',
      title: 'Loving Kindness',
      description: 'Cultivate compassion and love for yourself and others through this heart-opening practice.',
      category: 'Compassion',
      durationMinutes: 8,
      instructor: 'Aura Guide',
      tags: ['compassion', 'love', 'kindness', 'heart'],
      accentColor: Color(0xFFEC4899),
      script: '''
Welcome to this loving kindness meditation. Sit comfortably and close your eyes.

Begin with a few deep breaths. Inhale peace... exhale tension. Breathe in love... breathe out worry.

Place your hand on your heart and feel its gentle rhythm. This is the center of your compassion.

Begin by offering loving kindness to yourself. Silently repeat these phrases:

"May I be happy. May I be healthy. May I be at peace. May I be free from suffering."

Feel these words in your heart. If resistance arises, that's okay. Simply continue with gentle intention.

"May I be happy. May I be healthy. May I be at peace. May I be free from suffering."

Now, bring to mind someone you love dearly. See their face in your mind's eye. Offer them the same loving wishes:

"May you be happy. May you be healthy. May you be at peace. May you be free from suffering."

Feel the warmth of love flowing from your heart to theirs.

Next, think of someone neutral - perhaps a neighbor or cashier. Extend the same kindness:

"May you be happy. May you be healthy. May you be at peace. May you be free from suffering."

Now, if you feel ready, bring to mind someone with whom you have difficulty. This is challenging, so be gentle with yourself:

"May you be happy. May you be healthy. May you be at peace. May you be free from suffering."

Finally, extend loving kindness to all beings everywhere:

"May all beings be happy. May all beings be healthy. May all beings be at peace. May all beings be free from suffering."

Feel the circle of compassion expanding from your heart to encompass the entire world.

Rest in this feeling of universal love and connection.

When you're ready, slowly open your eyes, carrying this loving kindness with you.
''',
    ),
    
    MeditationSession(
      id: 'stress_relief',
      title: 'Stress Relief',
      description: 'Quick and effective techniques to release stress and find calm in challenging moments.',
      category: 'Stress Relief',
      durationMinutes: 7,
      instructor: 'Aura Guide',
      tags: ['stress', 'anxiety', 'calm', 'quick'],
      accentColor: Color(0xFF10B981),
      script: '''
Welcome to this stress relief meditation. You can do this sitting or standing, wherever you are.

First, acknowledge that you're feeling stressed. It's okay - stress is a natural human response.

Take a deep breath in through your nose for 4 counts... hold for 4... and exhale through your mouth for 6 counts.

Again, breathe in for 4... hold for 4... and out for 6. This longer exhale activates your relaxation response.

One more time. In for 4... hold for 4... out for 6.

Now, let's release physical tension. Scrunch up your face muscles tightly... and release. Feel the contrast.

Make fists with your hands, tense your arms... and let go. Notice the relaxation.

Shrug your shoulders up to your ears... and drop them down. Feel the tension melting away.

Tense your entire body for 5 seconds... and completely relax. Let yourself sink into this feeling.

Now, imagine your stress as a color. What color is it? See it clearly in your mind.

With each exhale, imagine breathing out this color, releasing the stress from your body.

Breathe in calm, peaceful energy. Breathe out the stress color.

Continue this for several breaths. In with peace... out with stress.

Now imagine a place where you feel completely safe and calm. It might be real or imaginary.

See yourself there now. Notice the details - what do you see, hear, smell?

Feel the peace of this place filling your entire being.

Know that you can return to this place anytime you need calm.

Take three more deep breaths, carrying this peace with you.

When you're ready, open your eyes, feeling more relaxed and centered.
''',
    ),
    
    MeditationSession(
      id: 'sleep_preparation',
      title: 'Sleep Preparation',
      description: 'Gentle meditation to help you unwind and prepare for restful sleep.',
      category: 'Sleep',
      durationMinutes: 12,
      instructor: 'Aura Guide',
      tags: ['sleep', 'bedtime', 'relaxation', 'night'],
      accentColor: Color(0xFF6366F1),
      script: '''
Welcome to this sleep preparation meditation. Make yourself comfortable in bed and close your eyes.

Begin by taking three slow, deep breaths. Let each exhale release the day's tensions and worries.

Feel your body sinking into the comfort of your bed. Notice how supported and safe you feel.

Starting with your toes, consciously relax each part of your body. Let your toes soften and release.

Feel relaxation moving up through your feet, ankles, and calves. Let them become heavy and still.

Allow this wave of relaxation to flow up through your thighs and hips. Feel them sinking into the mattress.

Let your abdomen soften with each breath. Release any holding or tension there.

Feel your back melting into the bed. Let your shoulders drop and soften.

Allow your arms to become heavy and relaxed. Let your hands rest peacefully.

Soften the muscles in your neck and face. Let your jaw drop slightly and your eyes rest gently closed.

Now, imagine you're lying in a peaceful meadow under a starlit sky. The air is warm and gentle.

Feel the soft grass beneath you and hear the quiet sounds of nature - perhaps a gentle breeze or distant crickets.

Look up at the stars twinkling peacefully above. Each star represents a peaceful thought.

If any worries arise, imagine them floating away like clouds, leaving only the peaceful stars.

Feel yourself becoming drowsier with each breath. Your body is completely relaxed and ready for sleep.

Count slowly backwards from 10, letting yourself drift deeper into relaxation with each number.

10... feeling peaceful and drowsy...
9... sinking deeper into comfort...
8... letting go of the day...
7... feeling safe and secure...
6... drifting toward sleep...
5... completely relaxed...
4... peaceful and calm...
3... ready for rest...
2... almost asleep...
1... drifting into peaceful sleep...

Let yourself drift off naturally, knowing you are safe and at peace.
''',
    ),
  ];

  // Get sessions by category
  static List<MeditationSession> getSessionsByCategory(String category) {
    return presetSessions.where((session) => session.category == category).toList();
  }

  // Get all categories
  static List<String> getAllCategories() {
    return presetSessions.map((session) => session.category).toSet().toList();
  }

  // Get sessions by duration
  static List<MeditationSession> getSessionsByDuration(int maxMinutes) {
    return presetSessions.where((session) => session.durationMinutes <= maxMinutes).toList();
  }
}