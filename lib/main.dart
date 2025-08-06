// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'package:faker/faker.dart' hide Color;
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
  double obstacleTimer = 0;

  @override
  Future<void> onLoad() async {
    addAll([
      platform,
      player,
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);

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
        // score.increase();
      }
    }
  }

  void spawnObstacle() {
    final y = size.y - platform.platformHeight - 40;
    add(ObstacleComponent(Vector2(size.x, y)));
  }

  @override
  void onTapDown(TapDownInfo info) {
    player.jump();
  }
}

// 🟦 Player
class PlayerComponent extends PositionComponent
    with HasGameReference<TapToJump> {
  Vector2 velocity = Vector2.zero();
  double gravity = 900;
  double jumpForce = -350;
  double lastDamageTime = 0;
  late final size2 = size;

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
          LogicalKeyboardKey.arrowDown: (_) {
            if (size2 == size) {
              size = size / 2;
            }
            return true;
          },
        },
        keyUp: {
          LogicalKeyboardKey.arrowLeft: (_) => stop(),
          LogicalKeyboardKey.arrowRight: (_) => stop(),
          LogicalKeyboardKey.arrowDown: (_) {
            size = size * 2;
            return true;
          },
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
      // game.healthBar.decrease();
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
    paint = Paint()..color = Color(0xFF6D4C41); // Brown
    anchor = Anchor.center;
  }
}

// 🔴 Obstacle
class ObstacleComponent extends RectangleComponent {
  bool hasScored = false;
  ObstacleComponent(Vector2 pos)
      : super(
          size: Vector2(20, random.decimal(scale: 60, min: 20)),
          anchor: Anchor.center,
          position: pos,
          paint: Paint()..color = random.element(Colors.primaries),
        );

  @override
  void update(double dt) {
    position.x -= 150 * dt;
    if (position.x + width < 0) removeFromParent();
  }
}
