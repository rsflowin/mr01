import 'package:flutter/material.dart';
import 'intro_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );
    
    _pulseController = AnimationController(
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

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF1A1A1A),
              Color(0xFF0A0A0A),
              Color(0xFF000000),
            ],
            stops: [0.0, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Mysterious background pattern
            Positioned.fill(
              child: CustomPaint(
                painter: MazePatterPainter(),
              ),
            ),
            
            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Spacer to push content up slightly
                          const Spacer(flex: 2),
                          
                          // Game Title with mysterious styling
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 10,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: const Color(0xFF8B0000).withOpacity(0.3),
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF8B0000).withOpacity(0.2),
                                        blurRadius: 20,
                                        spreadRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    'MAZE REIGNS',
                                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                      fontSize: 36,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4.0,
                                      shadows: [
                                        const Shadow(
                                          offset: Offset(2, 2),
                                          blurRadius: 8,
                                          color: Color(0xFF8B0000),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Subtitle
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Choose your fate in the endless labyrinth',
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 16,
                                fontStyle: FontStyle.italic,
                                color: const Color(0xFF888888),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          
                          const Spacer(flex: 3),
                          
                          // Menu buttons
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildMenuButton(
                                context,
                                'START',
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const IntroScreen(),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildMenuButton(
                                context,
                                'CONTINUE',
                                onPressed: () {
                                  // TODO: Load saved game
                                  _showComingSoon(context, 'Loading saved game...');
                                },
                                isEnabled: false, // Disabled until save system exists
                              ),
                              const SizedBox(height: 20),
                              _buildMenuButton(
                                context,
                                'SETTINGS',
                                onPressed: () {
                                  // TODO: Navigate to settings
                                  _showComingSoon(context, 'Opening settings...');
                                },
                              ),
                            ],
                          ),
                          
                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            // Atmospheric particles/dots
            ...List.generate(20, (index) => _buildFloatingParticle(index)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String text, {
    required VoidCallback onPressed,
    bool isEnabled = true,
  }) {
    return Container(
      width: 200,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isEnabled 
            ? const Color(0xFF8B0000).withOpacity(0.6)
            : const Color(0xFF444444),
          width: 2,
        ),
        gradient: isEnabled
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2A2A2A).withOpacity(0.8),
                const Color(0xFF1A1A1A).withOpacity(0.9),
              ],
            )
          : null,
        color: isEnabled ? null : const Color(0xFF1A1A1A).withOpacity(0.3),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(25),
          onTap: isEnabled ? onPressed : null,
          child: Container(
            alignment: Alignment.center,
            child: Text(
              text,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isEnabled 
                  ? const Color(0xFFD4D4D4)
                  : const Color(0xFF666666),
                letterSpacing: 2.0,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingParticle(int index) {
    final random = (index * 17) % 100;
    return Positioned(
      left: (random * 3.5) % MediaQuery.of(context).size.width,
      top: (random * 7.3) % MediaQuery.of(context).size.height,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return Opacity(
            opacity: (0.1 + (random / 100) * 0.3) * _pulseAnimation.value,
            child: Container(
              width: 2 + (random % 3),
              height: 2 + (random % 3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF8B0000).withOpacity(0.6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF8B0000).withOpacity(0.3),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showComingSoon(BuildContext context, String message) {
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
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'OK',
              style: TextStyle(color: Color(0xFF8B0000)),
            ),
          ),
        ],
      ),
    );
  }
}

// Custom painter for mysterious background maze pattern
class MazePatterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B0000).withOpacity(0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const gridSize = 40.0;
    
    // Draw subtle maze-like grid pattern
    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        // Random maze-like pattern
        final seed = ((x / gridSize).floor() * 17 + (y / gridSize).floor() * 31) % 100;
        
        if (seed % 4 == 0) {
          // Horizontal line
          canvas.drawLine(
            Offset(x, y),
            Offset(x + gridSize, y),
            paint,
          );
        }
        if (seed % 3 == 0) {
          // Vertical line
          canvas.drawLine(
            Offset(x, y),
            Offset(x, y + gridSize),
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}