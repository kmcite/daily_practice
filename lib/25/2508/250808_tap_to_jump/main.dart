// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(GameWidget(game: TapToJump()));

class TapToJump extends FlameGame
    with TapDetector, HasKeyboardHandlerComponents {
  final player = PlayerComponent();
  final platform = PlatformComponent();
  final healthBar = HealthBarComponent();
  final score = ScoreComponent();
  double obstacleTimer = 0;

  @override
  Future<void> onLoad() async {
    addAll([
      platform,
      player,
      healthBar,
      score,
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (healthBar.isDead && children.whereType<GameOverComponent>().isEmpty) {
      add(GameOverComponent());
      return;
    }

    obstacleTimer += dt;
    if (obstacleTimer > 1.5) {
      obstacleTimer = 0;
      spawnObstacle();
    }

    for (final obstacle in children.whereType<ObstacleComponent>()) {
      if (player.toAbsoluteRect().overlaps(obstacle.toAbsoluteRect())) {
        player.tryDamage();
      }
      if (!obstacle.hasScored &&
          obstacle.position.x + obstacle.width < player.position.x) {
        obstacle.hasScored = true;
        score.increase();
      }
    }
  }

  void spawnObstacle() {
    final y = size.y - platform.platformHeight - 40;
    add(ObstacleComponent(Vector2(size.x, y)));
  }

  @override
  void onTapDown(TapDownInfo info) {
    if (!healthBar.isDead) {
      player.jump();
    }
  }

  void resetGame() {
    children
        .whereType<ObstacleComponent>()
        .toList()
        .forEach((o) => o.removeFromParent());
    player.position = Vector2(100, 100);
    player.velocity = Vector2.zero();
    healthBar.reset();
    score.reset();
    resumeEngine();
  }
}

// 🟦 Player
class PlayerComponent extends PositionComponent
    with HasGameReference<TapToJump> {
  Vector2 velocity = Vector2.zero();
  double gravity = 900;
  double jumpForce = -350;
  double lastDamageTime = 0;

  @override
  Future<void> onLoad() async {
    size = Vector2(30, 30);
    position = Vector2(100, 100);
    anchor = Anchor.center;

    add(
      KeyboardListenerComponent(
        keyDown: {
          LogicalKeyboardKey.arrowLeft: (_) => moveLeft(),
          LogicalKeyboardKey.arrowRight: (_) => moveRight(),
          LogicalKeyboardKey.arrowUp: (_) {
            jump();
            return true;
          },
        },
        keyUp: {
          LogicalKeyboardKey.arrowLeft: (_) => stop(),
          LogicalKeyboardKey.arrowRight: (_) => stop(),
        },
      ),
    );
  }

  @override
  void update(double dt) {
    velocity.y += gravity * dt;
    position += velocity * dt;

    final floorY = game.size.y - game.platform.platformHeight;
    if (position.y + height / 2 >= floorY) {
      position.y = floorY - height / 2;
      velocity.y = 0;
    }

    position.x = position.x.clamp(width / 2, game.size.x - width / 2);
  }

  void jump() => velocity.y = jumpForce;
  bool moveLeft() => (velocity.x = -120) != null;
  bool moveRight() => (velocity.x = 120) != null;
  bool stop() => (velocity.x = 0) != null;

  void tryDamage() {
    final now = game.currentTime();
    if (now - lastDamageTime > 1) {
      game.healthBar.decrease();
      lastDamageTime = now;
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(6)),
      Paint()..color = Colors.blueAccent,
    );
  }
}

// 🟫 Platform
class PlatformComponent extends RectangleComponent
    with HasGameReference<TapToJump> {
  final double platformHeight = 20;
  @override
  Future<void> onLoad() async {
    size = Vector2(game.size.x, platformHeight);
    position = Vector2(game.size.x / 2, game.size.y - platformHeight / 2);
    paint = Paint()..color = const Color(0xFF6D4C41); // Brown
    anchor = Anchor.center;
  }
}

// 🔴 Obstacle
class ObstacleComponent extends RectangleComponent {
  bool hasScored = false;
  ObstacleComponent(Vector2 pos)
      : super(
          size: Vector2(20, 40),
          position: pos,
          paint: Paint()..color = Colors.deepOrange,
        );

  @override
  void update(double dt) {
    position.x -= 150 * dt;
    if (position.x + width < 0) removeFromParent();
  }
}

// ❤️ Health bar
class HealthBarComponent extends PositionComponent {
  final double maxWidth = 200;
  @override
  final double height = 20;
  int health = 5;
  late final TextComponent textComponent;

  int get percentage => (health * 20).clamp(0, 100);

  @override
  Future<void> onLoad() async {
    size = Vector2(maxWidth, height);
    position = Vector2(20, 20);
    anchor = Anchor.topLeft;

    textComponent = TextComponent(
      text: "$percentage%",
      position: Vector2(0, -25),
      anchor: Anchor.topLeft,
      textRenderer: TextPaint(
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );

    add(textComponent);
  }

  @override
  void update(double dt) {
    super.update(dt);
    textComponent.text = "$percentage%";
  }

  void reset() => health = 5;
  void decrease() => health = (health - 1).clamp(0, 5);
  bool get isDead => health <= 0;

  @override
  void render(Canvas canvas) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(size.toRect(), const Radius.circular(4)),
      Paint()..color = Colors.grey.shade700,
    );

    final filledWidth = (health / 5) * maxWidth;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, filledWidth, height),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.redAccent,
    );
  }
}

// 📈 Score display
class ScoreComponent extends TextComponent {
  int score = 0;

  @override
  Future<void> onLoad() async {
    position = Vector2(20, 50);
    anchor = Anchor.topLeft;
    text = "Score: 0";
    textRenderer = TextPaint(
      style: const TextStyle(fontSize: 16, color: Colors.white),
    );
  }

  void increase() {
    score++;
    text = "Score: $score";
  }

  void reset() {
    score = 0;
    text = "Score: 0";
  }
}

// 💀 Game Over popup
class GameOverComponent extends ButtonComponent
    with HasGameReference<TapToJump> {
  GameOverComponent()
      : super(
          position: Vector2.zero(),
          anchor: Anchor.center,
        );

  @override
  Future<void> onLoad() async {
    size = Vector2(280, 100);

    button = RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF222244),
    );

    final text = TextComponent(
      text: "GAME OVER\nTap to Restart",
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: const TextStyle(
          fontSize: 22,
          color: Colors.white,
          fontWeight: FontWeight.bold,
          shadows: [
            Shadow(blurRadius: 6, color: Colors.black),
          ],
        ),
      ),
    );

    add(text);
    position = game.size / 2;

    onPressed = () {
      removeFromParent();
      game.resetGame();
    };
  }
}
