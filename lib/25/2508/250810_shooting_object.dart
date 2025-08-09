import 'dart:async';
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame_tiled/flame_tiled.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(
    GameWidget(
      game: TiledGame()..debugMode = true,
    ),
  );
}

class TiledGame extends FlameGame with HasKeyboardHandlerComponents {
  late TiledComponent tiled;
  late Player player;
  @override
  FutureOr<void> onLoad() async {
    tiled = await TiledComponent.load(
      'level_1.tmx',
      Vector2.all(32),
    );
    await add(tiled);
    player = Player();

    final spawnpoints = tiled.tileMap.getLayer<ObjectGroup>('spawnpoints');
    for (final spawnpoint in spawnpoints!.objects) {
      player.position = spawnpoint.position;
    }
    add(player);
  }
}

class Player extends MaterialIconComponent
    with KeyboardHandler, HasGameReference<TiledGame> {
  Player() : super(icon: Icons.ios_share);
  @override
  FutureOr<void> onLoad() {
    anchor = Anchor.center;
  }

  @override
  bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
    if (keysPressed.contains(LogicalKeyboardKey.arrowLeft)) {
      moveLeft();
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowRight)) {
      moveRight();
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowUp)) {
      moveUp();
    } else if (keysPressed.contains(LogicalKeyboardKey.arrowDown)) {
      moveDown();
    } else if (keysPressed.contains(LogicalKeyboardKey.space)) {
      shoot();
    }
    return true;
  }

  void moveUp() {
    position.y -= 10;
    angle = 0;
  }

  void moveDown() {
    position.y += 10;
    angle = pi;
  }

  void moveRight() {
    position.x += 10;
    angle = pi / 2;
  }

  void moveLeft() {
    position.x -= 10;
    angle = -pi / 2;
  }

  void shoot() {
    game.add(
      Shoot(
        position: position.clone(),
        direction: ShootDirection.random,
      ),
    );
  }
}

enum ShootDirection {
  up,
  down,
  left,
  right;

  static ShootDirection get random =>
      ShootDirection.values[Random().nextInt(ShootDirection.values.length)];
}

class Shoot extends MaterialIconComponent {
  Shoot({
    super.position,
    required this.direction,
  }) : super(icon: Icons.bolt);
  ShootDirection direction;
  @override
  void update(double dt) {
    switch (direction) {
      case ShootDirection.up:
        position.y -= position.y * dt * 10;
      case ShootDirection.down:
        position.y += position.y * dt * 10;
      case ShootDirection.left:
        position.x -= position.x * dt * 10;
      case ShootDirection.right:
        position.x += position.x * dt * 10;
    }
  }
}

class MaterialIconComponent extends PositionComponent {
  IconData icon;
  late TextPainter tp;

  MaterialIconComponent({
    required this.icon,
    super.position,
    double size = 48,
  }) {
    tp = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          fontSize: size,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
  }
  @override
  void render(Canvas canvas) {
    tp.layout();
    tp.paint(canvas, Offset.zero);
  }
}

// final _rand = Random();

// class FlappyBirdGame extends FlameGame
//     with HasKeyboardHandlerComponents, HasCollisionDetection {
//   static const double pillarSpeed = -150;
//   static const double gravity = 500;
//   static const double jumpForce = -250;

//   late BirdComponent bird;
//   late ScoreText scoreText;
//   int score = 0;
//   int lives = 3;

//   @override
//   FutureOr<void> onLoad() async {
//     add(ParallaxBackground());
//     add(PlatformComponent());

//     bird = BirdComponent();
//     add(bird);

//     scoreText = ScoreText();
//     add(scoreText);

//     // Spawn pillars every 2.5 seconds
//     add(
//       TimerComponent(
//         period: 2.5,
//         repeat: true,
//         onTick: () => spawnPillars(),
//       ),
//     );
//   }

//   void spawnPillars() {
//     const gapHeight = 140.0;
//     final minPillarHeight = 40.0;
//     final maxPillarHeight = size.y - gapHeight - minPillarHeight;

//     final topHeight = _rand.nextDouble() * (maxPillarHeight - minPillarHeight) +
//         minPillarHeight;
//     final bottomHeight = size.y - gapHeight - topHeight;

//     // Top pillar
//     add(PillarComponent(
//       size: Vector2(30, topHeight),
//       position: Vector2(size.x, 0),
//     ));

//     // Bottom pillar
//     add(PillarComponent(
//       size: Vector2(30, bottomHeight),
//       position: Vector2(size.x, topHeight + gapHeight),
//     ));
//   }

//   void addScore() {
//     score++;
//     scoreText.updateScore(score);
//   }

//   void loseLife() {
//     lives--;
//     if (lives <= 0) {
//       overlays.add('GameOver');
//       pauseEngine();
//     }
//   }
// }

// class BirdComponent extends PositionComponent
//     with KeyboardHandler, CollisionCallbacks, HasGameReference<FlappyBirdGame> {
//   double velocityY = 0;

//   BirdComponent() {
//     size = Vector2(40, 40);
//     position = Vector2(80, 200);
//   }

//   @override
//   FutureOr<void> onLoad() {
//     add(RectangleComponent(size: size, paint: Paint()..color = Colors.blue));

//     add(TextComponent(
//       text: 'F',
//       anchor: Anchor.center,
//       position: size / 2,
//       textRenderer: TextPaint(
//         style: const TextStyle(color: Colors.white, fontSize: 20),
//       ),
//     ));

//     add(RectangleHitbox());
//   }

//   @override
//   void update(double dt) {
//     super.update(dt);

//     velocityY += FlappyBirdGame.gravity * dt;
//     position.y += velocityY * dt;

//     if (position.y + size.y > game.size.y) {
//       position.y = game.size.y - size.y;
//       velocityY = 0;
//     }
//   }

//   @override
//   bool onKeyEvent(KeyEvent event, Set<LogicalKeyboardKey> keysPressed) {
//     if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.space) {
//       velocityY = FlappyBirdGame.jumpForce;
//       return true;
//     }
//     return false;
//   }

//   @override
//   void onCollisionStart(
//       Set<Vector2> intersectionPoints, PositionComponent other) {
//     if (other is PillarComponent || other is PlatformComponent) {
//       game.loseLife();
//     }
//     super.onCollisionStart(intersectionPoints, other);
//   }
// }

// class PillarComponent extends RectangleComponent
//     with CollisionCallbacks, HasGameReference<FlappyBirdGame> {
//   PillarComponent({super.size, super.position}) {
//     paint = Paint()..color = Colors.green;
//   }

//   @override
//   FutureOr<void> onLoad() {
//     add(RectangleHitbox());
//   }

//   @override
//   void update(double dt) {
//     super.update(dt);
//     position.x += FlappyBirdGame.pillarSpeed * dt;

//     if (position.x + size.x < 0) {
//       removeFromParent();
//       game.addScore();
//     }
//   }
// }

// class PlatformComponent extends RectangleComponent
//     with CollisionCallbacks, HasGameReference<FlappyBirdGame> {
//   PlatformComponent() {
//     // ignore: unused_local_variable
//     const platformHeight = 20.0;
//     size = Vector2.zero(); // will set onLoad
//   }

//   @override
//   FutureOr<void> onLoad() {
//     size = Vector2(game.size.x, 20);
//     position = Vector2(0, game.size.y - 20);
//     paint = Paint()..color = Colors.red;
//     add(RectangleHitbox());
//   }
// }

// class ParallaxBackground extends Component {
//   @override
//   FutureOr<void> onLoad() async {
//     // parallax = await game.loadParallax(
//     //   [
//     //     ParallaxImageData('bg_layer1.png'),
//     //     ParallaxImageData('bg_layer2.png'),
//     //   ],
//     //   baseVelocity: Vector2(20, 0),
//     //   velocityMultiplierDelta: Vector2(1.5, 0),
//     // );
//   }
// }

// class ScoreText extends TextComponent with HasGameReference<FlappyBirdGame> {
//   ScoreText() {
//     anchor = Anchor.topCenter;
//     // positionType = PositionType.viewport;
//     position = Vector2(0, 20);
//     textRenderer = TextPaint(
//       style: const TextStyle(
//         fontSize: 36,
//         fontWeight: FontWeight.bold,
//         color: Colors.black,
//       ),
//     );
//     text = 'Score: 0  Lives: 3';
//   }

//   void updateScore(int score) {
//     text = 'Score: $score  Lives: ${game.lives}';
//   }
// }
