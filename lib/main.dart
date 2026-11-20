
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';

import 'apex_game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  runApp(const ApexApp());
}

class ApexApp extends StatelessWidget {
  const ApexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RacingScreen(),
    );
  }
}

class RacingScreen extends StatefulWidget {
  const RacingScreen({super.key});

  @override
  State<RacingScreen> createState() => _RacingScreenState();
}

class _RacingScreenState extends State<RacingScreen> {
  late final ApexGame game;

  @override
  void initState() {
    super.initState();
    game = ApexGame();
  }

  @override
  void dispose() {
    game.speedNotifier.dispose();
    game.scoreNotifier.dispose();
    game.bestNotifier.dispose();
    super.dispose();
  }

  Widget control({
    required IconData icon,
    required String label,
    required VoidCallback down,
    required VoidCallback up,
  }) {
    return Listener(
      onPointerDown: (_) => down(),
      onPointerUp: (_) => up(),
      onPointerCancel: (_) => up(),
      child: Container(
        width: 66,
        height: 66,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white54),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 29),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget hud() {
    return Positioned(
      top: 12,
      left: 15,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'APEX',
              style: TextStyle(
                color: Colors.redAccent,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: game.speedNotifier,
              builder: (_, speed, __) => Text(
                '$speed KM/H',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: game.scoreNotifier,
              builder: (_, score, __) => Text(
                'DISTANCE: $score',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
            ValueListenableBuilder<int>(
              valueListenable: game.bestNotifier,
              builder: (_, best, __) => Text(
                'BEST: $best',
                style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          final down = event is KeyDownEvent;
          final up = event is KeyUpEvent;

          if (!down && !up) {
            return KeyEventResult.ignored;
          }

          final key = event.logicalKey;

          if (key == LogicalKeyboardKey.arrowLeft ||
              key == LogicalKeyboardKey.keyA) {
            game.setSteering(down ? -1 : 0);
            return KeyEventResult.handled;
          }

          if (key == LogicalKeyboardKey.arrowRight ||
              key == LogicalKeyboardKey.keyD) {
            game.setSteering(down ? 1 : 0);
            return KeyEventResult.handled;
          }

          if (key == LogicalKeyboardKey.arrowUp ||
              key == LogicalKeyboardKey.space) {
            game.setAccelerating(down);
            return KeyEventResult.handled;
          }

          if (key == LogicalKeyboardKey.arrowDown) {
            game.setBraking(down);
            return KeyEventResult.handled;
          }

          return KeyEventResult.ignored;
        },
        child: Stack(
          children: [
            Positioned.fill(
              child: GameWidget<ApexGame>(game: game),
            ),

            hud(),

            Positioned(
              bottom: 20,
              left: 20,
              child: Row(
                children: [
                  control(
                    icon: Icons.arrow_left,
                    label: 'LEFT',
                    down: () => game.setSteering(-1),
                    up: () => game.setSteering(0),
                  ),
                  const SizedBox(width: 12),
                  control(
                    icon: Icons.arrow_right,
                    label: 'RIGHT',
                    down: () => game.setSteering(1),
                    up: () => game.setSteering(0),
                  ),
                ],
              ),
            ),

            Positioned(
              bottom: 20,
              right: 20,
              child: Row(
                children: [
                  control(
                    icon: Icons.arrow_downward,
                    label: 'BRAKE',
                    down: () => game.setBraking(true),
                    up: () => game.setBraking(false),
                  ),
                  const SizedBox(width: 12),
                  control(
                    icon: Icons.local_gas_station,
                    label: 'GAS',
                    down: () => game.setAccelerating(true),
                    up: () => game.setAccelerating(false),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
