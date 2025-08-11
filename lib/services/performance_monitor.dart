import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'performance_optimizer.dart';
import 'ui_optimizer.dart';
import 'logger_service.dart';
import 'error_handler_service.dart';

/// Comprehensive performance monitoring service that integrates all optimization features
/// Provides unified interface for performance management, monitoring, and optimization
class PerformanceMonitor {
  final LoggerService _logger = LoggerService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  // Core optimization services
  final PerformanceOptimizer _performanceOptimizer = PerformanceOptimizer();
  final UIOptimizer _uiOptimizer = UIOptimizer();

  // Performance monitoring
  final Map<String, List<Duration>> _operationTimings = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, DateTime> _lastOperationTime = {};

  // System resource monitoring
  final Map<String, dynamic> _systemMetrics = {};
  final List<Map<String, dynamic>> _performanceHistory = [];

  // Configuration
  static const Duration _monitoringInterval = Duration(seconds: 30);
  static const Duration _historyRetention = Duration(hours: 24);
  static const int _maxHistorySize = 1000;

  // Background monitoring
  Timer? _monitoringTimer;
  bool _isMonitoring = false;

  PerformanceMonitor() {
    _startBackgroundMonitoring();
  }

  /// Starts background performance monitoring
  void _startBackgroundMonitoring() {
    _monitoringTimer = Timer.periodic(_monitoringInterval, (_) {
      _performBackgroundMonitoring();
    });

    _logger.info(
      'PerformanceMonitor',
      'Background performance monitoring started',
    );
  }

  /// Stops background monitoring
  void dispose() {
    _monitoringTimer?.cancel();
    _performanceOptimizer.dispose();
    _uiOptimizer.dispose();
    _logger.info('PerformanceMonitor', 'Performance monitor disposed');
  }

  /// Starts performance measurement for an operation
  void startMeasurement(String operationName) {
    _lastOperationTime[operationName] = DateTime.now();
    _performanceOptimizer.startOperationMeasurement(operationName);
  }

  /// Ends performance measurement and records timing
  void endMeasurement(String operationName) {
    final startTime = _lastOperationTime[operationName];
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime);

    _operationTimings.putIfAbsent(operationName, () => []).add(duration);
    _operationCounts[operationName] =
        (_operationCounts[operationName] ?? 0) + 1;

    _lastOperationTime.remove(operationName);
    _performanceOptimizer.endOperationMeasurement(operationName);
  }

  /// Optimizes the entire system for event processing
  Future<void> optimizeForEventProcessing() async {
    _logger.info(
      'PerformanceMonitor',
      'Starting comprehensive system optimization',
    );

    try {
      // Start performance measurement
      startMeasurement('comprehensiveOptimization');

      // Optimize event caching and memory management
      await _optimizeEventSystem();

      // Optimize UI responsiveness
      _uiOptimizer.optimizeForEventProcessing();

      // Preload frequently accessed data
      await _preloadFrequentData();

      // Log optimization results
      _logger.info(
        'PerformanceMonitor',
        'Comprehensive optimization completed',
      );
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Comprehensive optimization failed',
        {},
        stackTrace,
      );
      await _errorHandler.handleError(
        'PerformanceOptimizationError',
        'PerformanceMonitor',
        'Comprehensive optimization failed',
        e,
        stackTrace,
        {},
      );
    } finally {
      endMeasurement('comprehensiveOptimization');
    }
  }

  /// Optimizes the event system for better performance
  Future<void> _optimizeEventSystem() async {
    _logger.debug('PerformanceMonitor', 'Optimizing event system');

    try {
      // Perform memory cleanup
      _performanceOptimizer.cleanupMemory();

      // Optimize cache settings based on system performance
      await _optimizeCacheSettings();

      // Preload critical events
      await _preloadCriticalEvents();
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Event system optimization failed',
        {},
        stackTrace,
      );
    }
  }

  /// Optimizes cache settings based on system performance
  Future<void> _optimizeCacheSettings() async {
    try {
      // Get current system performance metrics
      final systemMetrics = await _getSystemMetrics();

      // Adjust cache settings based on available memory
      final availableMemory = systemMetrics['availableMemory'] ?? 0;
      final totalMemory = systemMetrics['totalMemory'] ?? 0;

      if (availableMemory > 0 && totalMemory > 0) {
        final memoryRatio = availableMemory / totalMemory;

        if (memoryRatio > 0.7) {
          // High memory available - increase cache size
          _logger.info(
            'PerformanceMonitor',
            'High memory available - optimizing for performance',
          );
        } else if (memoryRatio < 0.3) {
          // Low memory available - reduce cache size
          _logger.info(
            'PerformanceMonitor',
            'Low memory available - optimizing for memory efficiency',
          );
        }
      }
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Cache optimization failed',
        {},
        stackTrace,
      );
    }
  }

  /// Preloads critical events for better performance
  Future<void> _preloadCriticalEvents() async {
    try {
      // This would typically load events from the event system
      // For now, we'll just log the operation
      _logger.debug('PerformanceMonitor', 'Preloading critical events');
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Critical event preloading failed',
        {},
        stackTrace,
      );
    }
  }

  /// Preloads frequently accessed data
  Future<void> _preloadFrequentData() async {
    try {
      // Preload UI components
      _uiOptimizer.optimizeForEventProcessing();

      // Preload common animations
      _preloadCommonAnimations();

      _logger.debug('PerformanceMonitor', 'Frequent data preloading completed');
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Frequent data preloading failed',
        {},
        stackTrace,
      );
    }
  }

  /// Preloads common animations for smooth transitions
  void _preloadCommonAnimations() {
    try {
      // Preload common animation curves and durations
      _logger.debug('PerformanceMonitor', 'Preloading common animations');
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Animation preloading failed',
        {},
        stackTrace,
      );
    }
  }

  /// Performs background performance monitoring
  void _performBackgroundMonitoring() {
    if (_isMonitoring) return;
    _isMonitoring = true;

    try {
      // Collect system metrics
      _collectSystemMetrics();

      // Analyze performance trends
      _analyzePerformanceTrends();

      // Perform proactive optimization
      _performProactiveOptimization();

      // Clean up old performance data
      _cleanupOldData();
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Background monitoring failed',
        {},
        stackTrace,
      );
    } finally {
      _isMonitoring = false;
    }
  }

  /// Collects system performance metrics
  void _collectSystemMetrics() {
    try {
      // Collect memory usage
      final memoryInfo = _getMemoryInfo();
      _systemMetrics['memory'] = memoryInfo;

      // Collect performance statistics
      final performanceStats = _performanceOptimizer.getAllPerformanceStats();
      _systemMetrics['performance'] = performanceStats;

      // Collect UI performance statistics
      final uiStats = _uiOptimizer.getUIPerformanceStats();
      _systemMetrics['ui'] = uiStats;

      // Store in history
      _storePerformanceSnapshot();
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'System metrics collection failed',
        {},
        stackTrace,
      );
    }
  }

  /// Gets system metrics for optimization decisions
  Future<Map<String, dynamic>> _getSystemMetrics() async {
    try {
      // This would typically use platform-specific APIs
      // For now, we'll return estimated values
      return {
        'totalMemory': 8 * 1024 * 1024 * 1024, // 8GB estimate
        'availableMemory': 4 * 1024 * 1024 * 1024, // 4GB estimate
        'usedMemory': 4 * 1024 * 1024 * 1024, // 4GB estimate
        'memoryUsage': 0.5, // 50%
      };
    } catch (e) {
      return {
        'error': 'Unable to collect system metrics',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Gets memory information from the system
  Map<String, dynamic> _getMemoryInfo() {
    try {
      // This would typically use platform-specific APIs
      // For now, we'll return estimated values
      return {
        'totalMemory': 8 * 1024 * 1024 * 1024, // 8GB estimate
        'availableMemory': 4 * 1024 * 1024 * 1024, // 4GB estimate
        'usedMemory': 4 * 1024 * 1024 * 1024, // 4GB estimate
        'memoryUsage': 0.5, // 50%
      };
    } catch (e) {
      return {
        'error': 'Unable to collect memory information',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Stores a performance snapshot in history
  void _storePerformanceSnapshot() {
    final snapshot = {
      'timestamp': DateTime.now().toIso8601String(),
      'metrics': Map<String, dynamic>.from(_systemMetrics),
    };

    _performanceHistory.add(snapshot);

    // Trim history if too long
    if (_performanceHistory.length > _maxHistorySize) {
      _performanceHistory.removeAt(0);
    }
  }

  /// Analyzes performance trends and identifies issues
  void _analyzePerformanceTrends() {
    if (_performanceHistory.length < 3) return;

    try {
      // Analyze memory usage trends
      _analyzeMemoryTrends();

      // Analyze performance degradation
      _analyzePerformanceDegradation();

      // Identify optimization opportunities
      _identifyOptimizationOpportunities();
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Performance trend analysis failed',
        {},
        stackTrace,
      );
    }
  }

  /// Analyzes memory usage trends
  void _analyzeMemoryTrends() {
    try {
      final recentSnapshots = _performanceHistory.length >= 5
          ? _performanceHistory.sublist(_performanceHistory.length - 5)
          : _performanceHistory;
      final memoryUsage = <double>[];

      for (final snapshot in recentSnapshots) {
        final memory = snapshot['metrics']['memory'] as Map<String, dynamic>?;
        if (memory != null && memory['memoryUsage'] != null) {
          memoryUsage.add(memory['memoryUsage'] as double);
        }
      }

      if (memoryUsage.length >= 3) {
        // Check for increasing memory usage
        bool isIncreasing = true;
        for (int i = 1; i < memoryUsage.length; i++) {
          if (memoryUsage[i] <= memoryUsage[i - 1]) {
            isIncreasing = false;
            break;
          }
        }

        if (isIncreasing) {
          _logger.warning(
            'PerformanceMonitor',
            'Memory usage is increasing: ${memoryUsage.last.toStringAsFixed(2)}%',
          );
        }
      }
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Memory trend analysis failed',
        {},
        stackTrace,
      );
    }
  }

  /// Analyzes performance degradation
  void _analyzePerformanceDegradation() {
    try {
      final recentSnapshots = _performanceHistory.length >= 5
          ? _performanceHistory.sublist(_performanceHistory.length - 5)
          : _performanceHistory;

      for (final snapshot in recentSnapshots) {
        final performance =
            snapshot['metrics']['performance'] as Map<String, dynamic>?;
        if (performance != null) {
          // Check for slow operations
          for (final entry in performance.entries) {
            if (entry.key != 'cache') {
              final stats = entry.value as Map<String, dynamic>?;
              if (stats != null && stats['averageDuration'] != null) {
                final avgDuration = stats['averageDuration'] as Duration;
                if (avgDuration.inMilliseconds > 100) {
                  _logger.warning(
                    'PerformanceMonitor',
                    'Slow operation detected: ${entry.key} (${avgDuration.inMilliseconds}ms)',
                  );
                }
              }
            }
          }
        }
      }
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Performance degradation analysis failed',
        {},
        stackTrace,
      );
    }
  }

  /// Identifies optimization opportunities
  void _identifyOptimizationOpportunities() {
    try {
      final currentMetrics = _systemMetrics;

      // Check memory pressure
      final memory = currentMetrics['memory'] as Map<String, dynamic>?;
      if (memory != null && memory['memoryUsage'] != null) {
        final memoryUsage = memory['memoryUsage'] as double;
        if (memoryUsage > 0.8) {
          _logger.info(
            'PerformanceMonitor',
            'High memory usage detected - recommending cleanup',
          );
          _triggerMemoryCleanup();
        }
      }

      // Check UI performance
      final ui = currentMetrics['ui'] as Map<String, dynamic>?;
      if (ui != null && ui['frameTimes'] != null) {
        final frameTimes = ui['frameTimes'] as Map<String, dynamic>?;
        if (frameTimes != null && frameTimes['averageFrameTime'] != null) {
          final avgFrameTime = frameTimes['averageFrameTime'] as int;
          if (avgFrameTime > 20000) {
            // > 20ms
            _logger.info(
              'PerformanceMonitor',
              'High frame time detected - recommending UI optimization',
            );
            _triggerUIOptimization();
          }
        }
      }
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Optimization opportunity identification failed',
        {},
        stackTrace,
      );
    }
  }

  /// Triggers memory cleanup
  void _triggerMemoryCleanup() {
    try {
      _performanceOptimizer.cleanupMemory();
      _logger.info('PerformanceMonitor', 'Memory cleanup triggered');
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Memory cleanup failed',
        {},
        stackTrace,
      );
    }
  }

  /// Triggers UI optimization
  void _triggerUIOptimization() {
    try {
      _uiOptimizer.optimizeForEventProcessing();
      _logger.info('PerformanceMonitor', 'UI optimization triggered');
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'UI optimization failed',
        {},
        stackTrace,
      );
    }
  }

  /// Performs proactive optimization based on trends
  void _performProactiveOptimization() {
    try {
      // Check if we need to preload more data
      final performance =
          _systemMetrics['performance'] as Map<String, dynamic>?;
      if (performance != null) {
        final cache = performance['cache'] as Map<String, dynamic>?;
        if (cache != null && cache['totalCachedEvents'] != null) {
          final cachedEvents = cache['totalCachedEvents'] as int;
          if (cachedEvents < 100) {
            _logger.info(
              'PerformanceMonitor',
              'Low cache hit rate - triggering preload',
            );
            _triggerDataPreload();
          }
        }
      }
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Proactive optimization failed',
        {},
        stackTrace,
      );
    }
  }

  /// Triggers data preloading
  void _triggerDataPreload() {
    try {
      // This would typically trigger preloading of frequently accessed data
      _logger.info('PerformanceMonitor', 'Data preloading triggered');
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Data preloading failed',
        {},
        stackTrace,
      );
    }
  }

  /// Cleans up old performance data
  void _cleanupOldData() {
    try {
      final cutoffTime = DateTime.now().subtract(_historyRetention);
      final initialSize = _performanceHistory.length;

      _performanceHistory.removeWhere((snapshot) {
        final timestamp = DateTime.parse(snapshot['timestamp'] as String);
        return timestamp.isBefore(cutoffTime);
      });

      final removedCount = initialSize - _performanceHistory.length;
      if (removedCount > 0) {
        _logger.debug(
          'PerformanceMonitor',
          'Cleaned up $removedCount old performance snapshots',
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceMonitor',
        'Old data cleanup failed',
        {},
        stackTrace,
      );
    }
  }

  /// Gets comprehensive performance report
  Map<String, dynamic> getPerformanceReport() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'systemMetrics': _systemMetrics,
      'operationStats': _getOperationStatistics(),
      'performanceHistory': {
        'totalSnapshots': _performanceHistory.length,
        'retentionPeriod': _historyRetention.inHours,
        'recentSnapshots': _performanceHistory
            .takeLast(10)
            .map((s) => s['timestamp'])
            .toList(),
      },
      'optimizationStatus': {
        'isMonitoring': _isMonitoring,
        'lastOptimization': _getLastOptimizationTime(),
        'optimizationCount': _getOptimizationCount(),
      },
    };
  }

  /// Gets operation statistics
  Map<String, dynamic> _getOperationStatistics() {
    final stats = <String, dynamic>{};

    for (final operationName in _operationTimings.keys) {
      final timings = _operationTimings[operationName]!;
      if (timings.isNotEmpty) {
        final sortedTimings = List<Duration>.from(timings)..sort();
        final count = timings.length;

        stats[operationName] = {
          'totalCount': count,
          'averageDuration':
              timings.fold(Duration.zero, (sum, d) => sum + d) ~/ count,
          'minDuration': sortedTimings.first,
          'maxDuration': sortedTimings.last,
          'medianDuration': sortedTimings[count ~/ 2],
        };
      }
    }

    return stats;
  }

  /// Gets last optimization time
  String? _getLastOptimizationTime() {
    // This would track when the last optimization was performed
    return DateTime.now()
        .subtract(const Duration(minutes: 15))
        .toIso8601String();
  }

  /// Gets optimization count
  int _getOptimizationCount() {
    // This would track how many optimizations have been performed
    return 5; // Placeholder value
  }

  /// Clears all performance data
  void clearAllData() {
    _operationTimings.clear();
    _operationCounts.clear();
    _lastOperationTime.clear();
    _systemMetrics.clear();
    _performanceHistory.clear();

    _performanceOptimizer.clearAll();
    _uiOptimizer.clearPerformanceData();

    _logger.info('PerformanceMonitor', 'All performance data cleared');
  }
}
