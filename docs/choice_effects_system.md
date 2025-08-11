# Enhanced Choice Effects Application System

## Overview

The enhanced choice effects application system provides comprehensive handling of all effect types when players make choices during events. It includes detailed tracking, proper bounds checking, robust error handling, and extensive validation for all effect applications.

## Key Features

### 1. Enhanced Stat Changes Application

- **Comprehensive Bounds Checking**: All stats are clamped to the 0-100 range with detailed tracking
- **Change Tracking**: Records requested vs. actual changes applied
- **Warning System**: Alerts when values are clamped to boundaries
- **Multiple Stat Support**: Handles HP, SAN/SANITY, FIT/FITNESS, and HUNGER

### 2. Advanced Inventory Management

- **Smart Item Addition**: Checks inventory capacity and provides appropriate feedback
- **Item Validation**: Ensures items exist before removal attempts
- **Display Name Resolution**: Provides human-readable item names
- **Quantity Handling**: Supports proper item stacking and quantity management

### 3. Status Effect Application

- **Proper Categorization**: Automatically determines BUFF vs DEBUFF types
- **Duration Management**: Sets appropriate durations for different effect types
- **Effect Database**: Maintains common status effects with proper metadata
- **Conflict Resolution**: Handles duplicate status effects appropriately

### 4. Comprehensive Effect Tracking

The enhanced system tracks all effects applied with detailed information:

```dart
final effectsApplied = {
  'statChanges': <String, Map<String, int>>{},     // Detailed stat change tracking
  'itemsGained': <String>[],                       // Successfully added items
  'itemsLost': <String>[],                         // Successfully removed items
  'statusEffectsApplied': <String>[],              // Applied status effects
  'errors': <String>[],                            // Error messages
  'warnings': <String>[],                          // Warning messages
};
```

## API Reference

### Main Methods

#### `applyChoiceEffectsToGameStateEnhanced`

Enhanced effects application with detailed tracking:

```dart
Map<String, dynamic> applyChoiceEffectsToGameStateEnhanced(
  Choice choice,
  GameState gameState, {
  bool useSuccessEffects = true,
})
```

**Returns:**
```dart
{
  'gameState': GameState,           // Updated game state
  'effectsApplied': Map,           // Detailed tracking information
  'description': String,           // Effect description
}
```

#### `applyChoiceEffectsToGameState` (Legacy)

Backward-compatible method that returns only the updated GameState:

```dart
GameState applyChoiceEffectsToGameState(
  Choice choice,
  GameState gameState, {
  bool useSuccessEffects = true,
})
```

### Effect Types

#### Stat Changes

```json
{
  "statChanges": {
    "HP": 15,
    "SAN": -10,
    "FITNESS": 5,
    "HUNGER": -3
  }
}
```

**Stat Change Tracking:**
```dart
{
  "HP": {
    "requested": 15,     // Original change requested
    "actual": 10,        // Actual change applied (may differ due to clamping)
    "oldValue": 85,      // Value before change
    "newValue": 95       // Value after change
  }
}
```

#### Item Changes

```json
{
  "itemsGained": ["sword", "magic_ring", "potion"],
  "itemsLost": ["old_weapon", "used_consumable"]
}
```

**Features:**
- Automatic display name resolution
- Inventory capacity checking
- Existence validation for removals
- Proper quantity management

#### Status Effects

```json
{
  "applyStatus": ["blessing", "curse", "strength", "weakness"]
}
```

**Built-in Status Effects:**
- `curse` - Cursed (DEBUFF, 5 turns)
- `blessing` - Blessed (BUFF, 3 turns)
- `weakness` - Weakness (DEBUFF, 3 turns)
- `strength` - Strength (BUFF, 4 turns)
- `poison` - Poisoned (DEBUFF, 4 turns)
- `healing` - Regeneration (BUFF, 2 turns)

## Usage Examples

### Basic Effect Application

```dart
final choice = Choice(
  text: 'Heal and train',
  successEffects: ChoiceEffects(
    description: 'You feel better and stronger',
    statChanges: {'HP': 15, 'FITNESS': 10},
    itemsGained: ['energy_drink'],
    applyStatus: ['blessing'],
  ),
);

final result = processor.applyChoiceEffectsToGameStateEnhanced(
  choice,
  gameState,
);

final updatedGameState = result['gameState'] as GameState;
final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;
```

### Handling Extreme Values

```dart
final choice = Choice(
  text: 'Extreme healing',
  successEffects: ChoiceEffects(
    description: 'Powerful healing magic',
    statChanges: {'HP': 200}, // Will be clamped to 100
  ),
);

final result = processor.applyChoiceEffectsToGameStateEnhanced(choice, gameState);
final warnings = result['effectsApplied']['warnings'] as List<String>;

// warnings will contain: "HP clamped to maximum (100)"
```

### Complex Effect Combinations

```dart
final choice = Choice(
  text: 'Magical transformation',
  successEffects: ChoiceEffects(
    description: 'You undergo a magical transformation',
    statChanges: {'HP': -10, 'SAN': 20, 'FITNESS': -5},
    itemsGained: ['magic_essence', 'transformation_relic'],
    itemsLost: ['mortal_flesh'],
    applyStatus: ['blessing', 'weakness'],
  ),
);
```

### Processing Choice with Enhanced Tracking

```dart
final result = processor.processChoiceSelectionEnhanced(
  event,
  choiceIndex,
  gameState,
  roomEventData,
);

// Access all tracking information
final gameStateResult = result['gameState'] as GameState;
final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;
final warnings = effectsApplied['warnings'] as List<String>;
final errors = effectsApplied['errors'] as List<String>;
```

## Error Handling

### Warning Conditions

1. **Stat Clamping**: When stat changes exceed 0-100 bounds
2. **Inventory Full**: When items cannot be added due to capacity
3. **Item Not Found**: When trying to remove non-existent items

### Error Conditions

1. **Invalid Stat Names**: Throws `ArgumentError` for unknown stats
2. **Item Addition Failures**: Caught and logged in error tracking
3. **Status Effect Failures**: Caught and logged in error tracking

### Example Error Handling

```dart
final result = processor.applyChoiceEffectsToGameStateEnhanced(choice, gameState);
final effectsApplied = result['effectsApplied'] as Map<String, dynamic>;

// Check for issues
final warnings = effectsApplied['warnings'] as List<String>;
final errors = effectsApplied['errors'] as List<String>;

if (warnings.isNotEmpty) {
  print('Warnings during effect application: ${warnings.join(', ')}');
}

if (errors.isNotEmpty) {
  print('Errors during effect application: ${errors.join(', ')}');
}
```

## Database Integration Notes

The current implementation includes placeholder methods for database integration:

- `_getItemDisplayName()` - Would load from item database
- `_createStatusEffect()` - Would load from status effect database

In a production implementation, these would query actual databases to:
- Load item metadata (name, description, icon)
- Load status effect data (name, type, duration, effects)
- Validate item and status effect existence

## Backward Compatibility

The system maintains full backward compatibility:

1. **Legacy Methods**: Original `applyChoiceEffects` methods are preserved
2. **Existing Tests**: All original tests continue to pass
3. **API Compatibility**: Enhanced methods are additions, not replacements
4. **Data Structures**: GameState and related models remain unchanged

## Performance Considerations

- **Effect Tracking**: Minimal overhead for tracking data collection
- **Bounds Checking**: Efficient clamping operations
- **Memory Management**: Proper cleanup of temporary data structures
- **Error Handling**: Graceful handling without performance impact

## Testing

Comprehensive test coverage includes:

- **Stat Change Testing**: All stat types and boundary conditions
- **Inventory Testing**: Full/empty scenarios and edge cases
- **Status Effect Testing**: Proper categorization and duration handling
- **Error Condition Testing**: All warning and error scenarios
- **Backward Compatibility**: Verification of legacy method behavior
- **Complex Scenarios**: Multi-effect combinations and edge cases
