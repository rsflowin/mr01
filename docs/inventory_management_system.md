# Inventory Management During Events

## Overview

The inventory management system enables players to strategically use items before making event choices, providing immediate stat changes, status effect removal/application, and proper handling of consumable vs non-consumable items. The system integrates seamlessly with the existing GameState and provides comprehensive tracking and validation.

## Key Features

### 1. Strategic Item Usage
- **Pre-Event Usage**: Players can use items before making event choices
- **Immediate Effects**: Item effects are applied instantly upon use
- **Strategic Planning**: Allows optimization of survival chances through item usage

### 2. Comprehensive Item Database
- **JSON-Based Loading**: Items loaded from `data/items.json`
- **Fallback System**: Graceful handling when database files are missing
- **Validation**: Comprehensive item data validation and error handling

### 3. Consumable vs Non-Consumable Items
- **Consumable Items**: Removed from inventory after use
- **Non-Consumable Items**: Remain in inventory after use
- **Quantity Management**: Proper handling of item quantities and stacking

### 4. Advanced Effect Application
- **Stat Changes**: Immediate stat modifications with bounds checking (0-100)
- **Status Effect Removal**: Remove negative status effects (bleeding, poison, etc.)
- **Status Effect Application**: Apply positive status effects (buffs, healing, etc.)
- **Effect Tracking**: Detailed tracking of all effects applied

## Architecture

### Component Structure
```
InventoryManager
├── Item Database Loading & Validation
├── Inventory Display & Filtering  
├── Item Usage & Effect Application
├── Consumable/Non-Consumable Handling
└── Error Handling & Fallback Systems
```

### Data Models

#### Item Model (`Item`)
```dart
class Item {
  final String id;
  final String name;
  final String description;
  final String image;
  final String itemType;
  final bool consumeOnUse;
  final ItemEffects effects;
}
```

#### Item Effects Model (`ItemEffects`)
```dart
class ItemEffects {
  final Map<String, int>? statChanges;    // HP, SAN, FITNESS, HUNGER changes
  final List<String>? removeStatus;       // Status effects to remove
  final List<String>? applyStatus;        // Status effects to apply
}
```

## API Reference

### Main Methods

#### `loadItemDatabase()`
Loads items from JSON file with comprehensive error handling:
```dart
await inventoryManager.loadItemDatabase();
```

#### `displayInventory(GameState, {bool showUsableOnly})`
Returns inventory display data for UI:
```dart
final inventoryDisplay = inventoryManager.displayInventory(
  gameState,
  showUsableOnly: true, // Filter non-usable items
);
```

**Returns:**
```dart
[
  {
    'id': 'first_aid_kit',
    'name': '구급상자',
    'description': '응급 처치 키트',
    'image': 'first_aid_kit.png',
    'quantity': 2,
    'consumeOnUse': true,
    'effects': {
      'statChanges': ['HP: +40', 'SAN: +5'],
      'removeStatus': ['BLEEDING', 'SPRAIN']
    },
    'canUse': true,
    'usageRestrictions': []
  }
]
```

#### `useItem(String itemId, GameState, {int quantity})`
Uses an item and applies effects immediately:
```dart
final result = inventoryManager.useItem(
  'first_aid_kit',
  gameState,
  quantity: 1,
);
```

**Returns:**
```dart
{
  'success': true,
  'gameState': updatedGameState,
  'effectsApplied': {
    'statChanges': {
      'HP': {
        'requested': 40,
        'actual': 40,
        'oldValue': 50,
        'newValue': 90
      }
    },
    'statusRemoved': ['bleeding', 'sprain'],
    'statusApplied': [],
    'errors': [],
    'warnings': []
  },
  'description': 'Used 구급상자. Effects: HP +40, SAN +5. Removed: bleeding, sprain',
  'itemConsumed': true
}
```

## Item Database Format

### JSON Structure
```json
{
  "items": {
    "first_aid_kit": {
      "id": "first_aid_kit",
      "name": "구급상자",
      "description": "응급 처치에 필요한 모든 것이 들어있는 키트",
      "image": "first_aid_kit.png",
      "itemType": "ACTIVE",
      "consumeOnUse": true,
      "effects": {
        "statChanges": {"HP": 40, "SAN": 5},
        "removeStatus": ["bleeding", "sprain"],
        "applyStatus": null
      }
    },
    "multitool": {
      "id": "multitool",
      "name": "멀티툴",
      "description": "다양한 도구가 하나로 합쳐진 만능 도구",
      "image": "multitool.png",
      "itemType": "PASSIVE",
      "consumeOnUse": false,
      "effects": {
        "statChanges": {"SAN": 5},
        "removeStatus": null,
        "applyStatus": null
      }
    }
  }
}
```

### Item Properties

- **id**: Unique identifier
- **name**: Display name (supports localization)
- **description**: Detailed description
- **image**: Image filename for UI
- **itemType**: ACTIVE (usable) or PASSIVE (equipment)
- **consumeOnUse**: true = consumed, false = reusable
- **effects**: Item effects when used

### Effect Types

#### Stat Changes
```json
"statChanges": {
  "HP": 40,        // Health increase
  "SAN": -10,      // Sanity decrease  
  "FITNESS": 15,   // Fitness increase
  "HUNGER": 20     // Hunger increase
}
```

#### Status Effect Management
```json
"removeStatus": ["bleeding", "poison", "fatigue"],
"applyStatus": ["energized", "focused", "blessed"]
```

## Usage Examples

### Basic Item Usage
```dart
// Load item database
await inventoryManager.loadItemDatabase();

// Display available items
final items = inventoryManager.displayInventory(gameState);

// Use a health potion
final result = inventoryManager.useItem('health_potion', gameState);
if (result['success']) {
  gameState = result['gameState'];
  print(result['description']);
}
```

### Pre-Event Strategic Usage
```dart
// Before making event choice, player can use items
final availableItems = inventoryManager.displayInventory(
  gameState,
  showUsableOnly: true,
);

// Player chooses to use first aid kit
final healResult = inventoryManager.useItem('first_aid_kit', gameState);
if (healResult['success']) {
  gameState = healResult['gameState'];
  
  // Now make event choice with improved stats
  final choiceResult = eventProcessor.processChoiceSelectionEnhanced(
    event,
    choiceIndex,
    gameState,
    roomEventData,
  );
}
```

### Multiple Item Usage
```dart
// Use multiple items of same type
final result = inventoryManager.useItem(
  'painkillers',
  gameState,
  quantity: 2,
);

// Check for warnings (like stat clamping)
final warnings = result['effectsApplied']['warnings'] as List<String>;
for (final warning in warnings) {
  print('Warning: $warning');
}
```

### Item Availability Checking
```dart
final items = inventoryManager.displayInventory(gameState);
for (final item in items) {
  if (item['canUse']) {
    print('${item['name']}: Available');
    print('Effects: ${item['effects']['statChanges']}');
  } else {
    print('${item['name']}: ${item['usageRestrictions'].join(', ')}');
  }
}
```

## Error Handling

### Graceful Degradation
- **Missing Database**: Uses fallback items
- **Invalid Items**: Skips and logs warnings
- **File Errors**: Comprehensive error reporting

### Validation Layers
1. **Database Loading**: JSON structure validation
2. **Item Usage**: Inventory and quantity validation
3. **Effect Application**: Stat bounds and status effect validation

### Example Error Scenarios
```dart
// Item not in inventory
final result = inventoryManager.useItem('nonexistent_item', gameState);
// result['success'] = false
// result['errors'] = ['Item nonexistent_item not found in inventory']

// Insufficient quantity
final result = inventoryManager.useItem('potion', gameState, quantity: 5);
// result['success'] = false  
// result['errors'] = ['Insufficient quantity: have 2, need 5']

// Item not in database
final result = inventoryManager.useItem('unknown_item', gameState);
// result['success'] = false
// result['errors'] = ['Item unknown_item not found in database']
```

## Integration Points

### Event System Integration
```dart
// In event processing flow:
// 1. Display event
// 2. Show available items for use
// 3. Allow item usage
// 4. Show event choices with updated stats
// 5. Process choice selection
```

### UI Integration
```dart
// Display inventory with usage options
Widget buildInventoryUI(List<Map<String, dynamic>> items) {
  return ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];
      return ListTile(
        title: Text(item['name']),
        subtitle: Text(item['description']),
        trailing: item['canUse'] 
          ? ElevatedButton(
              onPressed: () => useItem(item['id']),
              child: Text('Use'),
            )
          : Text('Cannot use'),
      );
    },
  );
}
```

### GameState Integration
- **Seamless Integration**: Works directly with existing GameState model
- **State Preservation**: Maintains all game state properties
- **Effect Tracking**: Compatible with existing effect systems

## Performance Considerations

### Optimizations
- **Database Caching**: Items loaded once and cached in memory
- **Lazy Loading**: Only loads items when needed
- **Efficient Validation**: Fast item existence and requirement checks

### Memory Management
- **Cleanup**: Automatic cleanup of consumed items
- **Efficient Storage**: Minimal memory footprint for item data
- **Resource Management**: Proper file handle management

## Testing Coverage

### Comprehensive Test Suite
- **15 Unit Tests**: Cover all major functionality
- **Edge Case Testing**: Boundary conditions and error scenarios
- **Integration Testing**: GameState integration verification
- **Performance Testing**: Large inventory handling

### Test Categories
1. **Database Loading**: Valid/invalid files, fallback behavior
2. **Item Display**: Filtering, formatting, availability
3. **Item Usage**: Success/failure scenarios, quantity handling
4. **Effect Application**: Stat changes, status effects, bounds checking
5. **Error Handling**: Invalid inputs, missing items, database errors

## Future Enhancements

### Planned Features
- **Item Cooldowns**: Time-based usage restrictions
- **Item Combinations**: Crafting and combination systems
- **Conditional Effects**: Context-dependent item effects
- **Advanced Status Effects**: More complex status effect interactions

### Extensibility
- **Modular Design**: Easy addition of new item types
- **Plugin Architecture**: Support for custom item effects
- **Database Migration**: Support for database schema updates
- **Localization Support**: Multi-language item descriptions
