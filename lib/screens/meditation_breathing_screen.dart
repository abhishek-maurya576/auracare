import 'package:flutter/material.dart';
import 'package:auracare/widgets/aura_background.dart';
import 'package:auracare/widgets/glass_widgets.dart';

class MeditationBreathingScreen extends StatelessWidget {
  const MeditationBreathingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Meditation & Breathing',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const AuraBackground(),
          Center(
            child: GlassCard(
              child: SizedBox(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.6,
                child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Meditation & Breathing exercises will go here.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                // Placeholder for future content like exercise list, animations, etc.
              ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}