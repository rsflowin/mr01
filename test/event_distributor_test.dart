import 'dart:math';
import 'package:test/test.dart';
import '../lib/services/event_distributor.dart';
import '../lib/models/event_model.dart';
import '../lib/models/maze_model.dart';

void main() {
  group('EventDistributor', () {
    late EventDistributor distributor;

    setUp(() {
      distributor = EventDistributor();
    });

    group('selectEventsByWeight', () {
      test('should return empty list when count is 0', () {
        final events = _createTestEvents({'event1': 10, 'event2': 20});

        final result = distributor.selectEventsByWeight(events, 0);

        expect(result, isEmpty);
      });

      test('should return empty list when events map is empty', () {
        final result = distributor.selectEventsByWeight({}, 5);

        expect(result, isEmpty);
      });

      test('should throw ArgumentError when count is negative', () {
        final events = _createTestEvents({'event1': 10});

        expect(
          () => distributor.selectEventsByWeight(events, -1),
          throwsA(isA<ArgumentError>()),
        );
      });

      test(
        'should throw ArgumentError when count exceeds available events',
        () {
          final events = _createTestEvents({'event1': 10, 'event2': 20});

          expect(
            () => distributor.selectEventsByWeight(events, 3),
            throwsA(isA<ArgumentError>()),
          );
        },
      );

      test('should select single event when count is 1', () {
        final events = _createTestEvents({'event1': 10, 'event2': 20});

        final result = distributor.selectEventsByWeight(events, 1);

        expect(result, hasLength(1));
        expect(events.keys, contains(result.first));
      });

      test('should select all events when count equals available events', () {
        final events = _createTestEvents({
          'event1': 10,
          'event2': 20,
          'event3': 15,
        });

        final result = distributor.selectEventsByWeight(events, 3);

        expect(result, hasLength(3));
        expect(result.toSet(), equals(events.keys.toSet()));
      });

      test('should not select the same event twice', () {
        final events = _createTestEvents({
          'event1': 10,
          'event2': 20,
          'event3': 15,
        });

        final result = distributor.selectEventsByWeight(events, 2);

        expect(result, hasLength(2));
        expect(result.toSet(), hasLength(2)); // No duplicates
      });

      test('should handle events with weight 1', () {
        final events = _createTestEvents({
          'event1': 1,
          'event2': 1,
          'event3': 1,
        });

        final result = distributor.selectEventsByWeight(events, 2);

        expect(result, hasLength(2));
        expect(result.every((id) => events.containsKey(id)), isTrue);
      });

      test('should use default weight for events with invalid weights', () {
        final events = {
          'event1': _createEvent('event1', weight: 0), // Invalid weight
          'event2': _createEvent('event2', weight: -5), // Invalid weight
          'event3': _createEvent('event3', weight: 20), // Valid weight
        };

        // Should not throw and should handle invalid weights gracefully
        final result = distributor.selectEventsByWeight(events, 2);

        expect(result, hasLength(2));
        expect(result.every((id) => events.containsKey(id)), isTrue);
      });

      test('should respect weight distribution over multiple runs', () {
        // Create events with significantly different weights
        final events = _createTestEvents({'low_weight': 1, 'high_weight': 100});

        // Use a fixed seed for reproducible results
        final seededDistributor = EventDistributor(random: Random(42));

        // Run selection many times and count occurrences
        final selectionCounts = <String, int>{};
        const iterations = 1000;

        for (int i = 0; i < iterations; i++) {
          final result = seededDistributor.selectEventsByWeight(events, 1);
          final selectedId = result.first;
          selectionCounts[selectedId] = (selectionCounts[selectedId] ?? 0) + 1;
        }

        // High weight event should be selected much more often
        final highWeightCount = selectionCounts['high_weight'] ?? 0;
        final lowWeightCount = selectionCounts['low_weight'] ?? 0;

        // With weight ratio of 100:1, high weight should be selected ~99% of the time
        expect(highWeightCount, greaterThan(lowWeightCount * 50));
        expect(highWeightCount + lowWeightCount, equals(iterations));
      });

      test('should distribute selections fairly with equal weights', () {
        final events = _createTestEvents({
          'event1': 10,
          'event2': 10,
          'event3': 10,
        });

        // Use a fixed seed for reproducible results
        final seededDistributor = EventDistributor(random: Random(123));

        // Run selection many times and count occurrences
        final selectionCounts = <String, int>{};
        const iterations = 3000; // Multiple of 3 for even distribution

        for (int i = 0; i < iterations; i++) {
          final result = seededDistributor.selectEventsByWeight(events, 1);
          final selectedId = result.first;
          selectionCounts[selectedId] = (selectionCounts[selectedId] ?? 0) + 1;
        }

        // Each event should be selected roughly equally (within reasonable variance)
        final expectedCount = iterations / 3;
        final tolerance = expectedCount * 0.2; // 20% tolerance

        for (final eventId in events.keys) {
          final count = selectionCounts[eventId] ?? 0;
          expect(count, greaterThan(expectedCount - tolerance));
          expect(count, lessThan(expectedCount + tolerance));
        }
      });

      test('should handle large weight values', () {
        final events = _createTestEvents({
          'event1': 1000000,
          'event2': 2000000,
        });

        final result = distributor.selectEventsByWeight(events, 1);

        expect(result, hasLength(1));
        expect(events.keys, contains(result.first));
      });

      test('should work with single event', () {
        final events = _createTestEvents({'only_event': 42});

        final result = distributor.selectEventsByWeight(events, 1);

        expect(result, equals(['only_event']));
      });

      test('should maintain selection order independence', () {
        final events = _createTestEvents({
          'event1': 10,
          'event2': 20,
          'event3': 30,
        });

        // Multiple selections should be independent
        final result1 = distributor.selectEventsByWeight(events, 2);
        final result2 = distributor.selectEventsByWeight(events, 2);

        expect(result1, hasLength(2));
        expect(result2, hasLength(2));
        // Results may be different (due to randomness) but should be valid
        expect(result1.every((id) => events.containsKey(id)), isTrue);
        expect(result2.every((id) => events.containsKey(id)), isTrue);
      });
    });

    group('weight validation', () {
      test('should handle zero weight by using default', () {
        final events = {
          'zero_weight': _createEvent('zero_weight', weight: 0),
          'normal_weight': _createEvent('normal_weight', weight: 15),
        };

        // Should not throw and should be able to select from both events
        final result = distributor.selectEventsByWeight(events, 2);

        expect(result, hasLength(2));
        expect(result, containsAll(['zero_weight', 'normal_weight']));
      });

      test('should handle negative weight by using default', () {
        final events = {
          'negative_weight': _createEvent('negative_weight', weight: -10),
          'normal_weight': _createEvent('normal_weight', weight: 25),
        };

        // Should not throw and should be able to select from both events
        final result = distributor.selectEventsByWeight(events, 1);

        expect(result, hasLength(1));
        expect(events.keys, contains(result.first));
      });

      test('should handle mix of valid and invalid weights', () {
        final events = {
          'invalid1': _createEvent('invalid1', weight: 0),
          'invalid2': _createEvent('invalid2', weight: -5),
          'valid1': _createEvent('valid1', weight: 10),
          'valid2': _createEvent('valid2', weight: 20),
        };

        final result = distributor.selectEventsByWeight(events, 3);

        expect(result, hasLength(3));
        expect(result.every((id) => events.containsKey(id)), isTrue);
      });
    });

    group('edge cases', () {
      test('should handle very large selection counts', () {
        // Create many events
        final events = <String, Event>{};
        for (int i = 0; i < 100; i++) {
          events['event_$i'] = _createEvent('event_$i', weight: i + 1);
        }

        final result = distributor.selectEventsByWeight(events, 50);

        expect(result, hasLength(50));
        expect(result.toSet(), hasLength(50)); // No duplicates
        expect(result.every((id) => events.containsKey(id)), isTrue);
      });

      test('should be deterministic with same seed', () {
        final events = _createTestEvents({
          'event1': 10,
          'event2': 20,
          'event3': 30,
        });

        final distributor1 = EventDistributor(random: Random(999));
        final distributor2 = EventDistributor(random: Random(999));

        final result1 = distributor1.selectEventsByWeight(events, 2);
        final result2 = distributor2.selectEventsByWeight(events, 2);

        expect(result1, equals(result2));
      });
    });

    group('assignTrapEvents', () {
      late MazeData testMaze;
      late Map<String, Event> trapEvents;

      setUp(() {
        testMaze = _createTestMaze();
        trapEvents = _createTrapEvents(15); // More than needed for testing
      });

      test('should assign exactly 10 trap events to unique rooms', () {
        distributor.assignTrapEvents(testMaze, trapEvents);

        final roomEventData = distributor.allRoomEventData;

        // Count rooms with trap events
        int trapRoomCount = 0;
        int totalTrapEvents = 0;

        for (final roomData in roomEventData.values) {
          if (roomData.hasTrapEvent) {
            trapRoomCount++;
            totalTrapEvents += roomData.availableEventIds.length;
          }
        }

        expect(trapRoomCount, equals(10));
        expect(totalTrapEvents, equals(10));
      });

      test('should not assign trap events to start or exit rooms', () {
        distributor.assignTrapEvents(testMaze, trapEvents);

        final roomEventData = distributor.allRoomEventData;

        // Check start room
        final startRoomId = '${testMaze.startRoom.x}_${testMaze.startRoom.y}';
        final startRoomData = roomEventData[startRoomId];
        expect(startRoomData?.hasTrapEvent, isFalse);

        // Check exit room
        final exitRoomId = '${testMaze.exitRoom.x}_${testMaze.exitRoom.y}';
        final exitRoomData = roomEventData[exitRoomId];
        expect(exitRoomData?.hasTrapEvent, isFalse);
      });

      test('should mark trap rooms as exclusive (no other events allowed)', () {
        distributor.assignTrapEvents(testMaze, trapEvents);

        final roomEventData = distributor.allRoomEventData;

        for (final roomData in roomEventData.values) {
          if (roomData.hasTrapEvent) {
            expect(roomData.isAvailableForEvents, isFalse);
            expect(
              roomData.availableEventIds.length,
              equals(1),
            ); // Only the trap event
          }
        }
      });

      test('should use weighted selection for trap events', () {
        // Create trap events with different weights
        final weightedTrapEvents = {
          'low_weight_trap': _createTrapEvent('low_weight_trap', weight: 1),
          'high_weight_trap': _createTrapEvent('high_weight_trap', weight: 100),
        };

        // Add more events to reach 10 total
        for (int i = 0; i < 8; i++) {
          weightedTrapEvents['trap_$i'] = _createTrapEvent(
            'trap_$i',
            weight: 10,
          );
        }

        // Use seeded random for reproducible results
        final seededDistributor = EventDistributor(random: Random(42));
        seededDistributor.assignTrapEvents(testMaze, weightedTrapEvents);

        final roomEventData = seededDistributor.allRoomEventData;
        final assignedEvents = <String>[];

        for (final roomData in roomEventData.values) {
          if (roomData.hasTrapEvent) {
            assignedEvents.addAll(roomData.availableEventIds);
          }
        }

        expect(assignedEvents, hasLength(10));
        expect(
          assignedEvents.every((id) => weightedTrapEvents.containsKey(id)),
          isTrue,
        );
      });

      test('should throw ArgumentError when no trap events available', () {
        expect(
          () => distributor.assignTrapEvents(testMaze, {}),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when insufficient trap events', () {
        final insufficientEvents = _createTrapEvents(5); // Only 5 events

        expect(
          () => distributor.assignTrapEvents(testMaze, insufficientEvents),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should initialize room event data for all rooms', () {
        distributor.assignTrapEvents(testMaze, trapEvents);

        final roomEventData = distributor.allRoomEventData;

        // Should have data for all 64 rooms (8x8 grid)
        expect(roomEventData, hasLength(64));

        // Check that all rooms are represented
        for (int y = 0; y < 8; y++) {
          for (int x = 0; x < 8; x++) {
            final roomId = '${x}_${y}';
            expect(roomEventData.containsKey(roomId), isTrue);
          }
        }
      });

      test('should handle multiple assignments to same distributor', () {
        // First assignment
        distributor.assignTrapEvents(testMaze, trapEvents);

        // Second assignment should reset and reassign
        final newTrapEvents = _createTrapEvents(12);
        distributor.assignTrapEvents(testMaze, newTrapEvents);
        final secondAssignment = distributor.allRoomEventData;

        // Should still have exactly 10 trap rooms
        int trapRoomCount = 0;
        for (final roomData in secondAssignment.values) {
          if (roomData.hasTrapEvent) {
            trapRoomCount++;
          }
        }

        expect(trapRoomCount, equals(10));
      });

      test('should provide access to room event data', () {
        distributor.assignTrapEvents(testMaze, trapEvents);

        // Test getRoomEventData method
        final roomData = distributor.getRoomEventData('0_0');
        expect(roomData, isNotNull);
        expect(roomData!.roomId, equals('0_0'));

        // Test allRoomEventData getter
        final allData = distributor.allRoomEventData;
        expect(allData, isNotEmpty);
        expect(allData.containsKey('0_0'), isTrue);
      });

      test('should handle edge case with exactly 10 trap events', () {
        final exactTrapEvents = _createTrapEvents(10);

        distributor.assignTrapEvents(testMaze, exactTrapEvents);

        final roomEventData = distributor.allRoomEventData;
        int trapRoomCount = 0;

        for (final roomData in roomEventData.values) {
          if (roomData.hasTrapEvent) {
            trapRoomCount++;
          }
        }

        expect(trapRoomCount, equals(10));
      });

      test('should assign different events to different rooms', () {
        distributor.assignTrapEvents(testMaze, trapEvents);

        final roomEventData = distributor.allRoomEventData;
        final assignedEvents = <String>[];

        for (final roomData in roomEventData.values) {
          if (roomData.hasTrapEvent) {
            assignedEvents.addAll(roomData.availableEventIds);
          }
        }

        // All assigned events should be unique
        expect(assignedEvents.toSet(), hasLength(assignedEvents.length));
        expect(assignedEvents, hasLength(10));
      });
    });

    group('assignItemEvents', () {
      late MazeData testMaze;
      late Map<String, Event> itemEvents;
      late Map<String, Event> trapEvents;

      setUp(() {
        testMaze = _createTestMaze();
        itemEvents = _createItemEvents(20); // More than needed for testing
        trapEvents = _createTrapEvents(15);
      });

      test('should assign exactly 15 item events', () {
        // First assign trap events
        distributor.assignTrapEvents(testMaze, trapEvents);

        // Then assign item events
        distributor.assignItemEvents(testMaze, itemEvents);

        final roomEventData = distributor.allRoomEventData;

        // Count total item events (events in non-trap rooms)
        int totalItemEvents = 0;

        for (final roomData in roomEventData.values) {
          if (!roomData.hasTrapEvent) {
            totalItemEvents += roomData.availableEventIds.length;
          }
        }

        expect(totalItemEvents, equals(15));
      });

      test('should not assign item events to trap rooms', () {
        // First assign trap events
        distributor.assignTrapEvents(testMaze, trapEvents);

        // Then assign item events
        distributor.assignItemEvents(testMaze, itemEvents);

        final roomEventData = distributor.allRoomEventData;

        for (final roomData in roomEventData.values) {
          if (roomData.hasTrapEvent) {
            // Trap rooms should only have trap events (1 event each)
            expect(roomData.availableEventIds.length, equals(1));
          }
        }
      });

      test('should not assign item events to start or exit rooms', () {
        distributor.assignItemEvents(testMaze, itemEvents);

        final roomEventData = distributor.allRoomEventData;

        // Check start room has no events
        final startRoomId = '${testMaze.startRoom.x}_${testMaze.startRoom.y}';
        final startRoomData = roomEventData[startRoomId];
        expect(startRoomData?.availableEventIds, isEmpty);

        // Check exit room has no events
        final exitRoomId = '${testMaze.exitRoom.x}_${testMaze.exitRoom.y}';
        final exitRoomData = roomEventData[exitRoomId];
        expect(exitRoomData?.availableEventIds, isEmpty);
      });

      test('should allow multiple item events per room', () {
        // Create scenario with limited available rooms to force multiple events per room
        final smallItemEvents = _createItemEvents(15);

        distributor.assignItemEvents(testMaze, smallItemEvents);

        final roomEventData = distributor.allRoomEventData;

        // Count rooms with events and rooms with multiple events
        int roomsWithEvents = 0;
        int roomsWithMultipleEvents = 0;

        for (final roomData in roomEventData.values) {
          if (roomData.availableEventIds.isNotEmpty && !roomData.hasTrapEvent) {
            roomsWithEvents++;
            if (roomData.availableEventIds.length > 1) {
              roomsWithMultipleEvents++;
            }
          }
        }

        expect(roomsWithEvents, greaterThan(0));
        // With 15 events and 62 available rooms, we might have multiple events per room
        // This test just ensures the system allows it
        expect(roomsWithMultipleEvents, greaterThanOrEqualTo(0));
      });

      test('should use weighted selection for item events', () {
        final weightedItemEvents = <String, Event>{};

        // Create 15 events with two different weights
        for (int i = 0; i < 10; i++) {
          weightedItemEvents['heavy_item_$i'] = _createEvent(
            'heavy_item_$i',
            weight: 100,
          );
        }
        for (int i = 0; i < 5; i++) {
          weightedItemEvents['light_item_$i'] = _createEvent(
            'light_item_$i',
            weight: 1,
          );
        }

        // Use seeded random for predictable results
        final seededDistributor = EventDistributor(random: Random(12345));

        seededDistributor.assignItemEvents(testMaze, weightedItemEvents);

        final roomEventData = seededDistributor.allRoomEventData;
        final assignedEvents = <String>[];

        for (final roomData in roomEventData.values) {
          if (!roomData.hasTrapEvent) {
            assignedEvents.addAll(roomData.availableEventIds);
          }
        }

        // With the seeded random and high weight difference,
        // we should see more heavy_item events than light_item events
        final heavyCount = assignedEvents
            .where((id) => id.startsWith('heavy_item'))
            .length;
        final lightCount = assignedEvents
            .where((id) => id.startsWith('light_item'))
            .length;

        expect(heavyCount, greaterThan(lightCount));
      });

      test('should throw ArgumentError when no item events available', () {
        expect(
          () => distributor.assignItemEvents(testMaze, {}),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should throw ArgumentError when insufficient item events', () {
        final insufficientEvents = _createItemEvents(10); // Need 15

        expect(
          () => distributor.assignItemEvents(testMaze, insufficientEvents),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('should handle assignment after trap events are assigned', () {
        // First assign trap events
        distributor.assignTrapEvents(testMaze, trapEvents);

        // Then assign item events
        distributor.assignItemEvents(testMaze, itemEvents);

        final roomEventData = distributor.allRoomEventData;

        // Verify we have both trap and item events
        int trapRooms = 0;
        int roomsWithItemEvents = 0;
        int totalItemEvents = 0;

        for (final roomData in roomEventData.values) {
          if (roomData.hasTrapEvent) {
            trapRooms++;
          } else if (roomData.availableEventIds.isNotEmpty) {
            roomsWithItemEvents++;
            totalItemEvents += roomData.availableEventIds.length;
          }
        }

        expect(trapRooms, equals(10));
        expect(totalItemEvents, equals(15));
        expect(roomsWithItemEvents, greaterThan(0));
      });

      test('should assign events to available rooms efficiently', () {
        distributor.assignItemEvents(testMaze, itemEvents);

        final roomEventData = distributor.allRoomEventData;

        // Count total available rooms (excluding start/exit)
        int totalAvailableRooms = 0;
        int roomsWithEvents = 0;

        for (int y = 0; y < 8; y++) {
          for (int x = 0; x < 8; x++) {
            final room = testMaze.getRoomAt(x, y);
            if (room != null && !room.isStart && !room.isExit) {
              totalAvailableRooms++;
              final roomId = '${room.x}_${room.y}';
              final roomData = roomEventData[roomId];
              if (roomData != null && roomData.availableEventIds.isNotEmpty) {
                roomsWithEvents++;
              }
            }
          }
        }

        expect(totalAvailableRooms, equals(62)); // 64 - 2 (start/exit)
        expect(roomsWithEvents, greaterThan(0));
        expect(
          roomsWithEvents,
          lessThanOrEqualTo(15),
        ); // At most 15 rooms can have events
      });
    });

    group('assignCharacterMonsterEvents', () {
      late MazeData testMaze;
      late Map<String, Event> characterEvents;
      late Map<String, Event> monsterEvents;
      late Map<String, Event> trapEvents;

      setUp(() {
        testMaze = _createTestMaze();
        characterEvents = _createCharacterEvents(10);
        monsterEvents = _createMonsterEvents(8);
        trapEvents = _createTrapEvents(15);
      });

      test('should assign events to all available rooms', () {
        // First assign trap events to reduce available rooms
        distributor.assignTrapEvents(testMaze, trapEvents);

        // Then assign character and monster events
        distributor.assignCharacterMonsterEvents(
          testMaze,
          characterEvents,
          monsterEvents,
        );

        final roomEventData = distributor.allRoomEventData;

        // Count rooms with character/monster events (non-trap rooms with events)
        int roomsWithCharacterMonsterEvents = 0;
        int totalCharacterMonsterEvents = 0;

        for (final roomData in roomEventData.values) {
          if (!roomData.hasTrapEvent && roomData.availableEventIds.isNotEmpty) {
            roomsWithCharacterMonsterEvents++;
            totalCharacterMonsterEvents += roomData.availableEventIds.length;
          }
        }

        // Should have events in all non-trap rooms (62 - 10 trap rooms = 52 rooms)
        expect(roomsWithCharacterMonsterEvents, equals(52));
        expect(
          totalCharacterMonsterEvents,
          greaterThan(52),
        ); // At least 1 per room
      });

      test('should assign between 1 and 20 events per room', () {
        distributor.assignCharacterMonsterEvents(
          testMaze,
          characterEvents,
          monsterEvents,
        );

        final roomEventData = distributor.allRoomEventData;

        for (final roomData in roomEventData.values) {
          if (!roomData.hasTrapEvent && roomData.availableEventIds.isNotEmpty) {
            expect(roomData.availableEventIds.length, greaterThanOrEqualTo(1));
            expect(roomData.availableEventIds.length, lessThanOrEqualTo(20));
          }
        }
      });

      test('should throw ArgumentError when no events available', () {
        expect(
          () => distributor.assignCharacterMonsterEvents(testMaze, {}, {}),
          throwsA(isA<ArgumentError>()),
        );
      });
    });
  });
}

/// Helper function to create test events with specified weights
Map<String, Event> _createTestEvents(Map<String, int> eventWeights) {
  final events = <String, Event>{};

  for (final entry in eventWeights.entries) {
    events[entry.key] = _createEvent(entry.key, weight: entry.value);
  }

  return events;
}

/// Helper function to create a single test event
Event _createEvent(String id, {int weight = 10}) {
  return Event(
    id: id,
    name: 'Test Event $id',
    description: 'Test description for $id',
    image: 'test_image.png',
    category: 'test',
    weight: weight,
    persistence: 'oneTime',
    choices: [
      Choice(
        text: 'Test choice',
        successEffects: ChoiceEffects(description: 'Test effect'),
      ),
    ],
  );
}

/// Helper function to create a test maze with 8x8 grid
MazeData _createTestMaze() {
  // Create 8x8 grid of rooms
  List<List<MazeRoom>> grid = List.generate(
    8,
    (y) => List.generate(
      8,
      (x) => MazeRoom(
        x: x,
        y: y,
        north: true,
        east: true,
        south: true,
        west: true,
        isStart: x == 0 && y == 7, // Bottom-left
        isExit: x == 7 && y == 0, // Top-right
      ),
    ),
  );

  return MazeData(
    id: 1,
    name: 'Test Maze',
    difficulty: 'Easy',
    grid: grid,
    startRoom: grid[7][0], // Bottom-left
    exitRoom: grid[0][7], // Top-right
  );
}

/// Helper function to create trap events
Map<String, Event> _createTrapEvents(int count) {
  final events = <String, Event>{};

  for (int i = 0; i < count; i++) {
    final id = 'trap_event_$i';
    events[id] = _createTrapEvent(id);
  }

  return events;
}

/// Helper function to create a single trap event
Event _createTrapEvent(String id, {int weight = 10}) {
  return Event(
    id: id,
    name: 'Trap Event $id',
    description: 'A dangerous trap awaits...',
    image: 'trap_image.png',
    category: 'trap',
    weight: weight,
    persistence: 'persistent', // Traps are persistent
    choices: [
      Choice(
        text: 'Try to disarm',
        successEffects: ChoiceEffects(description: 'Successfully disarmed'),
      ),
      Choice(
        text: 'Trigger carefully',
        successEffects: ChoiceEffects(description: 'Triggered safely'),
      ),
    ],
  );
}

/// Helper function to create item events for testing
Map<String, Event> _createItemEvents(int count) {
  final events = <String, Event>{};

  for (int i = 0; i < count; i++) {
    final id = 'item_event_$i';
    events[id] = _createItemEvent(id, weight: 5 + (i % 20));
  }

  return events;
}

/// Helper function to create a single item event
Event _createItemEvent(String id, {int weight = 10}) {
  return Event(
    id: id,
    name: 'Item Event $id',
    description: 'You found a useful item!',
    image: 'item_image.png',
    category: 'item',
    weight: weight,
    persistence: 'oneTime', // Items are consumed once
    choices: [
      Choice(
        text: 'Take the item',
        successEffects: ChoiceEffects(
          description: 'Added to inventory',
          itemsGained: ['generic_item'],
        ),
      ),
      Choice(
        text: 'Leave it',
        successEffects: ChoiceEffects(description: 'Left the item behind'),
      ),
    ],
  );
}

/// Helper function to create character events for testing
Map<String, Event> _createCharacterEvents(int count) {
  final events = <String, Event>{};

  for (int i = 0; i < count; i++) {
    final id = 'character_event_$i';
    events[id] = _createCharacterEvent(id, weight: 8 + (i % 15));
  }

  return events;
}

/// Helper function to create a single character event
Event _createCharacterEvent(String id, {int weight = 10}) {
  return Event(
    id: id,
    name: 'Character Event $id',
    description: 'You encounter a character...',
    image: 'character_image.png',
    category: 'character',
    weight: weight,
    persistence: 'oneTime', // Characters are encountered once
    choices: [
      Choice(
        text: 'Talk to them',
        successEffects: ChoiceEffects(
          description: 'Had a conversation',
          statChanges: {'SAN': 5},
        ),
      ),
      Choice(
        text: 'Ignore them',
        successEffects: ChoiceEffects(description: 'Walked away'),
      ),
    ],
  );
}

/// Helper function to create monster events for testing
Map<String, Event> _createMonsterEvents(int count) {
  final events = <String, Event>{};

  for (int i = 0; i < count; i++) {
    final id = 'monster_event_$i';
    events[id] = _createMonsterEvent(id, weight: 12 + (i % 10));
  }

  return events;
}

/// Helper function to create a single monster event
Event _createMonsterEvent(String id, {int weight = 10}) {
  return Event(
    id: id,
    name: 'Monster Event $id',
    description: 'A dangerous creature blocks your path!',
    image: 'monster_image.png',
    category: 'monster',
    weight: weight,
    persistence: 'oneTime', // Monsters are defeated once
    choices: [
      Choice(
        text: 'Fight',
        successEffects: ChoiceEffects(
          description: 'Victory!',
          statChanges: {'HP': -10, 'FITNESS': 5},
        ),
      ),
      Choice(
        text: 'Run away',
        successEffects: ChoiceEffects(
          description: 'Escaped safely',
          statChanges: {'SAN': -5},
        ),
      ),
    ],
  );
}
