import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

enum Direction { up, down, left, right }

class SnakeGameApp extends StatefulWidget {
  const SnakeGameApp({super.key});

  @override
  State<SnakeGameApp> createState() => _SnakeGameAppState();
}

class _SnakeGameAppState extends State<SnakeGameApp> {
  static const int rows = 20;
  static const int columns = 20;

  List<Point<int>> snake = [
    const Point(10, 10),
    const Point(10, 11),
    const Point(10, 12),
  ];
  Point<int> food = const Point(5, 5);
  Direction direction = Direction.up;
  List<Direction> directionQueue = [];
  bool isPlaying = false;
  bool isGameOver = false;
  int score = 0;
  Timer? timer;
  final FocusNode _focusNode = FocusNode();
  Offset? _panStart;

  @override
  void initState() {
    super.initState();
    _spawnFood();
  }

  @override
  void dispose() {
    timer?.cancel();
    _focusNode.dispose();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      isPlaying = true;
      isGameOver = false;
      score = 0;
      snake = [
        const Point(10, 10),
        const Point(10, 11),
        const Point(10, 12),
      ];
      direction = Direction.up;
      directionQueue.clear();
      _spawnFood();
    });
    timer?.cancel();
    timer = Timer.periodic(const Duration(milliseconds: 200), (Timer t) {
      _moveSnake();
    });
    _focusNode.requestFocus();
  }

  void _spawnFood() {
    final random = Random();
    Point<int> newFood;
    do {
      newFood = Point(random.nextInt(columns), random.nextInt(rows));
    } while (snake.contains(newFood));
    food = newFood;
  }

  void _moveSnake() {
    if (directionQueue.isNotEmpty) {
      direction = directionQueue.removeAt(0);
    }
    
    Point<int> newHead;
    switch (direction) {
      case Direction.up:
        newHead = Point(snake.first.x, snake.first.y - 1);
        break;
      case Direction.down:
        newHead = Point(snake.first.x, snake.first.y + 1);
        break;
      case Direction.left:
        newHead = Point(snake.first.x - 1, snake.first.y);
        break;
      case Direction.right:
        newHead = Point(snake.first.x + 1, snake.first.y);
        break;
    }

    if (newHead.x < 0 ||
        newHead.x >= columns ||
        newHead.y < 0 ||
        newHead.y >= rows ||
        snake.contains(newHead)) {
      _gameOver();
      return;
    }

    setState(() {
      snake.insert(0, newHead);
      if (newHead == food) {
        score += 10;
        _spawnFood();
      } else {
        snake.removeLast();
      }
    });
  }

  void _gameOver() {
    timer?.cancel();
    setState(() {
      isPlaying = false;
      isGameOver = true;
    });
  }

  void _queueDirection(Direction dir) {
    final lastDir = directionQueue.isNotEmpty ? directionQueue.last : direction;
    if (dir == Direction.up && lastDir != Direction.down && lastDir != Direction.up) {
      directionQueue.add(dir);
    } else if (dir == Direction.down && lastDir != Direction.up && lastDir != Direction.down) {
      directionQueue.add(dir);
    } else if (dir == Direction.left && lastDir != Direction.right && lastDir != Direction.left) {
      directionQueue.add(dir);
    } else if (dir == Direction.right && lastDir != Direction.left && lastDir != Direction.right) {
      directionQueue.add(dir);
    }
  }

  void _handleKey(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.keyW) {
        _queueDirection(Direction.up);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown || event.logicalKey == LogicalKeyboardKey.keyS) {
        _queueDirection(Direction.down);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft || event.logicalKey == LogicalKeyboardKey.keyA) {
        _queueDirection(Direction.left);
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight || event.logicalKey == LogicalKeyboardKey.keyD) {
        _queueDirection(Direction.right);
      }
    }
  }

  void _handlePanStart(DragStartDetails details) {
    _panStart = details.localPosition;
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    if (_panStart == null) return;
    
    final dx = details.localPosition.dx - _panStart!.dx;
    final dy = details.localPosition.dy - _panStart!.dy;
    
    if (dx.abs() < 20 && dy.abs() < 20) return;

    if (dx.abs() > dy.abs()) {
      if (dx > 0) {
        _queueDirection(Direction.right);
      } else {
        _queueDirection(Direction.left);
      }
    } else {
      if (dy > 0) {
        _queueDirection(Direction.down);
      } else {
        _queueDirection(Direction.up);
      }
    }
    
    _panStart = details.localPosition;
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKey,
      child: GestureDetector(
        onTap: () => _focusNode.requestFocus(),
        child: Container(
          color: const Color(0xFF1E1E1E),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Score: $score',
                      style: GoogleFonts.firaCode(
                        color: Colors.purpleAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isPlaying && !isGameOver)
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Start Game', style: GoogleFonts.firaCode(fontWeight: FontWeight.bold)),
                      )
                    else if (isGameOver)
                      ElevatedButton(
                        onPressed: _startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.redAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: Text('Play Again', style: GoogleFonts.firaCode(fontWeight: FontWeight.bold)),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: GestureDetector(
                      onPanStart: _handlePanStart,
                      onPanUpdate: _handlePanUpdate,
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.purple, width: 2),
                          color: Colors.black,
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final cellSize = constraints.maxWidth / columns;
                            return Stack(
                              children: [
                                // Draw Food
                                Positioned(
                                  left: food.x * cellSize,
                                  top: food.y * cellSize,
                                  width: cellSize,
                                  height: cellSize,
                                  child: Container(
                                    margin: const EdgeInsets.all(2),
                                    decoration: BoxDecoration(
                                      color: Colors.redAccent,
                                      borderRadius: BorderRadius.circular(cellSize / 2),
                                    ),
                                  ),
                                ),
                                // Draw Snake
                                ...snake.map((p) {
                                  final isHead = p == snake.first;
                                  return Positioned(
                                    left: p.x * cellSize,
                                    top: p.y * cellSize,
                                    width: cellSize,
                                    height: cellSize,
                                    child: Container(
                                      margin: const EdgeInsets.all(1),
                                      decoration: BoxDecoration(
                                        color: isHead ? Colors.purpleAccent : Colors.purple,
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  );
                                }),
                                if (isGameOver)
                                  Center(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      color: Colors.black87,
                                      child: Text(
                                        'GAME OVER',
                                        style: GoogleFonts.firaCode(
                                          color: Colors.redAccent,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
