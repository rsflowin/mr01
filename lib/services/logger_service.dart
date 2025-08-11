import 'dart:developer' as developer;
import 'dart:io';

/// Centralized logging service for the event system
/// Provides structured logging with different levels, error tracking, and performance monitoring
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  // Log levels
  static const String _debug = 'DEBUG';
  static const String _info = 'INFO';
  static const String _warning = 'WARNING';
  static const String _error = 'ERROR';
  static const String _critical = 'CRITICAL';

  // Configuration
  bool _enableConsoleLogging = true;
  bool _enableFileLogging = false;
  bool _enablePerformanceLogging = true;
  bool _enableEventLogging = true; // New: Event-specific logging
  String _logLevel = _info; // Default log level

  // Performance tracking
  final Map<String, DateTime> _performanceStartTimes = {};
  final Map<String, List<Duration>> _performanceMetrics = {};

  // Error tracking
  final List<LogEntry> _errorLog = [];
  final int _maxErrorLogSize = 100;

  // Event operation tracking
  final List<EventLogEntry> _eventLog = [];
  final int _maxEventLogSize = 200;

  /// Configure logging behavior
  void configure({
    bool? enableConsoleLogging,
    bool? enableFileLogging,
    bool? enablePerformanceLogging,
    bool? enableEventLogging,
    String? logLevel,
  }) {
    _enableConsoleLogging = enableConsoleLogging ?? _enableConsoleLogging;
    _enableFileLogging = enableFileLogging ?? _enableFileLogging;
    _enablePerformanceLogging =
        enablePerformanceLogging ?? _enablePerformanceLogging;
    _enableEventLogging = enableEventLogging ?? _enableEventLogging;
    _logLevel = logLevel ?? _logLevel;

    _log(_info, 'LoggerService', 'Logging configured', {
      'consoleLogging': _enableConsoleLogging,
      'fileLogging': _enableFileLogging,
      'performanceLogging': _enablePerformanceLogging,
      'eventLogging': _enableEventLogging,
      'logLevel': _logLevel,
    });
  }

  /// Log a debug message
  void debug(
    String component,
    String message, [
    Map<String, dynamic>? context,
  ]) {
    _log(_debug, component, message, context);
  }

  /// Log an info message
  void info(String component, String message, [Map<String, dynamic>? context]) {
    _log(_info, component, message, context);
  }

  /// Log a warning message
  void warning(
    String component,
    String message, [
    Map<String, dynamic>? context,
  ]) {
    _log(_warning, component, message, context);
  }

  /// Log an error message
  void error(
    String component,
    String message, [
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  ]) {
    _log(_error, component, message, context, stackTrace);
  }

  /// Log a critical error message
  void critical(
    String component,
    String message, [
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  ]) {
    _log(_critical, component, message, context, stackTrace);
  }

  /// Log event-specific operations with detailed context
  void logEventOperation(
    String operation,
    String eventId,
    String component, [
    Map<String, dynamic>? context,
    bool isSuccess = true,
  ]) {
    if (!_enableEventLogging) return;

    final eventEntry = EventLogEntry(
      timestamp: DateTime.now(),
      operation: operation,
      eventId: eventId,
      component: component,
      context: context,
      isSuccess: isSuccess,
    );

    _addToEventLog(eventEntry);

    // Also log to regular log system
    final level = isSuccess ? _info : _warning;
    final message = '$operation for event $eventId';
    _log(level, component, message, context);
  }

  /// Log event assignment operations
  void logEventAssignment(
    String eventId,
    String roomId,
    String eventType, [
    Map<String, dynamic>? context,
  ]) {
    logEventOperation('EventAssignment', eventId, 'EventDistributor', {
      'roomId': roomId,
      'eventType': eventType,
      ...?context,
    });
  }

  /// Log event loading operations
  void logEventLoading(
    String eventId,
    String eventType,
    String source, [
    Map<String, dynamic>? context,
    bool isSuccess = true,
  ]) {
    logEventOperation('EventLoading', eventId, 'EventLoader', {
      'eventType': eventType,
      'source': source,
      ...?context,
    }, isSuccess);
  }

  /// Log event processing operations
  void logEventProcessing(
    String eventId,
    String roomId,
    String operation, [
    Map<String, dynamic>? context,
    bool isSuccess = true,
  ]) {
    logEventOperation('EventProcessing', eventId, 'EventProcessor', {
      'roomId': roomId,
      'operation': operation,
      ...?context,
    }, isSuccess);
  }

  /// Log choice validation operations
  void logChoiceValidation(
    String eventId,
    String choiceText,
    bool isValid, [
    Map<String, dynamic>? context,
  ]) {
    logEventOperation('ChoiceValidation', eventId, 'EventProcessor', {
      'choiceText': choiceText,
      'isValid': isValid,
      ...?context,
    }, isValid);
  }

  /// Start performance measurement for a named operation
  void startPerformanceMeasurement(String operationName) {
    if (!_enablePerformanceLogging) return;

    _performanceStartTimes[operationName] = DateTime.now();
    _log(_debug, 'Performance', 'Started measurement: $operationName');
  }

  /// End performance measurement and log the duration
  void endPerformanceMeasurement(String operationName) {
    if (!_enablePerformanceLogging) return;

    final startTime = _performanceStartTimes.remove(operationName);
    if (startTime == null) {
      _log(
        _warning,
        'Performance',
        'No start time found for operation: $operationName',
      );
      return;
    }

    final duration = DateTime.now().difference(startTime);

    // Store performance metrics
    _performanceMetrics.putIfAbsent(operationName, () => []).add(duration);

    _log(_info, 'Performance', 'Operation completed: $operationName', {
      'duration': duration.inMilliseconds,
      'durationFormatted': '${duration.inMilliseconds}ms',
    });
  }

  /// Get performance statistics for an operation
  Map<String, dynamic>? getPerformanceStats(String operationName) {
    final metrics = _performanceMetrics[operationName];
    if (metrics == null || metrics.isEmpty) return null;

    final totalDuration = metrics.fold<Duration>(
      Duration.zero,
      (total, duration) => total + duration,
    );

    final avgDuration = Duration(
      milliseconds: totalDuration.inMilliseconds ~/ metrics.length,
    );

    return {
      'operationName': operationName,
      'totalRuns': metrics.length,
      'totalDuration': totalDuration.inMilliseconds,
      'averageDuration': avgDuration.inMilliseconds,
      'minDuration': metrics
          .map((d) => d.inMilliseconds)
          .reduce((a, b) => a < b ? a : b),
      'maxDuration': metrics
          .map((d) => d.inMilliseconds)
          .reduce((a, b) => a > b ? a : b),
    };
  }

  /// Get all performance statistics
  Map<String, Map<String, dynamic>> getAllPerformanceStats() {
    final stats = <String, Map<String, dynamic>>{};
    for (final operationName in _performanceMetrics.keys) {
      final stat = getPerformanceStats(operationName);
      if (stat != null) {
        stats[operationName] = stat;
      }
    }
    return stats;
  }

  /// Get error log entries
  List<LogEntry> getErrorLog() => List.unmodifiable(_errorLog);

  /// Clear error log
  void clearErrorLog() {
    _errorLog.clear();
    _log(_info, 'LoggerService', 'Error log cleared');
  }

  /// Get event log entries
  List<EventLogEntry> getEventLog() => List.unmodifiable(_eventLog);

  /// Clear event log
  void clearEventLog() {
    _eventLog.clear();
    _log(_info, 'LoggerService', 'Event log cleared');
  }

  /// Get event statistics
  Map<String, dynamic> getEventStatistics() {
    if (_eventLog.isEmpty) {
      return {
        'totalEvents': 0,
        'operations': {},
        'components': {},
        'successRate': 0.0,
      };
    }

    final operations = <String, int>{};
    final components = <String, int>{};
    int successfulOperations = 0;

    for (final entry in _eventLog) {
      operations[entry.operation] = (operations[entry.operation] ?? 0) + 1;
      components[entry.component] = (components[entry.component] ?? 0) + 1;
      if (entry.isSuccess) successfulOperations++;
    }

    final successRate = _eventLog.length > 0
        ? (successfulOperations / _eventLog.length) * 100
        : 0.0;

    return {
      'totalEvents': _eventLog.length,
      'operations': operations,
      'components': components,
      'successfulOperations': successfulOperations,
      'successRate': successRate.toStringAsFixed(2),
      'firstEvent': _eventLog.first.timestamp.toIso8601String(),
      'lastEvent': _eventLog.last.timestamp.toIso8601String(),
    };
  }

  /// Export logs to a file (for debugging purposes)
  Future<void> exportLogs(String filePath) async {
    if (!_enableFileLogging) return;

    try {
      final file = File(filePath);
      final buffer = StringBuffer();

      // Add performance stats
      buffer.writeln('=== PERFORMANCE STATISTICS ===');
      final performanceStats = getAllPerformanceStats();
      for (final stat in performanceStats.values) {
        buffer.writeln(
          '${stat['operationName']}: ${stat['totalRuns']} runs, avg: ${stat['averageDuration']}ms',
        );
      }

      // Add event statistics
      buffer.writeln('\n=== EVENT STATISTICS ===');
      final eventStats = getEventStatistics();
      buffer.writeln('Total events: ${eventStats['totalEvents']}');
      buffer.writeln('Success rate: ${eventStats['successRate']}%');
      buffer.writeln('Operations: ${eventStats['operations']}');
      buffer.writeln('Components: ${eventStats['components']}');

      // Add error log
      buffer.writeln('\n=== ERROR LOG ===');
      for (final entry in _errorLog) {
        buffer.writeln(
          '${entry.timestamp}: ${entry.level} - ${entry.component}: ${entry.message}',
        );
        if (entry.context != null) {
          buffer.writeln('  Context: ${entry.context}');
        }
        if (entry.stackTrace != null) {
          buffer.writeln('  Stack trace: ${entry.stackTrace}');
        }
      }

      // Add event log
      buffer.writeln('\n=== EVENT LOG ===');
      for (final entry in _eventLog) {
        buffer.writeln(
          '${entry.timestamp}: ${entry.operation} - ${entry.component} - Event: ${entry.eventId}',
        );
        if (entry.context != null) {
          buffer.writeln('  Context: ${entry.context}');
        }
        buffer.writeln('  Success: ${entry.isSuccess}');
      }

      await file.writeAsString(buffer.toString());
      _log(_info, 'LoggerService', 'Logs exported to: $filePath');
    } catch (e, stackTrace) {
      _log(
        _error,
        'LoggerService',
        'Failed to export logs: $e',
        null,
        stackTrace,
      );
    }
  }

  /// Internal logging method
  void _log(
    String level,
    String component,
    String message, [
    Map<String, dynamic>? context,
    StackTrace? stackTrace,
  ]) {
    // Check if we should log this level
    if (!_shouldLogLevel(level)) return;

    final timestamp = DateTime.now();
    final logEntry = LogEntry(
      timestamp: timestamp,
      level: level,
      component: component,
      message: message,
      context: context,
      stackTrace: stackTrace,
    );

    // Add to error log if it's an error or critical
    if (level == _error || level == _critical) {
      _addToErrorLog(logEntry);
    }

    // Console logging
    if (_enableConsoleLogging) {
      _logToConsole(logEntry);
    }

    // File logging (if enabled)
    if (_enableFileLogging) {
      _logToFile(logEntry);
    }

    // Developer logging for debugging
    developer.log(
      '${logEntry.formattedMessage}',
      name: 'EventSystem',
      level: _getLogLevelValue(level),
    );
  }

  /// Check if we should log at the specified level
  bool _shouldLogLevel(String level) {
    final levelValues = {
      _debug: 0,
      _info: 1,
      _warning: 2,
      _error: 3,
      _critical: 4,
    };

    final currentLevelValue = levelValues[_logLevel] ?? 1;
    final messageLevelValue = levelValues[level] ?? 0;

    return messageLevelValue >= currentLevelValue;
  }

  /// Add entry to error log
  void _addToErrorLog(LogEntry entry) {
    _errorLog.add(entry);

    // Keep error log size manageable
    if (_errorLog.length > _maxErrorLogSize) {
      _errorLog.removeAt(0);
    }
  }

  /// Add entry to event log
  void _addToEventLog(EventLogEntry entry) {
    _eventLog.add(entry);

    // Keep event log size manageable
    if (_eventLog.length > _maxEventLogSize) {
      _eventLog.removeAt(0);
    }
  }

  /// Log to console with color coding
  void _logToConsole(LogEntry entry) {
    final colorCode = _getColorCode(entry.level);
    final resetCode = '\x1B[0m';

    print('$colorCode${entry.formattedMessage}$resetCode');
  }

  /// Log to file
  void _logToFile(LogEntry entry) {
    // Implementation for file logging would go here
    // For now, we'll just use console logging
  }

  /// Get color code for console output
  String _getColorCode(String level) {
    switch (level) {
      case _debug:
        return '\x1B[36m'; // Cyan
      case _info:
        return '\x1B[32m'; // Green
      case _warning:
        return '\x1B[33m'; // Yellow
      case _error:
        return '\x1B[31m'; // Red
      case _critical:
        return '\x1B[35m'; // Magenta
      default:
        return '\x1B[0m'; // Reset
    }
  }

  /// Get log level value for developer.log
  int _getLogLevelValue(String level) {
    switch (level) {
      case _debug:
        return 500;
      case _info:
        return 800;
      case _warning:
        return 900;
      case _error:
        return 1000;
      case _critical:
        return 1200;
      default:
        return 800;
    }
  }

  /// Get comprehensive logging report
  Map<String, dynamic> getLoggingReport() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'configuration': {
        'consoleLogging': _enableConsoleLogging,
        'fileLogging': _enableFileLogging,
        'performanceLogging': _enablePerformanceLogging,
        'eventLogging': _enableEventLogging,
        'logLevel': _logLevel,
      },
      'statistics': {
        'errorLogSize': _errorLog.length,
        'eventLogSize': _eventLog.length,
        'maxErrorLogSize': _maxErrorLogSize,
        'maxEventLogSize': _maxEventLogSize,
      },
      'performance': getAllPerformanceStats(),
      'events': getEventStatistics(),
    };
  }
}

/// Represents a single log entry
class LogEntry {
  final DateTime timestamp;
  final String level;
  final String component;
  final String message;
  final Map<String, dynamic>? context;
  final StackTrace? stackTrace;

  LogEntry({
    required this.timestamp,
    required this.level,
    required this.component,
    required this.message,
    this.context,
    this.stackTrace,
  });

  /// Get formatted message for display
  String get formattedMessage {
    final timeStr = timestamp.toIso8601String();
    final contextStr = context != null ? ' | Context: $context' : '';
    final stackStr = stackTrace != null
        ? ' | Stack: ${stackTrace.toString().split('\n').take(3).join(' | ')}'
        : '';

    return '[$timeStr] $level | $component: $message$contextStr$stackStr';
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'level': level,
      'component': component,
      'message': message,
      'context': context,
      'stackTrace': stackTrace?.toString(),
    };
  }
}

/// Represents a single event log entry
class EventLogEntry {
  final DateTime timestamp;
  final String operation;
  final String eventId;
  final String component;
  final Map<String, dynamic>? context;
  final bool isSuccess;

  EventLogEntry({
    required this.timestamp,
    required this.operation,
    required this.eventId,
    required this.component,
    this.context,
    required this.isSuccess,
  });

  /// Get formatted message for display
  String get formattedMessage {
    final timeStr = timestamp.toIso8601String();
    final status = isSuccess ? 'SUCCESS' : 'FAILED';
    final contextStr = context != null ? ' | Context: $context' : '';

    return '[$timeStr] $operation | $component | Event: $eventId | $status$contextStr';
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'operation': operation,
      'eventId': eventId,
      'component': component,
      'context': context,
      'isSuccess': isSuccess,
    };
  }
}

/// Global logger instance for easy access
final logger = LoggerService();
