import 'dart:async';
import 'package:flutter/foundation.dart';

/// Service responsible for managing turn transitions and timing
///
/// Handles the display of turn transition messages and flow control
/// according to the requirements for creating tension and urgency
class TurnManager {
  static const Duration _defaultTransitionDuration = Duration(
    milliseconds: 1500,
  );

  /// Displays the turn transition message for a brief period
  ///
  /// Shows "Others in the maze are moving" message to create tension
  ///
  /// [onTransitionStart] - Callback when transition begins
  /// [onTransitionComplete] - Callback when transition completes
  /// [duration] - Optional custom duration (defaults to 1.5 seconds)
  ///
  /// Returns a Future that completes when the transition is finished
  Future<void> displayTurnTransition({
    VoidCallback? onTransitionStart,
    VoidCallback? onTransitionComplete,
    Duration? duration,
  }) async {
    final transitionDuration = duration ?? _defaultTransitionDuration;

    // Signal start of transition
    onTransitionStart?.call();

    // Wait for the specified duration
    await waitForTransition(transitionDuration);

    // Signal completion of transition
    onTransitionComplete?.call();
  }

  /// Waits for the specified transition duration
  ///
  /// [duration] - The duration to wait
  ///
  /// Returns a Future that completes after the duration
  Future<void> waitForTransition(Duration duration) async {
    await Future.delayed(duration);
  }

  /// Returns to the movement selection phase after turn transition
  ///
  /// [onReturnToMovement] - Callback to handle return to movement phase
  void returnToMovementPhase({VoidCallback? onReturnToMovement}) {
    onReturnToMovement?.call();
  }

  /// Gets the standard turn transition message
  ///
  /// Returns the message to display during turn transitions
  String getTurnTransitionMessage() {
    return "Others in the maze are moving...";
  }

  /// Processes a complete turn cycle with transition
  ///
  /// [onTransitionStart] - Called when transition begins
  /// [onTransitionComplete] - Called when transition ends
  /// [onReturnToMovement] - Called when returning to movement phase
  /// [duration] - Optional custom transition duration
  ///
  /// Returns a Future that completes when the full turn cycle is finished
  Future<void> processTurnCycle({
    VoidCallback? onTransitionStart,
    VoidCallback? onTransitionComplete,
    VoidCallback? onReturnToMovement,
    Duration? duration,
  }) async {
    // Display transition message
    await displayTurnTransition(
      onTransitionStart: onTransitionStart,
      onTransitionComplete: onTransitionComplete,
      duration: duration,
    );

    // Return to movement phase
    returnToMovementPhase(onReturnToMovement: onReturnToMovement);
  }

  /// Creates a turn transition state for UI components
  ///
  /// [isActive] - Whether the transition is currently active
  /// [message] - The message to display (defaults to standard message)
  /// [progress] - Optional progress value between 0.0 and 1.0
  ///
  /// Returns a map containing the transition state data
  Map<String, dynamic> createTransitionState({
    required bool isActive,
    String? message,
    double? progress,
  }) {
    return {
      'isActive': isActive,
      'message': message ?? getTurnTransitionMessage(),
      'progress': progress ?? (isActive ? null : 1.0),
      'startTime': isActive ? DateTime.now() : null,
    };
  }

  /// Validates turn transition parameters
  ///
  /// [duration] - Duration to validate
  ///
  /// Returns true if parameters are valid
  bool validateTransitionParameters({Duration? duration}) {
    if (duration != null) {
      // Duration should be between 500ms and 5 seconds for reasonable UX
      return duration.inMilliseconds >= 500 && duration.inMilliseconds <= 5000;
    }
    return true;
  }

  /// Gets recommended transition duration based on game state
  ///
  /// [gameComplexity] - Complexity level of the current game state
  /// [playerPreference] - Player's preference for transition speed
  ///
  /// Returns appropriate transition duration
  Duration getRecommendedDuration({
    String gameComplexity = 'normal',
    String playerPreference = 'normal',
  }) {
    switch (playerPreference.toLowerCase()) {
      case 'fast':
        return const Duration(milliseconds: 1000);
      case 'slow':
        return const Duration(milliseconds: 2000);
      case 'normal':
      default:
        return _defaultTransitionDuration;
    }
  }

  /// Creates a turn transition animation controller configuration
  ///
  /// [duration] - Animation duration
  ///
  /// Returns configuration map for animation controllers
  Map<String, dynamic> createAnimationConfig({Duration? duration}) {
    final animationDuration = duration ?? _defaultTransitionDuration;

    return {
      'duration': animationDuration,
      'fadeInDuration': Duration(
        milliseconds: (animationDuration.inMilliseconds * 0.2).round(),
      ),
      'holdDuration': Duration(
        milliseconds: (animationDuration.inMilliseconds * 0.6).round(),
      ),
      'fadeOutDuration': Duration(
        milliseconds: (animationDuration.inMilliseconds * 0.2).round(),
      ),
      'curve': 'easeInOut',
    };
  }
}
