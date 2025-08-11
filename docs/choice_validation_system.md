# Choice Requirement Validation System

## Overview

The choice requirement validation system provides comprehensive validation of player choices based on inventory items and character stats. It supports both detailed validation results for UI feedback and simple boolean validation for backward compatibility.

## Features

### Enhanced Validation (`validateChoiceRequirementsEnhanced`)

This method works with the `GameState` model and provides detailed validation results:

```dart
final validation = processor.validateChoiceRequirementsEnhanced(choice, gameState);

// Results include:
// - isAvailable: bool - Whether the choice can be selected
// - failureReasons: List<String> - Human-readable failure reasons
// - missingItems: List<String> - List of required items not in inventory
// - insufficientStats: List<Map> - Detailed stat requirement failures
```

### Display with Validation (`displayEventWithValidation`)

Enhanced event display that includes choice availability information:

```dart
final eventDisplay = processor.displayEventWithValidation(event, gameState);

// Each choice includes:
// - text: String - Choice text
// - isAvailable: bool - Whether choice can be selected
// - failureReasons: List<String> - Why choice is unavailable
// - missingItems: List<String> - Required items not possessed
// - insufficientStats: List<Map> - Stat requirements not met
```

### Enhanced Choice Processing (`processChoiceSelectionEnhanced`)

Processes choice selection with full GameState integration:

```dart
final result = processor.processChoiceSelectionEnhanced(
  event, 
  choiceIndex, 
  gameState, 
  roomEventData
);

// Returns:
// - gameState: GameState - Updated game state
// - roomEventData: RoomEventData - Updated room data
// - description: String - Result description
// - success: bool - Whether choice succeeded
// - choiceText: String - Selected choice text
// - validation: Map - Original validation results
```

## Requirement Types

### Item Requirements

```json
{
  "requirements": {
    "items": ["sword", "magic_key", "potion"]
  }
}
```

The system checks if the player's inventory contains all required items.

### Stat Requirements

```json
{
  "requirements": {
    "stats": {
      "FITNESS": {"operator": ">", "value": 50},
      "HP": {"operator": ">=", "value": 30},
      "SAN": {"operator": "==", "value": 100}
    }
  }
}
```

Supported operators:
- `>` - Greater than
- `>=` - Greater than or equal
- `<` - Less than
- `<=` - Less than or equal
- `==` - Equal to

Supported stat names:
- `HP` - Health points
- `SAN` or `SANITY` - Sanity points
- `FIT` or `FITNESS` - Fitness level
- `HUNGER` - Hunger level

### Combined Requirements

```json
{
  "requirements": {
    "items": ["magic_sword"],
    "stats": {
      "FITNESS": {"operator": ">", "value": 60},
      "SAN": {"operator": ">=", "value": 50}
    }
  }
}
```

All requirements must be met for the choice to be available.

## UI Integration

### Choice Button Styling

Use the validation results to style choice buttons:

```dart
// Example UI logic
Widget buildChoiceButton(Map<String, dynamic> choiceData) {
  final isAvailable = choiceData['isAvailable'] as bool;
  final failureReasons = choiceData['failureReasons'] as List<String>;
  
  return ElevatedButton(
    onPressed: isAvailable ? () => selectChoice() : null,
    style: ElevatedButton.styleFrom(
      backgroundColor: isAvailable ? Colors.blue : Colors.grey,
    ),
    child: Column(
      children: [
        Text(choiceData['text']),
        if (!isAvailable) 
          Text(
            failureReasons.join(', '),
            style: TextStyle(color: Colors.red, fontSize: 12),
          ),
      ],
    ),
  );
}
```

### Detailed Feedback

Show specific failure reasons to help players understand requirements:

```dart
void showChoiceTooltip(Map<String, dynamic> choiceData) {
  final missingItems = choiceData['missingItems'] as List<String>;
  final insufficientStats = choiceData['insufficientStats'] as List;
  
  final feedback = <String>[];
  
  if (missingItems.isNotEmpty) {
    feedback.add('Required items: ${missingItems.join(', ')}');
  }
  
  for (final stat in insufficientStats) {
    feedback.add(
      '${stat['statName']}: ${stat['currentValue']} ${stat['operator']} ${stat['requiredValue']} required'
    );
  }
  
  // Show feedback to player
}
```

## Backward Compatibility

The original `validateChoiceRequirements` method is preserved for backward compatibility with existing code that uses Map-based player state.

```dart
// Legacy method - still supported
bool isValid = processor.validateChoiceRequirements(choice, playerStateMap);
```

## Error Handling

The enhanced validation system provides comprehensive error handling:

- Invalid operators throw `ArgumentError`
- Unknown stat names default to value 0
- Missing requirements are treated as "no requirements" (always valid)
- Choice selection with unmet requirements throws `StateError` with detailed failure reasons

## Testing

Comprehensive test coverage is provided in `test/event_processor_enhanced_test.dart`, including:

- Item requirement validation
- Stat requirement validation with all operators
- Combined requirement validation
- UI feedback data validation
- Error handling scenarios
- Backward compatibility verification
