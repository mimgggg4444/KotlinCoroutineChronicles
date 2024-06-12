import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:trex/game/game_config.dart';
import 'package:trex/game/game_over/config.dart';
import 'package:trex/game/game_over/game_over.dart';
import 'package:trex/game/horizon/horizon.dart';
import 'package:trex/game/obstacle/obstacle.dart';
import 'package:trex/game/t_rex/t_rex.dart';

import 'collision/collision_utils.dart';

class Bg extends Component with HasGameRef {


  Vector2 size = Vector2.zero();

  late final ui.Paint _paint = ui.Paint()..color = const ui.Color(0xffffffff);

  @override
  void render(ui.Canvas c) {
    final rect = ui.Rect.fromLTWH(0, 0, size.x, size.y);
    c.drawRect(rect, _paint);
  }

  @override
  void onGameResize(Vector2 gameSize) {
    size = gameSize;
  }
}

enum TRexGameStatus { playing, waiting, gameOver }

class TRexGame extends FlameGame with TapDetector {
  TRexGame({
    required this.spriteImage,
  }) : super();

  late final config = GameConfig();

  // 아이템 생성 관련 변수 추가
  double itemTimer = 0;

  @override
  ui.Color backgroundColor() => const ui.Color(0xFFFFFFFF);

  final ui.Image spriteImage;

  /// children
  late final tRex = TRex();
  late final horizon = Horizon();
  late final gameOverPanel = GameOverPanel(spriteImage, GameOverConfig());

  @override
  Future<void> onLoad() async {
    add(Bg());
    add(horizon);
    add(tRex);
    add(gameOverPanel);
  }

  // state
  late TRexGameStatus status = TRexGameStatus.waiting;
  late double currentSpeed = 0.0;
  late double timePlaying = 0.0;

  bool get playing => status == TRexGameStatus.playing;

  bool get gameOver => status == TRexGameStatus.gameOver;

  @override
  void onTapDown(TapDownInfo event) {
    if (gameOver) {
      restart();
      return;
    }

    // 아이템 클릭 시 무적 상태 활성화
    if (tRex.hasItem && event.raw.globalPosition.dx >= tRex.x && event.raw.globalPosition.dx <= tRex.x + tRex.config.width &&
        event.raw.globalPosition.dy >= tRex.y && event.raw.globalPosition.dy <= tRex.y + tRex.config.height) {
      tRex.activateInvincibility();
    } else {
      tRex.startJump(currentSpeed);
    }
  }


  void onAction() {
    if (gameOver) {
      restart();
      return;
    }
    tRex.startJump(currentSpeed);
  }

  void startGame() {
    tRex.status = TRexStatus.running;
    status = TRexGameStatus.playing;
    tRex.hasPlayedIntro = true;
    currentSpeed = config.speed;
  }

  void doGameOver() {
    gameOverPanel.visible = true;
    status = TRexGameStatus.gameOver;
    tRex.status = TRexStatus.crashed;
    currentSpeed = 0.0;
  }

  void restart() {
    status = TRexGameStatus.playing;
    tRex.reset();
    horizon.reset();
    currentSpeed = config.speed;
    gameOverPanel.visible = false;
    timePlaying = 0.0;
  }



  // 게임 속도 관련 함수
  @override
  void update(double dt) {

    // 일정 시간마다 아이템 생성
    itemTimer += dt;
    if (itemTimer >= 20) { // 20초마다 아이템 생성
      tRex.getItem();
      itemTimer = 0;
    }

    super.update(dt);

    if (gameOver) {
      return;
    }

    if (tRex.playingIntro && tRex.x >= tRex.config.startXPos) {
      startGame();
    } else if (tRex.playingIntro) {}

    if (playing) {
      timePlaying += dt;

      final obstacles = horizon.horizonLine.obstacleManager.children;
      final hasCollision = obstacles.isNotEmpty &&
          checkForCollision(obstacles.first as Obstacle, tRex);
      if (!hasCollision) {
        if (currentSpeed < config.maxSpeed) {
          currentSpeed += config.acceleration;
        }
      } else {
        doGameOver();
      }
    }
  }
}
