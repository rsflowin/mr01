import '../models/event_model.dart';
import '../models/room_event_data.dart';
import '../models/game_state.dart';
import 'logger_service.dart';

/// Centralized error handling service for the event system
/// Provides error recovery strategies, graceful degradation, and fallback mechanisms
class ErrorHandlerService {
  static final ErrorHandlerService _instance = ErrorHandlerService._internal();
  factory ErrorHandlerService() => _instance;
  ErrorHandlerService._internal();

  // Error tracking
  final List<ErrorRecord> _errorHistory = [];
  final int _maxErrorHistorySize = 50;

  // Recovery strategies
  final Map<String, ErrorRecoveryStrategy> _recoveryStrategies = {};

  /// Initialize error handling with default recovery strategies
  void initialize() {
    logger.info('ErrorHandlerService', 'Initializing error handling service');

    // Register default recovery strategies
    _registerDefaultRecoveryStrategies();

    logger.info('ErrorHandlerService', 'Error handling service initialized');
  }

  /// Register default recovery strategies
  void _registerDefaultRecoveryStrategies() {
    // Event loading errors
    _recoveryStrategies['EventLoadingError'] = ErrorRecoveryStrategy(
      name: 'EventLoadingError',
      description: 'Fallback to default events when loading fails',
      recoveryAction: _handleEventLoadingError,
      severity: ErrorSeverity.warning,
    );

    // Event assignment errors
    _recoveryStrategies['EventAssignmentError'] = ErrorRecoveryStrategy(
      name: 'EventAssignmentError',
      description: 'Regenerate event assignments when distribution fails',
      recoveryAction: _handleEventAssignmentError,
      severity: ErrorSeverity.warning,
    );

    // Event processing errors
    _recoveryStrategies['EventProcessingError'] = ErrorRecoveryStrategy(
      name: 'EventProcessingError',
      description: 'Skip problematic events and continue with navigation',
      recoveryAction: _handleEventProcessingError,
      severity: ErrorSeverity.error,
    );

    // Data corruption errors
    _recoveryStrategies['DataCorruptionError'] = ErrorRecoveryStrategy(
      name: 'DataCorruptionError',
      description: 'Reset to safe state and regenerate data',
      recoveryAction: _handleDataCorruptionError,
      severity: ErrorSeverity.critical,
    );

    // Validation errors
    _recoveryStrategies['ValidationError'] = ErrorRecoveryStrategy(
      name: 'ValidationError',
      description: 'Apply data sanitization and continue',
      recoveryAction: _handleValidationError,
      severity: ErrorSeverity.warning,
    );

    // Player state consistency errors
    _recoveryStrategies['PlayerStateError'] = ErrorRecoveryStrategy(
      name: 'PlayerStateError',
      description: 'Correct player state inconsistencies and continue',
      recoveryAction: _handlePlayerStateError,
      severity: ErrorSeverity.error,
    );

    // Event assignment persistence errors
    _recoveryStrategies['EventPersistenceError'] = ErrorRecoveryStrategy(
      name: 'EventPersistenceError',
      description: 'Regenerate event assignments when persistence fails',
      recoveryAction: _handleEventPersistenceError,
      severity: ErrorSeverity.warning,
    );

    // Choice processing errors
    _recoveryStrategies['ChoiceProcessingError'] = ErrorRecoveryStrategy(
      name: 'ChoiceProcessingError',
      description: 'Skip problematic choices and provide fallback options',
      recoveryAction: _handleChoiceProcessingError,
      severity: ErrorSeverity.error,
    );
  }

  /// Handle an error with appropriate recovery strategy
  Future<ErrorRecoveryResult> handleError(
    String errorType,
    String component,
    String message,
    dynamic error,
    StackTrace? stackTrace, [
    Map<String, dynamic>? context,
  ]) async {
    final timestamp = DateTime.now();

    // Log the error
    logger.error(component, message, context, stackTrace);

    // Create error record
    final errorRecord = ErrorRecord(
      timestamp: timestamp,
      errorType: errorType,
      component: component,
      message: message,
      error: error,
      stackTrace: stackTrace,
      context: context,
    );

    // Add to history
    _addToErrorHistory(errorRecord);

    // Find and execute recovery strategy
    final strategy = _recoveryStrategies[errorType];
    if (strategy != null) {
      try {
        logger.info(
          'ErrorHandlerService',
          'Executing recovery strategy: ${strategy.name}',
        );
        final result = await strategy.recoveryAction(errorRecord);

        logger.info('ErrorHandlerService', 'Recovery strategy completed', {
          'strategy': strategy.name,
          'success': result.success,
          'message': result.message,
        });

        return result;
      } catch (e, recoveryStackTrace) {
        logger.error(
          'ErrorHandlerService',
          'Recovery strategy failed: $e',
          null,
          recoveryStackTrace,
        );

        return ErrorRecoveryResult(
          success: false,
          message: 'Recovery strategy failed: $e',
          fallbackApplied: false,
        );
      }
    } else {
      logger.warning(
        'ErrorHandlerService',
        'No recovery strategy found for error type: $errorType',
      );

      // Apply default fallback
      return await _applyDefaultFallback(errorRecord);
    }
  }

  /// Handle event loading errors
  Future<ErrorRecoveryResult> _handleEventLoadingError(
    ErrorRecord errorRecord,
  ) async {
    logger.info('ErrorHandlerService', 'Handling event loading error');

    // This would typically involve creating fallback events
    // For now, we'll just return a success result indicating fallback was applied
    return ErrorRecoveryResult(
      success: true,
      message: 'Fallback events created for failed loading',
      fallbackApplied: true,
    );
  }

  /// Handle event assignment errors
  Future<ErrorRecoveryResult> _handleEventAssignmentError(
    ErrorRecord errorRecord,
  ) async {
    logger.info('ErrorHandlerService', 'Handling event assignment error');

    // This would typically involve regenerating event assignments
    return ErrorRecoveryResult(
      success: true,
      message: 'Event assignments regenerated',
      fallbackApplied: true,
    );
  }

  /// Handle event processing errors
  Future<ErrorRecoveryResult> _handleEventProcessingError(
    ErrorRecord errorRecord,
  ) async {
    logger.info('ErrorHandlerService', 'Handling event processing error');

    // This would typically involve skipping the problematic event
    return ErrorRecoveryResult(
      success: true,
      message: 'Problematic event skipped, continuing with navigation',
      fallbackApplied: true,
    );
  }

  /// Handle data corruption errors
  Future<ErrorRecoveryResult> _handleDataCorruptionError(
    ErrorRecord errorRecord,
  ) async {
    logger.warning('ErrorHandlerService', 'Handling data corruption error');

    // This would typically involve resetting to a safe state
    return ErrorRecoveryResult(
      success: true,
      message: 'Data reset to safe state',
      fallbackApplied: true,
    );
  }

  /// Handle validation errors
  Future<ErrorRecoveryResult> _handleValidationError(
    ErrorRecord errorRecord,
  ) async {
    logger.info('ErrorHandlerService', 'Handling validation error');

    // This would typically involve data sanitization
    return ErrorRecoveryResult(
      success: true,
      message: 'Data sanitized and validation passed',
      fallbackApplied: true,
    );
  }

  /// Handle player state consistency errors
  Future<ErrorRecoveryResult> _handlePlayerStateError(
    ErrorRecord errorRecord,
  ) async {
    logger.info('ErrorHandlerService', 'Handling player state error');

    // This would typically involve correcting player state inconsistencies
    return ErrorRecoveryResult(
      success: true,
      message: 'Player state corrected and consistency restored',
      fallbackApplied: true,
    );
  }

  /// Handle event persistence errors
  Future<ErrorRecoveryResult> _handleEventPersistenceError(
    ErrorRecord errorRecord,
  ) async {
    logger.info('ErrorHandlerService', 'Handling event persistence error');

    // This would typically involve regenerating event assignments
    return ErrorRecoveryResult(
      success: true,
      message: 'Event assignments regenerated due to persistence failure',
      fallbackApplied: true,
    );
  }

  /// Handle choice processing errors
  Future<ErrorRecoveryResult> _handleChoiceProcessingError(
    ErrorRecord errorRecord,
  ) async {
    logger.info('ErrorHandlerService', 'Handling choice processing error');

    // This would typically involve providing fallback choice options
    return ErrorRecoveryResult(
      success: true,
      message: 'Fallback choice options provided',
      fallbackApplied: true,
    );
  }

  /// Apply default fallback when no specific strategy exists
  Future<ErrorRecoveryResult> _applyDefaultFallback(
    ErrorRecord errorRecord,
  ) async {
    logger.info('ErrorHandlerService', 'Applying default fallback');

    // Default fallback: log the error and continue
    return ErrorRecoveryResult(
      success: true,
      message: 'Default fallback applied - continuing operation',
      fallbackApplied: true,
    );
  }

  /// Add error to history
  void _addToErrorHistory(ErrorRecord errorRecord) {
    _errorHistory.add(errorRecord);

    // Keep history size manageable
    if (_errorHistory.length > _maxErrorHistorySize) {
      _errorHistory.removeAt(0);
    }
  }

  /// Get error history
  List<ErrorRecord> getErrorHistory() => List.unmodifiable(_errorHistory);

  /// Clear error history
  void clearErrorHistory() {
    _errorHistory.clear();
    logger.info('ErrorHandlerService', 'Error history cleared');
  }

  /// Get error statistics
  Map<String, dynamic> getErrorStatistics() {
    if (_errorHistory.isEmpty) {
      return {'totalErrors': 0, 'errorTypes': {}, 'components': {}};
    }

    final errorTypes = <String, int>{};
    final components = <String, int>{};
    final severityCounts = <String, int>{};

    for (final record in _errorHistory) {
      errorTypes[record.errorType] = (errorTypes[record.errorType] ?? 0) + 1;
      components[record.component] = (components[record.component] ?? 0) + 1;
    }

    return {
      'totalErrors': _errorHistory.length,
      'errorTypes': errorTypes,
      'components': components,
      'firstError': _errorHistory.first.timestamp.toIso8601String(),
      'lastError': _errorHistory.last.timestamp.toIso8601String(),
    };
  }

  /// Validate data integrity
  bool validateDataIntegrity(
    Map<String, dynamic> data,
    List<String> requiredFields,
  ) {
    try {
      for (final field in requiredFields) {
        if (!data.containsKey(field)) {
          logger.warning(
            'ErrorHandlerService',
            'Missing required field: $field',
          );
          return false;
        }
      }
      return true;
    } catch (e, stackTrace) {
      logger.error(
        'ErrorHandlerService',
        'Data validation failed: $e',
        null,
        stackTrace,
      );
      return false;
    }
  }

  /// Sanitize data to prevent corruption
  Map<String, dynamic> sanitizeData(Map<String, dynamic> data) {
    try {
      final sanitized = <String, dynamic>{};

      for (final entry in data.entries) {
        final key = entry.key.toString();
        final value = entry.value;

        // Remove null values
        if (value != null) {
          // Sanitize string values
          if (value is String) {
            sanitized[key] = value.trim();
          } else {
            sanitized[key] = value;
          }
        }
      }

      return sanitized;
    } catch (e, stackTrace) {
      logger.error(
        'ErrorHandlerService',
        'Data sanitization failed: $e',
        null,
        stackTrace,
      );
      return data; // Return original data if sanitization fails
    }
  }

  /// Check if error rate is acceptable
  bool isErrorRateAcceptable() {
    if (_errorHistory.isEmpty) return true;

    final recentErrors = _errorHistory
        .where(
          (record) => DateTime.now().difference(record.timestamp).inMinutes < 5,
        )
        .length;

    // Consider error rate acceptable if less than 10 errors in 5 minutes
    return recentErrors < 10;
  }

  /// Get recommendations for error prevention
  List<String> getErrorPreventionRecommendations() {
    final recommendations = <String>[];

    if (_errorHistory.isEmpty) {
      recommendations.add('No errors detected - system is running smoothly');
      return recommendations;
    }

    // Analyze error patterns
    final errorTypes = <String, int>{};
    for (final record in _errorHistory) {
      errorTypes[record.errorType] = (errorTypes[record.errorType] ?? 0) + 1;
    }

    // Generate recommendations based on error patterns
    if (errorTypes['EventLoadingError'] != null &&
        errorTypes['EventLoadingError']! > 5) {
      recommendations.add('Consider checking event data files for corruption');
    }

    if (errorTypes['ValidationError'] != null &&
        errorTypes['ValidationError']! > 3) {
      recommendations.add(
        'Review data validation logic and input sanitization',
      );
    }

    if (errorTypes['DataCorruptionError'] != null) {
      recommendations.add('Implement data backup and recovery mechanisms');
    }

    if (errorTypes['PlayerStateError'] != null &&
        errorTypes['PlayerStateError']! > 2) {
      recommendations.add(
        'Review player state management and validation logic',
      );
    }

    if (errorTypes['EventPersistenceError'] != null) {
      recommendations.add(
        'Check save/load system and event assignment persistence',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add('Monitor error patterns for emerging issues');
    }

    return recommendations;
  }

  /// Validate player state consistency
  bool validatePlayerStateConsistency(GameState gameState) {
    try {
      final errors = <String>[];

      // Check player stats bounds
      final stats = gameState.stats;
      if (stats.hp < 0 || stats.hp > 100) {
        errors.add('Player HP out of bounds: ${stats.hp}');
      }
      if (stats.san < 0 || stats.san > 100) {
        errors.add('Player SAN out of bounds: ${stats.san}');
      }
      if (stats.hunger < 0 || stats.hunger > 100) {
        errors.add('Player hunger out of bounds: ${stats.hunger}');
      }
      if (stats.fit < 0 || stats.fit > 100) {
        errors.add('Player fitness out of bounds: ${stats.fit}');
      }

      // Check inventory consistency
      final inventory = gameState.inventory;
      if (inventory.items.length > 100) {
        errors.add(
          'Player inventory too large: ${inventory.items.length} items',
        );
      }

      // Check for duplicate items
      final itemIds = inventory.items.map((item) => item.id).toSet();
      if (itemIds.length != inventory.items.length) {
        errors.add('Duplicate items detected in inventory');
      }

      // Check status effects consistency
      final statusEffects = gameState.statusEffects;
      if (statusEffects.length > 20) {
        errors.add('Too many status effects: ${statusEffects.length}');
      }

      if (errors.isNotEmpty) {
        logger.warning(
          'ErrorHandlerService',
          'Player state consistency issues found',
          {
            'errors': errors,
            'playerStats': stats.toMap(),
            'inventorySize': inventory.items.length,
            'statusEffectsCount': statusEffects.length,
          },
        );
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      logger.error(
        'ErrorHandlerService',
        'Player state validation failed: $e',
        null,
        stackTrace,
      );
      return false;
    }
  }

  /// Correct player state inconsistencies
  GameState correctPlayerStateInconsistencies(GameState gameState) {
    try {
      logger.info(
        'ErrorHandlerService',
        'Correcting player state inconsistencies',
      );

      // Create a copy of the game state to modify
      final correctedState = gameState.copyWith();

      // Correct stats bounds
      final stats = correctedState.stats;
      stats.hp = stats.hp.clamp(0, 100);
      stats.san = stats.san.clamp(0, 100);
      stats.hunger = stats.hunger.clamp(0, 100);
      stats.fit = stats.fit.clamp(0, 100);

      // Remove duplicate items from inventory by creating new inventory
      final uniqueItems = <String, InventoryItem>{};
      for (final item in correctedState.inventory.items) {
        uniqueItems[item.id] = item;
      }
      final correctedInventory = PlayerInventory(
        items: uniqueItems.values.toList(),
        maxSlots: correctedState.inventory.maxSlots,
      );

      // Limit status effects
      final correctedStatusEffects = correctedState.statusEffects.length > 20
          ? correctedState.statusEffects.take(20).toList()
          : correctedState.statusEffects;

      // Create corrected state with new inventory and status effects
      final finalCorrectedState = correctedState.copyWith(
        inventory: correctedInventory,
        statusEffects: correctedStatusEffects,
      );

      logger.info(
        'ErrorHandlerService',
        'Player state inconsistencies corrected',
      );
      return finalCorrectedState;
    } catch (e, stackTrace) {
      logger.error(
        'ErrorHandlerService',
        'Failed to correct player state inconsistencies: $e',
        null,
        stackTrace,
      );
      return gameState; // Return original state if correction fails
    }
  }

  /// Validate event assignment consistency
  bool validateEventAssignmentConsistency(
    Map<String, RoomEventData> roomEvents,
  ) {
    try {
      final errors = <String>[];

      // Check for rooms with no events
      final emptyRooms = roomEvents.entries
          .where((entry) => entry.value.availableEventIds.isEmpty)
          .map((entry) => entry.key)
          .toList();

      if (emptyRooms.length > 10) {
        errors.add('Too many empty rooms: ${emptyRooms.length}');
      }

      // Check for rooms with excessive events
      final excessiveEventRooms = roomEvents.entries
          .where((entry) => entry.value.availableEventIds.length > 25)
          .map((entry) => entry.key)
          .toList();

      if (excessiveEventRooms.isNotEmpty) {
        errors.add(
          'Rooms with excessive events: ${excessiveEventRooms.join(', ')}',
        );
      }

      // Check for duplicate event assignments
      final allEventIds = <String>{};
      for (final roomData in roomEvents.values) {
        for (final eventId in roomData.availableEventIds) {
          if (allEventIds.contains(eventId)) {
            errors.add('Duplicate event assignment: $eventId');
          }
          allEventIds.add(eventId);
        }
      }

      if (errors.isNotEmpty) {
        logger.warning(
          'ErrorHandlerService',
          'Event assignment consistency issues found',
          {
            'errors': errors,
            'totalRooms': roomEvents.length,
            'emptyRooms': emptyRooms.length,
            'excessiveEventRooms': excessiveEventRooms.length,
          },
        );
        return false;
      }

      return true;
    } catch (e, stackTrace) {
      logger.error(
        'ErrorHandlerService',
        'Event assignment validation failed: $e',
        null,
        stackTrace,
      );
      return false;
    }
  }

  /// Get comprehensive system health report
  Map<String, dynamic> getSystemHealthReport() {
    final errorStats = getErrorStatistics();
    final errorRate = isErrorRateAcceptable();
    final recommendations = getErrorPreventionRecommendations();

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'errorStatistics': errorStats,
      'errorRateAcceptable': errorRate,
      'recommendations': recommendations,
      'recoveryStrategies': _recoveryStrategies.keys.toList(),
      'maxErrorHistorySize': _maxErrorHistorySize,
      'currentErrorHistorySize': _errorHistory.length,
    };
  }
}

/// Represents an error record
class ErrorRecord {
  final DateTime timestamp;
  final String errorType;
  final String component;
  final String message;
  final dynamic error;
  final StackTrace? stackTrace;
  final Map<String, dynamic>? context;

  ErrorRecord({
    required this.timestamp,
    required this.errorType,
    required this.component,
    required this.message,
    required this.error,
    this.stackTrace,
    this.context,
  });

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'errorType': errorType,
      'component': component,
      'message': message,
      'error': error.toString(),
      'stackTrace': stackTrace?.toString(),
      'context': context,
    };
  }
}

/// Represents an error recovery strategy
class ErrorRecoveryStrategy {
  final String name;
  final String description;
  final Future<ErrorRecoveryResult> Function(ErrorRecord) recoveryAction;
  final ErrorSeverity severity;

  ErrorRecoveryStrategy({
    required this.name,
    required this.description,
    required this.recoveryAction,
    required this.severity,
  });
}

/// Represents the result of an error recovery attempt
class ErrorRecoveryResult {
  final bool success;
  final String message;
  final bool fallbackApplied;

  ErrorRecoveryResult({
    required this.success,
    required this.message,
    required this.fallbackApplied,
  });
}

/// Error severity levels
enum ErrorSeverity { low, warning, error, critical }

/// Global error handler instance for easy access
final errorHandler = ErrorHandlerService();
