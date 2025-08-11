import 'package:flutter/material.dart';
import 'intro_screen.dart';
import 'settings_screen.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';

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
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.8,
            colors: [
              AppTheme.backgroundSecondary,
              AppTheme.backgroundPrimary,
              const Color(0xFF000000),
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Mysterious background pattern with modern styling
            Positioned.fill(
              child: CustomPaint(
                painter: ModernMazePatterPainter(),
              ),
            ),
            
            // Animated background particles
            ...List.generate(30, (index) => _buildModernParticle(index)),
            
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
                          // Language toggle at top-right
                          Align(
                            alignment: Alignment.topRight,
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _LanguageToggle(),
                            ),
                          ),
                          
                          // Spacer to push content up slightly
                          const Spacer(flex: 2),
                          
                          // Modern game title with glass morphism
                          AnimatedBuilder(
                            animation: _pulseAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _pulseAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.mysteriousGradient,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: AppTheme.accentPrimary.withOpacity(0.3),
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.accentPrimary.withOpacity(0.3),
                                        blurRadius: 24,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 8),
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 16,
                                        spreadRadius: -4,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ShaderMask(
                                    shaderCallback: (bounds) => const LinearGradient(
                                      colors: [Colors.white, Color(0xFFE2E8F0)],
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                    ).createShader(bounds),
                                    child: Text(
                                      'MAZE REIGNS',
                                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 3.0,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Modern subtitle with animation
                          TweenAnimationBuilder<double>(
                            duration: const Duration(seconds: 2),
                            tween: Tween(begin: 0.0, end: 1.0),
                            builder: (context, value, child) {
                              return Opacity(
                                opacity: value,
                                child: Transform.translate(
                                  offset: Offset(0, 20 * (1 - value)),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 20),
                                    child: _SubtitleByLocale(),
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const Spacer(flex: 3),
                          
                          // Menu buttons
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              _buildMenuButton(
                                context,
                                _textByLocale(en: 'START', ko: '시작'),
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
                                _textByLocale(en: 'CONTINUE', ko: '이어하기'),
                                onPressed: () {
                                  // TODO: Load saved game
                                  _showComingSoon(context, _textByLocale(en: 'Loading saved game...', ko: '저장된 게임을 불러오는 중...'));
                                },
                                isEnabled: false, // Disabled until save system exists
                              ),
                              const SizedBox(height: 20),
                              _buildMenuButton(
                                context,
                                _textByLocale(en: 'SETTINGS', ko: '설정'),
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => const SettingsScreen(),
                                    ),
                                  );
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
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 200),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Container(
            width: 240,
            height: 56,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: isEnabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.backgroundSecondary.withOpacity(0.9),
                      AppTheme.backgroundTertiary.withOpacity(0.8),
                    ],
                  )
                : LinearGradient(
                    colors: [
                      AppTheme.backgroundTertiary.withOpacity(0.3),
                      AppTheme.backgroundTertiary.withOpacity(0.3),
                    ],
                  ),
              border: Border.all(
                color: isEnabled 
                  ? AppTheme.accentPrimary.withOpacity(0.4)
                  : AppTheme.borderSecondary.withOpacity(0.3),
                width: 1,
              ),
              boxShadow: isEnabled ? [
                BoxShadow(
                  color: AppTheme.accentPrimary.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: isEnabled ? onPressed : null,
                child: Container(
                  alignment: Alignment.center,
                  child: Text(
                    text,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isEnabled 
                        ? AppTheme.textPrimary
                        : AppTheme.textTertiary,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildModernParticle(int index) {
    final random = (index * 17) % 100;
    final colors = [AppTheme.accentPrimary, AppTheme.accentSecondary, AppTheme.warningColor];
    final color = colors[index % colors.length];
    
    return Positioned(
      left: (random * 3.5) % MediaQuery.of(context).size.width,
      top: (random * 7.3) % MediaQuery.of(context).size.height,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, child) {
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 2000 + (random * 10)),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeInOut,
            builder: (context, animationValue, _) {
              return Opacity(
                opacity: (0.1 + (random / 100) * 0.4) * _pulseAnimation.value * animationValue,
                child: Container(
                  width: 1 + (random % 4).toDouble(),
                  height: 1 + (random % 4).toDouble(),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withOpacity(0.8),
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.4),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              );
            },
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
        title: Text(
          _textByLocale(en: 'Coming Soon', ko: '곧 제공됩니다'),
          style: const TextStyle(color: Color(0xFFD4D4D4)),
        ),
        content: Text(
          message,
          style: const TextStyle(color: Color(0xFFB0B0B0)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              _textByLocale(en: 'OK', ko: '확인'),
              style: const TextStyle(color: Color(0xFF8B0000)),
            ),
          ),
        ],
      ),
    );
  }

  String _textByLocale({required String en, required String ko}) {
    final locale = LocaleService.instance.localeNotifier.value;
    final code = locale?.languageCode;
    if (code == 'ko') return ko;
    if (code == 'en') return en;
    // Fallback to device locale if set to system
    final platformCode = Localizations.localeOf(context).languageCode;
    return platformCode == 'ko' ? ko : en;
  }
}

// Modern maze pattern painter with gradient effects
class ModernMazePatterPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const gridSize = 50.0;
    
    // Create gradient shader for the maze lines
    final gradientShader = const LinearGradient(
      colors: [
        Color(0x10ffffff),
        Color(0x206366F1),
        Color(0x108B5CF6),
      ],
      stops: [0.0, 0.5, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    paint.shader = gradientShader;
    
    // Draw modern geometric maze pattern
    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        final seed = ((x / gridSize).floor() * 23 + (y / gridSize).floor() * 41) % 100;
        
        // Create more complex geometric patterns
        if (seed % 6 == 0) {
          // Horizontal line with rounded ends
          final path = Path()
            ..moveTo(x + 5, y)
            ..lineTo(x + gridSize - 5, y);
          canvas.drawPath(path, paint);
        }
        
        if (seed % 5 == 0) {
          // Vertical line with rounded ends
          final path = Path()
            ..moveTo(x, y + 5)
            ..lineTo(x, y + gridSize - 5);
          canvas.drawPath(path, paint);
        }
        
        if (seed % 8 == 0) {
          // Corner arcs for more organic feel
          final rect = Rect.fromLTWH(x, y, gridSize * 0.3, gridSize * 0.3);
          canvas.drawArc(rect, 0, 1.57, false, paint);
        }
      }
    }
    
    // Add subtle radial gradient overlay
    final overlayPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.0, -0.3),
        radius: 1.2,
        colors: [
          Colors.transparent,
          AppTheme.accentPrimary.withOpacity(0.02),
          AppTheme.backgroundPrimary.withOpacity(0.1),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      overlayPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _LanguageToggle extends StatelessWidget {
  final LocaleService _localeService = LocaleService.instance;

  _LanguageToggle();

  @override
  Widget build(BuildContext context) {
    final current = _localeService.localeNotifier.value;
    final isKo = (current?.languageCode ?? Localizations.localeOf(context).languageCode) == 'ko';
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildChip(context, label: 'EN', selected: !isKo, onTap: () => _localeService.setLocale(const Locale('en'))),
          _buildChip(context, label: 'KO', selected: isKo, onTap: () => _localeService.setLocale(const Locale('ko'))),
        ],
      ),
    );
  }

  Widget _buildChip(BuildContext context, {required String label, required bool selected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.white.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                letterSpacing: 1.2,
              ),
        ),
      ),
    );
  }
}

class _SubtitleByLocale extends StatelessWidget {
  final LocaleService _localeService = LocaleService.instance;

  _SubtitleByLocale();

  @override
  Widget build(BuildContext context) {
    final locale = _localeService.localeNotifier.value ?? Localizations.localeOf(context);
    final isKo = locale.languageCode == 'ko';
    final text = isKo
        ? '끝없는 미궁에서 운명을 선택하세요'
        : 'Choose your fate in the endless labyrinth';
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            fontStyle: FontStyle.italic,
            color: AppTheme.textSecondary,
            height: 1.4,
          ),
      textAlign: TextAlign.center,
    );
  }
}