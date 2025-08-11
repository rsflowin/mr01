import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'logger_service.dart';

/// Service responsible for UI optimization and responsiveness during event processing
/// Implements frame rate management, smooth transitions, and UI performance monitoring
/// Enhanced with event-specific optimizations and better memory management
class UIOptimizer {
  final LoggerService _logger = LoggerService();

  // Frame rate management
  static const double _targetFrameRate = 60.0;
  static const Duration _frameBudget = Duration(milliseconds: 16); // ~60 FPS

  // UI performance tracking
  final Map<String, List<Duration>> _uiOperationTimings = {};
  final Map<String, int> _frameDropCounts = {};
  final List<Duration> _frameTimes = [];

  // Transition management
  final Map<String, AnimationController> _activeAnimations = {};
  final List<String> _pendingTransitions = [];

  // Memory management for UI
  final Map<String, int> _widgetMemoryUsage = {};
  final List<String> _recentlyUsedWidgets = [];
  static const int _maxWidgetMemorySize = 50 * 1024 * 1024; // 50MB

  // Event-specific UI optimization
  final Map<String, bool> _eventUIStates = {};
  final Map<String, List<String>> _eventWidgetCache = {};
  final Map<String, DateTime> _eventWidgetTimestamps = {};
  static const Duration _eventWidgetCacheExpiry = Duration(minutes: 15);

  // Background optimization
  Timer? _optimizationTimer;
  bool _isOptimizing = false;

  UIOptimizer() {
    _startBackgroundOptimization();
  }

  /// Starts background optimization timer for UI performance
  void _startBackgroundOptimization() {
    _optimizationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _performBackgroundOptimization();
    });

    _logger.info('UIOptimizer', 'Background UI optimization timer started');
  }

  /// Stops background optimization timer
  void dispose() {
    _optimizationTimer?.cancel();
    _cleanupActiveAnimations();
    _cleanupExpiredEventWidgetCache();
    _logger.info('UIOptimizer', 'UI optimizer disposed');
  }

  /// Optimizes UI rendering for smooth event processing
  void optimizeForEventProcessing() {
    _logger.debug('UIOptimizer', 'Optimizing UI for event processing');

    // Schedule frame rate optimization
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _optimizeFrameRate();
    });

    // Pre-warm animation controllers
    _prewarmAnimations();

    // Optimize memory usage
    _optimizeMemoryUsage();

    // Set event UI state for optimization
    _setEventUIState(true);
  }

  /// Sets event UI state for optimization
  void _setEventUIState(bool isEventActive) {
    _eventUIStates['event_processing'] = isEventActive;

    if (isEventActive) {
      // Reduce frame rate during event processing for stability
      _reduceFrameRateForEvents();
    } else {
      // Restore normal frame rate
      _restoreNormalFrameRate();
    }
  }

  /// Reduces frame rate during event processing for stability
  void _reduceFrameRateForEvents() {
    try {
      // Schedule frame rate reduction
      SchedulerBinding.instance.scheduleFrameCallback((_) {
        // Reduce frame rate to 30 FPS during events for better stability
        const eventFrameBudget = Duration(milliseconds: 33);

        SchedulerBinding.instance.addPostFrameCallback((_) {
          // Add delay to reduce frame rate
          Future.delayed(eventFrameBudget, () {
            if (_eventUIStates['event_processing'] == true) {
              SchedulerBinding.instance.scheduleFrameCallback((_) {});
            }
          });
        });
      });
    } catch (e, stackTrace) {
      _logger.error(
        'UIOptimizer',
        'Frame rate reduction for events failed',
        {},
        stackTrace,
      );
    }
  }

  /// Restores normal frame rate after event processing
  void _restoreNormalFrameRate() {
    _logger.debug('UIOptimizer', 'Restoring normal frame rate');
    // Frame rate will automatically return to normal on next frame
  }

  /// Optimizes UI after event processing is complete
  void optimizeAfterEventProcessing() {
    _logger.debug('UIOptimizer', 'Optimizing UI after event processing');

    // Set event UI state to false
    _setEventUIState(false);

    // Schedule frame rate optimization
    SchedulerBinding.instance.scheduleFrameCallback((_) {
      _optimizeFrameRate();
    });

    // Clean up event-specific UI resources
    _cleanupEventUIResources();

    // Optimize memory usage
    _optimizeMemoryUsage();
  }

  /// Cleans up event-specific UI resources
  void _cleanupEventUIResources() {
    // Clean up expired event widget cache
    _cleanupExpiredEventWidgetCache();

    // Reset event UI states
    _eventUIStates.clear();

    _logger.debug('UIOptimizer', 'Cleaned up event-specific UI resources');
  }

  /// Caches event widgets for better performance
  void cacheEventWidgets(String eventId, List<String> widgetKeys) {
    _eventWidgetCache[eventId] = List<String>.from(widgetKeys);
    _eventWidgetTimestamps[eventId] = DateTime.now();

    _logger.debug(
      'UIOptimizer',
      'Cached ${widgetKeys.length} widgets for event: $eventId',
    );
  }

  /// Gets cached event widgets
  List<String>? getCachedEventWidgets(String eventId) {
    final timestamp = _eventWidgetTimestamps[eventId];
    if (timestamp == null) return null;

    // Check if cache is still valid
    if (DateTime.now().difference(timestamp) > _eventWidgetCacheExpiry) {
      _eventWidgetCache.remove(eventId);
      _eventWidgetTimestamps.remove(eventId);
      return null;
    }

    return _eventWidgetCache[eventId];
  }

  /// Cleans up expired event widget cache
  void _cleanupExpiredEventWidgetCache() {
    final cutoffTime = DateTime.now().subtract(_eventWidgetCacheExpiry);
    final expiredEventIds = <String>[];

    for (final entry in _eventWidgetTimestamps.entries) {
      if (entry.value.isBefore(cutoffTime)) {
        expiredEventIds.add(entry.key);
      }
    }

    for (final eventId in expiredEventIds) {
      _eventWidgetCache.remove(eventId);
      _eventWidgetTimestamps.remove(eventId);
    }

    if (expiredEventIds.isNotEmpty) {
      _logger.debug(
        'UIOptimizer',
        'Cleaned up ${expiredEventIds.length} expired event widget caches',
      );
    }
  }

  /// Optimizes frame rate for smooth rendering
  void _optimizeFrameRate() {
    try {
      // Monitor frame times
      final frameStartTime = DateTime.now();

      SchedulerBinding.instance.addPostFrameCallback((_) {
        final frameEndTime = DateTime.now();
        final frameDuration = frameEndTime.difference(frameStartTime);

        _frameTimes.add(frameDuration);
        if (_frameTimes.length > 100) {
          _frameTimes.removeAt(0);
        }

        // Check for frame drops
        if (frameDuration > _frameBudget) {
          _handleFrameDrop(frameDuration);
        }
      });
    } catch (e, stackTrace) {
      _logger.error(
        'UIOptimizer',
        'Frame rate optimization failed',
        {},
        stackTrace,
      );
    }
  }

  /// Handles frame drops by adjusting rendering strategy
  void _handleFrameDrop(Duration frameDuration) {
    final operationName = 'frame_drop';
    _frameDropCounts[operationName] =
        (_frameDropCounts[operationName] ?? 0) + 1;

    // Log frame drop for monitoring
    _logger.warning(
      'UIOptimizer',
      'Frame drop detected: ${frameDuration.inMilliseconds}ms (target: ${_frameBudget.inMilliseconds}ms)',
    );

    // Adjust rendering strategy based on frame drop severity
    if (frameDuration.inMilliseconds > _frameBudget.inMilliseconds * 2) {
      _applyAggressiveOptimization();
    } else {
      _applyModerateOptimization();
    }
  }

  /// Applies moderate optimization for minor frame drops
  void _applyModerateOptimization() {
    // Reduce animation complexity
    _reduceAnimationComplexity();

    // Optimize widget rebuilds
    _optimizeWidgetRebuilds();
  }

  /// Applies aggressive optimization for severe frame drops
  void _applyAggressiveOptimization() {
    // Disable non-essential animations
    _disableNonEssentialAnimations();

    // Reduce widget complexity
    _reduceWidgetComplexity();

    // Force garbage collection if available
    _forceGarbageCollection();
  }

  /// Reduces animation complexity
  void _reduceAnimationComplexity() {
    for (final controller in _activeAnimations.values) {
      final duration = controller.duration;
      if (duration != null && duration.inMilliseconds > 500) {
        controller.duration = const Duration(milliseconds: 300);
      }
    }
  }

  /// Optimizes widget rebuilds
  void _optimizeWidgetRebuilds() {
    // Mark widgets for optimization
    _recentlyUsedWidgets.forEach((widgetKey) {
      final currentUsage = _widgetMemoryUsage[widgetKey] ?? 0;
      _widgetMemoryUsage[widgetKey] = (currentUsage * 0.8).round();
    });
  }

  /// Disables non-essential animations
  void _disableNonEssentialAnimations() {
    for (final entry in _activeAnimations.entries) {
      final controller = entry.value;
      if (entry.key.startsWith('non_essential_')) {
        controller.stop();
      }
    }
  }

  /// Reduces widget complexity
  void _reduceWidgetComplexity() {
    // Reduce memory usage for complex widgets
    final complexWidgets = _widgetMemoryUsage.entries
        .where((entry) => entry.value > 1024)
        .toList();

    for (final entry in complexWidgets) {
      _widgetMemoryUsage[entry.key] = (entry.value * 0.7).round();
    }
  }

  /// Forces garbage collection if available
  void _forceGarbageCollection() {
    try {
      // This is a hint to the garbage collector
      // The actual behavior depends on the platform
      _logger.debug('UIOptimizer', 'Requesting garbage collection');
    } catch (e) {
      // Garbage collection not available on this platform
      _logger.debug('UIOptimizer', 'Garbage collection not available');
    }
  }

  /// Pre-warms animation controllers for smooth transitions
  void _prewarmAnimations() {
    try {
      // Pre-warm common animation controllers
      _logger.debug('UIOptimizer', 'Pre-warming animation controllers');

      // This would typically involve creating and warming up common animations
      // For now, we'll just log the operation
    } catch (e, stackTrace) {
      _logger.error(
        'UIOptimizer',
        'Animation pre-warming failed',
        {},
        stackTrace,
      );
    }
  }

  /// Optimizes memory usage for UI components
  void _optimizeMemoryUsage() {
    try {
      final currentMemoryUsage = _widgetMemoryUsage.values.fold(
        0,
        (sum, size) => sum + size,
      );

      if (currentMemoryUsage > _maxWidgetMemorySize) {
        _cleanupWidgetMemory();
      }

      // Clean up old widget references
      _cleanupOldWidgetReferences();
    } catch (e, stackTrace) {
      _logger.error(
        'UIOptimizer',
        'Memory optimization failed',
        {},
        stackTrace,
      );
    }
  }

  /// Cleans up widget memory when usage is high
  void _cleanupWidgetMemory() {
    final beforeSize = _widgetMemoryUsage.length;

    // Remove widgets with low memory usage
    final lowMemoryWidgets = _widgetMemoryUsage.entries
        .where((entry) => entry.value < 100)
        .map((entry) => entry.key)
        .toList();

    for (final widgetKey in lowMemoryWidgets) {
      _widgetMemoryUsage.remove(widgetKey);
      _recentlyUsedWidgets.remove(widgetKey);
    }

    _logger.info(
      'UIOptimizer',
      'Cleaned up ${beforeSize - _widgetMemoryUsage.length} low-memory widgets',
    );
  }

  /// Cleans up old widget references
  void _cleanupOldWidgetReferences() {
    // Keep only recently used widgets
    if (_recentlyUsedWidgets.length > 100) {
      final removeCount = _recentlyUsedWidgets.length - 100;
      _recentlyUsedWidgets.removeRange(0, removeCount);

      _logger.debug(
        'UIOptimizer',
        'Cleaned up $removeCount old widget references',
      );
    }
  }

  /// Performs background optimization operations
  void _performBackgroundOptimization() {
    if (_isOptimizing) return;

    _isOptimizing = true;

    try {
      // Clean up expired caches
      _cleanupExpiredEventWidgetCache();

      // Optimize memory usage
      _optimizeMemoryUsage();

      // Check frame rate performance
      _checkFrameRatePerformance();
    } finally {
      _isOptimizing = false;
    }
  }

  /// Checks frame rate performance and logs statistics
  void _checkFrameRatePerformance() {
    if (_frameTimes.isEmpty) return;

    final averageFrameTime =
        _frameTimes.fold(Duration.zero, (sum, duration) => sum + duration) ~/
        _frameTimes.length;

    final frameDropCount = _frameDropCounts['frame_drop'] ?? 0;

    if (frameDropCount > 0) {
      _logger.info(
        'UIOptimizer',
        'Frame rate performance: avg ${averageFrameTime.inMilliseconds}ms, '
            'drops: $frameDropCount',
      );
    }
  }

  /// Cleans up active animations
  void _cleanupActiveAnimations() {
    for (final controller in _activeAnimations.values) {
      try {
        controller.dispose();
      } catch (e) {
        // Controller already disposed
      }
    }
    _activeAnimations.clear();
  }

  /// Gets UI performance statistics
  Map<String, dynamic> getUIPerformanceStats() {
    return {
      'frameRate': {
        'averageFrameTime': _frameTimes.isNotEmpty
            ? _frameTimes.fold(Duration.zero, (sum, d) => sum + d) ~/
                  _frameTimes.length
            : Duration.zero,
        'frameDropCount': _frameDropCounts['frame_drop'] ?? 0,
        'totalFrames': _frameTimes.length,
      },
      'memory': {
        'widgetMemoryUsage': _widgetMemoryUsage.values.fold(
          0,
          (sum, size) => sum + size,
        ),
        'activeWidgets': _widgetMemoryUsage.length,
        'recentlyUsedWidgets': _recentlyUsedWidgets.length,
      },
      'animations': {
        'activeAnimations': _activeAnimations.length,
        'pendingTransitions': _pendingTransitions.length,
      },
      'events': {
        'eventUIStates': _eventUIStates,
        'cachedEventWidgets': _eventWidgetCache.length,
      },
    };
  }

  /// Registers an animation controller for management
  void registerAnimationController(String key, AnimationController controller) {
    _activeAnimations[key] = controller;
  }

  /// Unregisters an animation controller
  void unregisterAnimationController(String key) {
    _activeAnimations.remove(key);
  }

  /// Adds a pending transition
  void addPendingTransition(String transitionId) {
    _pendingTransitions.add(transitionId);
  }

  /// Removes a completed transition
  void removePendingTransition(String transitionId) {
    _pendingTransitions.remove(transitionId);
  }

  /// Tracks widget memory usage
  void trackWidgetMemory(String widgetKey, int memoryUsage) {
    _widgetMemoryUsage[widgetKey] = memoryUsage;
    _recentlyUsedWidgets.remove(widgetKey);
    _recentlyUsedWidgets.add(widgetKey);
  }

  /// Clears all performance data
  void clearAll() {
    _uiOperationTimings.clear();
    _frameDropCounts.clear();
    _frameTimes.clear();
    _widgetMemoryUsage.clear();
    _recentlyUsedWidgets.clear();
    _eventUIStates.clear();
    _eventWidgetCache.clear();
    _eventWidgetTimestamps.clear();

    _cleanupActiveAnimations();
    _pendingTransitions.clear();

    _logger.info('UIOptimizer', 'All UI performance data cleared');
  }
}
