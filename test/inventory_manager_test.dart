import 'package:test/test.dart';
import 'dart:io';
import 'dart:convert';
import '../lib/services/inventory_manager.dart';
import '../lib/models/item_model.dart';
import '../lib/models/game_state.dart';

void main() {
  group('InventoryManager', () {
    late InventoryManager inventoryManager;
    late GameState testGameState;

    setUp(() {
      inventoryManager = InventoryManager();
      testGameState = _createTestGameState();
    });

    group('Item Database Loading', () {
      test('should load items from JSON file', () async {
        // Create a temporary test file
        await _createTestItemFile();

        await inventoryManager.loadItemDatabase();

        expect(inventoryManager.isDatabaseLoaded, isTrue);
        expect(inventoryManager.itemCount, greaterThan(0));

        // Check if a specific item was loaded
        final healthPotion = inventoryManager.getItem('first_aid_kit');
        expect(healthPotion, isNotNull);
        expect(healthPotion!.name, isNotEmpty);

        // Clean up
        await _cleanupTestFile();
      });

      test('should use fallback items when file not found', () async {
        // Ensure no test file exists
        await _cleanupTestFile();

        await inventoryManager.loadItemDatabase();

        expect(inventoryManager.isDatabaseLoaded, isTrue);
        expect(
          inventoryManager.itemCount,
          equals(1),
        ); // Should have fallback item

        final fallbackItem = inventoryManager.getItem('health_potion');
        expect(fallbackItem, isNotNull);
        expect(fallbackItem!.name, equals('Health Potion'));
      });
    });

    group('displayInventory', () {
      setUp(() async {
        await _createTestItemFile();
        await inventoryManager.loadItemDatabase();
      });

      tearDown(() async {
        await _cleanupTestFile();
      });

      test('should display usable items from inventory', () {
        final gameState = _createTestGameState(
          inventory: [
            InventoryItem(
              id: 'first_aid_kit',
              name: 'First Aid Kit',
              quantity: 2,
            ),
            InventoryItem(id: 'painkillers', name: 'Painkillers', quantity: 1),
          ],
        );

        final display = inventoryManager.displayInventory(gameState);

        expect(display, hasLength(2));

        final firstAidDisplay = display.firstWhere(
          (item) => item['id'] == 'first_aid_kit',
        );
        expect(firstAidDisplay['name'], equals('구급상자'));
        expect(firstAidDisplay['quantity'], equals(2));
        expect(firstAidDisplay['consumeOnUse'], isTrue);
        expect(firstAidDisplay['canUse'], isTrue);
        expect(firstAidDisplay['effects'], isA<Map<String, dynamic>>());
      });

      test('should filter out non-usable items when requested', () {
        final gameState = _createTestGameState(
          inventory: [
            InventoryItem(id: 'first_aid_kit', name: 'First Aid Kit'),
            InventoryItem(id: 'invalid_item', name: 'Invalid Item'),
          ],
        );

        final displayUsableOnly = inventoryManager.displayInventory(
          gameState,
          showUsableOnly: true,
        );
        final displayAll = inventoryManager.displayInventory(
          gameState,
          showUsableOnly: false,
        );

        expect(displayUsableOnly.length, lessThanOrEqualTo(displayAll.length));
      });

      test('should handle items not in database gracefully', () {
        final gameState = _createTestGameState(
          inventory: [
            InventoryItem(id: 'unknown_item', name: 'Unknown Item'),
            InventoryItem(id: 'first_aid_kit', name: 'First Aid Kit'),
          ],
        );

        final display = inventoryManager.displayInventory(gameState);

        // Should only display the known item
        expect(display, hasLength(1));
        expect(display.first['id'], equals('first_aid_kit'));
      });
    });

    group('useItem', () {
      setUp(() async {
        await _createTestItemFile();
        await inventoryManager.loadItemDatabase();
      });

      tearDown(() async {
        await _cleanupTestFile();
      });

      test('should successfully use consumable item with stat effects', () {
        final gameState = _createTestGameState(
          stats: PlayerStats(hp: 50, san: 60, fit: 70, hunger: 80),
          inventory: [
            InventoryItem(
              id: 'first_aid_kit',
              name: 'First Aid Kit',
              quantity: 2,
            ),
          ],
        );

        final result = inventoryManager.useItem('first_aid_kit', gameState);

        expect(result['success'], isTrue);
        expect(result['itemConsumed'], isTrue);
        expect(result['description'], isA<String>());

        final updatedGameState = result['gameState'] as GameState;
        expect(updatedGameState.stats.hp, equals(90)); // 50 + 40
        expect(updatedGameState.stats.san, equals(65)); // 60 + 5
        expect(
          updatedGameState.inventory.getItem('first_aid_kit')!.quantity,
          equals(1),
        );

        final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;
        expect(effectsApplied['statChanges'], isNotEmpty);
      });

      test('should handle stat clamping correctly', () {
        final gameState = _createTestGameState(
          stats: PlayerStats(hp: 95, san: 60, fit: 70, hunger: 80),
          inventory: [
            InventoryItem(id: 'first_aid_kit', name: 'First Aid Kit'),
          ],
        );

        final result = inventoryManager.useItem('first_aid_kit', gameState);

        expect(result['success'], isTrue);

        final updatedGameState = result['gameState'] as GameState;
        expect(updatedGameState.stats.hp, equals(100)); // Clamped to maximum

        final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;
        final warnings = effectsApplied['warnings'] as List<String>;
        expect(warnings, contains('HP clamped to maximum (100)'));
      });

      test('should use multiple quantities correctly', () {
        final gameState = _createTestGameState(
          stats: PlayerStats(hp: 20, san: 30, fit: 70, hunger: 80),
          inventory: [
            InventoryItem(id: 'painkillers', name: 'Painkillers', quantity: 3),
          ],
        );

        final result = inventoryManager.useItem(
          'painkillers',
          gameState,
          quantity: 2,
        );

        expect(result['success'], isTrue);

        final updatedGameState = result['gameState'] as GameState;
        expect(updatedGameState.stats.san, equals(50)); // 30 + (10 * 2)
        expect(
          updatedGameState.inventory.getItem('painkillers')!.quantity,
          equals(1),
        );
      });

      test('should handle status effect removal', () {
        final gameState = _createTestGameState(
          statusEffects: [
            StatusEffect(
              id: 'bleeding',
              name: 'Bleeding',
              type: 'DEBUFF',
              remainingDuration: 3,
            ),
            StatusEffect(
              id: 'sprain',
              name: 'Sprained',
              type: 'DEBUFF',
              remainingDuration: 2,
            ),
          ],
          inventory: [
            InventoryItem(id: 'first_aid_kit', name: 'First Aid Kit'),
          ],
        );

        final result = inventoryManager.useItem('first_aid_kit', gameState);

        expect(result['success'], isTrue);

        final updatedGameState = result['gameState'] as GameState;
        expect(
          updatedGameState.statusEffects.any(
            (effect) => effect.id == 'bleeding',
          ),
          isFalse,
        );
        expect(
          updatedGameState.statusEffects.any((effect) => effect.id == 'sprain'),
          isFalse,
        );

        final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;
        final statusRemoved = effectsApplied['statusRemoved'] as List<String>;
        expect(statusRemoved, contains('bleeding'));
        expect(statusRemoved, contains('sprain'));
      });

      test('should fail when item not in inventory', () {
        final gameState = _createTestGameState(inventory: []);

        final result = inventoryManager.useItem('first_aid_kit', gameState);

        expect(result['success'], isFalse);
        expect(
          result['errors'],
          contains('Item first_aid_kit not found in inventory'),
        );
      });

      test('should fail when insufficient quantity', () {
        final gameState = _createTestGameState(
          inventory: [
            InventoryItem(
              id: 'first_aid_kit',
              name: 'First Aid Kit',
              quantity: 1,
            ),
          ],
        );

        final result = inventoryManager.useItem(
          'first_aid_kit',
          gameState,
          quantity: 2,
        );

        expect(result['success'], isFalse);
        expect(result['errors'].first, contains('Insufficient quantity'));
      });

      test('should fail when item not in database', () {
        final gameState = _createTestGameState(
          inventory: [InventoryItem(id: 'unknown_item', name: 'Unknown Item')],
        );

        final result = inventoryManager.useItem('unknown_item', gameState);

        expect(result['success'], isFalse);
        expect(
          result['errors'],
          contains('Item unknown_item not found in database'),
        );
      });

      test('should fail with invalid quantity', () {
        final gameState = _createTestGameState(
          inventory: [
            InventoryItem(id: 'first_aid_kit', name: 'First Aid Kit'),
          ],
        );

        final result = inventoryManager.useItem(
          'first_aid_kit',
          gameState,
          quantity: 0,
        );

        expect(result['success'], isFalse);
        expect(result['errors'].first, contains('Invalid quantity'));
      });
    });

    group('Item Effects Formatting', () {
      setUp(() async {
        await _createTestItemFile();
        await inventoryManager.loadItemDatabase();
      });

      tearDown(() async {
        await _cleanupTestFile();
      });

      test('should format stat changes for display', () {
        final gameState = _createTestGameState(
          inventory: [
            InventoryItem(id: 'first_aid_kit', name: 'First Aid Kit'),
          ],
        );

        final display = inventoryManager.displayInventory(gameState);
        final firstAidDisplay = display.first;

        expect(firstAidDisplay['effects'], isA<Map<String, dynamic>>());
        final effects = firstAidDisplay['effects'] as Map<String, dynamic>;

        if (effects.containsKey('statChanges')) {
          final statChanges = effects['statChanges'] as List<String>;
          expect(statChanges, isNotEmpty);
          expect(statChanges.any((change) => change.contains('HP')), isTrue);
        }
      });
    });

    group('Integration with GameState', () {
      setUp(() async {
        await _createTestItemFile();
        await inventoryManager.loadItemDatabase();
      });

      tearDown(() async {
        await _cleanupTestFile();
      });

      test('should preserve other game state properties', () {
        final gameState = _createTestGameState(
          turnCount: 5,
          statusEffects: [
            StatusEffect(
              id: 'blessing',
              name: 'Blessed',
              type: 'BUFF',
              remainingDuration: 2,
            ),
          ],
          inventory: [
            InventoryItem(id: 'first_aid_kit', name: 'First Aid Kit'),
          ],
        );

        final result = inventoryManager.useItem('first_aid_kit', gameState);
        final updatedGameState = result['gameState'] as GameState;

        expect(updatedGameState.turnCount, equals(5));
        expect(
          updatedGameState.statusEffects.any(
            (effect) => effect.id == 'blessing',
          ),
          isTrue,
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
  int? turnCount,
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
    turnCount: turnCount ?? 0,
  );
}

/// Helper to create test item file
Future<void> _createTestItemFile() async {
  const testItemData = {
    "items": {
      "first_aid_kit": {
        "id": "first_aid_kit",
        "name": "구급상자",
        "description": "응급 처치에 필요한 모든 것이 들어있는 키트. 심각한 부상을 치료할 수 있다.",
        "image": "first_aid_kit.png",
        "itemType": "ACTIVE",
        "consumeOnUse": true,
        "effects": {
          "statChanges": {"HP": 40, "SAN": 5},
          "removeStatus": ["bleeding", "sprain"],
          "applyStatus": null,
        },
      },
      "painkillers": {
        "id": "painkillers",
        "name": "진통제",
        "description": "통증을 잠시 잊게 해준다. 몸의 피로와 어지러움이 가신다.",
        "image": "painkillers.png",
        "itemType": "ACTIVE",
        "consumeOnUse": true,
        "effects": {
          "statChanges": {"SAN": 10},
          "removeStatus": ["fatigue", "dizziness"],
          "applyStatus": null,
        },
      },
    },
  };

  final file = File('data/items.json');
  await file.create(recursive: true);
  await file.writeAsString(json.encode(testItemData));
}

/// Helper to clean up test file
Future<void> _cleanupTestFile() async {
  final file = File('data/items.json');
  if (await file.exists()) {
    await file.delete();
  }

  // Also clean up the directory if it's empty
  final dir = Directory('data');
  if (await dir.exists()) {
    final contents = await dir.list().toList();
    if (contents.isEmpty) {
      await dir.delete();
    }
  }
}
