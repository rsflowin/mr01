import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../theme/app_theme.dart';
import '../models/maze_model.dart';
import '../widgets/modern_game_ui.dart';
import '../services/locale_service.dart';

class MazeMapScreen extends StatefulWidget {
  final MazeData mazeData;
  final int currentX;
  final int currentY;
  final Set<String> visitedRooms;
  final VoidCallback? onClose;

  const MazeMapScreen({
    super.key,
    required this.mazeData,
    required this.currentX,
    required this.currentY,
    required this.visitedRooms,
    this.onClose,
  });

  @override
  State<MazeMapScreen> createState() => _MazeMapScreenState();
}

class _MazeMapScreenState extends State<MazeMapScreen>
    with TickerProviderStateMixin {
  late AnimationController _mapController;
  late AnimationController _pulseController;
  late Animation<double> _mapAnimation;
  late Animation<double> _pulseAnimation;
  
  final LocaleService _localeService = LocaleService.instance;
  double _mapScale = 1.0;
  Offset _mapOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    
    _mapController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _mapAnimation = CurvedAnimation(
      parent: _mapController,
      curve: Curves.easeOutCubic,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _mapController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _mapController.dispose();
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
        child: SafeArea(
          child: Column(
            children: [
              // Header
              ModernGameHeader(
                title: _textByLocale(en: 'Maze Map', ko: '미로 지도'),
                subtitle: _textByLocale(
                  en: 'Current: (${widget.currentX}, ${widget.currentY})',
                  ko: '현재 위치: (${widget.currentX}, ${widget.currentY})',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _resetMapView,
                      icon: const Icon(
                        Icons.center_focus_strong,
                        color: AppTheme.textPrimary,
                      ),
                      tooltip: _textByLocale(en: 'Center on player', ko: '플레이어 중심으로'),
                    ),
                    IconButton(
                      onPressed: widget.onClose ?? () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              // Map Content
              Expanded(
                child: AnimatedBuilder(
                  animation: _mapAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _mapAnimation.value,
                      child: Opacity(
                        opacity: _mapAnimation.value,
                        child: _buildInteractiveMap(),
                      ),
                    );
                  },
                ),
              ),

              // Map Controls and Legend
              _buildMapControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveMap() {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 3.0,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: CustomPaint(
          painter: ModernMazePainter(
            mazeData: widget.mazeData,
            currentX: widget.currentX,
            currentY: widget.currentY,
            visitedRooms: widget.visitedRooms,
            pulseAnimation: _pulseAnimation,
          ),
        ),
      ),
    );
  }

  Widget _buildMapControls() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary.withOpacity(0.9),
        border: Border(
          top: BorderSide(
            color: AppTheme.borderSecondary.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Legend
          Row(
            children: [
              Text(
                _textByLocale(en: 'Legend:', ko: '범례:'),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _buildLegendItem(
                      color: AppTheme.accentPrimary,
                      label: _textByLocale(en: 'Current', ko: '현재'),
                      icon: Icons.my_location,
                    ),
                    _buildLegendItem(
                      color: AppTheme.textSecondary,
                      label: _textByLocale(en: 'Visited', ko: '방문함'),
                      icon: Icons.check_circle_outline,
                    ),
                    _buildLegendItem(
                      color: AppTheme.successColor,
                      label: _textByLocale(en: 'Start', ko: '시작'),
                      icon: Icons.flag_circle,
                    ),
                    _buildLegendItem(
                      color: AppTheme.warningColor,
                      label: _textByLocale(en: 'Exit', ko: '출구'),
                      icon: Icons.exit_to_app,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatChip(
                _textByLocale(en: 'Explored', ko: '탐험'),
                '${widget.visitedRooms.length}/64',
                AppTheme.accentSecondary,
              ),
              _buildStatChip(
                _textByLocale(en: 'Progress', ko: '진행률'),
                '${((widget.visitedRooms.length / 64) * 100).round()}%',
                AppTheme.successColor,
              ),
              _buildStatChip(
                _textByLocale(en: 'Size', ko: '크기'),
                '8x8',
                AppTheme.textSecondary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem({
    required Color color,
    required String label,
    required IconData icon,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  void _resetMapView() {
    setState(() {
      _mapScale = 1.0;
      _mapOffset = Offset.zero;
    });
  }

  String _textByLocale({required String en, required String ko}) {
    final locale = _localeService.localeNotifier.value;
    final code = locale?.languageCode;
    if (code == 'ko') return ko;
    if (code == 'en') return en;
    // Fallback to device locale if set to system
    final platformCode = Localizations.localeOf(context).languageCode;
    return platformCode == 'ko' ? ko : en;
  }
}

class ModernMazePainter extends CustomPainter {
  final MazeData mazeData;
  final int currentX;
  final int currentY;
  final Set<String> visitedRooms;
  final Animation<double> pulseAnimation;

  ModernMazePainter({
    required this.mazeData,
    required this.currentX,
    required this.currentY,
    required this.visitedRooms,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    const gridSize = 8;
    final cellSize = math.min(size.width, size.height) / (gridSize + 2);
    final offsetX = (size.width - (gridSize * cellSize)) / 2;
    final offsetY = (size.height - (gridSize * cellSize)) / 2;

    // Draw background grid
    _drawBackground(canvas, size, cellSize, offsetX, offsetY);
    
    // Draw maze walls
    _drawMazeWalls(canvas, cellSize, offsetX, offsetY);
    
    // Draw rooms
    _drawRooms(canvas, cellSize, offsetX, offsetY);
    
    // Draw connections between visited rooms
    _drawConnections(canvas, cellSize, offsetX, offsetY);
    
    // Draw special locations
    _drawSpecialLocations(canvas, cellSize, offsetX, offsetY);
    
    // Draw current position (animated)
    _drawCurrentPosition(canvas, cellSize, offsetX, offsetY);
  }

  void _drawBackground(Canvas canvas, Size size, double cellSize, double offsetX, double offsetY) {
    final backgroundPaint = Paint()
      ..color = AppTheme.backgroundTertiary.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, cellSize * 8, cellSize * 8),
      backgroundPaint,
    );
  }

  void _drawMazeWalls(Canvas canvas, double cellSize, double offsetX, double offsetY) {
    final wallPaint = Paint()
      ..color = AppTheme.borderPrimary.withOpacity(0.6)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw outer walls
    canvas.drawRect(
      Rect.fromLTWH(offsetX, offsetY, cellSize * 8, cellSize * 8),
      wallPaint,
    );

    // Draw internal walls based on maze structure
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final room = mazeData.rooms.firstWhere(
          (r) => r.x == x && r.y == y,
          orElse: () => Room(x: x, y: y, north: false, east: false, south: false, west: false),
        );

        final roomX = offsetX + x * cellSize;
        final roomY = offsetY + y * cellSize;

        // Draw walls if doors don't exist
        if (!room.north && y > 0) {
          canvas.drawLine(
            Offset(roomX, roomY),
            Offset(roomX + cellSize, roomY),
            wallPaint,
          );
        }
        if (!room.east && x < 7) {
          canvas.drawLine(
            Offset(roomX + cellSize, roomY),
            Offset(roomX + cellSize, roomY + cellSize),
            wallPaint,
          );
        }
        if (!room.south && y < 7) {
          canvas.drawLine(
            Offset(roomX, roomY + cellSize),
            Offset(roomX + cellSize, roomY + cellSize),
            wallPaint,
          );
        }
        if (!room.west && x > 0) {
          canvas.drawLine(
            Offset(roomX, roomY),
            Offset(roomX, roomY + cellSize),
            wallPaint,
          );
        }
      }
    }
  }

  void _drawRooms(Canvas canvas, double cellSize, double offsetX, double offsetY) {
    final visitedPaint = Paint()
      ..color = AppTheme.textSecondary.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    final unvisitedPaint = Paint()
      ..color = AppTheme.backgroundPrimary.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final roomKey = '$x,$y';
        final isVisited = visitedRooms.contains(roomKey);
        
        final roomRect = Rect.fromLTWH(
          offsetX + x * cellSize + 2,
          offsetY + y * cellSize + 2,
          cellSize - 4,
          cellSize - 4,
        );

        canvas.drawRRect(
          RRect.fromRectAndRadius(roomRect, const Radius.circular(4)),
          isVisited ? visitedPaint : unvisitedPaint,
        );

        // Add subtle inner border for visited rooms
        if (isVisited) {
          final borderPaint = Paint()
            ..color = AppTheme.textSecondary.withOpacity(0.5)
            ..strokeWidth = 1.0
            ..style = PaintingStyle.stroke;

          canvas.drawRRect(
            RRect.fromRectAndRadius(roomRect, const Radius.circular(4)),
            borderPaint,
          );
        }
      }
    }
  }

  void _drawConnections(Canvas canvas, double cellSize, double offsetX, double offsetY) {
    final connectionPaint = Paint()
      ..color = AppTheme.accentPrimary.withOpacity(0.4)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final roomKey = '$x,$y';
        if (!visitedRooms.contains(roomKey)) continue;

        final room = mazeData.rooms.firstWhere(
          (r) => r.x == x && r.y == y,
          orElse: () => Room(x: x, y: y, north: false, east: false, south: false, west: false),
        );

        final centerX = offsetX + x * cellSize + cellSize / 2;
        final centerY = offsetY + y * cellSize + cellSize / 2;

        // Draw connections to adjacent visited rooms
        if (room.north && visitedRooms.contains('$x,${y - 1}')) {
          canvas.drawLine(
            Offset(centerX, centerY),
            Offset(centerX, centerY - cellSize / 2),
            connectionPaint,
          );
        }
        if (room.east && visitedRooms.contains('${x + 1},$y')) {
          canvas.drawLine(
            Offset(centerX, centerY),
            Offset(centerX + cellSize / 2, centerY),
            connectionPaint,
          );
        }
        if (room.south && visitedRooms.contains('$x,${y + 1}')) {
          canvas.drawLine(
            Offset(centerX, centerY),
            Offset(centerX, centerY + cellSize / 2),
            connectionPaint,
          );
        }
        if (room.west && visitedRooms.contains('${x - 1},$y')) {
          canvas.drawLine(
            Offset(centerX, centerY),
            Offset(centerX - cellSize / 2, centerY),
            connectionPaint,
          );
        }
      }
    }
  }

  void _drawSpecialLocations(Canvas canvas, double cellSize, double offsetX, double offsetY) {
    // Draw start position
    if (mazeData.startX >= 0 && mazeData.startY >= 0) {
      _drawSpecialMarker(
        canvas,
        offsetX + mazeData.startX * cellSize,
        offsetY + mazeData.startY * cellSize,
        cellSize,
        AppTheme.successColor,
        Icons.flag_circle,
      );
    }

    // Draw exit position
    if (mazeData.exitX >= 0 && mazeData.exitY >= 0) {
      _drawSpecialMarker(
        canvas,
        offsetX + mazeData.exitX * cellSize,
        offsetY + mazeData.exitY * cellSize,
        cellSize,
        AppTheme.warningColor,
        Icons.exit_to_app,
      );
    }
  }

  void _drawCurrentPosition(Canvas canvas, double cellSize, double offsetX, double offsetY) {
    final centerX = offsetX + currentX * cellSize + cellSize / 2;
    final centerY = offsetY + currentY * cellSize + cellSize / 2;
    
    // Animated pulse effect
    final pulseScale = pulseAnimation.value;
    final radius = (cellSize * 0.3) * pulseScale;

    // Outer glow
    final glowPaint = Paint()
      ..color = AppTheme.accentPrimary.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius + 8,
      glowPaint,
    );

    // Main player marker
    final playerPaint = Paint()
      ..color = AppTheme.accentPrimary
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      playerPaint,
    );

    // Inner highlight
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius * 0.4,
      highlightPaint,
    );
  }

  void _drawSpecialMarker(
    Canvas canvas,
    double x,
    double y,
    double cellSize,
    Color color,
    IconData icon,
  ) {
    final centerX = x + cellSize / 2;
    final centerY = y + cellSize / 2;
    final radius = cellSize * 0.25;

    // Background circle
    final bgPaint = Paint()
      ..color = color.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius + 4,
      bgPaint,
    );

    // Main circle
    final mainPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(centerX, centerY),
      radius,
      mainPaint,
    );
  }

  @override
  bool shouldRepaint(covariant ModernMazePainter oldDelegate) {
    return oldDelegate.currentX != currentX ||
        oldDelegate.currentY != currentY ||
        oldDelegate.visitedRooms != visitedRooms ||
        oldDelegate.pulseAnimation != pulseAnimation;
  }
}