
import 'dart:math' as math;

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApexGame extends FlameGame {
  double speed = 0;
  double distance = 0;
  double playerX = 0;
  double steering = 0;

  bool accelerating = false;
  bool braking = false;

  int score = 0;
  int bestScore = 0;

  final speedNotifier = ValueNotifier<int>(0);
  final scoreNotifier = ValueNotifier<int>(0);
  final bestNotifier = ValueNotifier<int>(0);

  late final SharedPreferencesAsync prefs;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    prefs = SharedPreferencesAsync();

    bestScore = await prefs.getInt('apex_best') ?? 0;
    bestNotifier.value = bestScore;
  }

  void setSteering(double value) {
    steering = value.clamp(-1.0, 1.0).toDouble();
  }

  void setAccelerating(bool value) {
    accelerating = value;
  }

  void setBraking(bool value) {
    braking = value;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (accelerating) {
      speed += 110 * dt;
    } else {
      speed -= 28 * dt;
    }

    if (braking) {
      speed -= 180 * dt;
    }

    speed = speed.clamp(0.0, 280.0).toDouble();

    playerX += steering * (1.5 + speed / 180) * dt;
    playerX = playerX.clamp(-0.85, 0.85).toDouble();

    distance += speed * dt * 0.08;

    score = distance.floor();

    speedNotifier.value = speed.round();
    scoreNotifier.value = score;

    if (score > bestScore) {
      bestScore = score;
      bestNotifier.value = bestScore;
      prefs.setInt('apex_best', bestScore);
    }
  }

  double roadCenter(double t, double w) {
    return w * 0.5 +
        math.sin(distance * 0.012 + t * 3.0) * w * 0.045;
  }

  double roadHalfWidth(double t, double w) {
    return w * (0.055 + t * 0.39);
  }

  Path createRoad(double w, double h) {
    final horizon = h * 0.27;
    final path = Path();

    for (int i = 0; i <= 40; i++) {
      final t = i / 40;
      final y = horizon + t * (h - horizon);
      final center = roadCenter(t, w);
      final half = roadHalfWidth(t, w);

      if (i == 0) {
        path.moveTo(center - half, y);
      } else {
        path.lineTo(center - half, y);
      }
    }

    for (int i = 40; i >= 0; i--) {
      final t = i / 40;
      final y = horizon + t * (h - horizon);
      final center = roadCenter(t, w);
      final half = roadHalfWidth(t, w);

      path.lineTo(center + half, y);
    }

    path.close();
    return path;
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final w = size.x;
    final h = size.y;

    if (w <= 0 || h <= 0) return;

    final horizon = h * 0.27;

    // Sky
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF102B55),
            Color(0xFF4F9FC0),
            Color(0xFFB8D7D5),
          ],
        ).createShader(Rect.fromLTWH(0, 0, w, h)),
    );

    // Sun
    canvas.drawCircle(
      Offset(w * 0.79, h * 0.13),
      w * 0.055,
      Paint()..color = const Color(0xFFFFD783),
    );

    // Mountains
    final mountains = Path()
      ..moveTo(0, horizon)
      ..lineTo(w * 0.16, h * 0.14)
      ..lineTo(w * 0.28, horizon)
      ..lineTo(w * 0.43, h * 0.16)
      ..lineTo(w * 0.58, horizon)
      ..lineTo(w * 0.76, h * 0.13)
      ..lineTo(w, horizon)
      ..lineTo(w, h * 0.45)
      ..lineTo(0, h * 0.45)
      ..close();

    canvas.drawPath(
      mountains,
      Paint()..color = const Color(0xFF536E79),
    );

    // Grass
    canvas.drawRect(
      Rect.fromLTWH(0, horizon, w, h - horizon),
      Paint()..color = const Color(0xFF397A49),
    );

    // Road shoulder
    canvas.drawPath(
      createRoad(w, h),
      Paint()..color = const Color(0xFFE6D6A7),
    );

    // Asphalt
    final road = Path();

    for (int i = 0; i <= 40; i++) {
      final t = i / 40;
      final y = horizon + t * (h - horizon);
      final center = roadCenter(t, w);
      final half = roadHalfWidth(t, w) * 0.94;

      if (i == 0) {
        road.moveTo(center - half, y);
      } else {
        road.lineTo(center - half, y);
      }
    }

    for (int i = 40; i >= 0; i--) {
      final t = i / 40;
      final y = horizon + t * (h - horizon);
      final center = roadCenter(t, w);
      final half = roadHalfWidth(t, w) * 0.94;

      road.lineTo(center + half, y);
    }

    road.close();

    canvas.drawPath(
      road,
      Paint()..color = const Color(0xFF30363D),
    );

    // Road borders
    for (final side in [-1.0, 1.0]) {
      final edge = Path();

      for (int i = 0; i <= 40; i++) {
        final t = i / 40;
        final y = horizon + t * (h - horizon);
        final center = roadCenter(t, w);
        final half = roadHalfWidth(t, w) * 0.94;
        final x = center + side * half;

        if (i == 0) {
          edge.moveTo(x, y);
        } else {
          edge.lineTo(x, y);
        }
      }

      canvas.drawPath(
        edge,
        Paint()
          ..color = Colors.white
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke,
      );
    }

    // Lane markings
    final phase = (distance * 0.025) % 1.0;

    for (int lane = -1; lane <= 1; lane += 2) {
      for (int i = 0; i < 14; i++) {
        final t = ((i / 14 + phase) % 1.0);
        final y = horizon + t * (h - horizon);

        final center = roadCenter(t, w);
        final half = roadHalfWidth(t, w) * 0.94;
        final x = center + lane * half * 0.33;

        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(x, y),
              width: 1.5 + t * 5,
              height: 3 + t * 23,
            ),
            const Radius.circular(2),
          ),
          Paint()..color = Colors.white,
        );
      }
    }

    // Trees
    for (int i = 0; i < 12; i++) {
      final t = ((i / 12 + phase * 0.55) % 1.0);
      final y = horizon + t * (h - horizon);

      final center = roadCenter(t, w);
      final half = roadHalfWidth(t, w);
      final treeSize = 5 + t * 32;

      for (final side in [-1.0, 1.0]) {
        final x = center + side * (half + treeSize * 0.9);

        canvas.drawRect(
          Rect.fromLTWH(
            x - treeSize * 0.08,
            y - treeSize * 0.25,
            treeSize * 0.16,
            treeSize * 0.6,
          ),
          Paint()..color = const Color(0xFF65452D),
        );

        final tree = Path()
          ..moveTo(x, y - treeSize)
          ..lineTo(x - treeSize * 0.5, y)
          ..lineTo(x + treeSize * 0.5, y)
          ..close();

        canvas.drawPath(
          tree,
          Paint()..color = const Color(0xFF164B35),
        );
      }
    }

    drawCar(canvas, w, h);
  }

  void drawCar(Canvas canvas, double w, double h) {
    final carX = w * (0.5 + playerX * 0.30);
    final carY = h * 0.79;

    final carW = w * 0.17;
    final carH = h * 0.17;

    // Shadow
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(carX, carY + carH * 0.4),
        width: carW * 1.2,
        height: carH * 0.32,
      ),
      Paint()..color = const Color(0x66000000),
    );

    // Wheels
    final wheelPaint = Paint()..color = const Color(0xFF101418);

    for (final side in [-1.0, 1.0]) {
      for (final vertical in [-0.2, 0.25]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset(
                carX + side * carW * 0.43,
                carY + vertical * carH,
              ),
              width: carW * 0.2,
              height: carH * 0.38,
            ),
            const Radius.circular(5),
          ),
          wheelPaint,
        );
      }
    }

    // Body
    final body = Path()
      ..moveTo(carX - carW * 0.48, carY + carH * 0.38)
      ..lineTo(carX - carW * 0.40, carY - carH * 0.18)
      ..lineTo(carX - carW * 0.23, carY - carH * 0.49)
      ..lineTo(carX + carW * 0.23, carY - carH * 0.49)
      ..lineTo(carX + carW * 0.40, carY - carH * 0.18)
      ..lineTo(carX + carW * 0.48, carY + carH * 0.38)
      ..close();

    canvas.drawPath(
      body,
      Paint()..color = const Color(0xFFE53935),
    );

    // Glass
    final glass = Path()
      ..moveTo(carX - carW * 0.22, carY - carH * 0.18)
      ..lineTo(carX - carW * 0.14, carY - carH * 0.42)
      ..lineTo(carX + carW * 0.14, carY - carH * 0.42)
      ..lineTo(carX + carW * 0.22, carY - carH * 0.18)
      ..close();

    canvas.drawPath(
      glass,
      Paint()..color = const Color(0xFF8BD3E8),
    );

    // Lights
    for (final side in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(
              carX + side * carW * 0.32,
              carY + carH * 0.25,
            ),
            width: carW * 0.16,
            height: carH * 0.08,
          ),
          const Radius.circular(3),
        ),
        Paint()..color = const Color(0xFFFFE1A0),
      );
    }
  }

  @override
  void onRemove() {
    speedNotifier.dispose();
    scoreNotifier.dispose();
    bestNotifier.dispose();
    super.onRemove();
  }
}
