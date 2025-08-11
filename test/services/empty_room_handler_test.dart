import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/event_processor.dart';
import '../../lib/models/event_model.dart';
import '../../lib/models/room_event_data.dart';
import '../../lib/models/game_state.dart';

void main() {
  group('Empty Room Handling Tests', () {
    late EventProcessor eventProcessor;
    late Map<String, Event> mockEventDatabase;

    setUp(() {
      mockEventDatabase = {};
      eventProcessor = EventProcessor(eventDatabase: mockEventDatabase);
    });

    group('Empty Room Detection', () {
      test('isRoomEmpty returns true for room with no available events', () {
        final roomData = RoomEventData.empty('1,1');
        expect(eventProcessor.isRoomEmpty(roomData), isTrue);
      });

      test('isRoomEmpty returns false for room with available events', () {
        final roomData = RoomEventData.empty('1,1').addEvent('test_event');
        expect(eventProcessor.isRoomEmpty(roomData), isFalse);
      });

      test('isRoomEmpty returns true for room with only consumed events', () {
        final roomData = RoomEventData.empty(
          '1,1',
        ).addEvent('test_event').consumeEvent('test_event');
        expect(eventProcessor.isRoomEmpty(roomData), isTrue);
      });
    });

    group('Empty Room Event Creation', () {
      test('createEmptyRoomEvent returns valid event structure', () {
        final event = eventProcessor.createEmptyRoomEvent();

        expect(event.id, equals('empty_room_rest'));
        expect(event.name, equals('Empty Room'));
        expect(event.category, equals('rest'));
        expect(event.persistence, equals('persistent'));
        expect(event.choices.length, equals(1));
        expect(event.choices.first.text, equals('Take a break'));
      });

      test('createEmptyRoomEvent includes minor stat recovery', () {
        final event = eventProcessor.createEmptyRoomEvent();
        final choice = event.choices.first;
        final statChanges = choice.successEffects?.statChanges;

        expect(statChanges, isNotNull);
        expect(statChanges!['HP'], greaterThan(0));
        expect(statChanges['SAN'], greaterThan(0));
        expect(statChanges['FITNESS'], greaterThan(0));
        expect(statChanges['HUNGER'], lessThan(0)); // Hunger cost
      });

      test(
        'createEmptyRoomEvent with room data provides contextual description',
        () {
          final roomData = RoomEventData.empty('2,3');
          final event = eventProcessor.createEmptyRoomEvent(
            roomEventData: roomData,
          );

          expect(event.description, isNotEmpty);
          expect(event.description, contains('room'));
          expect(event.description.length, greaterThan(10));
        },
      );

      test('createEmptyRoomEvent provides varied descriptions', () {
        final descriptions = <String>{};

        // Generate multiple events to test variety
        for (int i = 0; i < 20; i++) {
          final roomData = RoomEventData.empty('$i,0');
          final event = eventProcessor.createEmptyRoomEvent(
            roomEventData: roomData,
          );
          descriptions.add(event.description);
        }

        // Should have multiple different descriptions
        expect(descriptions.length, greaterThan(1));
      });
    });

    group('Enhanced Empty Room Event Creation', () {
      test('createEmptyRoomEventEnhanced adapts to player state', () {
        final roomData = RoomEventData.empty('1,1');
        final playerState = {
          'stats': {'HP': 20, 'SAN': 15, 'FITNESS': 25, 'HUNGER': 80},
        };

        final event = eventProcessor.createEmptyRoomEventEnhanced(
          roomData,
          playerState,
        );
        final statChanges = event.choices.first.successEffects?.statChanges;

        expect(statChanges, isNotNull);
        // Should provide enhanced recovery for critically low stats
        expect(statChanges!['HP'], greaterThan(3)); // Enhanced HP recovery
        expect(statChanges['SAN'], greaterThan(4)); // Enhanced SAN recovery
      });

      test(
        'createEmptyRoomEventEnhanced reduces hunger cost when starving',
        () {
          final roomData = RoomEventData.empty('1,1');
          final playerState = {
            'stats': {'HP': 50, 'SAN': 50, 'FITNESS': 50, 'HUNGER': 15},
          };

          final event = eventProcessor.createEmptyRoomEventEnhanced(
            roomData,
            playerState,
          );
          final statChanges = event.choices.first.successEffects?.statChanges;

          expect(statChanges, isNotNull);
          expect(statChanges!['HUNGER'], equals(-1)); // Reduced hunger cost
        },
      );
    });

    group('GameState Integration', () {
      test('createEmptyRoomEventForGameState works with GameState', () {
        final roomData = RoomEventData.empty('1,1');
        final gameState = GameState(
          stats: PlayerStats(hp: 30, san: 25, fit: 40, hunger: 70),
        );

        final event = eventProcessor.createEmptyRoomEventForGameState(
          roomData,
          gameState,
        );
        final statChanges = event.choices.first.successEffects?.statChanges;

        expect(statChanges, isNotNull);
        expect(
          statChanges!['HP'],
          greaterThan(3),
        ); // Enhanced recovery for low HP
        expect(
          statChanges['SAN'],
          greaterThan(4),
        ); // Enhanced recovery for low SAN
      });

      test('processRoomEntryEnhanced returns empty room data', () {
        final roomData = RoomEventData.empty('1,1');
        final gameState = GameState();

        final result = eventProcessor.processRoomEntryEnhanced(
          roomData,
          gameState,
        );

        expect(result['isEmptyRoom'], isTrue);
        expect(result['event'], isA<Event>());
        expect(result['roomEventData'], equals(roomData));
      });
    });

    group('Empty Room Messaging', () {
      test('getEmptyRoomMessage returns consistent message', () {
        final message1 = eventProcessor.getEmptyRoomMessage();
        final message2 = eventProcessor.getEmptyRoomMessage();

        expect(message1, equals(message2));
        expect(message1, contains('empty'));
        expect(message1, contains('rest'));
      });

      test('validateEmptyRoomSetup correctly validates empty rooms', () {
        final emptyRoom = RoomEventData.empty('1,1');
        final roomWithEvents = RoomEventData.empty(
          '1,1',
        ).addEvent('test_event');

        expect(eventProcessor.validateEmptyRoomSetup(emptyRoom), isTrue);
        expect(eventProcessor.validateEmptyRoomSetup(roomWithEvents), isFalse);
      });

      test('createEmptyRoomDisplay provides UI-ready data', () {
        final roomData = RoomEventData.empty('1,1');
        final display = eventProcessor.createEmptyRoomDisplay(roomData);

        expect(display['isEmptyRoom'], isTrue);
        expect(display['name'], equals('Empty Room'));
        expect(display['choices'], isA<List>());
        expect(display['choices'].length, equals(1));
        expect(display['choices'][0]['isAvailable'], isTrue);
      });
    });

    group('Rest Action Processing', () {
      test('processRestAction applies effects correctly', () {
        final choice = Choice(
          text: 'Take a break',
          successEffects: ChoiceEffects(
            description: 'You feel refreshed.',
            statChanges: {'HP': 5, 'SAN': 3, 'HUNGER': -1},
          ),
        );
        final playerState = {
          'stats': {'HP': 50, 'SAN': 60, 'FITNESS': 70, 'HUNGER': 80},
          'inventory': <String>[],
          'statusEffects': <String>[],
        };

        final result = eventProcessor.processRestAction(choice, playerState);

        expect(result['actionType'], equals('rest'));
        expect(result['isEmptyRoomAction'], isTrue);
        expect(result['restBenefits'], isA<String>());
        expect(result['restBenefits'], contains('wounds feel better'));
      });

      test('rest benefits description handles empty stat changes', () {
        final choice = Choice(
          text: 'Take a break',
          successEffects: ChoiceEffects(
            description: 'You feel refreshed.',
            statChanges: {},
          ),
        );
        final playerState = {
          'stats': {'HP': 50, 'SAN': 60, 'FITNESS': 70, 'HUNGER': 80},
          'inventory': <String>[],
          'statusEffects': <String>[],
        };

        final result = eventProcessor.processRestAction(choice, playerState);

        expect(result['restBenefits'], contains('refreshed'));
      });

      test('rest benefits description includes all relevant stat changes', () {
        final choice = Choice(
          text: 'Take a break',
          successEffects: ChoiceEffects(
            description: 'You feel refreshed.',
            statChanges: {'HP': 3, 'SAN': 4, 'FITNESS': 1, 'HUNGER': -2},
          ),
        );
        final playerState = {
          'stats': {'HP': 50, 'SAN': 60, 'FITNESS': 70, 'HUNGER': 80},
          'inventory': <String>[],
          'statusEffects': <String>[],
        };

        final result = eventProcessor.processRestAction(choice, playerState);
        final benefits = result['restBenefits'] as String;

        expect(benefits, contains('wounds feel better'));
        expect(benefits, contains('mind feels clearer'));
        expect(benefits, contains('body feels more energized'));
        expect(benefits, contains('hungrier'));
      });
    });

    group('Room Entry Processing', () {
      test(
        'processRoomEntry uses enhanced empty room event when room is empty',
        () {
          final emptyRoom = RoomEventData.empty('1,1');
          final playerState = {
            'stats': {'HP': 50, 'SAN': 60, 'FITNESS': 70, 'HUNGER': 80},
          };

          final result = eventProcessor.processRoomEntry(
            emptyRoom,
            playerState,
          );

          expect(result['isEmptyRoom'], isTrue);
          expect(result['event'], isA<Event>());
          expect(
            (result['event'] as Event).id,
            equals('empty_room_rest_enhanced'),
          );
        },
      );

      test('processRoomEntry selects regular event when room has events', () {
        // Add a mock event to the database
        final mockEvent = Event(
          id: 'test_event',
          name: 'Test Event',
          description: 'A test event',
          image: 'test.png',
          category: 'test',
          weight: 10,
          persistence: 'oneTime',
          choices: [],
        );
        mockEventDatabase['test_event'] = mockEvent;

        final roomWithEvents = RoomEventData.empty(
          '1,1',
        ).addEvent('test_event');
        final playerState = {
          'stats': {'HP': 50, 'SAN': 60, 'FITNESS': 70, 'HUNGER': 80},
        };

        final result = eventProcessor.processRoomEntry(
          roomWithEvents,
          playerState,
        );

        expect(result['isEmptyRoom'], isFalse);
        expect(result['event'], isA<Event>());
        expect((result['event'] as Event).id, equals('test_event'));
      });
    });

    group('Edge Cases', () {
      test('handles null room data gracefully', () {
        expect(
          () => eventProcessor.createEmptyRoomEvent(roomEventData: null),
          returnsNormally,
        );
      });

      test('handles empty player state gracefully', () {
        final roomData = RoomEventData.empty('1,1');
        final emptyPlayerState = <String, dynamic>{};

        expect(
          () => eventProcessor.createEmptyRoomEventEnhanced(
            roomData,
            emptyPlayerState,
          ),
          returnsNormally,
        );
      });

      test('adaptive rest changes handle missing stats', () {
        final roomData = RoomEventData.empty('1,1');
        final playerStateWithMissingStats = {
          'stats': {'HP': 50}, // Missing other stats
        };

        final event = eventProcessor.createEmptyRoomEventEnhanced(
          roomData,
          playerStateWithMissingStats,
        );
        final statChanges = event.choices.first.successEffects?.statChanges;

        expect(statChanges, isNotNull);
        expect(statChanges!['HP'], isA<int>());
        expect(statChanges['SAN'], isA<int>());
      });
    });
  });
}
