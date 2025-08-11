import 'dart:convert';
import 'dart:io';
import '../models/item_model.dart';
import '../models/game_state.dart';

/// Service responsible for managing inventory during events
///
/// Handles item display, usage, effect application, and consumable management
class InventoryManager {
  static const String _itemsPath = 'data/items.json';
  final Map<String, Item> _itemDatabase = {};

  /// Loads item database from JSON file
  Future<void> loadItemDatabase() async {
    try {
      final file = File(_itemsPath);
      if (!file.existsSync()) {
        print(
          'Warning: Items file not found at $_itemsPath - using fallback items',
        );
        _createFallbackItems();
        return;
      }

      final contents = await file.readAsString();
      final data = json.decode(contents) as Map<String, dynamic>;
      final itemsData = data['items'] as Map<String, dynamic>;

      _itemDatabase.clear();
      for (final entry in itemsData.entries) {
        try {
          final item = Item.fromMap(entry.value as Map<String, dynamic>);
          if (item.isValid()) {
            _itemDatabase[entry.key] = item;
          } else {
            print('Warning: Invalid item data for ${entry.key} - skipping');
          }
        } catch (e) {
          print('Error: Failed to parse item ${entry.key}: $e - skipping');
        }
      }

      print('Successfully loaded ${_itemDatabase.length} items from database');
    } catch (e) {
      print('Error: Failed to load item database: $e');
      _createFallbackItems();
    }
  }

  /// Creates fallback items if database loading fails
  void _createFallbackItems() {
    _itemDatabase.clear();
    _itemDatabase['health_potion'] = Item(
      id: 'health_potion',
      name: 'Health Potion',
      description: 'Restores health',
      image: 'health_potion.png',
      itemType: 'ACTIVE',
      consumeOnUse: true,
      effects: ItemEffects(statChanges: {'HP': 25}),
    );
    print('Using fallback item database with ${_itemDatabase.length} items');
  }

  /// Displays inventory items that can be used during events
  ///
  /// [gameState] - Current game state with inventory
  /// [showUsableOnly] - If true, only shows items that have effects
  ///
  /// Returns a list of inventory display data
  List<Map<String, dynamic>> displayInventory(
    GameState gameState, {
    bool showUsableOnly = true,
  }) {
    final inventoryDisplay = <Map<String, dynamic>>[];

    for (final inventoryItem in gameState.inventory.items) {
      final item = _itemDatabase[inventoryItem.id];

      // Skip items not in database or without effects if filtering
      if (item == null) {
        print('Warning: Item ${inventoryItem.id} not found in database');
        continue;
      }

      if (showUsableOnly && !item.effects.hasEffects) {
        continue;
      }

      inventoryDisplay.add({
        'id': item.id,
        'name': item.name,
        'description': item.description,
        'image': item.image,
        'quantity': inventoryItem.quantity,
        'consumeOnUse': item.consumeOnUse,
        'effects': _formatEffectsForDisplay(item.effects),
        'canUse': _canUseItem(item, gameState),
        'usageRestrictions': _getUsageRestrictions(item, gameState),
      });
    }

    return inventoryDisplay;
  }

  /// Uses an item and applies its effects immediately
  ///
  /// [itemId] - ID of the item to use
  /// [gameState] - Current game state to modify
  /// [quantity] - Number of items to use (default 1)
  ///
  /// Returns result with updated game state and effect information
  Map<String, dynamic> useItem(
    String itemId,
    GameState gameState, {
    int quantity = 1,
  }) {
    final result = {
      'success': false,
      'gameState': gameState,
      'effectsApplied': <String, dynamic>{
        'statChanges': <String, Map<String, int>>{},
        'statusRemoved': <String>[],
        'statusApplied': <String>[],
        'errors': <String>[],
        'warnings': <String>[],
      },
      'description': '',
      'itemConsumed': false,
    };

    // Validate item exists in database
    final item = _itemDatabase[itemId];
    if (item == null) {
      result['errors'] = ['Item $itemId not found in database'];
      result['description'] = 'Unknown item';
      return result;
    }

    // Validate item exists in inventory
    final inventoryItem = gameState.inventory.getItem(itemId);
    if (inventoryItem == null) {
      result['errors'] = ['Item $itemId not found in inventory'];
      result['description'] = 'Item not in inventory';
      return result;
    }

    // Validate quantity
    if (quantity <= 0) {
      result['errors'] = ['Invalid quantity: $quantity'];
      result['description'] = 'Invalid usage amount';
      return result;
    }

    if (quantity > inventoryItem.quantity) {
      result['errors'] = [
        'Insufficient quantity: have ${inventoryItem.quantity}, need $quantity',
      ];
      result['description'] = 'Not enough items';
      return result;
    }

    // Check if item can be used
    if (!_canUseItem(item, gameState)) {
      final restrictions = _getUsageRestrictions(item, gameState);
      result['errors'] = restrictions;
      result['description'] = 'Cannot use item: ${restrictions.join(', ')}';
      return result;
    }

    // Create a copy of the game state to modify
    GameState updatedState = gameState.copyWith();

    // Apply item effects
    final effectsResult = _applyItemEffects(item, updatedState, quantity);

    // Handle consumable items
    if (item.consumeOnUse) {
      final consumeSuccess = updatedState.inventory.removeItem(
        itemId,
        quantity: quantity,
      );
      if (!consumeSuccess) {
        result['errors'] = ['Failed to consume item from inventory'];
        result['description'] = 'Item consumption failed';
        return result;
      }
      result['itemConsumed'] = true;
    }

    // Build successful result
    result['success'] = true;
    result['gameState'] = updatedState;
    result['effectsApplied'] = effectsResult;
    result['description'] = _buildUsageDescription(
      item,
      effectsResult,
      quantity,
    );

    return result;
  }

  /// Applies item effects to game state
  Map<String, dynamic> _applyItemEffects(
    Item item,
    GameState gameState,
    int quantity,
  ) {
    final effectsApplied = {
      'statChanges': <String, Map<String, int>>{},
      'statusRemoved': <String>[],
      'statusApplied': <String>[],
      'errors': <String>[],
      'warnings': <String>[],
    };

    final effects = item.effects;

    // Apply stat changes
    if (effects.statChanges != null) {
      for (final entry in effects.statChanges!.entries) {
        final statName = entry.key.toUpperCase();
        final change = entry.value * quantity;

        try {
          final currentValue = _getStatValue(gameState.stats, statName);
          final newValue = (currentValue + change).clamp(0, 100);
          final actualChange = newValue - currentValue;

          (effectsApplied['statChanges']
              as Map<String, Map<String, int>>)[statName] = {
            'requested': change,
            'actual': actualChange,
            'oldValue': currentValue,
            'newValue': newValue,
          };

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
        } catch (e) {
          (effectsApplied['errors'] as List<String>).add(
            'Failed to apply stat change for $statName: $e',
          );
        }
      }
    }

    // Remove status effects
    if (effects.removeStatus != null) {
      for (final statusId in effects.removeStatus!) {
        final wasRemoved = gameState.statusEffects.any(
          (effect) => effect.id == statusId,
        );
        if (wasRemoved) {
          gameState.removeStatusEffect(statusId);
          (effectsApplied['statusRemoved'] as List<String>).add(statusId);
        }
      }
    }

    // Apply new status effects
    if (effects.applyStatus != null) {
      for (final statusId in effects.applyStatus!) {
        try {
          final statusEffect = _createStatusEffect(statusId);
          gameState.addStatusEffect(statusEffect);
          (effectsApplied['statusApplied'] as List<String>).add(statusId);
        } catch (e) {
          (effectsApplied['errors'] as List<String>).add(
            'Failed to apply status effect $statusId: $e',
          );
        }
      }
    }

    return effectsApplied;
  }

  /// Formats item effects for display to the player
  Map<String, dynamic> _formatEffectsForDisplay(ItemEffects effects) {
    final displayEffects = <String, dynamic>{};

    if (effects.statChanges != null) {
      final statDisplay = <String>[];
      for (final entry in effects.statChanges!.entries) {
        final statName = entry.key;
        final value = entry.value;
        final sign = value > 0 ? '+' : '';
        statDisplay.add('$statName: $sign$value');
      }
      displayEffects['statChanges'] = statDisplay;
    }

    if (effects.removeStatus != null && effects.removeStatus!.isNotEmpty) {
      displayEffects['removeStatus'] = effects.removeStatus!
          .map((status) => status.replaceAll('_', ' ').toUpperCase())
          .toList();
    }

    if (effects.applyStatus != null && effects.applyStatus!.isNotEmpty) {
      displayEffects['applyStatus'] = effects.applyStatus!
          .map((status) => status.replaceAll('_', ' ').toUpperCase())
          .toList();
    }

    return displayEffects;
  }

  /// Checks if an item can currently be used
  bool _canUseItem(Item item, GameState gameState) {
    // Basic validation - item must have effects
    if (!item.effects.hasEffects) {
      return false;
    }

    // Additional restrictions could be added here
    // For example: cooldowns, specific game state requirements, etc.

    return true;
  }

  /// Gets reasons why an item cannot be used
  List<String> _getUsageRestrictions(Item item, GameState gameState) {
    final restrictions = <String>[];

    if (!item.effects.hasEffects) {
      restrictions.add('Item has no usable effects');
    }

    // Additional restriction checks could be added here

    return restrictions;
  }

  /// Builds a descriptive text for item usage results
  String _buildUsageDescription(
    Item item,
    Map<String, dynamic> effectsApplied,
    int quantity,
  ) {
    final parts = <String>[];

    if (quantity > 1) {
      parts.add('Used $quantity ${item.name}');
    } else {
      parts.add('Used ${item.name}');
    }

    final statChanges =
        effectsApplied['statChanges'] as Map<String, Map<String, int>>;
    if (statChanges.isNotEmpty) {
      final statParts = <String>[];
      for (final entry in statChanges.entries) {
        final statName = entry.key;
        final change = entry.value['actual'] as int;
        if (change != 0) {
          final sign = change > 0 ? '+' : '';
          statParts.add('$statName $sign$change');
        }
      }
      if (statParts.isNotEmpty) {
        parts.add('Effects: ${statParts.join(', ')}');
      }
    }

    final statusRemoved = effectsApplied['statusRemoved'] as List<String>;
    if (statusRemoved.isNotEmpty) {
      parts.add('Removed: ${statusRemoved.join(', ')}');
    }

    final statusApplied = effectsApplied['statusApplied'] as List<String>;
    if (statusApplied.isNotEmpty) {
      parts.add('Applied: ${statusApplied.join(', ')}');
    }

    final warnings = effectsApplied['warnings'] as List<String>;
    if (warnings.isNotEmpty) {
      parts.add('Note: ${warnings.join(', ')}');
    }

    return parts.join('. ');
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
        throw ArgumentError('Unknown stat name: $statName');
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

  /// Helper method to create status effects (would load from database in real implementation)
  StatusEffect _createStatusEffect(String statusId) {
    // This would normally query a status effect database
    final statusEffectData = {
      'bleeding': {'name': 'Bleeding', 'type': 'DEBUFF', 'duration': 3},
      'sprain': {'name': 'Sprained', 'type': 'DEBUFF', 'duration': 4},
      'fatigue': {'name': 'Fatigued', 'type': 'DEBUFF', 'duration': 5},
      'dizziness': {'name': 'Dizzy', 'type': 'DEBUFF', 'duration': 2},
      'claustrophobia': {
        'name': 'Claustrophobic',
        'type': 'DEBUFF',
        'duration': 6,
      },
      'energized': {'name': 'Energized', 'type': 'BUFF', 'duration': 3},
      'focused': {'name': 'Focused', 'type': 'BUFF', 'duration': 4},
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

  /// Gets item from database by ID
  Item? getItem(String itemId) => _itemDatabase[itemId];

  /// Gets all items in database
  Map<String, Item> get allItems => Map.unmodifiable(_itemDatabase);

  /// Gets number of items in database
  int get itemCount => _itemDatabase.length;

  /// Checks if database is loaded
  bool get isDatabaseLoaded => _itemDatabase.isNotEmpty;
}
