import 'package:flutter/material.dart';

/// Widget responsible for displaying turn transition animations
///
/// Shows the "Others in the maze are moving" message with appropriate styling
/// and animations to create tension and urgency
class TurnTransitionWidget extends StatefulWidget {
  final String message;
  final bool isVisible;
  final Duration duration;
  final VoidCallback? onAnimationComplete;
  final TextStyle? textStyle;
  final Color? backgroundColor;

  const TurnTransitionWidget({
    super.key,
    required this.message,
    required this.isVisible,
    this.duration = const Duration(milliseconds: 1500),
    this.onAnimationComplete,
    this.textStyle,
    this.backgroundColor,
  });

  @override
  State<TurnTransitionWidget> createState() => _TurnTransitionWidgetState();
}

class _TurnTransitionWidgetState extends State<TurnTransitionWidget>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Fade animation controller
    _fadeController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    // Pulse animation controller (faster cycle for tension)
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Fade animation (fade in, hold, fade out)
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
      ),
    );

    // Pulse animation for text emphasis
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen for animation completion
    _fadeController.addStatusListener(_handleAnimationStatus);
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      // Stop pulse animation when fade completes
      _pulseController.stop();
      widget.onAnimationComplete?.call();
    }
  }

  @override
  void didUpdateWidget(TurnTransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _startTransition();
      } else {
        _stopTransition();
      }
    }
  }

  void _startTransition() {
    // Start both animations
    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  void _stopTransition() {
    // Stop animations
    _fadeController.reset();
    _pulseController.stop();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isVisible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: Listenable.merge([_fadeAnimation, _pulseAnimation]),
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Container(
            color:
                widget.backgroundColor ?? Colors.black.withValues(alpha: 0.8),
            child: Center(
              child: Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.amber.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Main transition message
                      Text(
                        widget.message,
                        style:
                            widget.textStyle ??
                            const TextStyle(
                              color: Colors.amber,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      // Subtle loading indicator
                      SizedBox(
                        width: 120,
                        child: LinearProgressIndicator(
                          backgroundColor: Colors.amber.withValues(alpha: 0.2),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.amber.withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Simplified turn transition overlay for minimal UI interference
class SimpleTurnTransitionOverlay extends StatelessWidget {
  final String message;
  final bool isVisible;
  final double opacity;

  const SimpleTurnTransitionOverlay({
    super.key,
    required this.message,
    required this.isVisible,
    this.opacity = 0.9,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.black.withValues(alpha: opacity),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber, width: 1),
          ),
          child: Text(
            message,
            style: const TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Turn transition builder for custom transition implementations
typedef TurnTransitionBuilder =
    Widget Function(
      BuildContext context,
      String message,
      bool isVisible,
      double progress,
    );

/// Customizable turn transition widget with builder pattern
class CustomTurnTransitionWidget extends StatefulWidget {
  final String message;
  final bool isVisible;
  final Duration duration;
  final TurnTransitionBuilder builder;
  final VoidCallback? onComplete;

  const CustomTurnTransitionWidget({
    super.key,
    required this.message,
    required this.isVisible,
    required this.builder,
    this.duration = const Duration(milliseconds: 1500),
    this.onComplete,
  });

  @override
  State<CustomTurnTransitionWidget> createState() =>
      _CustomTurnTransitionWidgetState();
}

class _CustomTurnTransitionWidgetState extends State<CustomTurnTransitionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onComplete?.call();
      }
    });
  }

  @override
  void didUpdateWidget(CustomTurnTransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isVisible != oldWidget.isVisible) {
      if (widget.isVisible) {
        _controller.forward();
      } else {
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return widget.builder(
          context,
          widget.message,
          widget.isVisible,
          _animation.value,
        );
      },
    );
  }
}
