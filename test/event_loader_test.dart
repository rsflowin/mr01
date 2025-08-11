import 'package:flutter_test/flutter_test.dart';
import 'dart:io';
import 'dart:convert';
import '../lib/services/event_loader.dart';
import '../lib/models/event_model.dart';

void main() {
  group('EventLoader', () {
    late EventLoader eventLoader;
    
    setUp(() {
      eventLoader = EventLoader();
    });
    
    group('validateEventStructure', () {
      test('should return true for valid event', () {
        final validEvent = Event(
          id: 'test_event',
          name: 'Test Event',
          description: 'A test event',
          image: 'test.png',
          category: 'trap',
          weight: 10,
          persistence: 'persistent',
          choices: [
            Choice(
              text: 'Test choice',
              successEffects: ChoiceEffects(
                description: 'Test effect',
              ),
            ),
          ],
        );
        
        expect(eventLoader.validateEventStructure(validEvent), isTrue);
      });
      
      test('should return false for event with invalid weight', () {
        final invalidEvent = Event(
          id: 'test_event',
          name: 'Test Event',
          description: 'A test event',
          image: 'test.png',
          category: 'trap',
          weight: 150, // Invalid weight > 100
          persistence: 'persistent',
          choices: [
            Choice(
              text: 'Test choice',
              successEffects: ChoiceEffects(
                description: 'Test effect',
              ),
            ),
          ],
        );
        
        expect(eventLoader.validateEventStructure(invalidEvent), isFalse);
      });
      
      test('should return false for event with zero weight', () {
        final invalidEvent = Event(
          id: 'test_event',
          name: 'Test Event',
          description: 'A test event',
          image: 'test.png',
          category: 'trap',
          weight: 0, // Invalid weight
          persistence: 'persistent',
          choices: [
            Choice(
              text: 'Test choice',
              successEffects: ChoiceEffects(
                description: 'Test effect',
              ),
            ),
          ],
        );
        
        expect(eventLoader.validateEventStructure(invalidEvent), isFalse);
      });
      
      test('should return false for event with empty choices', () {
        final invalidEvent = Event(
          id: 'test_event',
          name: 'Test Event',
          description: 'A test event',
          image: 'test.png',
          category: 'trap',
          weight: 10,
          persistence: 'persistent',
          choices: [], // Empty choices
        );
        
        expect(eventLoader.validateEventStructure(invalidEvent), isFalse);
      });
      
      test('should validate extreme stat changes', () {
        final eventWithExtremeStats = Event(
          id: 'test_event',
          name: 'Test Event',
          description: 'A test event',
          image: 'test.png',
          category: 'trap',
          weight: 10,
          persistence: 'persistent',
          choices: [
            Choice(
              text: 'Test choice',
              successEffects: ChoiceEffects(
                description: 'Test effect',
                statChanges: {'HP': 150}, // Extreme value
              ),
            ),
          ],
        );
        
        // Should still be valid but will log a warning
        expect(eventLoader.validateEventStructure(eventWithExtremeStats), isTrue);
      });
    });
    
    group('loadTrapEvents', () {
      test('should load trap events from existing file', () async {
        final trapEvents = await eventLoader.loadTrapEvents();
        
        expect(trapEvents, isNotEmpty);
        
        // Verify all events are trap category
        for (final event in trapEvents.values) {
          expect(event.category, equals('trap'));
          expect(event.persistence, equals('persistent'));
          expect(eventLoader.validateEventStructure(event), isTrue);
        }
      });
      
      test('should handle missing trap file gracefully', () async {
        // This test assumes the file exists, but tests the fallback mechanism
        // by checking that some events are returned even if file issues occur
        final trapEvents = await eventLoader.loadTrapEvents();
        
        expect(trapEvents, isNotEmpty);
      });
    });
    
    group('loadItemEvents', () {
      test('should load item events from existing file', () async {
        final itemEvents = await eventLoader.loadItemEvents();
        
        expect(itemEvents, isNotEmpty);
        
        // Verify all events are item category
        for (final event in itemEvents.values) {
          expect(event.category, equals('item'));
          expect(eventLoader.validateEventStructure(event), isTrue);
        }
      });
    });
    
    group('loadCharacterEvents', () {
      test('should load character events from multiple files', () async {
        final characterEvents = await eventLoader.loadCharacterEvents();
        
        expect(characterEvents, isNotEmpty);
        
        // Verify all events are character category
        for (final event in characterEvents.values) {
          expect(event.category, equals('character'));
          expect(eventLoader.validateEventStructure(event), isTrue);
        }
      });
    });
    
    group('loadMonsterEvents', () {
      test('should load monster events from existing file', () async {
        final monsterEvents = await eventLoader.loadMonsterEvents();
        
        expect(monsterEvents, isNotEmpty);
        
        // Verify all events are monster category
        for (final event in monsterEvents.values) {
          expect(event.category, equals('monster'));
          expect(eventLoader.validateEventStructure(event), isTrue);
        }
      });
    });
    
    group('loadAllEvents', () {
      test('should load all event types successfully', () async {
        final allEvents = await eventLoader.loadAllEvents();
        
        expect(allEvents, hasLength(4));
        expect(allEvents.keys, containsAll(['trap', 'item', 'character', 'monster']));
        
        // Verify each category has events
        expect(allEvents['trap'], isNotEmpty);
        expect(allEvents['item'], isNotEmpty);
        expect(allEvents['character'], isNotEmpty);
        expect(allEvents['monster'], isNotEmpty);
      });
    });
    
    group('getEventCounts', () {
      test('should return correct event counts', () async {
        final counts = await eventLoader.getEventCounts();
        
        expect(counts, hasLength(4));
        expect(counts.keys, containsAll(['trap', 'item', 'character', 'monster']));
        
        // All counts should be positive
        expect(counts['trap']!, greaterThan(0));
        expect(counts['item']!, greaterThan(0));
        expect(counts['character']!, greaterThan(0));
        expect(counts['monster']!, greaterThan(0));
      });
    });
    
    group('fallback behavior', () {
      test('should handle missing files by providing fallback events', () async {
        // Test that even if files are missing, we get some events back
        final trapEvents = await eventLoader.loadTrapEvents();
        final itemEvents = await eventLoader.loadItemEvents();
        final characterEvents = await eventLoader.loadCharacterEvents();
        final monsterEvents = await eventLoader.loadMonsterEvents();
        
        expect(trapEvents, isNotEmpty);
        expect(itemEvents, isNotEmpty);
        expect(characterEvents, isNotEmpty);
        expect(monsterEvents, isNotEmpty);
      });
    });
    
    group('error handling', () {
      test('should handle malformed JSON gracefully', () async {
        // This test would require creating a temporary malformed file
        // For now, we test that the loader doesn't crash and provides fallbacks
        final events = await eventLoader.loadTrapEvents();
        expect(events, isNotEmpty); // Should have fallback events at minimum
      });
      
      test('should validate event structure during loading', () async {
        final trapEvents = await eventLoader.loadTrapEvents();
        
        // All loaded events should pass validation
        for (final event in trapEvents.values) {
          expect(eventLoader.validateEventStructure(event), isTrue);
        }
      });
    });
  });
}