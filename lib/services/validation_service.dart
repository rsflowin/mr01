import '../models/event_model.dart';
import '../models/room_event_data.dart';
import '../models/game_state.dart';
import 'logger_service.dart';
import 'error_handler_service.dart';

/// Comprehensive validation service for the event system
/// Provides validation for events, game state, and data integrity
class ValidationService {
  static final ValidationService _instance = ValidationService._internal();
  factory ValidationService() => _instance;
  ValidationService._internal();

  // Validation rules and constraints
  static const int _maxEventWeight = 100;
  static const int _maxStatValue = 100;
  static const int _minStatValue = 0;
  static const int _maxChoiceTextLength = 500;
  static const int _maxEventDescriptionLength = 1000;
  static const int _maxInventorySize = 100;
  static const int _maxStatusEffects = 20;
  static const int _maxEventsPerRoom = 25;
  static const int _maxEmptyRooms = 10;

  /// Initialize validation service
  void initialize() {
    logger.info('ValidationService', 'Initializing validation service');
  }

  /// Validate an Event object comprehensively
  ValidationResult validateEvent(Event event) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Basic structure validation
      if (!_validateEventStructure(event, errors, warnings)) {
        return ValidationResult(
          isValid: false,
          errors: errors,
          warnings: warnings,
          severity: ValidationSeverity.critical,
        );
      }

      // Content validation
      _validateEventContent(event, errors, warnings);

      // Choice validation
      _validateEventChoices(event, errors, warnings);

      // Effect validation
      _validateEventEffects(event, errors, warnings);

      // Weight validation
      _validateEventWeight(event, errors, warnings);
    } catch (e, stackTrace) {
      logger.error(
        'ValidationService',
        'Event validation failed: $e',
        null,
        stackTrace,
      );
      errors.add('Validation process failed: $e');
    }

    final severity = _determineValidationSeverity(errors, warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      severity: severity,
    );
  }

  /// Validate event structure
  bool _validateEventStructure(
    Event event,
    List<String> errors,
    List<String> warnings,
  ) {
    // Required fields
    if (event.id.isEmpty) {
      errors.add('Event ID is required');
    }

    if (event.name.isEmpty) {
      errors.add('Event name is required');
    }

    if (event.description.isEmpty) {
      errors.add('Event description is required');
    }

    if (event.category.isEmpty) {
      errors.add('Event category is required');
    }

    if (event.choices.isEmpty) {
      errors.add('Event must have at least one choice');
    }

    // Validate ID format
    if (!_isValidEventId(event.id)) {
      warnings.add('Event ID format may not be optimal: ${event.id}');
    }

    return errors.isEmpty;
  }

  /// Validate event content
  void _validateEventContent(
    Event event,
    List<String> errors,
    List<String> warnings,
  ) {
    // Description length
    if (event.description.length > _maxEventDescriptionLength) {
      warnings.add(
        'Event description is very long (${event.description.length} characters)',
      );
    }

    // Name length
    if (event.name.length > 100) {
      warnings.add('Event name is very long (${event.name.length} characters)');
    }

    // Category validation
    final validCategories = ['trap', 'item', 'character', 'monster'];
    if (!validCategories.contains(event.category.toLowerCase())) {
      warnings.add(
        'Event category "${event.category}" is not in standard categories',
      );
    }
  }

  /// Validate event choices
  void _validateEventChoices(
    Event event,
    List<String> errors,
    List<String> warnings,
  ) {
    for (int i = 0; i < event.choices.length; i++) {
      final choice = event.choices[i];
      final choiceIndex = i + 1;

      // Choice text validation
      if (choice.text.isEmpty) {
        errors.add('Choice $choiceIndex text is required');
      }

      if (choice.text.length > _maxChoiceTextLength) {
        warnings.add(
          'Choice $choiceIndex text is very long (${choice.text.length} characters)',
        );
      }

      // Choice effects validation
      if (choice.successEffects.description.isEmpty) {
        warnings.add(
          'Choice $choiceIndex success effects description is empty',
        );
      }

      // Requirements validation
      if (choice.requirements != null) {
        _validateChoiceRequirements(
          choice.requirements!,
          choiceIndex,
          errors,
          warnings,
        );
      }

      // Success conditions validation
      if (choice.successConditions != null) {
        _validateSuccessConditions(
          choice.successConditions!,
          choiceIndex,
          errors,
          warnings,
        );
      }
    }
  }

  /// Validate choice requirements
  void _validateChoiceRequirements(
    Map<String, dynamic> requirements,
    int choiceIndex,
    List<String> errors,
    List<String> warnings,
  ) {
    for (final entry in requirements.entries) {
      final key = entry.key;
      final value = entry.value;

      switch (key) {
        case 'items':
          if (value is! List) {
            errors.add('Choice $choiceIndex items requirement must be a list');
          } else if (value.isEmpty) {
            warnings.add('Choice $choiceIndex has empty items requirement');
          }
          break;
        case 'stats':
          if (value is! Map) {
            errors.add('Choice $choiceIndex stats requirement must be a map');
          } else {
            _validateStatRequirements(value, choiceIndex, errors, warnings);
          }
          break;
        case 'statusEffects':
          if (value is! List) {
            errors.add(
              'Choice $choiceIndex statusEffects requirement must be a list',
            );
          }
          break;
        default:
          warnings.add(
            'Choice $choiceIndex has unknown requirement type: $key',
          );
      }
    }
  }

  /// Validate stat requirements
  void _validateStatRequirements(
    Map<dynamic, dynamic> stats,
    int choiceIndex,
    List<String> errors,
    List<String> warnings,
  ) {
    final validStats = ['hp', 'san', 'fit', 'hunger'];

    for (final entry in stats.entries) {
      final statName = entry.key.toString().toLowerCase();
      final statValue = entry.value;

      if (!validStats.contains(statName)) {
        warnings.add(
          'Choice $choiceIndex has unknown stat requirement: $statName',
        );
      }

      if (statValue is! int) {
        errors.add(
          'Choice $choiceIndex stat requirement value must be an integer',
        );
      } else if (statValue < 0 || statValue > 100) {
        warnings.add(
          'Choice $choiceIndex stat requirement value is outside normal range: $statValue',
        );
      }
    }
  }

  /// Validate success conditions
  void _validateSuccessConditions(
    Map<String, dynamic> conditions,
    int choiceIndex,
    List<String> errors,
    List<String> warnings,
  ) {
    for (final entry in conditions.entries) {
      final key = entry.key;
      final value = entry.value;

      switch (key) {
        case 'probability':
          if (value is! int || value < 0 || value > 100) {
            errors.add('Choice $choiceIndex success probability must be 0-100');
          }
          break;
        case 'diceRoll':
          if (value is! Map) {
            errors.add('Choice $choiceIndex diceRoll condition must be a map');
          }
          break;
        default:
          warnings.add(
            'Choice $choiceIndex has unknown success condition: $key',
          );
      }
    }
  }

  /// Validate event effects
  void _validateEventEffects(
    Event event,
    List<String> errors,
    List<String> warnings,
  ) {
    for (int i = 0; i < event.choices.length; i++) {
      final choice = event.choices[i];
      final choiceIndex = i + 1;

      // Success effects validation
      _validateChoiceEffects(
        choice.successEffects,
        choiceIndex,
        'success',
        errors,
        warnings,
      );

      // Failure effects validation
      if (choice.failureEffects != null) {
        _validateChoiceEffects(
          choice.failureEffects!,
          choiceIndex,
          'failure',
          errors,
          warnings,
        );
      }
    }
  }

  /// Validate choice effects
  void _validateChoiceEffects(
    ChoiceEffects effects,
    int choiceIndex,
    String effectType,
    List<String> errors,
    List<String> warnings,
  ) {
    // Stat changes validation
    if (effects.statChanges != null) {
      for (final entry in effects.statChanges!.entries) {
        final statName = entry.key.toLowerCase();
        final statChange = entry.value;

        if (!['hp', 'san', 'fit', 'hunger'].contains(statName)) {
          warnings.add(
            'Choice $choiceIndex $effectType effects has unknown stat: $statName',
          );
        }

        if (statChange.abs() > 50) {
          warnings.add(
            'Choice $choiceIndex $effectType effects has large stat change: $statChange',
          );
        }
      }
    }

    // Items validation
    if (effects.itemsGained != null && effects.itemsGained!.isEmpty) {
      warnings.add(
        'Choice $choiceIndex $effectType effects has empty itemsGained list',
      );
    }

    if (effects.itemsLost != null && effects.itemsLost!.isEmpty) {
      warnings.add(
        'Choice $choiceIndex $effectType effects has empty itemsLost list',
      );
    }

    // Status effects validation
    if (effects.applyStatus != null && effects.applyStatus!.isEmpty) {
      warnings.add(
        'Choice $choiceIndex $effectType effects has empty applyStatus list',
      );
    }
  }

  /// Validate event weight
  void _validateEventWeight(
    Event event,
    List<String> errors,
    List<String> warnings,
  ) {
    if (event.weight <= 0) {
      errors.add('Event weight must be positive');
    }

    if (event.weight > _maxEventWeight) {
      warnings.add(
        'Event weight ${event.weight} is very high (max recommended: $_maxEventWeight)',
      );
    }

    if (event.weight < 5) {
      warnings.add(
        'Event weight ${event.weight} is very low (min recommended: 5)',
      );
    }
  }

  /// Validate event ID format
  bool _isValidEventId(String id) {
    // Check if ID follows a reasonable pattern
    if (id.length < 3 || id.length > 50) return false;
    if (!RegExp(r'^[a-zA-Z0-9_-]+$').hasMatch(id)) return false;
    return true;
  }

  /// Validate RoomEventData
  ValidationResult validateRoomEventData(RoomEventData roomData) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Basic structure validation
      if (roomData.roomId.isEmpty) {
        errors.add('Room ID is required');
      }

      // Event count validation
      if (roomData.eventCount < 0) {
        errors.add('Event count cannot be negative');
      }

      // Available events validation
      if (roomData.availableEventIds.length != roomData.eventCount) {
        warnings.add(
          'Available event count (${roomData.availableEventIds.length}) does not match event count (${roomData.eventCount})',
        );
      }

      // Consumed events validation
      if (roomData.consumedEventIds.isNotEmpty &&
          roomData.availableEventIds.isEmpty) {
        warnings.add('Room has consumed events but no available events');
      }
    } catch (e, stackTrace) {
      logger.error(
        'ValidationService',
        'RoomEventData validation failed: $e',
        null,
        stackTrace,
      );
      errors.add('Validation process failed: $e');
    }

    final severity = _determineValidationSeverity(errors, warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      severity: severity,
    );
  }

  /// Validate GameState
  ValidationResult validateGameState(GameState gameState) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Player stats validation
      _validatePlayerStats(gameState.stats, errors, warnings);

      // Inventory validation
      _validateInventory(gameState.inventory, errors, warnings);

      // Status effects validation
      _validateStatusEffects(gameState.statusEffects, errors, warnings);

      // Turn count validation
      if (gameState.turnCount < 0) {
        errors.add('Turn count cannot be negative');
      }

      // Start time validation
      if (gameState.startTime.isAfter(DateTime.now())) {
        warnings.add('Game start time is in the future');
      }

      // Validate game state consistency
      _validateGameStateConsistency(gameState, errors, warnings);
    } catch (e, stackTrace) {
      logger.error(
        'ValidationService',
        'GameState validation failed: $e',
        null,
        stackTrace,
      );
      errors.add('Validation process failed: $e');
    }

    final severity = _determineValidationSeverity(errors, warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      severity: severity,
    );
  }

  /// Validate player stats
  void _validatePlayerStats(
    PlayerStats stats,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check stat bounds
    if (stats.hp < _minStatValue || stats.hp > _maxStatValue) {
      errors.add(
        'Player HP out of bounds: ${stats.hp} (should be $_minStatValue-$_maxStatValue)',
      );
    }

    if (stats.san < _minStatValue || stats.san > _maxStatValue) {
      errors.add(
        'Player SAN out of bounds: ${stats.san} (should be $_minStatValue-$_maxStatValue)',
      );
    }

    if (stats.fit < _minStatValue || stats.fit > _maxStatValue) {
      errors.add(
        'Player fitness out of bounds: ${stats.fit} (should be $_minStatValue-$_maxStatValue)',
      );
    }

    if (stats.hunger < _minStatValue || stats.hunger > _maxStatValue) {
      errors.add(
        'Player hunger out of bounds: ${stats.hunger} (should be $_minStatValue-$_maxStatValue)',
      );
    }

    // Check for critical stat levels
    if (stats.hp <= 10) {
      warnings.add('Player HP is critically low: ${stats.hp}');
    }

    if (stats.san <= 10) {
      warnings.add('Player SAN is critically low: ${stats.san}');
    }

    if (stats.hunger <= 10) {
      warnings.add('Player hunger is critically low: ${stats.hunger}');
    }

    if (stats.fit <= 10) {
      warnings.add('Player fitness is critically low: ${stats.fit}');
    }
  }

  /// Validate inventory
  void _validateInventory(
    PlayerInventory inventory,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check inventory size
    if (inventory.items.length > _maxInventorySize) {
      errors.add(
        'Inventory too large: ${inventory.items.length} items (max: $_maxInventorySize)',
      );
    }

    if (inventory.items.length > inventory.maxSlots) {
      warnings.add(
        'Inventory has more items than max slots: ${inventory.items.length}/${inventory.maxSlots}',
      );
    }

    // Check for duplicate items
    final itemIds = inventory.items.map((item) => item.id).toSet();
    if (itemIds.length != inventory.items.length) {
      warnings.add('Duplicate items detected in inventory');
    }

    // Validate individual items
    for (int i = 0; i < inventory.items.length; i++) {
      final item = inventory.items[i];
      final itemIndex = i + 1;

      if (item.id.isEmpty) {
        errors.add('Inventory item $itemIndex has empty ID');
      }

      if (item.name.isEmpty) {
        warnings.add('Inventory item $itemIndex has empty name');
      }

      if (item.quantity <= 0) {
        errors.add(
          'Inventory item $itemIndex has invalid quantity: ${item.quantity}',
        );
      }

      if (item.quantity > 99) {
        warnings.add(
          'Inventory item $itemIndex has very high quantity: ${item.quantity}',
        );
      }
    }
  }

  /// Validate status effects
  void _validateStatusEffects(
    List<StatusEffect> statusEffects,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check status effects count
    if (statusEffects.length > _maxStatusEffects) {
      errors.add(
        'Too many status effects: ${statusEffects.length} (max: $_maxStatusEffects)',
      );
    }

    // Validate individual status effects
    for (int i = 0; i < statusEffects.length; i++) {
      final effect = statusEffects[i];
      final effectIndex = i + 1;

      if (effect.id.isEmpty) {
        errors.add('Status effect $effectIndex has empty ID');
      }

      if (effect.name.isEmpty) {
        warnings.add('Status effect $effectIndex has empty name');
      }

      if (!['BUFF', 'DEBUFF'].contains(effect.type)) {
        errors.add(
          'Status effect $effectIndex has invalid type: ${effect.type}',
        );
      }

      if (effect.remainingDuration <= 0) {
        warnings.add(
          'Status effect $effectIndex has expired or invalid duration: ${effect.remainingDuration}',
        );
      }

      if (effect.remainingDuration > 100) {
        warnings.add(
          'Status effect $effectIndex has very long duration: ${effect.remainingDuration}',
        );
      }
    }

    // Check for duplicate status effects
    final effectIds = statusEffects.map((effect) => effect.id).toSet();
    if (effectIds.length != statusEffects.length) {
      warnings.add('Duplicate status effects detected');
    }
  }

  /// Validate game state consistency
  void _validateGameStateConsistency(
    GameState gameState,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check turn count consistency
    if (gameState.turnCount < 0) {
      errors.add('Turn count cannot be negative: ${gameState.turnCount}');
    }

    if (gameState.turnCount > 10000) {
      warnings.add('Turn count is very high: ${gameState.turnCount}');
    }

    // Check start time consistency
    if (gameState.startTime.isAfter(DateTime.now())) {
      errors.add('Game start time is in the future: ${gameState.startTime}');
    }

    // Check for game over conditions
    if (gameState.isGameOver) {
      warnings.add('Game is in game over state: ${gameState.gameOverReason}');
    }

    // Check current event consistency
    if (gameState.currentEventId != null && gameState.currentEvent == null) {
      warnings.add('Current event ID set but no event data available');
    }

    if (gameState.currentEvent != null && gameState.currentEventId == null) {
      warnings.add('Current event data available but no event ID set');
    }
  }

  /// Validate event assignment consistency
  ValidationResult validateEventAssignment(
    Map<String, RoomEventData> roomEvents,
    Map<String, Event> eventDatabase,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Check for rooms with no events
      final emptyRooms = roomEvents.entries
          .where((entry) => entry.value.availableEventIds.isEmpty)
          .map((entry) => entry.key)
          .toList();

      if (emptyRooms.length > _maxEmptyRooms) {
        warnings.add(
          'Too many empty rooms: ${emptyRooms.length} (max recommended: $_maxEmptyRooms)',
        );
      }

      // Check for rooms with excessive events
      final excessiveEventRooms = roomEvents.entries
          .where(
            (entry) => entry.value.availableEventIds.length > _maxEventsPerRoom,
          )
          .map((entry) => entry.key)
          .toList();

      if (excessiveEventRooms.isNotEmpty) {
        warnings.add(
          'Rooms with excessive events: ${excessiveEventRooms.join(', ')}',
        );
      }

      // Check for duplicate event assignments
      final allEventIds = <String>{};
      for (final roomData in roomEvents.values) {
        for (final eventId in roomData.availableEventIds) {
          if (allEventIds.contains(eventId)) {
            warnings.add('Duplicate event assignment: $eventId');
          }
          allEventIds.add(eventId);
        }
      }

      // Validate that all assigned events exist in database
      for (final eventId in allEventIds) {
        if (!eventDatabase.containsKey(eventId)) {
          errors.add('Assigned event not found in database: $eventId');
        }
      }

      // Check trap room exclusivity
      for (final entry in roomEvents.entries) {
        final roomData = entry.value;
        if (roomData.hasTrapEvent && roomData.availableEventIds.length > 1) {
          warnings.add(
            'Trap room ${entry.key} has additional events beyond trap',
          );
        }
      }
    } catch (e, stackTrace) {
      logger.error(
        'ValidationService',
        'Event assignment validation failed: $e',
        null,
        stackTrace,
      );
      errors.add('Event assignment validation process failed: $e');
    }

    final severity = _determineValidationSeverity(errors, warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      severity: severity,
    );
  }

  /// Enhanced validation for player state consistency
  /// Provides comprehensive validation across all player state aspects
  ValidationResult validatePlayerStateConsistency(GameState gameState) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Core player stats validation
      _validatePlayerStatsConsistency(gameState.stats, errors, warnings);

      // Inventory consistency validation
      _validateInventoryConsistency(gameState.inventory, errors, warnings);

      // Status effects consistency validation
      _validateStatusEffectsConsistency(
        gameState.statusEffects,
        errors,
        warnings,
      );

      // Game state logical consistency
      _validateGameStateLogicalConsistency(gameState, errors, warnings);

      // Player state transition validation
      _validatePlayerStateTransitions(gameState, errors, warnings);

      // Cross-reference validation between different state components
      _validateCrossReferenceConsistency(gameState, errors, warnings);
    } catch (e, stackTrace) {
      logger.error(
        'ValidationService',
        'Player state consistency validation failed: $e',
        null,
        stackTrace,
      );
      errors.add('Validation process failed: $e');
    }

    final severity = _determineValidationSeverity(errors, warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      severity: severity,
    );
  }

  /// Validate player stats consistency with enhanced checks
  void _validatePlayerStatsConsistency(
    PlayerStats stats,
    List<String> errors,
    List<String> warnings,
  ) {
    // Basic bounds validation
    if (stats.hp < _minStatValue || stats.hp > _maxStatValue) {
      errors.add(
        'Player HP out of bounds: ${stats.hp} (should be $_minStatValue-$_maxStatValue)',
      );
    }

    if (stats.san < _minStatValue || stats.san > _maxStatValue) {
      errors.add(
        'Player SAN out of bounds: ${stats.san} (should be $_minStatValue-$_maxStatValue)',
      );
    }

    if (stats.fit < _minStatValue || stats.fit > _maxStatValue) {
      errors.add(
        'Player fitness out of bounds: ${stats.fit} (should be $_minStatValue-$_maxStatValue)',
      );
    }

    if (stats.hunger < _minStatValue || stats.hunger > _maxStatValue) {
      errors.add(
        'Player hunger out of bounds: ${stats.hunger} (should be $_minStatValue-$_maxStatValue)',
      );
    }

    // Critical stat level warnings
    if (stats.hp <= 10) {
      warnings.add('Player HP is critically low: ${stats.hp}');
    }

    if (stats.san <= 10) {
      warnings.add('Player SAN is critically low: ${stats.san}');
    }

    if (stats.hunger <= 10) {
      warnings.add('Player hunger is critically low: ${stats.hunger}');
    }

    if (stats.fit <= 10) {
      warnings.add('Player fitness is critically low: ${stats.fit}');
    }

    // Stat relationship validation
    if (stats.hp == 0 && stats.san > 0) {
      warnings.add(
        'Player is dead (HP=0) but still has sanity (SAN=${stats.san})',
      );
    }

    if (stats.san == 0 && stats.hp > 0) {
      warnings.add('Player is insane (SAN=0) but still alive (HP=${stats.hp})');
    }

    // Stat balance warnings
    if (stats.hp > 80 && stats.san < 20) {
      warnings.add(
        'Player has high HP (${stats.hp}) but low SAN (${stats.san}) - unusual state',
      );
    }

    if (stats.fit > 80 && stats.hunger < 20) {
      warnings.add(
        'Player has high fitness (${stats.fit}) but low hunger (${stats.hunger}) - unusual state',
      );
    }
  }

  /// Validate inventory consistency with enhanced checks
  void _validateInventoryConsistency(
    PlayerInventory inventory,
    List<String> errors,
    List<String> warnings,
  ) {
    // Basic inventory size validation
    if (inventory.items.length > _maxInventorySize) {
      errors.add(
        'Inventory too large: ${inventory.items.length} items (max: $_maxInventorySize)',
      );
    }

    if (inventory.items.length > inventory.maxSlots) {
      warnings.add(
        'Inventory has more items than max slots: ${inventory.items.length}/${inventory.maxSlots}',
      );
    }

    // Check for duplicate items
    final itemIds = inventory.items.map((item) => item.id).toSet();
    if (itemIds.length != inventory.items.length) {
      warnings.add('Duplicate items detected in inventory');
    }

    // Validate individual items
    for (int i = 0; i < inventory.items.length; i++) {
      final item = inventory.items[i];
      final itemIndex = i + 1;

      if (item.id.isEmpty) {
        errors.add('Inventory item $itemIndex has empty ID');
      }

      if (item.name.isEmpty) {
        warnings.add('Inventory item $itemIndex has empty name');
      }

      if (item.quantity <= 0) {
        errors.add(
          'Inventory item $itemIndex has invalid quantity: ${item.quantity}',
        );
      }

      if (item.quantity > 99) {
        warnings.add(
          'Inventory item $itemIndex has very high quantity: ${item.quantity}',
        );
      }

      // Check for suspicious item quantities
      if (item.quantity > 50) {
        warnings.add(
          'Inventory item $itemIndex has unusually high quantity: ${item.quantity}',
        );
      }
    }

    // Inventory slot validation
    if (inventory.maxSlots <= 0) {
      errors.add('Inventory max slots must be positive: ${inventory.maxSlots}');
    }

    if (inventory.maxSlots > 50) {
      warnings.add('Inventory max slots is very high: ${inventory.maxSlots}');
    }
  }

  /// Validate status effects consistency with enhanced checks
  void _validateStatusEffectsConsistency(
    List<StatusEffect> statusEffects,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check status effects count
    if (statusEffects.length > _maxStatusEffects) {
      errors.add(
        'Too many status effects: ${statusEffects.length} (max: $_maxStatusEffects)',
      );
    }

    // Validate individual status effects
    for (int i = 0; i < statusEffects.length; i++) {
      final effect = statusEffects[i];
      final effectIndex = i + 1;

      if (effect.id.isEmpty) {
        errors.add('Status effect $effectIndex has empty ID');
      }

      if (effect.name.isEmpty) {
        warnings.add('Status effect $effectIndex has empty name');
      }

      if (!['BUFF', 'DEBUFF'].contains(effect.type)) {
        errors.add(
          'Status effect $effectIndex has invalid type: ${effect.type}',
        );
      }

      if (effect.remainingDuration <= 0) {
        warnings.add(
          'Status effect $effectIndex has expired or invalid duration: ${effect.remainingDuration}',
        );
      }

      if (effect.remainingDuration > 100) {
        warnings.add(
          'Status effect $effectIndex has very long duration: ${effect.remainingDuration}',
        );
      }

      // Check for suspicious durations
      if (effect.remainingDuration > 50) {
        warnings.add(
          'Status effect $effectIndex has unusually long duration: ${effect.remainingDuration}',
        );
      }
    }

    // Check for duplicate status effects
    final effectIds = statusEffects.map((effect) => effect.id).toSet();
    if (effectIds.length != statusEffects.length) {
      warnings.add('Duplicate status effects detected');
    }

    // Check for conflicting status effects
    _validateStatusEffectConflicts(statusEffects, warnings);
  }

  /// Validate status effect conflicts
  void _validateStatusEffectConflicts(
    List<StatusEffect> statusEffects,
    List<String> warnings,
  ) {
    // Group effects by type
    final buffs = statusEffects.where((e) => e.isBuff).toList();
    final debuffs = statusEffects.where((e) => e.isDebuff).toList();

    // Check for excessive buffs
    if (buffs.length > 10) {
      warnings.add('Player has many active buffs: ${buffs.length}');
    }

    // Check for excessive debuffs
    if (debuffs.length > 10) {
      warnings.add('Player has many active debuffs: ${debuffs.length}');
    }

    // Check for conflicting effect types (e.g., both buff and debuff for same stat)
    // This would require more detailed effect metadata to implement properly
  }

  /// Validate game state logical consistency
  void _validateGameStateLogicalConsistency(
    GameState gameState,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check turn count consistency
    if (gameState.turnCount < 0) {
      errors.add('Turn count cannot be negative: ${gameState.turnCount}');
    }

    if (gameState.turnCount > 10000) {
      warnings.add('Turn count is very high: ${gameState.turnCount}');
    }

    // Check start time consistency
    if (gameState.startTime.isAfter(DateTime.now())) {
      errors.add('Game start time is in the future: ${gameState.startTime}');
    }

    // Check for game over conditions
    if (gameState.isGameOver) {
      warnings.add('Game is in game over state: ${gameState.gameOverReason}');
    }

    // Check current event consistency
    if (gameState.currentEventId != null && gameState.currentEvent == null) {
      warnings.add('Current event ID set but no event data available');
    }

    if (gameState.currentEvent != null && gameState.currentEventId == null) {
      warnings.add('Current event data available but no event ID set');
    }

    // Check for logical inconsistencies in game state
    if (gameState.stats.hp == 0 && gameState.turnCount > 0) {
      warnings.add(
        'Player is dead but game has progressed: ${gameState.turnCount} turns',
      );
    }

    if (gameState.stats.san == 0 && gameState.turnCount > 0) {
      warnings.add(
        'Player is insane but game has progressed: ${gameState.turnCount} turns',
      );
    }
  }

  /// Validate player state transitions
  void _validatePlayerStateTransitions(
    GameState gameState,
    List<String> errors,
    List<String> warnings,
  ) {
    // This method would validate that state changes are reasonable
    // For now, we'll add basic transition validation

    // Check for sudden stat changes that might indicate bugs
    // This would require previous state comparison

    // Check for inventory changes that don't make sense
    if (gameState.inventory.items.length > 20 && gameState.turnCount < 10) {
      warnings.add(
        'Player has many items (${gameState.inventory.items.length}) early in game (turn ${gameState.turnCount})',
      );
    }

    // Check for status effect accumulation
    if (gameState.statusEffects.length > 15 && gameState.turnCount < 20) {
      warnings.add(
        'Player has many status effects (${gameState.statusEffects.length}) early in game (turn ${gameState.turnCount})',
      );
    }
  }

  /// Validate cross-reference consistency between different state components
  void _validateCrossReferenceConsistency(
    GameState gameState,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check if inventory items have valid references
    for (final item in gameState.inventory.items) {
      if (item.id.isEmpty || item.name.isEmpty) {
        warnings.add(
          'Inventory item has incomplete data: ID="${item.id}", Name="${item.name}"',
        );
      }
    }

    // Check if status effects have valid references
    for (final effect in gameState.statusEffects) {
      if (effect.id.isEmpty || effect.name.isEmpty) {
        warnings.add(
          'Status effect has incomplete data: ID="${effect.id}", Name="${effect.name}"',
        );
      }
    }

    // Check for consistency between stats and status effects
    // This would require more detailed effect metadata to implement properly
  }

  /// Validate player state before and after event processing
  ValidationResult validatePlayerStateTransition(
    GameState beforeState,
    GameState afterState,
    String eventId,
  ) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      // Check for unreasonable stat changes
      _validateStatChanges(
        beforeState.stats,
        afterState.stats,
        errors,
        warnings,
      );

      // Check for unreasonable inventory changes
      _validateInventoryChanges(
        beforeState.inventory,
        afterState.inventory,
        errors,
        warnings,
      );

      // Check for unreasonable status effect changes
      _validateStatusEffectChanges(
        beforeState.statusEffects,
        afterState.statusEffects,
        errors,
        warnings,
      );

      // Check turn count increment
      if (afterState.turnCount != beforeState.turnCount + 1) {
        warnings.add(
          'Turn count should increment by 1, but changed from ${beforeState.turnCount} to ${afterState.turnCount}',
        );
      }
    } catch (e, stackTrace) {
      logger.error(
        'ValidationService',
        'Player state transition validation failed: $e',
        null,
        stackTrace,
      );
      errors.add('Transition validation process failed: $e');
    }

    final severity = _determineValidationSeverity(errors, warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      severity: severity,
    );
  }

  /// Validate stat changes between states
  void _validateStatChanges(
    PlayerStats beforeStats,
    PlayerStats afterStats,
    List<String> errors,
    List<String> warnings,
  ) {
    final hpChange = afterStats.hp - beforeStats.hp;
    final sanChange = afterStats.san - beforeStats.san;
    final fitChange = afterStats.fit - beforeStats.fit;
    final hungerChange = afterStats.hunger - beforeStats.hunger;

    // Check for unreasonable stat changes
    if (hpChange.abs() > 50) {
      warnings.add(
        'Large HP change: $hpChange (from ${beforeStats.hp} to ${afterStats.hp})',
      );
    }

    if (sanChange.abs() > 50) {
      warnings.add(
        'Large SAN change: $sanChange (from ${beforeStats.san} to ${afterStats.san})',
      );
    }

    if (fitChange.abs() > 50) {
      warnings.add(
        'Large fitness change: $fitChange (from ${beforeStats.fit} to ${afterStats.fit})',
      );
    }

    if (hungerChange.abs() > 50) {
      warnings.add(
        'Large hunger change: $hungerChange (from ${beforeStats.hunger} to ${afterStats.hunger})',
      );
    }

    // Check for impossible stat changes
    if (afterStats.hp > 100 || afterStats.hp < 0) {
      errors.add('HP changed to invalid value: ${afterStats.hp}');
    }

    if (afterStats.san > 100 || afterStats.san < 0) {
      errors.add('SAN changed to invalid value: ${afterStats.san}');
    }

    if (afterStats.fit > 100 || afterStats.fit < 0) {
      errors.add('Fitness changed to invalid value: ${afterStats.fit}');
    }

    if (afterStats.hunger > 100 || afterStats.hunger < 0) {
      errors.add('Hunger changed to invalid value: ${afterStats.hunger}');
    }
  }

  /// Validate inventory changes between states
  void _validateInventoryChanges(
    PlayerInventory beforeInventory,
    PlayerInventory afterInventory,
    List<String> errors,
    List<String> warnings,
  ) {
    final itemCountChange =
        afterInventory.items.length - beforeInventory.items.length;

    // Check for unreasonable inventory size changes
    if (itemCountChange.abs() > 10) {
      warnings.add('Large inventory size change: $itemCountChange items');
    }

    // Check for inventory overflow
    if (afterInventory.items.length > afterInventory.maxSlots) {
      warnings.add(
        'Inventory size (${afterInventory.items.length}) exceeds max slots (${afterInventory.maxSlots})',
      );
    }

    // Check for duplicate items after changes
    final afterItemIds = afterInventory.items.map((item) => item.id).toSet();
    if (afterItemIds.length != afterInventory.items.length) {
      warnings.add('Duplicate items detected after inventory changes');
    }
  }

  /// Validate status effect changes between states
  void _validateStatusEffectChanges(
    List<StatusEffect> beforeEffects,
    List<StatusEffect> afterEffects,
    List<String> errors,
    List<String> warnings,
  ) {
    final effectCountChange = afterEffects.length - beforeEffects.length;

    // Check for unreasonable status effect count changes
    if (effectCountChange.abs() > 5) {
      warnings.add(
        'Large status effect count change: $effectCountChange effects',
      );
    }

    // Check for expired effects that weren't removed
    final expiredEffects = afterEffects
        .where((effect) => effect.remainingDuration <= 0)
        .toList();
    if (expiredEffects.isNotEmpty) {
      warnings.add(
        '${expiredEffects.length} expired status effects still present',
      );
    }

    // Check for duplicate effects after changes
    final afterEffectIds = afterEffects.map((effect) => effect.id).toSet();
    if (afterEffectIds.length != afterEffects.length) {
      warnings.add('Duplicate status effects detected after changes');
    }
  }

  /// Determine validation severity based on errors and warnings
  ValidationSeverity _determineValidationSeverity(
    List<String> errors,
    List<String> warnings,
  ) {
    if (errors.isNotEmpty) {
      if (errors.any(
        (error) =>
            error.contains('required') || error.contains('out of bounds'),
      )) {
        return ValidationSeverity.critical;
      }
      return ValidationSeverity.error;
    }

    if (warnings.isNotEmpty) {
      if (warnings.any((warning) => warning.contains('critically low'))) {
        return ValidationSeverity.warning;
      }
      return ValidationSeverity.low;
    }

    return ValidationSeverity.low;
  }

  /// Get comprehensive validation report
  Map<String, dynamic> getValidationReport() {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'validationRules': {
        'maxEventWeight': _maxEventWeight,
        'maxStatValue': _maxStatValue,
        'minStatValue': _minStatValue,
        'maxChoiceTextLength': _maxChoiceTextLength,
        'maxEventDescriptionLength': _maxEventDescriptionLength,
        'maxInventorySize': _maxInventorySize,
        'maxStatusEffects': _maxStatusEffects,
        'maxEventsPerRoom': _maxEventsPerRoom,
        'maxEmptyRooms': _maxEmptyRooms,
      },
      'recommendations': [
        'Validate events before assignment',
        'Check player state consistency regularly',
        'Monitor event assignment distribution',
        'Review validation warnings for optimization',
      ],
    };
  }

  /// Get validation summary statistics
  Map<String, dynamic> getValidationSummary(List<ValidationResult> results) {
    int totalValidations = results.length;
    int passedValidations = results.where((r) => r.isValid).length;
    int failedValidations = totalValidations - passedValidations;

    int totalErrors = results.fold(0, (sum, r) => sum + r.errors.length);
    int totalWarnings = results.fold(0, (sum, r) => sum + r.warnings.length);

    return {
      'totalValidations': totalValidations,
      'passedValidations': passedValidations,
      'failedValidations': failedValidations,
      'totalErrors': totalErrors,
      'totalWarnings': totalWarnings,
      'successRate': totalValidations > 0
          ? (passedValidations / totalValidations * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  /// Integrate player state validation with game flow
  /// This method should be called at key points in the game to ensure consistency
  ValidationResult validateGameFlowConsistency(
    GameState gameState,
    String flowPoint, {
    Map<String, dynamic>? context,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    try {
      logger.info(
        'ValidationService',
        'Validating game flow consistency at: $flowPoint',
      );

      // Perform comprehensive player state validation
      final stateValidation = validatePlayerStateConsistency(gameState);
      errors.addAll(stateValidation.errors);
      warnings.addAll(stateValidation.warnings);

      // Add flow-specific validation based on context
      switch (flowPoint) {
        case 'event_start':
          _validateEventStartConsistency(gameState, context, errors, warnings);
          break;
        case 'event_choice':
          _validateEventChoiceConsistency(gameState, context, errors, warnings);
          break;
        case 'event_complete':
          _validateEventCompleteConsistency(
            gameState,
            context,
            errors,
            warnings,
          );
          break;
        case 'turn_start':
          _validateTurnStartConsistency(gameState, context, errors, warnings);
          break;
        case 'turn_end':
          _validateTurnEndConsistency(gameState, context, errors, warnings);
          break;
        case 'save_game':
          _validateSaveGameConsistency(gameState, context, errors, warnings);
          break;
        case 'load_game':
          _validateLoadGameConsistency(gameState, context, errors, warnings);
          break;
        default:
          warnings.add('Unknown flow point: $flowPoint');
      }

      // Log validation results
      if (errors.isNotEmpty || warnings.isNotEmpty) {
        logger.warning(
          'ValidationService',
          'Game flow consistency issues found at $flowPoint',
          {
            'flowPoint': flowPoint,
            'errors': errors,
            'warnings': warnings,
            'context': context,
          },
        );
      } else {
        logger.info(
          'ValidationService',
          'Game flow consistency validated successfully at $flowPoint',
        );
      }
    } catch (e, stackTrace) {
      logger.error(
        'ValidationService',
        'Game flow consistency validation failed at $flowPoint: $e',
        null,
        stackTrace,
      );
      errors.add('Flow validation process failed: $e');
    }

    final severity = _determineValidationSeverity(errors, warnings);

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
      severity: severity,
    );
  }

  /// Validate consistency at event start
  void _validateEventStartConsistency(
    GameState gameState,
    Map<String, dynamic>? context,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check if player is in valid state to start an event
    if (gameState.isGameOver) {
      errors.add(
        'Cannot start event: game is over (${gameState.gameOverReason})',
      );
    }

    // Check if current event is properly set
    if (context != null && context['eventId'] != null) {
      if (gameState.currentEventId != context['eventId']) {
        warnings.add(
          'Event ID mismatch: current=${gameState.currentEventId}, context=${context['eventId']}',
        );
      }
    }

    // Check if player has required stats for event participation
    if (gameState.stats.hp <= 0) {
      errors.add(
        'Cannot start event: player is dead (HP=${gameState.stats.hp})',
      );
    }

    if (gameState.stats.san <= 0) {
      errors.add(
        'Cannot start event: player is insane (SAN=${gameState.stats.san})',
      );
    }
  }

  /// Validate consistency at event choice
  void _validateEventChoiceConsistency(
    GameState gameState,
    Map<String, dynamic>? context,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check if choice context is valid
    if (context != null) {
      if (context['choiceIndex'] == null) {
        warnings.add('Choice validation missing choice index');
      }

      if (context['eventId'] == null) {
        warnings.add('Choice validation missing event ID');
      }
    }

    // Check if player can make choices
    if (gameState.isGameOver) {
      errors.add('Cannot make choice: game is over');
    }
  }

  /// Validate consistency at event completion
  void _validateEventCompleteConsistency(
    GameState gameState,
    Map<String, dynamic>? context,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check if event was properly completed
    if (context != null && context['eventId'] != null) {
      if (gameState.currentEventId == context['eventId']) {
        warnings.add('Event completed but current event ID still set');
      }
    }

    // Check if turn count was incremented
    if (context != null && context['previousTurnCount'] != null) {
      final expectedTurnCount = context['previousTurnCount'] + 1;
      if (gameState.turnCount != expectedTurnCount) {
        warnings.add(
          'Turn count not properly incremented: expected $expectedTurnCount, got ${gameState.turnCount}',
        );
      }
    }
  }

  /// Validate consistency at turn start
  void _validateTurnStartConsistency(
    GameState gameState,
    Map<String, dynamic>? context,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check if player can continue playing
    if (gameState.isGameOver) {
      errors.add('Cannot start turn: game is over');
    }

    // Check for expired status effects that should be processed
    final expiredEffects = gameState.statusEffects
        .where((effect) => effect.remainingDuration <= 0)
        .toList();
    if (expiredEffects.isNotEmpty) {
      warnings.add(
        '${expiredEffects.length} expired status effects found at turn start',
      );
    }
  }

  /// Validate consistency at turn end
  void _validateTurnEndConsistency(
    GameState gameState,
    Map<String, dynamic>? context,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check if turn processing was completed
    if (context != null && context['previousTurnCount'] != null) {
      final expectedTurnCount = context['previousTurnCount'] + 1;
      if (gameState.turnCount != expectedTurnCount) {
        warnings.add(
          'Turn processing incomplete: expected turn count $expectedTurnCount, got ${gameState.turnCount}',
        );
      }
    }

    // Check for game over conditions
    if (gameState.isGameOver &&
        context != null &&
        context['wasGameOver'] == false) {
      logger.info(
        'ValidationService',
        'Game over condition detected at turn end: ${gameState.gameOverReason}',
      );
    }
  }

  /// Validate consistency before saving game
  void _validateSaveGameConsistency(
    GameState gameState,
    Map<String, dynamic>? context,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check if game state is in a saveable condition
    if (gameState.currentEventId != null && gameState.currentEvent == null) {
      warnings.add('Saving game with incomplete event state');
    }

    // Check for critical issues that might corrupt save data
    if (gameState.stats.hp < 0 || gameState.stats.hp > 100) {
      errors.add('Cannot save game: invalid HP value ${gameState.stats.hp}');
    }

    if (gameState.stats.san < 0 || gameState.stats.san > 100) {
      errors.add('Cannot save game: invalid SAN value ${gameState.stats.san}');
    }

    // Check for excessive data that might cause save issues
    if (gameState.inventory.items.length > 100) {
      warnings.add(
        'Saving game with very large inventory: ${gameState.inventory.items.length} items',
      );
    }

    if (gameState.statusEffects.length > 50) {
      warnings.add(
        'Saving game with many status effects: ${gameState.statusEffects.length} effects',
      );
    }
  }

  /// Validate consistency after loading game
  void _validateLoadGameConsistency(
    GameState gameState,
    Map<String, dynamic>? context,
    List<String> errors,
    List<String> warnings,
  ) {
    // Check if loaded game state is valid
    if (gameState.startTime.isAfter(DateTime.now())) {
      errors.add('Loaded game has future start time: ${gameState.startTime}');
    }

    // Check if loaded game state is reasonable
    if (gameState.turnCount < 0) {
      errors.add('Loaded game has negative turn count: ${gameState.turnCount}');
    }

    if (gameState.turnCount > 10000) {
      warnings.add(
        'Loaded game has very high turn count: ${gameState.turnCount}',
      );
    }

    // Check for data corruption indicators
    if (gameState.stats.hp < 0 || gameState.stats.hp > 100) {
      errors.add('Loaded game has corrupted HP value: ${gameState.stats.hp}');
    }

    if (gameState.stats.san < 0 || gameState.stats.san > 100) {
      errors.add('Loaded game has corrupted SAN value: ${gameState.stats.san}');
    }
  }

  /// Get comprehensive player state validation report
  Map<String, dynamic> getPlayerStateValidationReport(GameState gameState) {
    final validationResult = validatePlayerStateConsistency(gameState);

    return {
      'timestamp': DateTime.now().toIso8601String(),
      'validationResult': validationResult.toMap(),
      'playerState': {
        'stats': gameState.stats.toMap(),
        'inventorySize': gameState.inventory.items.length,
        'inventoryMaxSlots': gameState.inventory.maxSlots,
        'statusEffectsCount': gameState.statusEffects.length,
        'turnCount': gameState.turnCount,
        'isGameOver': gameState.isGameOver,
        'gameOverReason': gameState.gameOverReason,
        'startTime': gameState.startTime.toIso8601String(),
      },
      'validationMetrics': {
        'totalChecks':
            validationResult.errors.length + validationResult.warnings.length,
        'errorCount': validationResult.errors.length,
        'warningCount': validationResult.warnings.length,
        'severity': validationResult.severity.toString(),
        'isValid': validationResult.isValid,
      },
      'recommendations': _generatePlayerStateRecommendations(
        validationResult,
        gameState,
      ),
    };
  }

  /// Generate recommendations based on validation results
  List<String> _generatePlayerStateRecommendations(
    ValidationResult validationResult,
    GameState gameState,
  ) {
    final recommendations = <String>[];

    if (validationResult.errors.isNotEmpty) {
      recommendations.add('Fix critical validation errors before continuing');
    }

    if (validationResult.warnings.isNotEmpty) {
      recommendations.add('Review validation warnings for potential issues');
    }

    // Add specific recommendations based on player state
    if (gameState.stats.hp <= 20) {
      recommendations.add(
        'Player HP is very low - consider healing or avoiding dangerous situations',
      );
    }

    if (gameState.stats.san <= 20) {
      recommendations.add(
        'Player SAN is very low - consider sanity restoration or avoiding stressful events',
      );
    }

    if (gameState.inventory.items.length > gameState.inventory.maxSlots) {
      recommendations.add(
        'Inventory overflow detected - consider item management',
      );
    }

    if (gameState.statusEffects.length > 15) {
      recommendations.add(
        'Many active status effects - consider effect management',
      );
    }

    if (gameState.turnCount > 1000) {
      recommendations.add(
        'High turn count - consider game progression optimization',
      );
    }

    if (recommendations.isEmpty) {
      recommendations.add(
        'Player state appears healthy - continue normal gameplay',
      );
    }

    return recommendations;
  }
}

/// Represents a validation result
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final ValidationSeverity severity;

  ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
    required this.severity,
  });

  /// Get formatted error summary
  String get errorSummary {
    if (errors.isEmpty) return 'No errors';
    return '${errors.length} error(s): ${errors.join('; ')}';
  }

  /// Get formatted warning summary
  String get warningSummary {
    if (warnings.isEmpty) return 'No warnings';
    return '${warnings.length} warning(s): ${warnings.join('; ')}';
  }

  /// Convert to map for serialization
  Map<String, dynamic> toMap() {
    return {
      'isValid': isValid,
      'errors': errors,
      'warnings': warnings,
      'severity': severity.toString(),
      'errorSummary': errorSummary,
      'warningSummary': warningSummary,
    };
  }
}

/// Validation severity levels
enum ValidationSeverity { pass, warning, critical, error, low }

/// Global validation service instance for easy access
final validationService = ValidationService();
