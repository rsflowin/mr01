import 'dart:math';
import '../models/event_model.dart';
import '../models/room_event_data.dart';
import '../models/game_state.dart';
import 'validation_service.dart';
import 'logger_service.dart';

/// Service responsible for processing events when players enter rooms
///
/// Handles event selection, display, choice validation, and effect application
class EventProcessor {
  final Random _random;
  final Map<String, Event> _eventDatabase;
  final ValidationService validationService;
  final LoggerService logger;

  EventProcessor({Random? random, required Map<String, Event> eventDatabase})
    : _random = random ?? Random(),
      _eventDatabase = eventDatabase,
      validationService = ValidationService(),
      logger = LoggerService();

  /// Selects a random event from the available events in a room
  ///
  /// [availableEventIds] - List of event IDs available in the room
  ///
  /// Returns the selected Event object, or null if no events available
  Event? selectRandomEvent(List<String> availableEventIds) {
    if (availableEventIds.isEmpty) {
      logger.debug('EventProcessor', 'No events available in room');
      return null;
    }

    try {
      // Select a random event ID from available events
      final randomIndex = _random.nextInt(availableEventIds.length);
      final selectedEventId = availableEventIds[randomIndex];

      logger.debug('EventProcessor', 'Selected event: $selectedEventId from ${availableEventIds.length} available events');

      // Get the event from the database
      final event = _eventDatabase[selectedEventId];

      if (event == null) {
        logger.error('EventProcessor', 'Event with ID "$selectedEventId" not found in database', 
          {'selectedEventId': selectedEventId, 'availableEventIds': availableEventIds});
        throw StateError(
          'Event with ID "$selectedEventId" not found in database',
        );
      }

      logger.debug('EventProcessor', 'Successfully retrieved event: ${event.name}');
      return event;
    } catch (e, stackTrace) {
      logger.error('EventProcessor', 'Error selecting random event', 
        {'availableEventIds': availableEventIds}, stackTrace);
      rethrow;
    }
  }

  /// Displays an event to the player
  ///
  /// [event] - The event to display
  ///
  /// Returns a map containing the event display data
  Map<String, dynamic> displayEvent(Event event) {
    return {
      'eventId': event.id,
      'name': event.name,
      'description': event.description,
      'image': event.image,
      'category': event.category,
      'choices': event.choices
          .map(
            (choice) => {
              'text': choice.text,
              'isAvailable': true, // Will be updated by choice validation
            },
          )
          .toList(),
    };
  }

  /// Enhanced choice validation that works with GameState and provides detailed results
  ///
  /// [choice] - The choice to validate
  /// [gameState] - Current game state with proper models
  ///
  /// Returns a validation result with availability and reasons
  Map<String, dynamic> validateChoiceRequirementsEnhanced(
    Choice choice,
    GameState gameState,
  ) {
    // Validate player state consistency before choice validation
    final stateValidation = validationService.validatePlayerStateConsistency(gameState);
    if (!stateValidation.isValid) {
      logger.warning(
        'EventProcessor',
        'Player state validation failed during choice validation',
        {
          'errors': stateValidation.errors,
          'warnings': stateValidation.warnings,
        },
      );
    }

    final requirements = choice.requirements;
    final validationResult = {
      'isAvailable': true,
      'failureReasons': <String>[],
      'missingItems': <String>[],
      'insufficientStats': <Map<String, dynamic>>[],
      'stateValidation': stateValidation.toMap(),
    };

    // If no requirements, choice is always available
    if (requirements == null || requirements.isEmpty) {
      return validationResult;
    }

    // Check item requirements
    if (requirements.containsKey('items')) {
      final requiredItems = requirements['items'] as List<dynamic>?;
      if (requiredItems != null) {
        for (final itemId in requiredItems) {
          final itemIdStr = itemId.toString();
          if (!gameState.inventory.hasItem(itemIdStr)) {
            validationResult['isAvailable'] = false;
            (validationResult['missingItems'] as List<String>).add(itemIdStr);
            (validationResult['failureReasons'] as List<String>).add(
              'Missing required item: $itemIdStr',
            );
          }
        }
      }
    }

    // Check stat requirements
    if (requirements.containsKey('stats')) {
      final statRequirements = requirements['stats'] as Map<String, dynamic>?;
      if (statRequirements != null) {
        for (final entry in statRequirements.entries) {
          final statName = entry.key;
          final requirement = entry.value as Map<String, dynamic>;
          final operator = requirement['operator'] as String;
          final requiredValue = requirement['value'] as int;

          final currentStatValue = _getStatValue(gameState.stats, statName);

          final isPassed = _evaluateStatRequirement(
            currentStatValue,
            operator,
            requiredValue,
          );

          if (!isPassed) {
            validationResult['isAvailable'] = false;
            final insufficientStat = {
              'statName': statName,
              'currentValue': currentStatValue,
              'requiredValue': requiredValue,
              'operator': operator,
            };
            (validationResult['insufficientStats']
                    as List<Map<String, dynamic>>)
                .add(insufficientStat);
            (validationResult['failureReasons'] as List<String>).add(
              'Insufficient $statName: $currentStatValue $operator $requiredValue required',
            );
          }
        }
      }
    }

    return validationResult;
  }

  /// Legacy method for backward compatibility - validates choice requirements with Map-based state
  ///
  /// [choice] - The choice to validate
  /// [playerState] - Current player state (stats, inventory, etc.)
  ///
  /// Returns true if the choice can be selected
  bool validateChoiceRequirements(
    Choice choice,
    Map<String, dynamic> playerState,
  ) {
    final requirements = choice.requirements;

    // If no requirements, choice is always available
    if (requirements == null || requirements.isEmpty) {
      return true;
    }

    // Check item requirements
    if (requirements.containsKey('items')) {
      final requiredItems = requirements['items'] as List<String>?;
      final playerInventory = playerState['inventory'] as List<String>? ?? [];

      if (requiredItems != null) {
        for (final item in requiredItems) {
          if (!playerInventory.contains(item)) {
            return false;
          }
        }
      }
    }

    // Check stat requirements
    if (requirements.containsKey('stats')) {
      final statRequirements = requirements['stats'] as Map<String, dynamic>?;
      final playerStats = playerState['stats'] as Map<String, int>? ?? {};

      if (statRequirements != null) {
        for (final entry in statRequirements.entries) {
          final statName = entry.key;
          final requirement = entry.value as Map<String, dynamic>;
          final operator = requirement['operator'] as String;
          final value = requirement['value'] as int;
          final playerStatValue = playerStats[statName] ?? 0;

          switch (operator) {
            case '>':
              if (playerStatValue <= value) return false;
              break;
            case '>=':
              if (playerStatValue < value) return false;
              break;
            case '<':
              if (playerStatValue >= value) return false;
              break;
            case '<=':
              if (playerStatValue > value) return false;
              break;
            case '==':
              if (playerStatValue != value) return false;
              break;
            default:
              throw ArgumentError('Unknown operator: $operator');
          }
        }
      }
    }

    return true;
  }

  /// Applies the effects of a selected choice
  ///
  /// [choice] - The selected choice
  /// [playerState] - Current player state to modify
  /// [useSuccessEffects] - Whether to use success or failure effects
  ///
  /// Returns updated player state and result description
  Map<String, dynamic> applyChoiceEffects(
    Choice choice,
    Map<String, dynamic> playerState, {
    bool useSuccessEffects = true,
  }) {
    // Validate input player state before processing
    if (playerState.isEmpty) {
      logger.error(
        'EventProcessor',
        'Cannot apply choice effects: empty player state',
      );
      return {
        'playerState': playerState,
        'description': 'Error: Invalid player state',
        'success': false,
        'error': 'Empty player state',
      };
    }

    final effects = useSuccessEffects
        ? choice.successEffects
        : choice.failureEffects;

    if (effects == null) {
      return {
        'playerState': playerState,
        'description': 'Nothing happened.',
        'success': useSuccessEffects,
      };
    }

    // Create a copy of player state to modify
    final updatedState = Map<String, dynamic>.from(playerState);
    final updatedStats = Map<String, int>.from(updatedState['stats'] ?? {});
    final updatedInventory = List<String>.from(updatedState['inventory'] ?? []);
    final updatedStatusEffects = List<String>.from(
      updatedState['statusEffects'] ?? [],
    );

    // Store previous state for validation
    final previousStats = Map<String, int>.from(updatedStats);
    final previousInventorySize = updatedInventory.length;
    final previousStatusEffectsCount = updatedStatusEffects.length;

    // Apply stat changes
    if (effects.statChanges != null) {
      for (final entry in effects.statChanges!.entries) {
        final statName = entry.key;
        final change = entry.value;
        final currentValue = updatedStats[statName] ?? 0;
        final newValue = (currentValue + change).clamp(0, 100);
        updatedStats[statName] = newValue;
      }
    }

    // Apply item gains
    if (effects.itemsGained != null) {
      for (final item in effects.itemsGained!) {
        if (!updatedInventory.contains(item)) {
          updatedInventory.add(item);
        }
      }
    }

    // Apply item losses
    if (effects.itemsLost != null) {
      for (final item in effects.itemsLost!) {
        updatedInventory.remove(item);
      }
    }

    // Apply status effects
    if (effects.applyStatus != null) {
      for (final status in effects.applyStatus!) {
        if (!updatedStatusEffects.contains(status)) {
          updatedStatusEffects.add(status);
        }
      }
    }

    // Update the state
    updatedState['stats'] = updatedStats;
    updatedState['inventory'] = updatedInventory;
    updatedState['statusEffects'] = updatedStatusEffects;

    // Validate state changes
    final statChanges = <String, int>{};
    for (final entry in updatedStats.entries) {
      final statName = entry.key;
      final newValue = entry.value;
      final oldValue = previousStats[statName] ?? 0;
      statChanges[statName] = newValue - oldValue;
    }

    final inventoryChange = updatedInventory.length - previousInventorySize;
    final statusEffectsChange = updatedStatusEffects.length - previousStatusEffectsCount;

    // Log significant changes for debugging
    if (statChanges.values.any((change) => change.abs() > 20)) {
      logger.info(
        'EventProcessor',
        'Large stat changes detected during choice effects',
        {
          'statChanges': statChanges,
          'choiceId': choice.text,
          'useSuccessEffects': useSuccessEffects,
        },
      );
    }

    if (inventoryChange.abs() > 3) {
      logger.info(
        'EventProcessor',
        'Large inventory change detected during choice effects',
        {
          'inventoryChange': inventoryChange,
          'choiceId': choice.text,
          'useSuccessEffects': useSuccessEffects,
        },
      );
    }

    if (statusEffectsChange.abs() > 2) {
      logger.info(
        'EventProcessor',
        'Large status effects change detected during choice effects',
        {
          'statusEffectsChange': statusEffectsChange,
          'choiceId': choice.text,
          'useSuccessEffects': useSuccessEffects,
        },
      );
    }

    return {
      'playerState': updatedState,
      'description': effects.description,
      'success': useSuccessEffects,
      'changes': {
        'statChanges': statChanges,
        'inventoryChange': inventoryChange,
        'statusEffectsChange': statusEffectsChange,
      },
    };
  }

  /// Determines if a choice succeeds or fails based on success conditions
  ///
  /// [choice] - The choice to evaluate
  /// [playerState] - Current player state
  ///
  /// Returns true if the choice succeeds
  bool evaluateChoiceSuccess(Choice choice, Map<String, dynamic> playerState) {
    final successConditions = choice.successConditions;

    // If no success conditions, always succeed
    if (successConditions == null || successConditions.isEmpty) {
      return true;
    }

    // Check probability-based success
    if (successConditions.containsKey('probability')) {
      final probability = successConditions['probability'] as double;
      return _random.nextDouble() < probability;
    }

    // Check stat-based success conditions
    if (successConditions.containsKey('stats')) {
      final statConditions = successConditions['stats'] as Map<String, dynamic>;
      final playerStats = playerState['stats'] as Map<String, int>? ?? {};

      for (final entry in statConditions.entries) {
        final statName = entry.key;
        final condition = entry.value as Map<String, dynamic>;
        final operator = condition['operator'] as String;
        final value = condition['value'] as int;
        final playerStatValue = playerStats[statName] ?? 0;

        switch (operator) {
          case '>':
            if (playerStatValue <= value) return false;
            break;
          case '>=':
            if (playerStatValue < value) return false;
            break;
          case '<':
            if (playerStatValue >= value) return false;
            break;
          case '<=':
            if (playerStatValue > value) return false;
            break;
          case '==':
            if (playerStatValue != value) return false;
            break;
          default:
            throw ArgumentError('Unknown operator: $operator');
        }
      }
    }

    return true;
  }

  /// Removes a oneTime event from the room after it has been triggered
  ///
  /// [roomEventData] - The room's event data
  /// [eventId] - The ID of the event to remove
  ///
  /// Returns updated room event data
  RoomEventData removeOneTimeEvent(
    RoomEventData roomEventData,
    String eventId,
  ) {
    final event = _eventDatabase[eventId];

    // Only remove if it's a oneTime event
    if (event != null && event.persistence == 'oneTime') {
      return roomEventData.consumeEvent(eventId);
    }

    return roomEventData;
  }

  /// Detects if a room is effectively empty for event purposes
  ///
  /// [roomEventData] - The room's event data to check
  ///
  /// Returns true if the room has no available events to trigger
  bool isRoomEmpty(RoomEventData roomEventData) {
    return !roomEventData.hasAvailableEvents;
  }

  /// Creates a placeholder event for empty rooms with enhanced messaging
  ///
  /// [roomEventData] - Optional room data for context-specific messaging
  ///
  /// Returns a "Take a break" event for empty rooms with appropriate description
  Event createEmptyRoomEvent({RoomEventData? roomEventData}) {
    // Generate contextual description based on room state
    final description = _generateEmptyRoomDescription(roomEventData);

    return Event(
      id: 'empty_room_rest',
      name: 'Empty Room',
      description: description,
      image: 'empty_room.png',
      category: 'rest',
      weight: 1,
      persistence: 'persistent',
      choices: [
        Choice(
          text: 'Take a break',
          successEffects: ChoiceEffects(
            description: _generateRestResultDescription(),
            statChanges: _calculateRestStatChanges(),
          ),
        ),
      ],
    );
  }

  /// Generates contextual description for empty rooms
  ///
  /// [roomEventData] - Optional room data for context
  ///
  /// Returns appropriate description based on room state
  String _generateEmptyRoomDescription(RoomEventData? roomEventData) {
    final descriptions = [
      'This room appears to be empty. You can take a moment to rest and gather your thoughts.',
      'The room is quiet and peaceful. It seems like a good place to catch your breath.',
      'Nothing of interest catches your eye in this room. Perhaps a short rest would be beneficial.',
      'This chamber is vacant and still. The silence offers a welcome respite from your journey.',
      'The room stands empty, its walls bearing witness to your solitary passage. Time for a brief rest.',
      'An unremarkable room with little to offer except the opportunity to pause and recover.',
    ];

    // Use room data to influence description selection if available
    int descriptionIndex = 0;
    if (roomEventData != null) {
      // Create a deterministic but varied index based on room ID
      descriptionIndex =
          roomEventData.roomId.hashCode.abs() % descriptions.length;
    } else {
      // Random selection if no room data available
      descriptionIndex = _random.nextInt(descriptions.length);
    }

    return descriptions[descriptionIndex];
  }

  /// Generates varied result descriptions for rest actions
  ///
  /// Returns a random rest result description for variety
  String _generateRestResultDescription() {
    final descriptions = [
      'You take a moment to rest and feel slightly refreshed.',
      'A brief respite helps clear your mind and ease your fatigue.',
      'You sit down and take several deep breaths, feeling more centered.',
      'The short break allows you to gather your strength and composure.',
      'You pause to stretch and relax, feeling modestly rejuvenated.',
      'A moment of quiet reflection helps restore some of your energy.',
      'You take time to rest your weary body and calm your racing mind.',
      'The peaceful silence allows you to recover a bit of your vitality.',
    ];

    return descriptions[_random.nextInt(descriptions.length)];
  }

  /// Calculates stat changes for rest actions with minor recovery
  ///
  /// Returns a map of stat changes that provide small recovery benefits
  Map<String, int> _calculateRestStatChanges() {
    // Minor recovery with slight hunger cost
    // Values kept modest to not make empty rooms too beneficial
    return {
      'HP': 3, // Small health recovery
      'SAN': 4, // Slightly better sanity recovery (rest is good for mind)
      'FITNESS': 1, // Minor fitness recovery from rest
      'HUNGER': -2, // Small hunger cost for time spent resting
    };
  }

  /// Enhanced empty room event creation with player state consideration
  ///
  /// [roomEventData] - The room's event data
  /// [playerState] - Current player state for contextual rest benefits
  ///
  /// Returns an empty room event tailored to current player needs
  Event createEmptyRoomEventEnhanced(
    RoomEventData roomEventData,
    Map<String, dynamic> playerState,
  ) {
    final description = _generateEmptyRoomDescription(roomEventData);
    final restDescription = _generateRestResultDescription();
    final statChanges = _calculateAdaptiveRestStatChanges(playerState);

    return Event(
      id: 'empty_room_rest_enhanced',
      name: 'Empty Room',
      description: description,
      image: 'empty_room.png',
      category: 'rest',
      weight: 1,
      persistence: 'persistent',
      choices: [
        Choice(
          text: 'Take a break',
          successEffects: ChoiceEffects(
            description: restDescription,
            statChanges: statChanges,
          ),
        ),
      ],
    );
  }

  /// Calculates adaptive stat changes based on player's current state
  ///
  /// [playerState] - Current player state to analyze
  ///
  /// Returns stat changes that prioritize the player's greatest needs
  Map<String, int> _calculateAdaptiveRestStatChanges(
    Map<String, dynamic> playerState,
  ) {
    // Get current stats
    final stats = playerState['stats'] as Map<String, int>? ?? {};
    final hp = stats['HP'] ?? 100;
    final san = stats['SAN'] ?? 100;
    final fitness = stats['FITNESS'] ?? 100;
    final hunger = stats['HUNGER'] ?? 100;

    // Base recovery amounts
    int hpRecovery = 3;
    int sanRecovery = 4;
    int fitnessRecovery = 1;
    int hungerCost = 2;

    // Enhance recovery for critically low stats
    if (hp < 30) hpRecovery += 2; // Extra HP recovery when critical
    if (san < 30) sanRecovery += 3; // Extra sanity recovery when critical
    if (fitness < 30)
      fitnessRecovery += 2; // Extra fitness recovery when critical

    // Reduce hunger cost if already very hungry
    if (hunger < 20) hungerCost = 1; // Reduce hunger cost when starving

    return {
      'HP': hpRecovery,
      'SAN': sanRecovery,
      'FITNESS': fitnessRecovery,
      'HUNGER': -hungerCost,
    };
  }

  /// Processes a complete room entry event cycle
  ///
  /// [roomEventData] - The room's current event data
  /// [playerState] - Current player state
  ///
  /// Returns the selected event and updated room data, or empty room event if no events
  Map<String, dynamic> processRoomEntry(
    RoomEventData roomEventData,
    Map<String, dynamic> playerState,
  ) {
    Event selectedEvent;
    RoomEventData updatedRoomData = roomEventData;

    if (roomEventData.hasAvailableEvents) {
      // Select random event from available events
      selectedEvent = selectRandomEvent(roomEventData.availableEventIds)!;
    } else {
      // Use enhanced empty room event with contextual messaging
      selectedEvent = createEmptyRoomEventEnhanced(roomEventData, playerState);
    }

    return {
      'event': selectedEvent,
      'roomEventData': updatedRoomData,
      'eventDisplay': displayEvent(selectedEvent),
      'isEmptyRoom': isRoomEmpty(roomEventData),
    };
  }

  /// Enhanced room entry processing with GameState support
  ///
  /// [roomEventData] - The room's current event data
  /// [gameState] - Current game state with proper models
  ///
  /// Returns the selected event and updated room data with enhanced type safety
  Map<String, dynamic> processRoomEntryEnhanced(
    RoomEventData roomEventData,
    GameState gameState,
  ) {
    Event selectedEvent;
    RoomEventData updatedRoomData = roomEventData;

    if (roomEventData.hasAvailableEvents) {
      // Select random event from available events
      selectedEvent = selectRandomEvent(roomEventData.availableEventIds)!;
    } else {
      // Use enhanced empty room event with GameState integration
      selectedEvent = createEmptyRoomEventForGameState(
        roomEventData,
        gameState,
      );
    }

    return {
      'event': selectedEvent,
      'roomEventData': updatedRoomData,
      'eventDisplay': displayEventWithValidation(selectedEvent, gameState),
      'isEmptyRoom': isRoomEmpty(roomEventData),
    };
  }

  /// Creates an empty room event optimized for GameState
  ///
  /// [roomEventData] - The room's event data
  /// [gameState] - Current game state for enhanced adaptive recovery
  ///
  /// Returns an empty room event with GameState-aware stat recovery
  Event createEmptyRoomEventForGameState(
    RoomEventData roomEventData,
    GameState gameState,
  ) {
    final description = _generateEmptyRoomDescription(roomEventData);
    final restDescription = _generateRestResultDescription();
    final statChanges = _calculateGameStateAdaptiveRestChanges(gameState);

    return Event(
      id: 'empty_room_rest_gamestate',
      name: 'Empty Room',
      description: description,
      image: 'empty_room.png',
      category: 'rest',
      weight: 1,
      persistence: 'persistent',
      choices: [
        Choice(
          text: 'Take a break',
          successEffects: ChoiceEffects(
            description: restDescription,
            statChanges: statChanges,
          ),
        ),
      ],
    );
  }

  /// Calculates adaptive stat changes based on GameState
  ///
  /// [gameState] - Current game state with PlayerStats
  ///
  /// Returns stat changes optimized for the player's current condition
  Map<String, int> _calculateGameStateAdaptiveRestChanges(GameState gameState) {
    final stats = gameState.stats;

    // Base recovery amounts
    int hpRecovery = 3;
    int sanRecovery = 4;
    int fitnessRecovery = 1;
    int hungerCost = 2;

    // Enhance recovery for critically low stats
    if (stats.hp < 30) hpRecovery += 2;
    if (stats.san < 30) sanRecovery += 3;
    if (stats.fit < 30) fitnessRecovery += 2;

    // Reduce hunger cost if already very hungry
    if (stats.hunger < 20) hungerCost = 1;

    // Consider status effects for additional bonuses/penalties
    final hasDebuffs = gameState.activeDebuffs.isNotEmpty;
    if (hasDebuffs) {
      // Slightly better recovery when suffering from debuffs
      sanRecovery += 1;
    }

    return {
      'HP': hpRecovery,
      'SAN': sanRecovery,
      'FITNESS': fitnessRecovery,
      'HUNGER': -hungerCost,
    };
  }

  /// Gets consistent empty room messaging for UI components
  ///
  /// [roomEventData] - Optional room data for context
  ///
  /// Returns standard empty room message for consistent UI display
  String getEmptyRoomMessage({RoomEventData? roomEventData}) {
    return 'This room appears to be empty. You can take a moment to rest and gather your thoughts.';
  }

  /// Validates that a room is properly configured for empty room handling
  ///
  /// [roomEventData] - The room data to validate
  ///
  /// Returns true if the room is correctly set up as empty
  bool validateEmptyRoomSetup(RoomEventData roomEventData) {
    return roomEventData.availableEventIds.isEmpty &&
        roomEventData.eventCount == 0;
  }

  /// Creates a standardized empty room display event for UI consistency
  ///
  /// [roomEventData] - The room's event data
  ///
  /// Returns a display-ready event with consistent messaging
  Map<String, dynamic> createEmptyRoomDisplay(RoomEventData roomEventData) {
    final event = createEmptyRoomEvent(roomEventData: roomEventData);

    return {
      'eventId': event.id,
      'name': event.name,
      'description': event.description,
      'image': event.image,
      'category': event.category,
      'isEmptyRoom': true,
      'choices': event.choices
          .map(
            (choice) => {
              'text': choice.text,
              'isAvailable': true, // Empty room choices are always available
              'description': choice.successEffects?.description ?? '',
            },
          )
          .toList(),
    };
  }

  /// Processes rest action effects from empty room choices
  ///
  /// [choice] - The rest choice selected by player
  /// [playerState] - Current player state to modify
  ///
  /// Returns updated player state and detailed effect description
  Map<String, dynamic> processRestAction(
    Choice choice,
    Map<String, dynamic> playerState,
  ) {
    // Apply standard choice effects
    final result = applyChoiceEffects(choice, playerState);

    // Add rest-specific metadata
    return {
      ...result,
      'actionType': 'rest',
      'isEmptyRoomAction': true,
      'restBenefits': _describeRestBenefits(choice.successEffects?.statChanges),
    };
  }

  /// Describes the benefits of rest action for player feedback
  ///
  /// [statChanges] - The stat changes applied by rest
  ///
  /// Returns human-readable description of rest benefits
  String _describeRestBenefits(Map<String, int>? statChanges) {
    if (statChanges == null || statChanges.isEmpty) {
      return 'You feel refreshed from the brief rest.';
    }

    final List<String> benefits = [];

    if (statChanges['HP'] != null && statChanges['HP']! > 0) {
      benefits.add('your wounds feel better');
    }
    if (statChanges['SAN'] != null && statChanges['SAN']! > 0) {
      benefits.add('your mind feels clearer');
    }
    if (statChanges['FITNESS'] != null && statChanges['FITNESS']! > 0) {
      benefits.add('your body feels more energized');
    }
    if (statChanges['HUNGER'] != null && statChanges['HUNGER']! < 0) {
      benefits.add('you feel slightly hungrier from the time spent resting');
    }

    if (benefits.isEmpty) {
      return 'You feel refreshed from the brief rest.';
    }

    return 'After resting, ${benefits.join(', ')}.';
  }

  /// Helper method to get stat value from PlayerStats
  int _getStatValue(PlayerStats stats, String statName) {
    switch (statName.toUpperCase()) {
      case 'HP':
        return stats.hp;
      case 'SAN':
      case 'SANITY':
        return stats.san;
      case 'FIT':
      case 'FITNESS':
        return stats.fit;
      case 'HUNGER':
        return stats.hunger;
      default:
        return 0;
    }
  }

  /// Helper method to evaluate stat requirements
  bool _evaluateStatRequirement(
    int currentValue,
    String operator,
    int requiredValue,
  ) {
    switch (operator) {
      case '>':
        return currentValue > requiredValue;
      case '>=':
        return currentValue >= requiredValue;
      case '<':
        return currentValue < requiredValue;
      case '<=':
        return currentValue <= requiredValue;
      case '==':
        return currentValue == requiredValue;
      default:
        throw ArgumentError('Unknown operator: $operator');
    }
  }

  /// Enhanced displayEvent method that includes choice availability information
  ///
  /// [event] - The event to display
  /// [gameState] - Current game state for choice validation
  ///
  /// Returns a map containing the event display data with choice availability
  Map<String, dynamic> displayEventWithValidation(
    Event event,
    GameState gameState,
  ) {
    final choices = event.choices.map((choice) {
      final validation = validateChoiceRequirementsEnhanced(choice, gameState);
      return {
        'text': choice.text,
        'isAvailable': validation['isAvailable'],
        'failureReasons': validation['failureReasons'],
        'missingItems': validation['missingItems'],
        'insufficientStats': validation['insufficientStats'],
      };
    }).toList();

    return {
      'eventId': event.id,
      'name': event.name,
      'description': event.description,
      'image': event.image,
      'category': event.category,
      'choices': choices,
    };
  }

  /// Processes a player's choice selection and applies effects
  ///
  /// [event] - The current event
  /// [choiceIndex] - Index of the selected choice
  /// [playerState] - Current player state
  /// [roomEventData] - Current room event data
  ///
  /// Returns updated player state, room data, and result description
  Map<String, dynamic> processChoiceSelection(
    Event event,
    int choiceIndex,
    Map<String, dynamic> playerState,
    RoomEventData roomEventData,
  ) {
    if (choiceIndex < 0 || choiceIndex >= event.choices.length) {
      throw ArgumentError('Invalid choice index: $choiceIndex');
    }

    final selectedChoice = event.choices[choiceIndex];

    // Validate choice requirements
    if (!validateChoiceRequirements(selectedChoice, playerState)) {
      throw StateError('Choice requirements not met');
    }

    // Determine success or failure
    final isSuccess = evaluateChoiceSuccess(selectedChoice, playerState);

    // Apply effects
    final effectsResult = applyChoiceEffects(
      selectedChoice,
      playerState,
      useSuccessEffects: isSuccess,
    );

    // Update room data (remove oneTime events)
    final updatedRoomData = removeOneTimeEvent(roomEventData, event.id);

    return {
      'playerState': effectsResult['playerState'],
      'roomEventData': updatedRoomData,
      'description': effectsResult['description'],
      'success': isSuccess,
      'choiceText': selectedChoice.text,
    };
  }

  /// Enhanced choice selection processing that works with GameState
  ///
  /// [event] - The current event
  /// [choiceIndex] - Index of the selected choice
  /// [gameState] - Current game state
  /// [roomEventData] - Current room event data
  ///
  /// Returns updated game state, room data, and result description
  Map<String, dynamic> processChoiceSelectionEnhanced(
    Event event,
    int choiceIndex,
    GameState gameState,
    RoomEventData roomEventData,
  ) {
    if (choiceIndex < 0 || choiceIndex >= event.choices.length) {
      throw ArgumentError('Invalid choice index: $choiceIndex');
    }

    final selectedChoice = event.choices[choiceIndex];

    // Validate choice requirements using enhanced validation
    final validation = validateChoiceRequirementsEnhanced(
      selectedChoice,
      gameState,
    );
    if (!validation['isAvailable']) {
      throw StateError(
        'Choice requirements not met: ${(validation['failureReasons'] as List<String>).join(', ')}',
      );
    }

    // Determine success or failure
    final isSuccess = evaluateChoiceSuccessEnhanced(selectedChoice, gameState);

    // Apply effects to game state with enhanced tracking
    final effectsResult = applyChoiceEffectsToGameStateEnhanced(
      selectedChoice,
      gameState,
      useSuccessEffects: isSuccess,
    );

    // Update room data (remove oneTime events)
    final updatedRoomData = removeOneTimeEvent(roomEventData, event.id);

    return {
      'gameState': effectsResult['gameState'],
      'roomEventData': updatedRoomData,
      'description': effectsResult['description'],
      'success': isSuccess,
      'choiceText': selectedChoice.text,
      'validation': validation,
      'effectsApplied': effectsResult['effectsApplied'],
    };
  }

  /// Enhanced choice success evaluation that works with GameState
  ///
  /// [choice] - The choice to evaluate
  /// [gameState] - Current game state
  ///
  /// Returns true if the choice succeeds
  bool evaluateChoiceSuccessEnhanced(Choice choice, GameState gameState) {
    final successConditions = choice.successConditions;

    // If no success conditions, always succeed
    if (successConditions == null || successConditions.isEmpty) {
      return true;
    }

    // Check probability-based success
    if (successConditions.containsKey('probability')) {
      final probability = successConditions['probability'] as double;
      return _random.nextDouble() < probability;
    }

    // Check stat-based success conditions
    if (successConditions.containsKey('stats')) {
      final statConditions = successConditions['stats'] as Map<String, dynamic>;

      for (final entry in statConditions.entries) {
        final statName = entry.key;
        final condition = entry.value as Map<String, dynamic>;
        final operator = condition['operator'] as String;
        final value = condition['value'] as int;
        final currentStatValue = _getStatValue(gameState.stats, statName);

        if (!_evaluateStatRequirement(currentStatValue, operator, value)) {
          return false;
        }
      }
    }

    return true;
  }

  /// Enhanced choice effects application directly to GameState
  ///
  /// [choice] - The selected choice
  /// [gameState] - Current game state to modify
  /// [useSuccessEffects] - Whether to use success or failure effects
  ///
  /// Returns updated game state with detailed effect tracking
  Map<String, dynamic> applyChoiceEffectsToGameStateEnhanced(
    Choice choice,
    GameState gameState, {
    bool useSuccessEffects = true,
  }) {
    final effects = useSuccessEffects
        ? choice.successEffects
        : choice.failureEffects;

    final effectsApplied = {
      'statChanges': <String, Map<String, int>>{},
      'itemsGained': <String>[],
      'itemsLost': <String>[],
      'statusEffectsApplied': <String>[],
      'errors': <String>[],
      'warnings': <String>[],
    };

    if (effects == null) {
      return {
        'gameState': gameState,
        'effectsApplied': effectsApplied,
        'description': 'Nothing happened.',
      };
    }

    // Create a copy of the game state to modify
    GameState updatedState = gameState.copyWith();

    // Apply stat changes with enhanced bounds checking and tracking
    if (effects.statChanges != null) {
      effectsApplied['statChanges'] = _applyStatChangesEnhanced(
        updatedState,
        effects.statChanges!,
        effectsApplied,
      );
    }

    // Apply item gains with inventory management
    if (effects.itemsGained != null) {
      _applyItemGainsEnhanced(
        updatedState,
        effects.itemsGained!,
        effectsApplied,
      );
    }

    // Apply item losses with validation
    if (effects.itemsLost != null) {
      _applyItemLossesEnhanced(
        updatedState,
        effects.itemsLost!,
        effectsApplied,
      );
    }

    // Apply status effects with proper categorization
    if (effects.applyStatus != null) {
      _applyStatusEffectsEnhanced(
        updatedState,
        effects.applyStatus!,
        effectsApplied,
      );
    }

    return {
      'gameState': updatedState,
      'effectsApplied': effectsApplied,
      'description': effects.description,
    };
  }

  /// Legacy method for backward compatibility
  GameState applyChoiceEffectsToGameState(
    Choice choice,
    GameState gameState, {
    bool useSuccessEffects = true,
  }) {
    final result = applyChoiceEffectsToGameStateEnhanced(
      choice,
      gameState,
      useSuccessEffects: useSuccessEffects,
    );
    return result['gameState'] as GameState;
  }

  /// Enhanced stat change application with comprehensive bounds checking
  Map<String, Map<String, int>> _applyStatChangesEnhanced(
    GameState gameState,
    Map<String, int> statChanges,
    Map<String, dynamic> effectsApplied,
  ) {
    final statChangeResults = <String, Map<String, int>>{};

    for (final entry in statChanges.entries) {
      final statName = entry.key.toUpperCase();
      final change = entry.value;

      // Get current stat value
      final currentValue = _getStatValue(gameState.stats, statName);
      final newValue = (currentValue + change).clamp(0, 100);

      // Track actual change applied (may be different from requested due to clamping)
      final actualChange = newValue - currentValue;

      statChangeResults[statName] = {
        'requested': change,
        'actual': actualChange,
        'oldValue': currentValue,
        'newValue': newValue,
      };

      // Apply the change
      _setStatValue(gameState.stats, statName, newValue);

      // Log warnings for clamped values
      if (actualChange != change) {
        if (newValue == 100 && change > 0) {
          (effectsApplied['warnings'] as List<String>).add(
            '$statName clamped to maximum (100)',
          );
        } else if (newValue == 0 && change < 0) {
          (effectsApplied['warnings'] as List<String>).add(
            '$statName clamped to minimum (0)',
          );
        }
      }
    }

    return statChangeResults;
  }

  /// Enhanced item gain application with inventory management
  void _applyItemGainsEnhanced(
    GameState gameState,
    List<String> itemsToGain,
    Map<String, dynamic> effectsApplied,
  ) {
    for (final itemId in itemsToGain) {
      try {
        // Create item (in a real implementation, this would load from item database)
        final item = InventoryItem(
          id: itemId,
          name: _getItemDisplayName(itemId),
          quantity: 1,
          description: 'Item gained from event',
        );

        // Try to add to inventory
        final success = gameState.inventory.addItem(item);

        if (success) {
          (effectsApplied['itemsGained'] as List<String>).add(itemId);
        } else {
          (effectsApplied['warnings'] as List<String>).add(
            'Inventory full - could not add $itemId',
          );
        }
      } catch (e) {
        (effectsApplied['errors'] as List<String>).add(
          'Failed to add item $itemId: $e',
        );
      }
    }
  }

  /// Enhanced item loss application with validation
  void _applyItemLossesEnhanced(
    GameState gameState,
    List<String> itemsToLose,
    Map<String, dynamic> effectsApplied,
  ) {
    for (final itemId in itemsToLose) {
      try {
        final success = gameState.inventory.removeItem(itemId);

        if (success) {
          (effectsApplied['itemsLost'] as List<String>).add(itemId);
        } else {
          (effectsApplied['warnings'] as List<String>).add(
            'Item $itemId not found in inventory',
          );
        }
      } catch (e) {
        (effectsApplied['errors'] as List<String>).add(
          'Failed to remove item $itemId: $e',
        );
      }
    }
  }

  /// Enhanced status effect application with proper categorization
  void _applyStatusEffectsEnhanced(
    GameState gameState,
    List<String> statusEffectsToApply,
    Map<String, dynamic> effectsApplied,
  ) {
    for (final statusId in statusEffectsToApply) {
      try {
        // In a real implementation, this would load from status effect database
        final statusEffect = _createStatusEffect(statusId);
        gameState.addStatusEffect(statusEffect);
        (effectsApplied['statusEffectsApplied'] as List<String>).add(statusId);
      } catch (e) {
        (effectsApplied['errors'] as List<String>).add(
          'Failed to apply status effect $statusId: $e',
        );
      }
    }
  }

  /// Helper method to set stat values
  void _setStatValue(PlayerStats stats, String statName, int value) {
    switch (statName.toUpperCase()) {
      case 'HP':
        stats.hp = value;
        break;
      case 'SAN':
      case 'SANITY':
        stats.san = value;
        break;
      case 'FIT':
      case 'FITNESS':
        stats.fit = value;
        break;
      case 'HUNGER':
        stats.hunger = value;
        break;
      default:
        throw ArgumentError('Unknown stat name: $statName');
    }
  }

  /// Helper method to get display name for items (would load from database in real implementation)
  String _getItemDisplayName(String itemId) {
    // This would normally query an item database
    final displayNames = {
      'sword': 'Iron Sword',
      'shield': 'Wooden Shield',
      'potion': 'Health Potion',
      'magic_ring': 'Magic Ring',
      'special_key': 'Special Key',
    };
    return displayNames[itemId] ?? itemId.replaceAll('_', ' ').toUpperCase();
  }

  /// Helper method to create status effects (would load from database in real implementation)
  StatusEffect _createStatusEffect(String statusId) {
    // This would normally query a status effect database
    final statusEffectData = {
      'curse': {'name': 'Cursed', 'type': 'DEBUFF', 'duration': 5},
      'blessing': {'name': 'Blessed', 'type': 'BUFF', 'duration': 3},
      'weakness': {'name': 'Weakness', 'type': 'DEBUFF', 'duration': 3},
      'strength': {'name': 'Strength', 'type': 'BUFF', 'duration': 4},
      'poison': {'name': 'Poisoned', 'type': 'DEBUFF', 'duration': 4},
      'healing': {'name': 'Regeneration', 'type': 'BUFF', 'duration': 2},
    };

    final data =
        statusEffectData[statusId] ??
        {
          'name': statusId.replaceAll('_', ' ').toUpperCase(),
          'type': 'DEBUFF',
          'duration': 3,
        };

    return StatusEffect(
      id: statusId,
      name: data['name'] as String,
      type: data['type'] as String,
      remainingDuration: data['duration'] as int,
    );
  }
}
