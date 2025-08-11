import 'dart:math';
import 'package:test/test.dart';
import '../lib/services/event_processor.dart';
import '../lib/models/event_model.dart';
import '../lib/models/room_event_data.dart';

void main() {
  group('EventProcessor', () {
    late EventProcessor processor;
    late Map<String, Event> eventDatabase;

    setUp(() {
      eventDatabase = _createTestEventDatabase();
      processor = EventProcessor(eventDatabase: eventDatabase);
    });

    group('selectRandomEvent', () {
      test('should return null when no events available', () {
        final result = processor.selectRandomEvent([]);
        expect(result, isNull);
      });

      test('should return the only event when one available', () {
        final result = processor.selectRandomEvent(['test_event']);

        expect(result, isNotNull);
        expect(result!.id, equals('test_event'));
      });

      test('should select from multiple events', () {
        final availableEvents = ['test_event', 'trap_event', 'item_event'];
        final result = processor.selectRandomEvent(availableEvents);

        expect(result, isNotNull);
        expect(availableEvents, contains(result!.id));
      });

      test('should throw StateError for non-existent event', () {
        expect(
          () => processor.selectRandomEvent(['non_existent_event']),
          throwsA(isA<StateError>()),
        );
      });

      test('should use random selection', () {
        // Use seeded random for predictable results
        final seededProcessor = EventProcessor(
          random: Random(12345),
          eventDatabase: eventDatabase,
        );

        final availableEvents = ['test_event', 'trap_event'];
        final results = <String>[];

        // Run multiple selections
        for (int i = 0; i < 100; i++) {
          final result = seededProcessor.selectRandomEvent(availableEvents);
          results.add(result!.id);
        }

        // Should have selected both events
        expect(results.toSet(), hasLength(2));
        expect(results, contains('test_event'));
        expect(results, contains('trap_event'));
      });
    });

    group('displayEvent', () {
      test('should return complete event display data', () {
        final event = eventDatabase['test_event']!;
        final display = processor.displayEvent(event);

        expect(display['eventId'], equals('test_event'));
        expect(display['name'], equals('Test Event'));
        expect(display['description'], contains('test description'));
        expect(display['image'], equals('test_image.png'));
        expect(display['category'], equals('test'));
        expect(display['choices'], isA<List>());
        expect(display['choices'], hasLength(2));
      });

      test('should include choice data', () {
        final event = eventDatabase['test_event']!;
        final display = processor.displayEvent(event);
        final choices = display['choices'] as List;

        expect(choices[0]['text'], equals('Option 1'));
        expect(choices[0]['isAvailable'], isTrue);
        expect(choices[1]['text'], equals('Option 2'));
        expect(choices[1]['isAvailable'], isTrue);
      });
    });

    group('validateChoiceRequirements', () {
      test('should return true when no requirements', () {
        final choice = Choice(
          text: 'Simple choice',
          successEffects: ChoiceEffects(description: 'Success'),
        );
        final playerState = _createTestPlayerState();

        final result = processor.validateChoiceRequirements(
          choice,
          playerState,
        );
        expect(result, isTrue);
      });

      test('should validate item requirements correctly', () {
        final choice = Choice(
          text: 'Use item',
          requirements: {
            'items': ['sword', 'shield'],
          },
          successEffects: ChoiceEffects(description: 'Success'),
        );

        // Player has required items
        final playerWithItems = _createTestPlayerState(
          inventory: ['sword', 'shield', 'potion'],
        );
        expect(
          processor.validateChoiceRequirements(choice, playerWithItems),
          isTrue,
        );

        // Player missing items
        final playerWithoutItems = _createTestPlayerState(
          inventory: ['potion'],
        );
        expect(
          processor.validateChoiceRequirements(choice, playerWithoutItems),
          isFalse,
        );
      });

      test('should validate stat requirements correctly', () {
        final choice = Choice(
          text: 'Strength check',
          requirements: {
            'stats': {
              'FITNESS': {'operator': '>', 'value': 50},
              'HP': {'operator': '>=', 'value': 20},
            },
          },
          successEffects: ChoiceEffects(description: 'Success'),
        );

        // Player meets requirements
        final strongPlayer = _createTestPlayerState(
          stats: {'FITNESS': 60, 'HP': 25, 'SAN': 70},
        );
        expect(
          processor.validateChoiceRequirements(choice, strongPlayer),
          isTrue,
        );

        // Player doesn't meet requirements
        final weakPlayer = _createTestPlayerState(
          stats: {'FITNESS': 40, 'HP': 15, 'SAN': 70},
        );
        expect(
          processor.validateChoiceRequirements(choice, weakPlayer),
          isFalse,
        );
      });

      test('should handle all comparison operators', () {
        final playerState = _createTestPlayerState(stats: {'FITNESS': 50});

        // Greater than
        final gtChoice = _createChoiceWithStatRequirement('>', 40);
        expect(
          processor.validateChoiceRequirements(gtChoice, playerState),
          isTrue,
        );

        final gtFailChoice = _createChoiceWithStatRequirement('>', 60);
        expect(
          processor.validateChoiceRequirements(gtFailChoice, playerState),
          isFalse,
        );

        // Greater than or equal
        final gteChoice = _createChoiceWithStatRequirement('>=', 50);
        expect(
          processor.validateChoiceRequirements(gteChoice, playerState),
          isTrue,
        );

        // Less than
        final ltChoice = _createChoiceWithStatRequirement('<', 60);
        expect(
          processor.validateChoiceRequirements(ltChoice, playerState),
          isTrue,
        );

        // Less than or equal
        final lteChoice = _createChoiceWithStatRequirement('<=', 50);
        expect(
          processor.validateChoiceRequirements(lteChoice, playerState),
          isTrue,
        );

        // Equal to
        final eqChoice = _createChoiceWithStatRequirement('==', 50);
        expect(
          processor.validateChoiceRequirements(eqChoice, playerState),
          isTrue,
        );
      });

      test('should throw error for unknown operator', () {
        final choice = Choice(
          text: 'Invalid operator',
          requirements: {
            'stats': {
              'FITNESS': {'operator': '!=', 'value': 50},
            },
          },
          successEffects: ChoiceEffects(description: 'Success'),
        );
        final playerState = _createTestPlayerState();

        expect(
          () => processor.validateChoiceRequirements(choice, playerState),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('evaluateChoiceSuccess', () {
      test('should return true when no success conditions', () {
        final choice = Choice(
          text: 'Always succeeds',
          successEffects: ChoiceEffects(description: 'Success'),
        );
        final playerState = _createTestPlayerState();

        final result = processor.evaluateChoiceSuccess(choice, playerState);
        expect(result, isTrue);
      });

      test('should handle probability-based success', () {
        // Use seeded random for predictable results
        final seededProcessor = EventProcessor(
          random: Random(54321),
          eventDatabase: eventDatabase,
        );

        final highProbChoice = Choice(
          text: 'High probability',
          successConditions: {'probability': 0.9},
          successEffects: ChoiceEffects(description: 'Success'),
        );

        final lowProbChoice = Choice(
          text: 'Low probability',
          successConditions: {'probability': 0.1},
          successEffects: ChoiceEffects(description: 'Success'),
        );

        final playerState = _createTestPlayerState();

        // Test multiple times to verify probability distribution
        int highSuccesses = 0;
        int lowSuccesses = 0;

        for (int i = 0; i < 100; i++) {
          if (seededProcessor.evaluateChoiceSuccess(
            highProbChoice,
            playerState,
          )) {
            highSuccesses++;
          }
          if (seededProcessor.evaluateChoiceSuccess(
            lowProbChoice,
            playerState,
          )) {
            lowSuccesses++;
          }
        }

        expect(highSuccesses, greaterThan(lowSuccesses));
        expect(highSuccesses, greaterThan(70)); // Should be around 90
        expect(lowSuccesses, lessThan(30)); // Should be around 10
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

        // High fitness player should succeed
        final strongPlayer = _createTestPlayerState(stats: {'FITNESS': 80});
        expect(processor.evaluateChoiceSuccess(choice, strongPlayer), isTrue);

        // Low fitness player should fail
        final weakPlayer = _createTestPlayerState(stats: {'FITNESS': 40});
        expect(processor.evaluateChoiceSuccess(choice, weakPlayer), isFalse);
      });
    });

    group('applyChoiceEffects', () {
      test('should apply stat changes correctly', () {
        final choice = Choice(
          text: 'Heal',
          successEffects: ChoiceEffects(
            description: 'You feel better',
            statChanges: {'HP': 10, 'SAN': -5},
          ),
        );

        final playerState = _createTestPlayerState(
          stats: {'HP': 50, 'SAN': 60},
        );

        final result = processor.applyChoiceEffects(choice, playerState);
        final newStats = result['playerState']['stats'] as Map<String, int>;

        expect(newStats['HP'], equals(60));
        expect(newStats['SAN'], equals(55));
        expect(result['description'], equals('You feel better'));
        expect(result['success'], isTrue);
      });

      test('should clamp stats to 0-100 range', () {
        final choice = Choice(
          text: 'Extreme effects',
          successEffects: ChoiceEffects(
            description: 'Extreme changes',
            statChanges: {'HP': 200, 'SAN': -200},
          ),
        );

        final playerState = _createTestPlayerState(
          stats: {'HP': 50, 'SAN': 50},
        );

        final result = processor.applyChoiceEffects(choice, playerState);
        final newStats = result['playerState']['stats'] as Map<String, int>;

        expect(newStats['HP'], equals(100)); // Clamped to max
        expect(newStats['SAN'], equals(0)); // Clamped to min
      });

      test('should handle item gains and losses', () {
        final choice = Choice(
          text: 'Trade items',
          successEffects: ChoiceEffects(
            description: 'Items traded',
            itemsGained: ['new_sword', 'magic_ring'],
            itemsLost: ['old_sword'],
          ),
        );

        final playerState = _createTestPlayerState(
          inventory: ['old_sword', 'potion'],
        );

        final result = processor.applyChoiceEffects(choice, playerState);
        final newInventory = result['playerState']['inventory'] as List<String>;

        expect(newInventory, contains('new_sword'));
        expect(newInventory, contains('magic_ring'));
        expect(newInventory, contains('potion'));
        expect(newInventory, isNot(contains('old_sword')));
      });

      test('should prevent duplicate items', () {
        final choice = Choice(
          text: 'Get item',
          successEffects: ChoiceEffects(
            description: 'Item gained',
            itemsGained: ['sword'],
          ),
        );

        final playerState = _createTestPlayerState(
          inventory: ['sword', 'potion'],
        );

        final result = processor.applyChoiceEffects(choice, playerState);
        final newInventory = result['playerState']['inventory'] as List<String>;

        expect(newInventory.where((item) => item == 'sword'), hasLength(1));
      });

      test('should apply status effects', () {
        final choice = Choice(
          text: 'Get cursed',
          successEffects: ChoiceEffects(
            description: 'You are cursed',
            applyStatus: ['curse', 'weakness'],
          ),
        );

        final playerState = _createTestPlayerState(statusEffects: ['blessing']);

        final result = processor.applyChoiceEffects(choice, playerState);
        final newStatusEffects =
            result['playerState']['statusEffects'] as List<String>;

        expect(newStatusEffects, contains('curse'));
        expect(newStatusEffects, contains('weakness'));
        expect(newStatusEffects, contains('blessing'));
      });

      test('should use failure effects when specified', () {
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

        final playerState = _createTestPlayerState(stats: {'HP': 50});

        final result = processor.applyChoiceEffects(
          choice,
          playerState,
          useSuccessEffects: false,
        );

        final newStats = result['playerState']['stats'] as Map<String, int>;
        expect(newStats['HP'], equals(40));
        expect(result['description'], equals('Failed!'));
        expect(result['success'], isFalse);
      });

      test('should handle null effects gracefully', () {
        final choice = Choice(
          text: 'No effect',
          successEffects: ChoiceEffects(description: 'Nothing'),
        );

        final playerState = _createTestPlayerState();
        final result = processor.applyChoiceEffects(choice, playerState);

        expect(result['description'], equals('Nothing'));
        expect(result['playerState'], equals(playerState));
      });
    });

    group('removeOneTimeEvent', () {
      test('should remove oneTime events', () {
        final roomData = RoomEventData.empty(
          'test_room',
        ).addEvent('oneTime_event').addEvent('persistent_event');

        final updatedRoom = processor.removeOneTimeEvent(
          roomData,
          'oneTime_event',
        );

        expect(updatedRoom.availableEventIds, contains('persistent_event'));
        expect(updatedRoom.availableEventIds, isNot(contains('oneTime_event')));
        expect(updatedRoom.consumedEventIds, contains('oneTime_event'));
      });

      test('should not remove persistent events', () {
        final roomData = RoomEventData.empty(
          'test_room',
        ).addEvent('persistent_event');

        final updatedRoom = processor.removeOneTimeEvent(
          roomData,
          'persistent_event',
        );

        expect(updatedRoom.availableEventIds, contains('persistent_event'));
        expect(updatedRoom.consumedEventIds, isEmpty);
      });

      test('should handle non-existent events gracefully', () {
        final roomData = RoomEventData.empty('test_room');

        final updatedRoom = processor.removeOneTimeEvent(
          roomData,
          'non_existent',
        );

        expect(updatedRoom, equals(roomData));
      });
    });

    group('createEmptyRoomEvent', () {
      test('should create valid empty room event', () {
        final event = processor.createEmptyRoomEvent();

        expect(event.id, equals('empty_room_rest'));
        expect(event.name, equals('Empty Room'));
        expect(event.description, contains('empty'));
        expect(event.persistence, equals('persistent'));
        expect(event.choices, hasLength(1));
        expect(event.choices.first.text, equals('Take a break'));
      });

      test('should provide rest benefits', () {
        final event = processor.createEmptyRoomEvent();
        final choice = event.choices.first;
        final effects = choice.successEffects;

        expect(effects.statChanges!['HP'], equals(2));
        expect(effects.statChanges!['SAN'], equals(3));
        expect(effects.statChanges!['HUNGER'], equals(-1));
      });
    });

    group('processRoomEntry', () {
      test('should select event when room has available events', () {
        final roomData = RoomEventData.empty(
          'test_room',
        ).addEvent('test_event');
        final playerState = _createTestPlayerState();

        final result = processor.processRoomEntry(roomData, playerState);

        expect(result['event'], isA<Event>());
        expect(result['event'].id, equals('test_event'));
        expect(result['roomEventData'], equals(roomData));
        expect(result['eventDisplay'], isA<Map<String, dynamic>>());
      });

      test('should use empty room event when no events available', () {
        final roomData = RoomEventData.empty('test_room');
        final playerState = _createTestPlayerState();

        final result = processor.processRoomEntry(roomData, playerState);

        expect(result['event'], isA<Event>());
        expect(result['event'].id, equals('empty_room_rest'));
        expect(result['roomEventData'], equals(roomData));
      });
    });

    group('processChoiceSelection', () {
      test('should process valid choice selection', () {
        final event = eventDatabase['test_event']!;
        final roomData = RoomEventData.empty(
          'test_room',
        ).addEvent('test_event');
        final playerState = _createTestPlayerState();

        final result = processor.processChoiceSelection(
          event,
          0, // First choice
          playerState,
          roomData,
        );

        expect(result['playerState'], isA<Map<String, dynamic>>());
        expect(result['roomEventData'], isA<RoomEventData>());
        expect(result['description'], isA<String>());
        expect(result['success'], isA<bool>());
        expect(result['choiceText'], equals('Option 1'));
      });

      test('should throw error for invalid choice index', () {
        final event = eventDatabase['test_event']!;
        final roomData = RoomEventData.empty('test_room');
        final playerState = _createTestPlayerState();

        expect(
          () => processor.processChoiceSelection(
            event,
            99,
            playerState,
            roomData,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw error when choice requirements not met', () {
        final event = eventDatabase['requirement_event']!;
        final roomData = RoomEventData.empty('test_room');
        final playerState = _createTestPlayerState(
          inventory: [], // No required items
        );

        expect(
          () =>
              processor.processChoiceSelection(event, 0, playerState, roomData),
          throwsA(isA<StateError>()),
        );
      });

      test('should remove oneTime events after processing', () {
        final event = eventDatabase['oneTime_event']!;
        final roomData = RoomEventData.empty(
          'test_room',
        ).addEvent('oneTime_event');
        final playerState = _createTestPlayerState();

        final result = processor.processChoiceSelection(
          event,
          0,
          playerState,
          roomData,
        );

        final updatedRoomData = result['roomEventData'] as RoomEventData;
        expect(updatedRoomData.availableEventIds, isEmpty);
        expect(updatedRoomData.consumedEventIds, contains('oneTime_event'));
      });
    });
  });
}

/// Helper function to create test event database
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
    'trap_event': Event(
      id: 'trap_event',
      name: 'Trap Event',
      description: 'A dangerous trap',
      image: 'trap_image.png',
      category: 'trap',
      weight: 15,
      persistence: 'persistent',
      choices: [
        Choice(
          text: 'Disarm trap',
          successEffects: ChoiceEffects(
            description: 'Trap disarmed',
            statChanges: {'SAN': 10},
          ),
          failureEffects: ChoiceEffects(
            description: 'Trap triggered!',
            statChanges: {'HP': -15},
          ),
        ),
      ],
    ),
    'item_event': Event(
      id: 'item_event',
      name: 'Item Discovery',
      description: 'You found an item',
      image: 'item_image.png',
      category: 'item',
      weight: 20,
      persistence: 'oneTime',
      choices: [
        Choice(
          text: 'Take item',
          successEffects: ChoiceEffects(
            description: 'Item taken',
            itemsGained: ['sword'],
          ),
        ),
      ],
    ),
    'persistent_event': Event(
      id: 'persistent_event',
      name: 'Persistent Event',
      description: 'This event persists',
      image: 'persistent_image.png',
      category: 'character',
      weight: 12,
      persistence: 'persistent',
      choices: [
        Choice(
          text: 'Interact',
          successEffects: ChoiceEffects(description: 'Interaction complete'),
        ),
      ],
    ),
    'oneTime_event': Event(
      id: 'oneTime_event',
      name: 'OneTime Event',
      description: 'This event happens once',
      image: 'onetime_image.png',
      category: 'monster',
      weight: 8,
      persistence: 'oneTime',
      choices: [
        Choice(
          text: 'Defeat monster',
          successEffects: ChoiceEffects(
            description: 'Monster defeated',
            statChanges: {'HP': -5},
          ),
        ),
      ],
    ),
    'requirement_event': Event(
      id: 'requirement_event',
      name: 'Requirement Event',
      description: 'Requires specific items',
      image: 'requirement_image.png',
      category: 'special',
      weight: 5,
      persistence: 'oneTime',
      choices: [
        Choice(
          text: 'Use special item',
          requirements: {
            'items': ['special_key'],
            'stats': {
              'FITNESS': {'operator': '>', 'value': 30},
            },
          },
          successEffects: ChoiceEffects(
            description: 'Special action completed',
            statChanges: {'SAN': 20},
          ),
        ),
      ],
    ),
  };
}

/// Helper function to create test player state
Map<String, dynamic> _createTestPlayerState({
  Map<String, int>? stats,
  List<String>? inventory,
  List<String>? statusEffects,
}) {
  return {
    'stats': stats ?? {'HP': 80, 'SAN': 70, 'HUNGER': 60, 'FITNESS': 75},
    'inventory': inventory ?? ['sword', 'potion'],
    'statusEffects': statusEffects ?? [],
  };
}

/// Helper function to create choice with stat requirement
Choice _createChoiceWithStatRequirement(String operator, int value) {
  return Choice(
    text: 'Stat check',
    requirements: {
      'stats': {
        'FITNESS': {'operator': operator, 'value': value},
      },
    },
    successEffects: ChoiceEffects(description: 'Success'),
  );
}
