import 'package:flutter_test/flutter_test.dart';
import '../lib/services/event_loader.dart';

void main() {
  group('EventLoader Integration Tests', () {
    late EventLoader eventLoader;
    
    setUp(() {
      eventLoader = EventLoader();
    });
    
    test('should load and validate all event files successfully', () async {
      print('Loading all events...');
      
      final allEvents = await eventLoader.loadAllEvents();
      final counts = await eventLoader.getEventCounts();
      
      print('Event counts: $counts');
      
      // Verify we have reasonable numbers of events
      expect(counts['trap']!, greaterThan(10));
      expect(counts['item']!, greaterThan(10));
      expect(counts['character']!, greaterThan(50)); // 18 files * ~10 events each
      expect(counts['monster']!, greaterThan(5));
      
      // Verify all events are properly structured
      int totalValidated = 0;
      
      for (final category in allEvents.keys) {
        for (final event in allEvents[category]!.values) {
          expect(eventLoader.validateEventStructure(event), isTrue, 
            reason: 'Event ${event.id} in category $category failed validation');
          totalValidated++;
        }
      }
      
      print('Successfully validated $totalValidated events');
      
      // Verify specific event properties
      final trapEvents = allEvents['trap']!;
      for (final event in trapEvents.values) {
        expect(event.category, equals('trap'));
        expect(event.persistence, equals('persistent'));
        expect(event.weight, greaterThan(0));
        expect(event.choices, isNotEmpty);
      }
      
      final itemEvents = allEvents['item']!;
      for (final event in itemEvents.values) {
        expect(event.category, equals('item'));
        expect(event.weight, greaterThan(0));
        expect(event.choices, isNotEmpty);
      }
      
      final characterEvents = allEvents['character']!;
      for (final event in characterEvents.values) {
        expect(event.category, equals('character'));
        expect(event.persistence, equals('oneTime'));
        expect(event.weight, greaterThan(0));
        expect(event.choices, isNotEmpty);
      }
      
      final monsterEvents = allEvents['monster']!;
      for (final event in monsterEvents.values) {
        expect(event.category, equals('monster'));
        expect(event.persistence, equals('oneTime'));
        expect(event.weight, greaterThan(0));
        expect(event.choices, isNotEmpty);
      }
    });
    
    test('should handle individual event file loading', () async {
      // Test each loader method individually
      final trapEvents = await eventLoader.loadTrapEvents();
      expect(trapEvents, isNotEmpty);
      print('Loaded ${trapEvents.length} trap events');
      
      final itemEvents = await eventLoader.loadItemEvents();
      expect(itemEvents, isNotEmpty);
      print('Loaded ${itemEvents.length} item events');
      
      final characterEvents = await eventLoader.loadCharacterEvents();
      expect(characterEvents, isNotEmpty);
      print('Loaded ${characterEvents.length} character events');
      
      final monsterEvents = await eventLoader.loadMonsterEvents();
      expect(monsterEvents, isNotEmpty);
      print('Loaded ${monsterEvents.length} monster events');
    });
    
    test('should validate event choice structures', () async {
      final allEvents = await eventLoader.loadAllEvents();
      
      for (final category in allEvents.keys) {
        for (final event in allEvents[category]!.values) {
          // Verify each choice has required properties
          for (final choice in event.choices) {
            expect(choice.text, isNotEmpty, 
              reason: 'Choice text empty in event ${event.id}');
            expect(choice.successEffects.description, isNotEmpty,
              reason: 'Success effects description empty in event ${event.id}');
            
            // If failure effects exist, they should be valid
            if (choice.failureEffects != null) {
              expect(choice.failureEffects!.description, isNotEmpty,
                reason: 'Failure effects description empty in event ${event.id}');
            }
          }
        }
      }
    });
  });
}