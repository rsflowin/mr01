import 'package:flutter/material.dart';
import 'dart:math';
import '../services/game_manager.dart';
import 'game_screen.dart';

class GameLoadingScreen extends StatefulWidget {
  const GameLoadingScreen({super.key});

  @override
  State<GameLoadingScreen> createState() => _GameLoadingScreenState();
}

class _GameLoadingScreenState extends State<GameLoadingScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    
    _spinController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);
    
    _checkGameInitialization();
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _checkGameInitialization() async {
    // Poll game manager until initialized
    while (!GameManager().isInitialized) {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
    }
    
    // Wait a moment to show completion
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (!mounted) return;
    
    // Navigate to game screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const GameScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: LoadingBackgroundPainter(),
            ),
          ),
          
          // Main loading content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Spinning maze icon
                AnimatedBuilder(
                  animation: _spinController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _spinController.value * 2 * pi,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFF8B0000).withOpacity(0.8),
                            width: 2,
                          ),
                        ),
                        child: CustomPaint(
                          painter: MazeCellPainter(),
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                // Pulsing loading text
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, child) {
                    final opacity = 0.5 + (_pulseController.value * 0.5);
                    return Text(
                      '미로를 준비하고 있습니다...',
                      style: TextStyle(
                        color: Color(0xFFE0E0E0).withOpacity(opacity),
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                      ),
                      textAlign: TextAlign.center,
                    );
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Loading progress indicator
                Container(
                  width: 200,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF333333),
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: 0.3 + (_pulseController.value * 0.7),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B0000),
                            borderRadius: BorderRadius.circular(1),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Loading status text
                Text(
                  GameManager().isInitializing 
                      ? '게임 데이터 로딩 중...' 
                      : '초기화 완료',
                  style: TextStyle(
                    color: const Color(0xFF666666),
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for loading background
class LoadingBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B0000).withOpacity(0.02)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const spacing = 40.0;
    
    // Draw subtle grid pattern
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        paint,
      );
    }
    
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for maze cell icon
class MazeCellPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B0000).withOpacity(0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final cellSize = size.width / 3;
    
    // Draw a simple 3x3 maze pattern
    for (int y = 0; y < 3; y++) {
      for (int x = 0; x < 3; x++) {
        final rect = Rect.fromLTWH(
          x * cellSize,
          y * cellSize,
          cellSize,
          cellSize,
        );
        
        canvas.drawRect(rect, paint);
        
        // Add some random internal lines for maze effect
        if ((x + y) % 2 == 0) {
          canvas.drawLine(
            Offset(rect.left, rect.center.dy),
            Offset(rect.right, rect.center.dy),
            paint,
          );
        } else {
          canvas.drawLine(
            Offset(rect.center.dx, rect.top),
            Offset(rect.center.dx, rect.bottom),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}