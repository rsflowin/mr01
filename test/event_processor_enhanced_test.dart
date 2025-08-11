import 'package:test/test.dart';
import '../lib/services/event_processor.dart';
import '../lib/models/event_model.dart';
import '../lib/models/room_event_data.dart';
import '../lib/models/game_state.dart';

void main() {
  group('EventProcessor Enhanced Validation', () {
    late EventProcessor processor;
    late Map<String, Event> eventDatabase;
    late GameState testGameState;

    setUp(() {
      eventDatabase = _createTestEventDatabase();
      processor = EventProcessor(eventDatabase: eventDatabase);
      testGameState = _createTestGameState();
    });

    group('validateChoiceRequirementsEnhanced', () {
      test('should return available when no requirements', () {
        final choice = Choice(
          text: 'Simple choice',
          successEffects: ChoiceEffects(description: 'Success'),
        );

        final result = processor.validateChoiceRequirementsEnhanced(
          choice,
          testGameState,
        );

        expect(result['isAvailable'], isTrue);
        expect(result['failureReasons'], isEmpty);
        expect(result['missingItems'], isEmpty);
        expect(result['insufficientStats'], isEmpty);
      });

      test('should validate item requirements correctly', () {
        final choice = Choice(
          text: 'Use items',
          requirements: {
            'items': ['sword', 'shield'],
          },
          successEffects: ChoiceEffects(description: 'Success'),
        );

        // Test with items present
        final gameStateWithItems = _createTestGameState(
          inventory: [
            InventoryItem(id: 'sword', name: 'Sword'),
            InventoryItem(id: 'shield', name: 'Shield'),
            InventoryItem(id: 'potion', name: 'Potion'),
          ],
        );

        final successResult = processor.validateChoiceRequirementsEnhanced(
          choice,
          gameStateWithItems,
        );

        expect(successResult['isAvailable'], isTrue);
        expect(successResult['missingItems'], isEmpty);

        // Test with missing items
        final gameStateWithoutItems = _createTestGameState(
          inventory: [InventoryItem(id: 'potion', name: 'Potion')],
        );

        final failureResult = processor.validateChoiceRequirementsEnhanced(
          choice,
          gameStateWithoutItems,
        );

        expect(failureResult['isAvailable'], isFalse);
        expect(failureResult['missingItems'], containsAll(['sword', 'shield']));
        expect(failureResult['failureReasons'], hasLength(2));
        expect(
          failureResult['failureReasons'],
          contains('Missing required item: sword'),
        );
        expect(
          failureResult['failureReasons'],
          contains('Missing required item: shield'),
        );
      });

      test('should validate stat requirements correctly', () {
        final choice = Choice(
          text: 'Strength check',
          requirements: {
            'stats': {
              'FITNESS': {'operator': '>', 'value': 50},
              'HP': {'operator': '>=', 'value': 30},
            },
          },
          successEffects: ChoiceEffects(description: 'Success'),
        );

        // Test with sufficient stats
        final strongGameState = _createTestGameState(
          stats: PlayerStats(hp: 40, san: 80, fit: 60, hunger: 70),
        );

        final successResult = processor.validateChoiceRequirementsEnhanced(
          choice,
          strongGameState,
        );

        expect(successResult['isAvailable'], isTrue);
        expect(successResult['insufficientStats'], isEmpty);

        // Test with insufficient stats
        final weakGameState = _createTestGameState(
          stats: PlayerStats(hp: 25, san: 80, fit: 40, hunger: 70),
        );

        final failureResult = processor.validateChoiceRequirementsEnhanced(
          choice,
          weakGameState,
        );

        expect(failureResult['isAvailable'], isFalse);
        expect(failureResult['insufficientStats'], hasLength(2));

        final insufficientStats = failureResult['insufficientStats'] as List;
        expect(
          insufficientStats.any((stat) => stat['statName'] == 'FITNESS'),
          isTrue,
        );
        expect(
          insufficientStats.any((stat) => stat['statName'] == 'HP'),
          isTrue,
        );
        expect(
          failureResult['failureReasons'],
          contains('Insufficient FITNESS: 40 > 50 required'),
        );
        expect(
          failureResult['failureReasons'],
          contains('Insufficient HP: 25 >= 30 required'),
        );
      });

      test('should handle combined item and stat requirements', () {
        final choice = Choice(
          text: 'Complex action',
          requirements: {
            'items': ['magic_sword'],
            'stats': {
              'SAN': {'operator': '>', 'value': 60},
            },
          },
          successEffects: ChoiceEffects(description: 'Success'),
        );

        // Test failure on both requirements
        final inadequateGameState = _createTestGameState(
          stats: PlayerStats(hp: 100, san: 50, fit: 70, hunger: 80),
          inventory: [InventoryItem(id: 'potion', name: 'Potion')],
        );

        final result = processor.validateChoiceRequirementsEnhanced(
          choice,
          inadequateGameState,
        );

        expect(result['isAvailable'], isFalse);
        expect(result['missingItems'], contains('magic_sword'));
        expect(result['insufficientStats'], hasLength(1));
        expect(result['failureReasons'], hasLength(2));
      });

      test('should handle all stat name variations', () {
        final choices = [
          _createChoiceWithStatRequirement('HP', '>', 50),
          _createChoiceWithStatRequirement('SAN', '>=', 60),
          _createChoiceWithStatRequirement('SANITY', '==', 70),
          _createChoiceWithStatRequirement('FIT', '<', 90),
          _createChoiceWithStatRequirement('FITNESS', '<=', 90),
          _createChoiceWithStatRequirement('HUNGER', '>', 40),
        ];

        final gameState = _createTestGameState(
          stats: PlayerStats(hp: 60, san: 70, fit: 85, hunger: 50),
        );

        for (final choice in choices) {
          final result = processor.validateChoiceRequirementsEnhanced(
            choice,
            gameState,
          );
          // All requirements should be met
          expect(
            result['isAvailable'],
            isTrue,
            reason: 'Failed for choice: ${choice.text}',
          );
        }
      });
    });

    group('displayEventWithValidation', () {
      test('should include choice availability information', () {
        final event = _createEventWithRequirements();
        final gameState = _createTestGameState(
          stats: PlayerStats(hp: 30, san: 80, fit: 40, hunger: 70),
          inventory: [InventoryItem(id: 'potion', name: 'Potion')],
        );

        final result = processor.displayEventWithValidation(event, gameState);

        expect(result['eventId'], equals(event.id));
        expect(result['name'], equals(event.name));
        expect(result['choices'], hasLength(3));

        final choices = result['choices'] as List;

        // First choice should be available (no requirements)
        expect(choices[0]['isAvailable'], isTrue);
        expect(choices[0]['failureReasons'], isEmpty);

        // Second choice should be unavailable (missing item)
        expect(choices[1]['isAvailable'], isFalse);
        expect(choices[1]['missingItems'], contains('sword'));

        // Third choice should be unavailable (insufficient fitness)
        expect(choices[2]['isAvailable'], isFalse);
        expect(choices[2]['insufficientStats'], isNotEmpty);
      });
    });

    group('evaluateChoiceSuccessEnhanced', () {
      test('should return true when no success conditions', () {
        final choice = Choice(
          text: 'Always succeeds',
          successEffects: ChoiceEffects(description: 'Success'),
        );

        final result = processor.evaluateChoiceSuccessEnhanced(
          choice,
          testGameState,
        );

        expect(result, isTrue);
      });

      test('should handle stat-based success conditions', () {
        final choice = Choice(
          text: 'Fitness check',
          successConditions: {
            'stats': {
              'FITNESS': {'operator': '>', 'value': 60},
            },
          },
          successEffects: ChoiceEffects(description: 'Success'),
        );

        // High fitness should succeed
        final strongGameState = _createTestGameState(
          stats: PlayerStats(hp: 100, san: 100, fit: 80, hunger: 80),
        );
        expect(
          processor.evaluateChoiceSuccessEnhanced(choice, strongGameState),
          isTrue,
        );

        // Low fitness should fail
        final weakGameState = _createTestGameState(
          stats: PlayerStats(hp: 100, san: 100, fit: 40, hunger: 80),
        );
        expect(
          processor.evaluateChoiceSuccessEnhanced(choice, weakGameState),
          isFalse,
        );
      });
    });

    group('applyChoiceEffectsToGameState', () {
      test('should apply stat changes correctly', () {
        final choice = Choice(
          text: 'Heal',
          successEffects: ChoiceEffects(
            description: 'You feel better',
            statChanges: {'HP': 10, 'SAN': -5, 'FITNESS': 3},
          ),
        );

        final gameState = _createTestGameState(
          stats: PlayerStats(hp: 50, san: 60, fit: 70, hunger: 80),
        );

        final result = processor.applyChoiceEffectsToGameState(
          choice,
          gameState,
        );

        expect(result.stats.hp, equals(60));
        expect(result.stats.san, equals(55));
        expect(result.stats.fit, equals(73));
        expect(result.stats.hunger, equals(80)); // Unchanged
      });

      test('should apply item gains and losses', () {
        final choice = Choice(
          text: 'Trade items',
          successEffects: ChoiceEffects(
            description: 'Items traded',
            itemsGained: ['new_sword', 'magic_ring'],
            itemsLost: ['old_sword'],
          ),
        );

        final gameState = _createTestGameState(
          inventory: [
            InventoryItem(id: 'old_sword', name: 'Old Sword'),
            InventoryItem(id: 'potion', name: 'Potion'),
          ],
        );

        final result = processor.applyChoiceEffectsToGameState(
          choice,
          gameState,
        );

        expect(result.inventory.hasItem('new_sword'), isTrue);
        expect(result.inventory.hasItem('magic_ring'), isTrue);
        expect(result.inventory.hasItem('potion'), isTrue);
        expect(result.inventory.hasItem('old_sword'), isFalse);
      });

      test('should apply status effects', () {
        final choice = Choice(
          text: 'Get cursed',
          successEffects: ChoiceEffects(
            description: 'You are cursed',
            applyStatus: ['curse', 'weakness'],
          ),
        );

        final gameState = _createTestGameState();

        final result = processor.applyChoiceEffectsToGameState(
          choice,
          gameState,
        );

        expect(result.statusEffects, hasLength(2));
        expect(
          result.statusEffects.any((effect) => effect.id == 'curse'),
          isTrue,
        );
        expect(
          result.statusEffects.any((effect) => effect.id == 'weakness'),
          isTrue,
        );
      });

      test('should handle failure effects', () {
        final choice = Choice(
          text: 'Risky action',
          successEffects: ChoiceEffects(
            description: 'Success!',
            statChanges: {'HP': 10},
          ),
          failureEffects: ChoiceEffects(
            description: 'Failed!',
            statChanges: {'HP': -10},
          ),
        );

        final gameState = _createTestGameState(
          stats: PlayerStats(hp: 50, san: 80, fit: 70, hunger: 60),
        );

        final result = processor.applyChoiceEffectsToGameState(
          choice,
          gameState,
          useSuccessEffects: false,
        );

        expect(result.stats.hp, equals(40));
      });
    });

    group('processChoiceSelectionEnhanced', () {
      test('should process valid choice selection', () {
        final event = eventDatabase['test_event']!;
        final roomData = RoomEventData.empty(
          'test_room',
        ).addEvent('test_event');

        final result = processor.processChoiceSelectionEnhanced(
          event,
          0, // First choice
          testGameState,
          roomData,
        );

        expect(result['gameState'], isA<GameState>());
        expect(result['roomEventData'], isA<RoomEventData>());
        expect(result['description'], isA<String>());
        expect(result['success'], isA<bool>());
        expect(result['choiceText'], equals('Option 1'));
        expect(result['validation'], isA<Map<String, dynamic>>());
      });

      test('should throw error when choice requirements not met', () {
        final event = _createEventWithRequirements();
        final roomData = RoomEventData.empty('test_room');
        final gameState = _createTestGameState(
          inventory: [], // No required items
        );

        expect(
          () => processor.processChoiceSelectionEnhanced(
            event,
            1, // Choice with item requirement
            gameState,
            roomData,
          ),
          throwsA(isA<StateError>()),
        );
      });
    });
  });
}

/// Helper to create test game state
GameState _createTestGameState({
  PlayerStats? stats,
  List<InventoryItem>? inventory,
  List<StatusEffect>? statusEffects,
}) {
  final playerInventory = PlayerInventory();
  if (inventory != null) {
    for (final item in inventory) {
      playerInventory.addItem(item);
    }
  }

  return GameState(
    stats: stats ?? PlayerStats(hp: 80, san: 70, fit: 75, hunger: 60),
    inventory: playerInventory,
    statusEffects: statusEffects ?? [],
  );
}

/// Helper to create choice with stat requirement
Choice _createChoiceWithStatRequirement(
  String statName,
  String operator,
  int value,
) {
  return Choice(
    text: '$statName check',
    requirements: {
      'stats': {
        statName: {'operator': operator, 'value': value},
      },
    },
    successEffects: ChoiceEffects(description: 'Success'),
  );
}

/// Helper to create event with various requirements
Event _createEventWithRequirements() {
  return Event(
    id: 'requirement_event',
    name: 'Requirement Event',
    description: 'An event with various requirements',
    image: 'requirement.png',
    category: 'test',
    weight: 10,
    persistence: 'oneTime',
    choices: [
      Choice(
        text: 'Simple choice',
        successEffects: ChoiceEffects(description: 'Simple success'),
      ),
      Choice(
        text: 'Use sword',
        requirements: {
          'items': ['sword'],
        },
        successEffects: ChoiceEffects(description: 'Sword used'),
      ),
      Choice(
        text: 'Athletic feat',
        requirements: {
          'stats': {
            'FITNESS': {'operator': '>', 'value': 60},
          },
        },
        successEffects: ChoiceEffects(description: 'Athletic success'),
      ),
    ],
  );
}

/// Helper to create test event database
Map<String, Event> _createTestEventDatabase() {
  return {
    'test_event': Event(
      id: 'test_event',
      name: 'Test Event',
      description: 'A test description',
      image: 'test_image.png',
      category: 'test',
      weight: 10,
      persistence: 'oneTime',
      choices: [
        Choice(
          text: 'Option 1',
          successEffects: ChoiceEffects(
            description: 'Option 1 succeeded',
            statChanges: {'HP': 5},
          ),
        ),
        Choice(
          text: 'Option 2',
          successEffects: ChoiceEffects(
            description: 'Option 2 succeeded',
            statChanges: {'SAN': 3},
          ),
        ),
      ],
    ),
  };
}
