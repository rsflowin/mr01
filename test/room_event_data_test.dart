import 'package:test/test.dart';
import '../lib/models/room_event_data.dart';

void main() {
  group('RoomEventData', () {
    late RoomEventData roomData;

    setUp(() {
      roomData = RoomEventData.empty('test_room');
    });

    group('creation and basic properties', () {
      test('should create empty room event data', () {
        expect(roomData.roomId, equals('test_room'));
        expect(roomData.availableEventIds, isEmpty);
        expect(roomData.consumedEventIds, isEmpty);
        expect(roomData.hasTrapEvent, isFalse);
        expect(roomData.eventCount, equals(0));
      });

      test('should create room event data with constructor', () {
        final data = RoomEventData(
          roomId: 'room_1',
          availableEventIds: ['event1', 'event2'],
          consumedEventIds: ['event3'],
          hasTrapEvent: true,
          eventCount: 2,
        );

        expect(data.roomId, equals('room_1'));
        expect(data.availableEventIds, equals(['event1', 'event2']));
        expect(data.consumedEventIds, equals(['event3']));
        expect(data.hasTrapEvent, isTrue);
        expect(data.eventCount, equals(2));
      });
    });

    group('copyWith', () {
      test(
        'should create copy with same values when no parameters provided',
        () {
          final original = RoomEventData(
            roomId: 'room_1',
            availableEventIds: ['event1'],
            consumedEventIds: ['event2'],
            hasTrapEvent: true,
            eventCount: 1,
          );

          final copy = original.copyWith();

          expect(copy.roomId, equals(original.roomId));
          expect(copy.availableEventIds, equals(original.availableEventIds));
          expect(copy.consumedEventIds, equals(original.consumedEventIds));
          expect(copy.hasTrapEvent, equals(original.hasTrapEvent));
          expect(copy.eventCount, equals(original.eventCount));

          // Should be different instances
          expect(identical(copy, original), isFalse);
          expect(
            identical(copy.availableEventIds, original.availableEventIds),
            isFalse,
          );
          expect(
            identical(copy.consumedEventIds, original.consumedEventIds),
            isFalse,
          );
        },
      );

      test('should create copy with updated values', () {
        final original = RoomEventData.empty('room_1');

        final updated = original.copyWith(
          roomId: 'room_2',
          availableEventIds: ['new_event'],
          hasTrapEvent: true,
          eventCount: 1,
        );

        expect(updated.roomId, equals('room_2'));
        expect(updated.availableEventIds, equals(['new_event']));
        expect(updated.consumedEventIds, isEmpty); // Unchanged
        expect(updated.hasTrapEvent, isTrue);
        expect(updated.eventCount, equals(1));
      });
    });

    group('addEvent', () {
      test('should add event to available events', () {
        final updated = roomData.addEvent('event1');

        expect(updated.availableEventIds, equals(['event1']));
        expect(updated.eventCount, equals(1));
        expect(updated.hasTrapEvent, isFalse);
      });

      test('should add trap event and mark room as trap room', () {
        final updated = roomData.addEvent('trap_event', isTrap: true);

        expect(updated.availableEventIds, equals(['trap_event']));
        expect(updated.eventCount, equals(1));
        expect(updated.hasTrapEvent, isTrue);
      });

      test('should not add duplicate events', () {
        final withEvent = roomData.addEvent('event1');
        final withDuplicate = withEvent.addEvent('event1');

        expect(withDuplicate.availableEventIds, equals(['event1']));
        expect(withDuplicate.eventCount, equals(1));
      });

      test('should preserve trap status when adding non-trap events', () {
        final withTrap = roomData.addEvent('trap_event', isTrap: true);
        final withRegular = withTrap.addEvent('regular_event');

        expect(withRegular.hasTrapEvent, isTrue);
        expect(
          withRegular.availableEventIds,
          equals(['trap_event', 'regular_event']),
        );
      });
    });

    group('consumeEvent', () {
      test('should move event from available to consumed', () {
        final withEvent = roomData.addEvent('event1');
        final consumed = withEvent.consumeEvent('event1');

        expect(consumed.availableEventIds, isEmpty);
        expect(consumed.consumedEventIds, equals(['event1']));
        expect(consumed.eventCount, equals(0));
      });

      test('should not affect non-existent events', () {
        final consumed = roomData.consumeEvent('non_existent');

        expect(consumed.availableEventIds, isEmpty);
        expect(consumed.consumedEventIds, isEmpty);
        expect(consumed.eventCount, equals(0));
      });

      test('should not add already consumed event again', () {
        final withEvent = roomData.addEvent('event1');
        final firstConsume = withEvent.consumeEvent('event1');
        final secondConsume = firstConsume.consumeEvent('event1');

        expect(secondConsume.consumedEventIds, equals(['event1']));
      });

      test('should handle multiple events', () {
        final withEvents = roomData
            .addEvent('event1')
            .addEvent('event2')
            .addEvent('event3');

        final consumed = withEvents.consumeEvent('event2');

        expect(consumed.availableEventIds, equals(['event1', 'event3']));
        expect(consumed.consumedEventIds, equals(['event2']));
        expect(consumed.eventCount, equals(2));
      });
    });

    group('restoreEvent', () {
      test('should move event from consumed back to available', () {
        final withEvent = roomData.addEvent('persistent_event');
        final consumed = withEvent.consumeEvent('persistent_event');
        final restored = consumed.restoreEvent('persistent_event');

        expect(restored.availableEventIds, equals(['persistent_event']));
        expect(restored.consumedEventIds, isEmpty);
        expect(restored.eventCount, equals(1));
      });

      test('should not affect non-existent consumed events', () {
        final restored = roomData.restoreEvent('non_existent');

        expect(restored.availableEventIds, isEmpty);
        expect(restored.consumedEventIds, isEmpty);
        expect(restored.eventCount, equals(0));
      });

      test('should not restore event that is already available', () {
        final withEvent = roomData.addEvent('event1');
        final restored = withEvent.restoreEvent('event1');

        expect(restored.availableEventIds, equals(['event1']));
        expect(restored.consumedEventIds, isEmpty);
        expect(restored.eventCount, equals(1));
      });
    });

    group('removeEventCompletely', () {
      test('should remove event from available events', () {
        final withEvent = roomData.addEvent('event1');
        final removed = withEvent.removeEventCompletely('event1');

        expect(removed.availableEventIds, isEmpty);
        expect(removed.consumedEventIds, isEmpty);
        expect(removed.eventCount, equals(0));
      });

      test('should remove event from consumed events', () {
        final withEvent = roomData.addEvent('event1');
        final consumed = withEvent.consumeEvent('event1');
        final removed = consumed.removeEventCompletely('event1');

        expect(removed.availableEventIds, isEmpty);
        expect(removed.consumedEventIds, isEmpty);
        expect(removed.eventCount, equals(0));
      });

      test('should handle non-existent events gracefully', () {
        final removed = roomData.removeEventCompletely('non_existent');

        expect(removed.availableEventIds, isEmpty);
        expect(removed.consumedEventIds, isEmpty);
        expect(removed.eventCount, equals(0));
      });
    });

    group('query methods', () {
      test('hasAvailableEvents should return correct status', () {
        expect(roomData.hasAvailableEvents, isFalse);

        final withEvent = roomData.addEvent('event1');
        expect(withEvent.hasAvailableEvents, isTrue);

        final consumed = withEvent.consumeEvent('event1');
        expect(consumed.hasAvailableEvents, isFalse);
      });

      test('isAvailableForEvents should return correct status', () {
        expect(roomData.isAvailableForEvents, isTrue);

        final withTrap = roomData.addEvent('trap_event', isTrap: true);
        expect(withTrap.isAvailableForEvents, isFalse);
      });

      test('hasEvent should check available events', () {
        final withEvent = roomData.addEvent('event1');

        expect(withEvent.hasEvent('event1'), isTrue);
        expect(withEvent.hasEvent('event2'), isFalse);

        final consumed = withEvent.consumeEvent('event1');
        expect(consumed.hasEvent('event1'), isFalse);
      });

      test('hasConsumedEvent should check consumed events', () {
        final withEvent = roomData.addEvent('event1');

        expect(withEvent.hasConsumedEvent('event1'), isFalse);

        final consumed = withEvent.consumeEvent('event1');
        expect(consumed.hasConsumedEvent('event1'), isTrue);
        expect(consumed.hasConsumedEvent('event2'), isFalse);
      });

      test('totalEventsAssigned should count all events', () {
        expect(roomData.totalEventsAssigned, equals(0));

        final withEvents = roomData
            .addEvent('event1')
            .addEvent('event2')
            .addEvent('event3');
        expect(withEvents.totalEventsAssigned, equals(3));

        final consumed = withEvents.consumeEvent('event1');
        expect(consumed.totalEventsAssigned, equals(3));
      });

      test('isEmpty should return correct status', () {
        expect(roomData.isEmpty, isTrue);

        final withEvent = roomData.addEvent('event1');
        expect(withEvent.isEmpty, isFalse);

        final consumed = withEvent.consumeEvent('event1');
        expect(consumed.isEmpty, isFalse);

        final removed = consumed.removeEventCompletely('event1');
        expect(removed.isEmpty, isTrue);
      });
    });

    group('immutable access', () {
      test('availableEvents should return immutable list', () {
        final withEvents = roomData.addEvent('event1').addEvent('event2');
        final events = withEvents.availableEvents;

        expect(events, equals(['event1', 'event2']));

        // Should throw when trying to modify
        expect(() => events.add('event3'), throwsUnsupportedError);
      });

      test('consumedEvents should return immutable list', () {
        final withEvent = roomData.addEvent('event1');
        final consumed = withEvent.consumeEvent('event1');
        final events = consumed.consumedEvents;

        expect(events, equals(['event1']));

        // Should throw when trying to modify
        expect(() => events.add('event2'), throwsUnsupportedError);
      });
    });

    group('equality and hashCode', () {
      test('should be equal when all properties match', () {
        final data1 = RoomEventData(
          roomId: 'room_1',
          availableEventIds: ['event1'],
          consumedEventIds: ['event2'],
          hasTrapEvent: true,
          eventCount: 1,
        );

        final data2 = RoomEventData(
          roomId: 'room_1',
          availableEventIds: ['event1'],
          consumedEventIds: ['event2'],
          hasTrapEvent: true,
          eventCount: 1,
        );

        expect(data1, equals(data2));
        expect(data1.hashCode, equals(data2.hashCode));
      });

      test('should not be equal when properties differ', () {
        final data1 = RoomEventData.empty('room_1');
        final data2 = RoomEventData.empty('room_2');

        expect(data1, isNot(equals(data2)));
      });

      test('should be identical to itself', () {
        expect(roomData, equals(roomData));
      });
    });

    group('toString', () {
      test('should provide meaningful string representation', () {
        final withEvents = roomData
            .addEvent('event1')
            .addEvent('trap_event', isTrap: true);
        final consumed = withEvents.consumeEvent('event1');

        final result = consumed.toString();

        expect(result, contains('test_room'));
        expect(result, contains('available: 1'));
        expect(result, contains('consumed: 1'));
        expect(result, contains('hasTrap: true'));
      });
    });

    group('complex scenarios', () {
      test('should handle persistence simulation for trap events', () {
        // Simulate persistent trap event
        final withTrap = roomData.addEvent('pit_trap', isTrap: true);

        // Trigger the trap (consume it)
        final triggered = withTrap.consumeEvent('pit_trap');
        expect(triggered.hasAvailableEvents, isFalse);
        expect(triggered.hasConsumedEvent('pit_trap'), isTrue);

        // Restore for next visit (persistent behavior)
        final restored = triggered.restoreEvent('pit_trap');
        expect(restored.hasAvailableEvents, isTrue);
        expect(restored.hasEvent('pit_trap'), isTrue);
        expect(restored.hasConsumedEvent('pit_trap'), isFalse);
      });

      test('should handle oneTime event consumption', () {
        // Simulate oneTime item event
        final withItem = roomData.addEvent('health_potion');

        // Use the item (consume it)
        final used = withItem.consumeEvent('health_potion');
        expect(used.hasAvailableEvents, isFalse);
        expect(used.hasConsumedEvent('health_potion'), isTrue);

        // OneTime events should not be restored
        // (this would be handled by the EventProcessor, not RoomEventData)
      });

      test('should handle mixed event types', () {
        final complex = roomData
            .addEvent('trap_event', isTrap: true)
            .addEvent('item_event')
            .addEvent('character_event')
            .addEvent('monster_event');

        expect(complex.totalEventsAssigned, equals(4));
        expect(complex.hasTrapEvent, isTrue);
        expect(complex.hasAvailableEvents, isTrue);

        // Consume some events
        final afterEvents = complex
            .consumeEvent('item_event')
            .consumeEvent('monster_event');

        expect(
          afterEvents.availableEventIds,
          equals(['trap_event', 'character_event']),
        );
        expect(
          afterEvents.consumedEventIds,
          equals(['item_event', 'monster_event']),
        );
        expect(afterEvents.eventCount, equals(2));
        expect(afterEvents.totalEventsAssigned, equals(4));
      });
    });
  });
}
