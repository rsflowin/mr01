import 'package:flutter_test/flutter_test.dart';
import 'package:mr01/models/event_model.dart';

void main() {
  group('ChoiceEffects', () {
    test('should create valid ChoiceEffects with required properties', () {
      final effects = ChoiceEffects(
        description: 'Test description',
        statChanges: {'HP': -10, 'SAN': 5},
        itemsGained: ['item1', 'item2'],
        itemsLost: ['item3'],
        applyStatus: ['status1'],
      );

      expect(effects.description, 'Test description');
      expect(effects.statChanges, {'HP': -10, 'SAN': 5});
      expect(effects.itemsGained, ['item1', 'item2']);
      expect(effects.itemsLost, ['item3']);
      expect(effects.applyStatus, ['status1']);
      expect(effects.isValid(), true);
    });

    test('should create ChoiceEffects with minimal required properties', () {
      final effects = ChoiceEffects(description: 'Minimal description');

      expect(effects.description, 'Minimal description');
      expect(effects.statChanges, null);
      expect(effects.itemsGained, null);
      expect(effects.itemsLost, null);
      expect(effects.applyStatus, null);
      expect(effects.isValid(), true);
    });

    test('should be invalid with empty description', () {
      final effects = ChoiceEffects(description: '');
      expect(effects.isValid(), false);
    });

    test('should serialize to and from Map correctly', () {
      final original = ChoiceEffects(
        description: 'Test description',
        statChanges: {'HP': -10, 'SAN': 5},
        itemsGained: ['item1', 'item2'],
        itemsLost: ['item3'],
        applyStatus: ['status1'],
      );

      final map = original.toMap();
      final restored = ChoiceEffects.fromMap(map);

      expect(restored, original);
      expect(restored.description, original.description);
      expect(restored.statChanges, original.statChanges);
      expect(restored.itemsGained, original.itemsGained);
      expect(restored.itemsLost, original.itemsLost);
      expect(restored.applyStatus, original.applyStatus);
    });

    test('should handle null values in fromMap', () {
      final map = {
        'description': 'Test description',
        'statChanges': null,
        'itemsGained': null,
        'itemsLost': null,
        'applyStatus': null,
      };

      final effects = ChoiceEffects.fromMap(map);

      expect(effects.description, 'Test description');
      expect(effects.statChanges, null);
      expect(effects.itemsGained, null);
      expect(effects.itemsLost, null);
      expect(effects.applyStatus, null);
    });

    test('should handle missing properties in fromMap', () {
      final map = {'description': 'Test description'};
      final effects = ChoiceEffects.fromMap(map);

      expect(effects.description, 'Test description');
      expect(effects.statChanges, null);
      expect(effects.itemsGained, null);
      expect(effects.itemsLost, null);
      expect(effects.applyStatus, null);
    });

    test('should create copy with modified properties', () {
      final original = ChoiceEffects(
        description: 'Original description',
        statChanges: {'HP': -10},
      );

      final copy = original.copyWith(
        description: 'Modified description',
        itemsGained: ['new_item'],
      );

      expect(copy.description, 'Modified description');
      expect(copy.statChanges, {'HP': -10}); // Unchanged
      expect(copy.itemsGained, ['new_item']); // Changed
    });

    test('should implement equality correctly', () {
      final effects1 = ChoiceEffects(
        description: 'Test description',
        statChanges: {'HP': -10, 'SAN': 5},
        itemsGained: ['item1', 'item2'],
      );

      final effects2 = ChoiceEffects(
        description: 'Test description',
        statChanges: {'HP': -10, 'SAN': 5},
        itemsGained: ['item1', 'item2'],
      );

      final effects3 = ChoiceEffects(
        description: 'Different description',
        statChanges: {'HP': -10, 'SAN': 5},
        itemsGained: ['item1', 'item2'],
      );

      expect(effects1, effects2);
      expect(effects1, isNot(effects3));
      expect(effects1.hashCode, effects2.hashCode);
    });
  });

  group('Choice', () {
    test('should create valid Choice with required properties', () {
      final successEffects = ChoiceEffects(description: 'Success');
      final failureEffects = ChoiceEffects(description: 'Failure');
      
      final choice = Choice(
        text: 'Test choice',
        requirements: {'items': ['item1'], 'stats': {'HP': {'operator': '>', 'value': 50}}},
        successConditions: {'stats': {'FITNESS': {'operator': '>', 'value': 60}}},
        successEffects: successEffects,
        failureEffects: failureEffects,
      );

      expect(choice.text, 'Test choice');
      expect(choice.requirements, isNotNull);
      expect(choice.successConditions, isNotNull);
      expect(choice.successEffects, successEffects);
      expect(choice.failureEffects, failureEffects);
      expect(choice.isValid(), true);
    });

    test('should create Choice with minimal required properties', () {
      final successEffects = ChoiceEffects(description: 'Success');
      
      final choice = Choice(
        text: 'Minimal choice',
        successEffects: successEffects,
      );

      expect(choice.text, 'Minimal choice');
      expect(choice.requirements, null);
      expect(choice.successConditions, null);
      expect(choice.successEffects, successEffects);
      expect(choice.failureEffects, null);
      expect(choice.isValid(), true);
    });

    test('should be invalid with empty text', () {
      final successEffects = ChoiceEffects(description: 'Success');
      final choice = Choice(text: '', successEffects: successEffects);
      expect(choice.isValid(), false);
    });

    test('should be invalid with invalid successEffects', () {
      final invalidEffects = ChoiceEffects(description: '');
      final choice = Choice(text: 'Test', successEffects: invalidEffects);
      expect(choice.isValid(), false);
    });

    test('should serialize to and from Map correctly', () {
      final successEffects = ChoiceEffects(description: 'Success');
      final failureEffects = ChoiceEffects(description: 'Failure');
      
      final original = Choice(
        text: 'Test choice',
        requirements: {'items': ['item1']},
        successConditions: {'stats': {'FITNESS': {'operator': '>', 'value': 60}}},
        successEffects: successEffects,
        failureEffects: failureEffects,
      );

      final map = original.toMap();
      final restored = Choice.fromMap(map);

      expect(restored, original);
      expect(restored.text, original.text);
      expect(restored.requirements, original.requirements);
      expect(restored.successConditions, original.successConditions);
      expect(restored.successEffects, original.successEffects);
      expect(restored.failureEffects, original.failureEffects);
    });

    test('should handle missing properties in fromMap', () {
      final map = {
        'text': 'Test choice',
        'successEffects': {'description': 'Success'},
      };

      final choice = Choice.fromMap(map);

      expect(choice.text, 'Test choice');
      expect(choice.requirements, null);
      expect(choice.successConditions, null);
      expect(choice.successEffects.description, 'Success');
      expect(choice.failureEffects, null);
    });
  });

  group('Event', () {
    test('should create valid Event with all properties', () {
      final choice1 = Choice(
        text: 'Choice 1',
        successEffects: ChoiceEffects(description: 'Success 1'),
      );
      final choice2 = Choice(
        text: 'Choice 2',
        successEffects: ChoiceEffects(description: 'Success 2'),
      );

      final event = Event(
        id: 'test_event_01',
        name: 'Test Event',
        description: 'A test event description',
        image: 'test_event.png',
        category: 'trap',
        weight: 15,
        persistence: 'persistent',
        choices: [choice1, choice2],
      );

      expect(event.id, 'test_event_01');
      expect(event.name, 'Test Event');
      expect(event.description, 'A test event description');
      expect(event.image, 'test_event.png');
      expect(event.category, 'trap');
      expect(event.weight, 15);
      expect(event.persistence, 'persistent');
      expect(event.choices.length, 2);
      expect(event.isValid(), true);
    });

    test('should be invalid with empty required properties', () {
      final choice = Choice(
        text: 'Choice',
        successEffects: ChoiceEffects(description: 'Success'),
      );

      // Empty id
      final event1 = Event(
        id: '',
        name: 'Test Event',
        description: 'Description',
        image: 'image.png',
        category: 'trap',
        weight: 10,
        persistence: 'persistent',
        choices: [choice],
      );
      expect(event1.isValid(), false);

      // Empty name
      final event2 = Event(
        id: 'test_01',
        name: '',
        description: 'Description',
        image: 'image.png',
        category: 'trap',
        weight: 10,
        persistence: 'persistent',
        choices: [choice],
      );
      expect(event2.isValid(), false);

      // Empty description
      final event3 = Event(
        id: 'test_01',
        name: 'Test Event',
        description: '',
        image: 'image.png',
        category: 'trap',
        weight: 10,
        persistence: 'persistent',
        choices: [choice],
      );
      expect(event3.isValid(), false);
    });

    test('should be invalid with invalid weight', () {
      final choice = Choice(
        text: 'Choice',
        successEffects: ChoiceEffects(description: 'Success'),
      );

      final event = Event(
        id: 'test_01',
        name: 'Test Event',
        description: 'Description',
        image: 'image.png',
        category: 'trap',
        weight: 0, // Invalid weight
        persistence: 'persistent',
        choices: [choice],
      );
      expect(event.isValid(), false);
    });

    test('should be invalid with invalid persistence', () {
      final choice = Choice(
        text: 'Choice',
        successEffects: ChoiceEffects(description: 'Success'),
      );

      final event = Event(
        id: 'test_01',
        name: 'Test Event',
        description: 'Description',
        image: 'image.png',
        category: 'trap',
        weight: 10,
        persistence: 'invalid', // Invalid persistence
        choices: [choice],
      );
      expect(event.isValid(), false);
    });

    test('should be invalid with empty choices', () {
      final event = Event(
        id: 'test_01',
        name: 'Test Event',
        description: 'Description',
        image: 'image.png',
        category: 'trap',
        weight: 10,
        persistence: 'persistent',
        choices: [], // Empty choices
      );
      expect(event.isValid(), false);
    });

    test('should be invalid with invalid choices', () {
      final invalidChoice = Choice(
        text: '', // Invalid choice
        successEffects: ChoiceEffects(description: 'Success'),
      );

      final event = Event(
        id: 'test_01',
        name: 'Test Event',
        description: 'Description',
        image: 'image.png',
        category: 'trap',
        weight: 10,
        persistence: 'persistent',
        choices: [invalidChoice],
      );
      expect(event.isValid(), false);
    });

    test('should serialize to and from Map correctly', () {
      final choice = Choice(
        text: 'Test choice',
        successEffects: ChoiceEffects(description: 'Success'),
      );

      final original = Event(
        id: 'test_event_01',
        name: 'Test Event',
        description: 'A test event description',
        image: 'test_event.png',
        category: 'trap',
        weight: 15,
        persistence: 'persistent',
        choices: [choice],
      );

      final map = original.toMap();
      final restored = Event.fromMap(map);

      expect(restored, original);
      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.image, original.image);
      expect(restored.category, original.category);
      expect(restored.weight, original.weight);
      expect(restored.persistence, original.persistence);
      expect(restored.choices.length, original.choices.length);
    });

    test('should handle missing properties in fromMap with defaults', () {
      final map = {
        'id': 'test_01',
        'name': 'Test Event',
        'description': 'Description',
        'choices': [
          {
            'text': 'Choice',
            'successEffects': {'description': 'Success'},
          }
        ],
      };

      final event = Event.fromMap(map);

      expect(event.id, 'test_01');
      expect(event.name, 'Test Event');
      expect(event.description, 'Description');
      expect(event.image, ''); // Default empty
      expect(event.category, ''); // Default empty
      expect(event.weight, 10); // Default weight
      expect(event.persistence, 'oneTime'); // Default persistence
      expect(event.choices.length, 1);
    });

    test('should serialize to and from JSON correctly', () {
      final choice = Choice(
        text: 'Test choice',
        successEffects: ChoiceEffects(description: 'Success'),
      );

      final original = Event(
        id: 'test_event_01',
        name: 'Test Event',
        description: 'A test event description',
        image: 'test_event.png',
        category: 'trap',
        weight: 15,
        persistence: 'persistent',
        choices: [choice],
      );

      final json = original.toJson();
      final restored = Event.fromJson(json);

      expect(restored, original);
    });

    test('should create copy with modified properties', () {
      final choice = Choice(
        text: 'Original choice',
        successEffects: ChoiceEffects(description: 'Success'),
      );

      final original = Event(
        id: 'test_01',
        name: 'Original Event',
        description: 'Original description',
        image: 'original.png',
        category: 'trap',
        weight: 10,
        persistence: 'oneTime',
        choices: [choice],
      );

      final newChoice = Choice(
        text: 'New choice',
        successEffects: ChoiceEffects(description: 'New success'),
      );

      final copy = original.copyWith(
        name: 'Modified Event',
        weight: 20,
        choices: [newChoice],
      );

      expect(copy.id, 'test_01'); // Unchanged
      expect(copy.name, 'Modified Event'); // Changed
      expect(copy.description, 'Original description'); // Unchanged
      expect(copy.weight, 20); // Changed
      expect(copy.choices.length, 1);
      expect(copy.choices[0].text, 'New choice'); // Changed
    });

    test('should implement equality correctly', () {
      final choice = Choice(
        text: 'Choice',
        successEffects: ChoiceEffects(description: 'Success'),
      );

      final event1 = Event(
        id: 'test_01',
        name: 'Test Event',
        description: 'Description',
        image: 'image.png',
        category: 'trap',
        weight: 10,
        persistence: 'persistent',
        choices: [choice],
      );

      final event2 = Event(
        id: 'test_01',
        name: 'Test Event',
        description: 'Description',
        image: 'image.png',
        category: 'trap',
        weight: 10,
        persistence: 'persistent',
        choices: [choice],
      );

      final event3 = Event(
        id: 'test_02', // Different id
        name: 'Test Event',
        description: 'Description',
        image: 'image.png',
        category: 'trap',
        weight: 10,
        persistence: 'persistent',
        choices: [choice],
      );

      expect(event1, event2);
      expect(event1, isNot(event3));
      expect(event1.hashCode, event2.hashCode);
    });
  });

  group('Event Model Integration', () {
    test('should handle complex event structure from JSON', () {
      final jsonData = {
        'id': 'trap_pitfall_01',
        'name': '숨겨진 함정 구덩이',
        'description': '발 밑의 바닥이 갑자기 푹 꺼진다! 아슬아슬하게 가장자리에 매달렸다.',
        'image': 'trap_pitfall.png',
        'category': 'trap',
        'weight': 20,
        'persistence': 'persistent',
        'choices': [
          {
            'text': '힘으로 기어오른다.',
            'requirements': null,
            'successConditions': {
              'stats': {
                'FITNESS': {'operator': '>', 'value': 50}
              }
            },
            'successEffects': {
              'description': '강한 팔 힘으로 간신히 기어올랐다.',
              'statChanges': {'FITNESS': 5, 'HUNGER': -5}
            },
            'failureEffects': {
              'description': '힘이 부족해 구덩이 아래로 떨어지며 발목을 접질렸다.',
              'statChanges': {'HP': -15, 'SAN': -10},
              'applyStatus': ['sprain']
            }
          },
          {
            'text': '밧줄을 사용한다.',
            'requirements': {
              'items': ['rope'],
              'stats': null
            },
            'successEffects': {
              'description': '밧줄을 단단히 고정하고 안전하게 빠져나왔다.',
              'statChanges': {'HUNGER': -2}
            }
          }
        ]
      };

      final event = Event.fromMap(jsonData);

      expect(event.isValid(), true);
      expect(event.id, 'trap_pitfall_01');
      expect(event.name, '숨겨진 함정 구덩이');
      expect(event.category, 'trap');
      expect(event.weight, 20);
      expect(event.persistence, 'persistent');
      expect(event.choices.length, 2);

      // Test first choice
      final choice1 = event.choices[0];
      expect(choice1.text, '힘으로 기어오른다.');
      expect(choice1.requirements, null);
      expect(choice1.successConditions, isNotNull);
      expect(choice1.successEffects.description, '강한 팔 힘으로 간신히 기어올랐다.');
      expect(choice1.successEffects.statChanges, {'FITNESS': 5, 'HUNGER': -5});
      expect(choice1.failureEffects, isNotNull);
      expect(choice1.failureEffects!.statChanges, {'HP': -15, 'SAN': -10});
      expect(choice1.failureEffects!.applyStatus, ['sprain']);

      // Test second choice
      final choice2 = event.choices[1];
      expect(choice2.text, '밧줄을 사용한다.');
      expect(choice2.requirements, {'items': ['rope'], 'stats': null});
      expect(choice2.successEffects.description, '밧줄을 단단히 고정하고 안전하게 빠져나왔다.');
      expect(choice2.successEffects.statChanges, {'HUNGER': -2});
      expect(choice2.failureEffects, null);
    });

    test('should validate data integrity across all models', () {
      // Create a complex event with all possible properties
      final event = Event(
        id: 'complex_event_01',
        name: 'Complex Event',
        description: 'A complex event for testing',
        image: 'complex.png',
        category: 'item',
        weight: 25,
        persistence: 'oneTime',
        choices: [
          Choice(
            text: 'Complex choice with requirements',
            requirements: {
              'items': ['item1', 'item2'],
              'stats': {'HP': {'operator': '>', 'value': 50}}
            },
            successConditions: {
              'stats': {'FITNESS': {'operator': '>=', 'value': 60}}
            },
            successEffects: ChoiceEffects(
              description: 'Success with all effects',
              statChanges: {'HP': 10, 'SAN': 5, 'FITNESS': -3},
              itemsGained: ['reward_item'],
              itemsLost: ['consumed_item'],
              applyStatus: ['buff_status'],
            ),
            failureEffects: ChoiceEffects(
              description: 'Failure with penalties',
              statChanges: {'HP': -20, 'SAN': -10},
              applyStatus: ['debuff_status'],
            ),
          ),
          Choice(
            text: 'Simple choice',
            successEffects: ChoiceEffects(
              description: 'Simple success',
              statChanges: {'SAN': 2},
            ),
          ),
        ],
      );

      // Validate the entire structure
      expect(event.isValid(), true);
      
      // Test serialization round-trip
      final json = event.toJson();
      final restored = Event.fromJson(json);
      expect(restored, event);
      expect(restored.isValid(), true);
      
      // Verify all nested objects are properly validated
      for (final choice in restored.choices) {
        expect(choice.isValid(), true);
        expect(choice.successEffects.isValid(), true);
        if (choice.failureEffects != null) {
          expect(choice.failureEffects!.isValid(), true);
        }
      }
    });
  });
}