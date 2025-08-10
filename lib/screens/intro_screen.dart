import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'game_screen.dart';
import 'game_loading_screen.dart';
import '../services/game_manager.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  Map<String, dynamic>? introData;
  int currentSceneIndex = 0;
  bool isLoading = true;
  String? currentText;
  bool isTypewriterComplete = false;
  
  @override
  void initState() {
    super.initState();
    
    _textController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _fadeController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    _loadIntroData();
    // Start game initialization in background during intro
    GameManager().initializeGame();
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _fadeController.dispose();
    super.dispose();
  }
  
  Future<void> _loadIntroData() async {
    try {
      final String jsonString = await rootBundle.loadString('data/intro.json');
      final data = json.decode(jsonString);
      setState(() {
        introData = data;
        isLoading = false;
      });
      _startCurrentScene();
    } catch (e) {
      print('Error loading intro data: $e');
      setState(() {
        isLoading = false;
      });
    }
  }
  
  void _startCurrentScene() {
    if (introData == null) return;
    
    final scenes = introData!['introSequence']['scenes'] as List;
    if (currentSceneIndex >= scenes.length) return;
    
    final currentScene = scenes[currentSceneIndex];
    final textStyle = currentScene['textStyle'] as Map<String, dynamic>;
    final animation = textStyle['animation'] as String;
    
    setState(() {
      currentText = currentScene['text'] as String;
      isTypewriterComplete = false;
    });
    
    _textController.reset();
    _fadeController.reset();
    
    if (animation == 'typewriter') {
      _textController.forward();
    } else if (animation == 'fadeIn') {
      _fadeController.forward();
    }
  }
  
  void _nextScene() {
    if (introData == null) return;
    
    final scenes = introData!['introSequence']['scenes'] as List;
    if (currentSceneIndex < scenes.length - 1) {
      setState(() {
        currentSceneIndex++;
      });
      _startCurrentScene();
    } else {
      _endIntro();
    }
  }
  
  void _skipIntro() {
    _endIntro();
  }
  
  void _endIntro() {
    // Check if game is ready, show loading if not
    if (!GameManager().isInitialized) {
      _showLoadingScreen();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const GameScreen(),
        ),
      );
    }
  }

  void _showLoadingScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const GameLoadingScreen(),
      ),
    );
  }
  
  void _showComingSoon(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Coming Soon',
          style: TextStyle(color: Color(0xFFD4D4D4)),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop(); // Return to main menu
            },
            child: const Text(
              'Back to Menu',
              style: TextStyle(color: Color(0xFF8B0000)),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildImagePlaceholder(String? imagePath) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF2A2A2A),
            const Color(0xFF0A0A0A),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Placeholder pattern
          CustomPaint(
            painter: IntroBackgroundPainter(),
            size: Size.infinite,
          ),
          // Image indicator
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.image_outlined,
                  size: 80,
                  color: const Color(0xFF8B0000).withOpacity(0.3),
                ),
                const SizedBox(height: 20),
                Text(
                  imagePath ?? 'No image specified',
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
  
  Widget _buildAnimatedText(String text, Map<String, dynamic> textStyle) {
    final animation = textStyle['animation'] as String;
    final color = _getTextColor(textStyle['color'] as String);
    final fontSize = _getFontSize(textStyle['size'] as String);
    
    if (animation == 'typewriter') {
      return AnimatedBuilder(
        animation: _textController,
        builder: (context, child) {
          final int textLength = (text.length * _textController.value).round();
          final displayText = text.substring(0, textLength);
          
          if (textLength >= text.length && !isTypewriterComplete) {
            Future.delayed(Duration.zero, () {
              setState(() {
                isTypewriterComplete = true;
              });
            });
          }
          
          return Text(
            displayText,
            style: TextStyle(
              color: color,
              fontSize: fontSize,
              height: 1.5,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.7),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          );
        },
      );
    } else if (animation == 'fadeIn') {
      return FadeTransition(
        opacity: _fadeAnimation,
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            height: 1.5,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 3,
                color: Colors.black.withOpacity(0.7),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }
  
  Color _getTextColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'white':
        return const Color(0xFFE0E0E0);
      case 'yellow':
        return const Color(0xFFFFD700);
      case 'red':
        return const Color(0xFF8B0000);
      default:
        return const Color(0xFFE0E0E0);
    }
  }
  
  double _getFontSize(String size) {
    switch (size.toLowerCase()) {
      case 'small':
        return 16.0;
      case 'large':
        return 24.0;
      case 'xlarge':
        return 32.0;
      default:
        return 20.0;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B0000),
          ),
        ),
      );
    }
    
    if (introData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: const Center(
          child: Text(
            'Failed to load intro data',
            style: TextStyle(color: Color(0xFFE0E0E0)),
          ),
        ),
      );
    }
    
    final scenes = introData!['introSequence']['scenes'] as List;
    if (currentSceneIndex >= scenes.length) {
      _endIntro();
      return const SizedBox.shrink();
    }
    
    final currentScene = scenes[currentSceneIndex];
    final backgroundImage = currentScene['background'] as String?;
    final text = currentScene['text'] as String;
    final textStyle = currentScene['textStyle'] as Map<String, dynamic>;
    
    return Scaffold(
      body: Stack(
        children: [
          // Background image or placeholder
          Positioned.fill(
            child: _buildImagePlaceholder(backgroundImage),
          ),
          
          // Skip button
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            right: 20,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: _skipIntro,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF8B0000).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: const Text(
                    'SKIP',
                    style: TextStyle(
                      color: Color(0xFFE0E0E0),
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Main content area
          Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 600),
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
              child: currentText != null
                  ? _buildAnimatedText(currentText!, textStyle)
                  : const SizedBox.shrink(),
            ),
          ),
          
          // Next button
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 40,
            right: 40,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(30),
                onTap: () {
                  final animation = textStyle['animation'] as String;
                  if (animation == 'typewriter' && !isTypewriterComplete) {
                    // Skip typewriter animation
                    _textController.forward();
                    setState(() {
                      isTypewriterComplete = true;
                    });
                  } else {
                    _nextScene();
                  }
                },
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: const Color(0xFF8B0000).withOpacity(0.7),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.arrow_forward_rounded,
                    color: Color(0xFFE0E0E0),
                    size: 28,
                  ),
                ),
              ),
            ),
          ),
          
          // Scene progress indicator
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 20,
            child: Row(
              children: scenes.asMap().entries.map((entry) {
                final index = entry.key;
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: index <= currentSceneIndex
                        ? const Color(0xFF8B0000)
                        : const Color(0xFF333333),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for intro background pattern
class IntroBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B0000).withOpacity(0.03)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const gridSize = 60.0;
    
    // Draw subtle atmospheric pattern
    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        final seed = ((x / gridSize).floor() * 23 + (y / gridSize).floor() * 41) % 100;
        
        if (seed % 7 == 0) {
          // Draw subtle squares
          canvas.drawRect(
            Rect.fromLTWH(x, y, gridSize * 0.3, gridSize * 0.3),
            paint,
          );
        }
        if (seed % 11 == 0) {
          // Draw subtle circles
          canvas.drawCircle(
            Offset(x + gridSize * 0.5, y + gridSize * 0.5),
            gridSize * 0.1,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}