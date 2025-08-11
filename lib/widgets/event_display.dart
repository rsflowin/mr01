import 'package:flutter/material.dart';
import 'dart:math' show sin;
import '../models/event_model.dart';

/// Widget for displaying event information including name, description, and image
///
/// Meets Requirements 4.1: Display event name, description, and image when triggered
class EventDisplay extends StatelessWidget {
  /// The event to display
  final Event event;

  /// Optional custom styling for the widget
  final EventDisplayStyle? style;

  /// Animation controller for entrance effects
  final AnimationController? animationController;

  const EventDisplay({
    super.key,
    required this.event,
    this.style,
    this.animationController,
  });

  @override
  Widget build(BuildContext context) {
    final displayStyle = style ?? EventDisplayStyle.defaultStyle();

    if (animationController != null) {
      return AnimatedBuilder(
        animation: animationController!,
        builder: (context, child) {
          return FadeTransition(
            opacity: animationController!,
            child: SlideTransition(
              position:
                  Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent: animationController!,
                      curve: Curves.easeOutCubic,
                    ),
                  ),
              child: child,
            ),
          );
        },
        child: _buildEventContent(displayStyle),
      );
    }

    return _buildEventContent(displayStyle);
  }

  Widget _buildEventContent(EventDisplayStyle displayStyle) {
    return Container(
      margin: displayStyle.margin,
      padding: displayStyle.padding,
      decoration: displayStyle.decoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Event image section
          if (event.image.isNotEmpty) _buildEventImage(displayStyle),

          // Event name
          _buildEventName(displayStyle),

          // Spacing between name and description
          SizedBox(height: displayStyle.spacingBetweenElements),

          // Event description
          _buildEventDescription(displayStyle),

          // Event category badge (optional)
          if (displayStyle.showCategoryBadge) ...[
            SizedBox(height: displayStyle.spacingBetweenElements),
            _buildCategoryBadge(displayStyle),
          ],
        ],
      ),
    );
  }

  Widget _buildEventImage(EventDisplayStyle style) {
    return Container(
      width: double.infinity,
      height: style.imageHeight,
      margin: EdgeInsets.only(bottom: style.spacingBetweenElements),
      decoration: BoxDecoration(
        color: style.imageBackgroundColor,
        borderRadius: style.imageBorderRadius,
        border: style.imageBorder,
        boxShadow: style.imageBoxShadow,
      ),
      child: ClipRRect(
        borderRadius: style.imageBorderRadius ?? BorderRadius.zero,
        child: _buildImageContent(style),
      ),
    );
  }

  Widget _buildImageContent(EventDisplayStyle style) {
    // For now, we'll display a placeholder with the image name
    // In a real implementation, this would load actual images
    return Container(
      decoration: BoxDecoration(
        gradient: _getImageGradientByCategory(event.category),
      ),
      child: Stack(
        children: [
          // Background pattern
          CustomPaint(
            painter: EventImagePatternPainter(category: event.category),
            size: Size.infinite,
          ),

          // Image placeholder with category-specific icon
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconByCategory(event.category),
                  size: style.imageIconSize,
                  color: style.imageIconColor,
                ),
                const SizedBox(height: 8),
                Text(
                  event.image,
                  style: style.imageNameTextStyle,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Category overlay
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                event.category.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventName(EventDisplayStyle style) {
    return Text(
      event.name,
      style: style.nameTextStyle,
      textAlign: style.nameAlignment,
    );
  }

  Widget _buildEventDescription(EventDisplayStyle style) {
    return Text(
      event.description,
      style: style.descriptionTextStyle,
      textAlign: style.descriptionAlignment,
    );
  }

  Widget _buildCategoryBadge(EventDisplayStyle style) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _getCategoryColor(event.category).withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getCategoryColor(event.category).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getIconByCategory(event.category),
              size: 16,
              color: _getCategoryColor(event.category),
            ),
            const SizedBox(width: 6),
            Text(
              event.category.toUpperCase(),
              style: TextStyle(
                color: _getCategoryColor(event.category),
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods for category-specific styling
  IconData _getIconByCategory(String category) {
    switch (category.toLowerCase()) {
      case 'trap':
        return Icons.warning;
      case 'item':
        return Icons.inventory;
      case 'character':
        return Icons.person;
      case 'monster':
        return Icons.pets;
      case 'rest':
        return Icons.bed;
      case 'special':
        return Icons.star;
      default:
        return Icons.help_outline;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'trap':
        return const Color(0xFFFF6B6B);
      case 'item':
        return const Color(0xFF4ECDC4);
      case 'character':
        return const Color(0xFF45B7D1);
      case 'monster':
        return const Color(0xFFFF8E53);
      case 'rest':
        return const Color(0xFF96CEB4);
      case 'special':
        return const Color(0xFFFEA47F);
      default:
        return const Color(0xFF8B8B8B);
    }
  }

  LinearGradient _getImageGradientByCategory(String category) {
    final color = _getCategoryColor(category);
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withOpacity(0.3),
        color.withOpacity(0.1),
        Colors.black.withOpacity(0.1),
      ],
    );
  }
}

/// Style configuration for EventDisplay widget
class EventDisplayStyle {
  final EdgeInsets margin;
  final EdgeInsets padding;
  final Decoration? decoration;
  final double spacingBetweenElements;
  final bool showCategoryBadge;

  // Image styling
  final double imageHeight;
  final Color imageBackgroundColor;
  final BorderRadius? imageBorderRadius;
  final Border? imageBorder;
  final List<BoxShadow>? imageBoxShadow;
  final double imageIconSize;
  final Color imageIconColor;
  final TextStyle imageNameTextStyle;

  // Text styling
  final TextStyle nameTextStyle;
  final TextAlign nameAlignment;
  final TextStyle descriptionTextStyle;
  final TextAlign descriptionAlignment;

  const EventDisplayStyle({
    this.margin = const EdgeInsets.all(16),
    this.padding = const EdgeInsets.all(20),
    this.decoration,
    this.spacingBetweenElements = 16,
    this.showCategoryBadge = true,
    this.imageHeight = 160,
    this.imageBackgroundColor = const Color(0xFF2A2A2A),
    this.imageBorderRadius,
    this.imageBorder,
    this.imageBoxShadow,
    this.imageIconSize = 48,
    this.imageIconColor = Colors.white70,
    this.imageNameTextStyle = const TextStyle(
      color: Colors.white60,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    ),
    this.nameTextStyle = const TextStyle(
      color: Color(0xFFE0E0E0),
      fontSize: 22,
      fontWeight: FontWeight.bold,
      height: 1.2,
    ),
    this.nameAlignment = TextAlign.center,
    this.descriptionTextStyle = const TextStyle(
      color: Color(0xFFD4D4D4),
      fontSize: 16,
      height: 1.5,
    ),
    this.descriptionAlignment = TextAlign.left,
  });

  /// Default styling that matches the game's theme
  factory EventDisplayStyle.defaultStyle() {
    return EventDisplayStyle(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B0000).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      imageBorderRadius: BorderRadius.circular(8),
      imageBorder: Border.all(
        color: const Color(0xFF8B0000).withOpacity(0.2),
        width: 1,
      ),
      imageBoxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  /// Compact styling for smaller displays
  factory EventDisplayStyle.compact() {
    return EventDisplayStyle(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      spacingBetweenElements: 8,
      imageHeight: 100,
      imageIconSize: 32,
      nameTextStyle: const TextStyle(
        color: Color(0xFFE0E0E0),
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      descriptionTextStyle: const TextStyle(
        color: Color(0xFFD4D4D4),
        fontSize: 14,
        height: 1.4,
      ),
      showCategoryBadge: false,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF8B0000).withOpacity(0.2),
          width: 1,
        ),
      ),
    );
  }

  /// Minimal styling for overlay displays
  factory EventDisplayStyle.minimal() {
    return EventDisplayStyle(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      spacingBetweenElements: 12,
      imageHeight: 80,
      imageIconSize: 24,
      nameTextStyle: const TextStyle(
        color: Color(0xFFE0E0E0),
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      descriptionTextStyle: const TextStyle(
        color: Color(0xFFD4D4D4),
        fontSize: 13,
        height: 1.3,
      ),
      showCategoryBadge: false,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }

  /// Copy this style with optional parameter overrides
  EventDisplayStyle copyWith({
    EdgeInsets? margin,
    EdgeInsets? padding,
    Decoration? decoration,
    double? spacingBetweenElements,
    bool? showCategoryBadge,
    double? imageHeight,
    Color? imageBackgroundColor,
    BorderRadius? imageBorderRadius,
    Border? imageBorder,
    List<BoxShadow>? imageBoxShadow,
    double? imageIconSize,
    Color? imageIconColor,
    TextStyle? imageNameTextStyle,
    TextStyle? nameTextStyle,
    TextAlign? nameAlignment,
    TextStyle? descriptionTextStyle,
    TextAlign? descriptionAlignment,
  }) {
    return EventDisplayStyle(
      margin: margin ?? this.margin,
      padding: padding ?? this.padding,
      decoration: decoration ?? this.decoration,
      spacingBetweenElements:
          spacingBetweenElements ?? this.spacingBetweenElements,
      showCategoryBadge: showCategoryBadge ?? this.showCategoryBadge,
      imageHeight: imageHeight ?? this.imageHeight,
      imageBackgroundColor: imageBackgroundColor ?? this.imageBackgroundColor,
      imageBorderRadius: imageBorderRadius ?? this.imageBorderRadius,
      imageBorder: imageBorder ?? this.imageBorder,
      imageBoxShadow: imageBoxShadow ?? this.imageBoxShadow,
      imageIconSize: imageIconSize ?? this.imageIconSize,
      imageIconColor: imageIconColor ?? this.imageIconColor,
      imageNameTextStyle: imageNameTextStyle ?? this.imageNameTextStyle,
      nameTextStyle: nameTextStyle ?? this.nameTextStyle,
      nameAlignment: nameAlignment ?? this.nameAlignment,
      descriptionTextStyle: descriptionTextStyle ?? this.descriptionTextStyle,
      descriptionAlignment: descriptionAlignment ?? this.descriptionAlignment,
    );
  }
}

/// Custom painter for event image background patterns
class EventImagePatternPainter extends CustomPainter {
  final String category;

  EventImagePatternPainter({required this.category});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..color = Colors.white.withOpacity(0.1);

    // Draw category-specific patterns
    switch (category.toLowerCase()) {
      case 'trap':
        _drawTrapPattern(canvas, size, paint);
        break;
      case 'item':
        _drawItemPattern(canvas, size, paint);
        break;
      case 'character':
        _drawCharacterPattern(canvas, size, paint);
        break;
      case 'monster':
        _drawMonsterPattern(canvas, size, paint);
        break;
      case 'rest':
        _drawRestPattern(canvas, size, paint);
        break;
      default:
        _drawDefaultPattern(canvas, size, paint);
    }
  }

  void _drawTrapPattern(Canvas canvas, Size size, Paint paint) {
    // Draw warning triangles
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 2; j++) {
        final x = (i + 0.5) * size.width / 3;
        final y = (j + 0.5) * size.height / 2;
        final triangleSize = 20.0;

        final path = Path();
        path.moveTo(x, y - triangleSize);
        path.lineTo(x - triangleSize, y + triangleSize);
        path.lineTo(x + triangleSize, y + triangleSize);
        path.close();

        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawItemPattern(Canvas canvas, Size size, Paint paint) {
    // Draw diamond grid
    const spacing = 40.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final centerX = x + spacing / 2;
        final centerY = y + spacing / 2;
        final diamondSize = 8.0;

        final path = Path();
        path.moveTo(centerX, centerY - diamondSize);
        path.lineTo(centerX + diamondSize, centerY);
        path.lineTo(centerX, centerY + diamondSize);
        path.lineTo(centerX - diamondSize, centerY);
        path.close();

        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawCharacterPattern(Canvas canvas, Size size, Paint paint) {
    // Draw circular patterns
    const spacing = 50.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final centerX = x + spacing / 2;
        final centerY = y + spacing / 2;

        canvas.drawCircle(Offset(centerX, centerY), 12, paint);
        canvas.drawCircle(Offset(centerX, centerY), 6, paint);
      }
    }
  }

  void _drawMonsterPattern(Canvas canvas, Size size, Paint paint) {
    // Draw jagged patterns
    const spacing = 30.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        final path = Path();
        path.moveTo(x, y);
        path.lineTo(x + spacing / 3, y + spacing / 2);
        path.lineTo(x + 2 * spacing / 3, y);
        path.lineTo(x + spacing, y + spacing / 2);

        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawRestPattern(Canvas canvas, Size size, Paint paint) {
    // Draw gentle wave patterns
    final path = Path();
    const amplitude = 20.0;
    const frequency = 0.02;

    for (double y = 0; y < size.height; y += 40) {
      path.reset();
      path.moveTo(0, y);

      for (double x = 0; x <= size.width; x += 2) {
        final waveY = y + amplitude * sin(x * frequency);
        path.lineTo(x, waveY);
      }

      canvas.drawPath(path, paint);
    }
  }

  void _drawDefaultPattern(Canvas canvas, Size size, Paint paint) {
    // Draw simple grid
    const spacing = 25.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! EventImagePatternPainter) return true;
    return oldDelegate.category != category;
  }
}
