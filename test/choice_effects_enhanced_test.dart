import 'package:test/test.dart';
import '../lib/services/event_processor.dart';
import '../lib/models/event_model.dart';
import '../lib/models/room_event_data.dart';
import '../lib/models/game_state.dart';

void main() {
  group('Enhanced Choice Effects Application', () {
    late EventProcessor processor;
    late Map<String, Event> eventDatabase;

    setUp(() {
      eventDatabase = _createTestEventDatabase();
      processor = EventProcessor(eventDatabase: eventDatabase);
    });

    group('applyChoiceEffectsToGameStateEnhanced', () {
      test('should apply stat changes with detailed tracking', () {
        final choice = Choice(
          text: 'Heal and train',
          successEffects: ChoiceEffects(
            description: 'You feel better and stronger',
            statChanges: {'HP': 15, 'SAN': -5, 'FITNESS': 10},
          ),
        );

        final gameState = _createTestGameState(
          stats: PlayerStats(hp: 50, san: 60, fit: 70, hunger: 80),
        );

        final result = processor.applyChoiceEffectsToGameStateEnhanced(
          choice,
          gameState,
        );

        final updatedGameState = result['gameState'] as GameState;
        final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;

        // Check stat changes
        expect(updatedGameState.stats.hp, equals(65));
        expect(updatedGameState.stats.san, equals(55));
        expect(updatedGameState.stats.fit, equals(80));

        // Check tracking data
        final statChanges =
            effectsApplied['statChanges'] as Map<String, Map<String, int>>;
        expect(statChanges['HP']!['requested'], equals(15));
        expect(statChanges['HP']!['actual'], equals(15));
        expect(statChanges['HP']!['oldValue'], equals(50));
        expect(statChanges['HP']!['newValue'], equals(65));

        expect(result['description'], equals('You feel better and stronger'));
      });

      test('should handle stat bounds with warnings', () {
        final choice = Choice(
          text: 'Extreme effects',
          successEffects: ChoiceEffects(
            description: 'Extreme changes occur',
            statChanges: {'HP': 200, 'SAN': -200},
          ),
        );

        final gameState = _createTestGameState(
          stats: PlayerStats(hp: 50, san: 50, fit: 70, hunger: 80),
        );

        final result = processor.applyChoiceEffectsToGameStateEnhanced(
          choice,
          gameState,
        );

        final updatedGameState = result['gameState'] as GameState;
        final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;

        // Check clamped values
        expect(updatedGameState.stats.hp, equals(100));
        expect(updatedGameState.stats.san, equals(0));

        // Check warnings
        final warnings = effectsApplied['warnings'] as List<String>;
        expect(warnings, contains('HP clamped to maximum (100)'));
        expect(warnings, contains('SAN clamped to minimum (0)'));

        // Check stat change tracking
        final statChanges =
            effectsApplied['statChanges'] as Map<String, Map<String, int>>;
        expect(statChanges['HP']!['requested'], equals(200));
        expect(
          statChanges['HP']!['actual'],
          equals(50),
        ); // Only increased by 50
        expect(statChanges['SAN']!['requested'], equals(-200));
        expect(
          statChanges['SAN']!['actual'],
          equals(-50),
        ); // Only decreased by 50
      });

      test('should handle item gains with inventory management', () {
        final choice = Choice(
          text: 'Find treasure',
          successEffects: ChoiceEffects(
            description: 'You found valuable items',
            itemsGained: ['sword', 'magic_ring', 'potion'],
          ),
        );

        final gameState = _createTestGameState(
          inventory: [InventoryItem(id: 'old_item', name: 'Old Item')],
        );

        final result = processor.applyChoiceEffectsToGameStateEnhanced(
          choice,
          gameState,
        );

        final updatedGameState = result['gameState'] as GameState;
        final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;

        // Check items were added
        expect(updatedGameState.inventory.hasItem('sword'), isTrue);
        expect(updatedGameState.inventory.hasItem('magic_ring'), isTrue);
        expect(updatedGameState.inventory.hasItem('potion'), isTrue);
        expect(updatedGameState.inventory.hasItem('old_item'), isTrue);

        // Check tracking
        final itemsGained = effectsApplied['itemsGained'] as List<String>;
        expect(itemsGained, contains('sword'));
        expect(itemsGained, contains('magic_ring'));
        expect(itemsGained, contains('potion'));
      });

      test('should handle inventory full scenario', () {
        final choice = Choice(
          text: 'Find more items',
          successEffects: ChoiceEffects(
            description: 'You found items but inventory is full',
            itemsGained: ['extra_item'],
          ),
        );

        // Create game state with full inventory
        final gameState = _createTestGameState(
          inventory: [
            InventoryItem(id: 'item1', name: 'Item 1'),
            InventoryItem(id: 'item2', name: 'Item 2'),
            InventoryItem(id: 'item3', name: 'Item 3'),
            InventoryItem(id: 'item4', name: 'Item 4'),
            InventoryItem(id: 'item5', name: 'Item 5'),
          ],
        );

        final result = processor.applyChoiceEffectsToGameStateEnhanced(
          choice,
          gameState,
        );

        final updatedGameState = result['gameState'] as GameState;
        final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;

        // Item should not be added
        expect(updatedGameState.inventory.hasItem('extra_item'), isFalse);

        // Should have warning
        final warnings = effectsApplied['warnings'] as List<String>;
        expect(warnings, contains('Inventory full - could not add extra_item'));
      });

      test('should handle item losses with validation', () {
        final choice = Choice(
          text: 'Lose items',
          successEffects: ChoiceEffects(
            description: 'You lost some items',
            itemsLost: ['sword', 'nonexistent_item'],
          ),
        );

        final gameState = _createTestGameState(
          inventory: [
            InventoryItem(id: 'sword', name: 'Iron Sword'),
            InventoryItem(id: 'potion', name: 'Health Potion'),
          ],
        );

        final result = processor.applyChoiceEffectsToGameStateEnhanced(
          choice,
          gameState,
        );

        final updatedGameState = result['gameState'] as GameState;
        final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;

        // Sword should be removed
        expect(updatedGameState.inventory.hasItem('sword'), isFalse);
        expect(updatedGameState.inventory.hasItem('potion'), isTrue);

        // Check tracking
        final itemsLost = effectsApplied['itemsLost'] as List<String>;
        expect(itemsLost, contains('sword'));

        // Should have warning for nonexistent item
        final warnings = effectsApplied['warnings'] as List<String>;
        expect(
          warnings,
          contains('Item nonexistent_item not found in inventory'),
        );
      });

      test('should apply status effects with proper categorization', () {
        final choice = Choice(
          text: 'Cast spells',
          successEffects: ChoiceEffects(
            description: 'You are affected by magic',
            applyStatus: ['blessing', 'curse', 'strength'],
          ),
        );

        final gameState = _createTestGameState();

        final result = processor.applyChoiceEffectsToGameStateEnhanced(
          choice,
          gameState,
        );

        final updatedGameState = result['gameState'] as GameState;
        final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;

        // Check status effects were added
        expect(updatedGameState.statusEffects, hasLength(3));
        expect(
          updatedGameState.statusEffects.any(
            (effect) => effect.id == 'blessing',
          ),
          isTrue,
        );
        expect(
          updatedGameState.statusEffects.any((effect) => effect.id == 'curse'),
          isTrue,
        );
        expect(
          updatedGameState.statusEffects.any(
            (effect) => effect.id == 'strength',
          ),
          isTrue,
        );

        // Check tracking
        final statusEffectsApplied =
            effectsApplied['statusEffectsApplied'] as List<String>;
        expect(statusEffectsApplied, contains('blessing'));
        expect(statusEffectsApplied, contains('curse'));
        expect(statusEffectsApplied, contains('strength'));

        // Check proper categorization
        final blessing = updatedGameState.statusEffects.firstWhere(
          (effect) => effect.id == 'blessing',
        );
        expect(blessing.type, equals('BUFF'));
        expect(blessing.name, equals('Blessed'));

        final curse = updatedGameState.statusEffects.firstWhere(
          (effect) => effect.id == 'curse',
        );
        expect(curse.type, equals('DEBUFF'));
        expect(curse.name, equals('Cursed'));
      });

      test('should handle failure effects correctly', () {
        final choice = Choice(
          text: 'Risky action',
          successEffects: ChoiceEffects(
            description: 'Success!',
            statChanges: {'HP': 10},
          ),
          failureEffects: ChoiceEffects(
            description: 'You failed and got hurt',
            statChanges: {'HP': -15, 'SAN': -10},
            applyStatus: ['weakness'],
          ),
        );

        final gameState = _createTestGameState(
          stats: PlayerStats(hp: 50, san: 70, fit: 60, hunger: 80),
        );

        final result = processor.applyChoiceEffectsToGameStateEnhanced(
          choice,
          gameState,
          useSuccessEffects: false,
        );

        final updatedGameState = result['gameState'] as GameState;

        // Check failure effects applied
        expect(updatedGameState.stats.hp, equals(35));
        expect(updatedGameState.stats.san, equals(60));
        expect(updatedGameState.statusEffects, hasLength(1));
        expect(updatedGameState.statusEffects.first.id, equals('weakness'));

        expect(result['description'], equals('You failed and got hurt'));
      });

      test('should handle combined complex effects', () {
        final choice = Choice(
          text: 'Complex magical ritual',
          successEffects: ChoiceEffects(
            description: 'The ritual succeeds with unexpected results',
            statChanges: {'HP': -20, 'SAN': 30, 'FITNESS': -10},
            itemsGained: ['magic_ring', 'ancient_scroll'],
            itemsLost: ['common_reagent'],
            applyStatus: ['blessing', 'weakness'],
          ),
        );

        final gameState = _createTestGameState(
          stats: PlayerStats(hp: 80, san: 50, fit: 70, hunger: 60),
          inventory: [
            InventoryItem(id: 'common_reagent', name: 'Common Reagent'),
            InventoryItem(id: 'other_item', name: 'Other Item'),
          ],
        );

        final result = processor.applyChoiceEffectsToGameStateEnhanced(
          choice,
          gameState,
        );

        final updatedGameState = result['gameState'] as GameState;
        final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;

        // Check all stat changes
        expect(updatedGameState.stats.hp, equals(60));
        expect(updatedGameState.stats.san, equals(80));
        expect(updatedGameState.stats.fit, equals(60));

        // Check inventory changes
        expect(updatedGameState.inventory.hasItem('magic_ring'), isTrue);
        expect(updatedGameState.inventory.hasItem('ancient_scroll'), isTrue);
        expect(updatedGameState.inventory.hasItem('common_reagent'), isFalse);
        expect(updatedGameState.inventory.hasItem('other_item'), isTrue);

        // Check status effects
        expect(updatedGameState.statusEffects, hasLength(2));

        // Check comprehensive tracking
        expect(effectsApplied['itemsGained'], hasLength(2));
        expect(effectsApplied['itemsLost'], contains('common_reagent'));
        expect(effectsApplied['statusEffectsApplied'], hasLength(2));
        expect(effectsApplied['errors'], isEmpty);
      });

      test('should handle null effects gracefully', () {
        final choice = Choice(
          text: 'No effects',
          successEffects: ChoiceEffects(description: 'Nothing happens'),
        );

        final gameState = _createTestGameState();

        final result = processor.applyChoiceEffectsToGameStateEnhanced(
          choice,
          gameState,
        );

        final updatedGameState = result['gameState'] as GameState;
        final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;

        // Game state should be unchanged
        expect(updatedGameState.stats.hp, equals(gameState.stats.hp));
        expect(
          updatedGameState.inventory.items.length,
          equals(gameState.inventory.items.length),
        );
        expect(
          updatedGameState.statusEffects.length,
          equals(gameState.statusEffects.length),
        );

        // Effects tracking should be empty
        expect(effectsApplied['statChanges'], isEmpty);
        expect(effectsApplied['itemsGained'], isEmpty);
        expect(effectsApplied['itemsLost'], isEmpty);
        expect(effectsApplied['statusEffectsApplied'], isEmpty);
        expect(effectsApplied['errors'], isEmpty);
        expect(effectsApplied['warnings'], isEmpty);
      });
    });

    group('processChoiceSelectionEnhanced with effects', () {
      test('should include effects tracking in results', () {
        final event = eventDatabase['complex_event']!;
        final roomData = RoomEventData.empty(
          'test_room',
        ).addEvent('complex_event');
        final gameState = _createTestGameState(
          inventory: [
            InventoryItem(id: 'required_item', name: 'Required Item'),
          ],
        );

        final result = processor.processChoiceSelectionEnhanced(
          event,
          0, // Choice with effects
          gameState,
          roomData,
        );

        expect(result['effectsApplied'], isA<Map<String, dynamic>>());
        final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;

        // Should have some effects applied
        expect(effectsApplied.containsKey('statChanges'), isTrue);
        expect(effectsApplied.containsKey('itemsGained'), isTrue);
        expect(effectsApplied.containsKey('itemsLost'), isTrue);
      });
    });

    group('backward compatibility', () {
      test('should maintain compatibility with original method', () {
        final choice = Choice(
          text: 'Simple heal',
          successEffects: ChoiceEffects(
            description: 'You feel better',
            statChanges: {'HP': 20},
          ),
        );

        // Create separate game states for each test
        final gameState1 = _createTestGameState(
          stats: PlayerStats(hp: 50, san: 70, fit: 80, hunger: 60),
        );
        final gameState2 = _createTestGameState(
          stats: PlayerStats(hp: 50, san: 70, fit: 80, hunger: 60),
        );

        // Test legacy method
        final legacyResult = processor.applyChoiceEffectsToGameState(
          choice,
          gameState1,
        );

        // Test enhanced method
        final enhancedResult = processor.applyChoiceEffectsToGameStateEnhanced(
          choice,
          gameState2,
        );

        // Results should be equivalent
        expect(legacyResult.stats.hp, equals(70));
        expect((enhancedResult['gameState'] as GameState).stats.hp, equals(70));
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

/// Helper to create test event database
Map<String, Event> _createTestEventDatabase() {
  return {
    'complex_event': Event(
      id: 'complex_event',
      name: 'Complex Event',
      description: 'An event with complex effects',
      image: 'complex.png',
      category: 'test',
      weight: 10,
      persistence: 'oneTime',
      choices: [
        Choice(
          text: 'Complex choice',
          requirements: {
            'items': ['required_item'],
          },
          successEffects: ChoiceEffects(
            description: 'Complex effects occur',
            statChanges: {'HP': 10, 'SAN': -5},
            itemsGained: ['reward_item'],
            itemsLost: ['required_item'],
            applyStatus: ['blessing'],
          ),
        ),
      ],
    ),
  };
}
