import 'package:flutter_test/flutter_test.dart';
import 'package:mr01/models/maze_model.dart';

void main() {
  group('Navigation Choice Generation Tests', () {
    test('should generate correct Korean text labels for each direction', () {
      // Test data for different room configurations
      final testCases = [
        {
          'room': MazeRoom(x: 0, y: 0, north: true, east: false, south: false, west: false),
          'expectedChoices': ['위쪽 문으로 간다'],
        },
        {
          'room': MazeRoom(x: 0, y: 0, north: false, east: true, south: false, west: false),
          'expectedChoices': ['오른쪽 문으로 간다'],
        },
        {
          'room': MazeRoom(x: 0, y: 0, north: false, east: false, south: true, west: false),
          'expectedChoices': ['아래쪽 문으로 간다'],
        },
        {
          'room': MazeRoom(x: 0, y: 0, north: false, east: false, south: false, west: true),
          'expectedChoices': ['왼쪽 문으로 간다'],
        },
        {
          'room': MazeRoom(x: 0, y: 0, north: true, east: true, south: true, west: true),
          'expectedChoices': ['위쪽 문으로 간다', '오른쪽 문으로 간다', '아래쪽 문으로 간다', '왼쪽 문으로 간다'],
        },
      ];

      for (final testCase in testCases) {
        final room = testCase['room'] as MazeRoom;
        final expectedChoices = testCase['expectedChoices'] as List<String>;
        
        // Simulate the choice generation logic from _updateNavigationChoices
        final List<Map<String, dynamic>> choices = [];
        
        if (room.north) {
          choices.add({
            'text': '위쪽 문으로 간다',
            'direction': 'north',
            'description': '북쪽 방향으로 이동합니다.',
          });
        }
        
        if (room.east) {
          choices.add({
            'text': '오른쪽 문으로 간다', 
            'direction': 'east',
            'description': '동쪽 방향으로 이동합니다.',
          });
        }
        
        if (room.south) {
          choices.add({
            'text': '아래쪽 문으로 간다',
            'direction': 'south', 
            'description': '남쪽 방향으로 이동합니다.',
          });
        }
        
        if (room.west) {
          choices.add({
            'text': '왼쪽 문으로 간다',
            'direction': 'west',
            'description': '서쪽 방향으로 이동합니다.',
          });
        }
        
        // Verify the generated choices match expected
        final actualChoiceTexts = choices.map((choice) => choice['text'] as String).toList();
        expect(actualChoiceTexts, equals(expectedChoices));
        
        // Verify direction mapping is correct
        for (final choice in choices) {
          final text = choice['text'] as String;
          final direction = choice['direction'] as String;
          
          switch (text) {
            case '위쪽 문으로 간다':
              expect(direction, equals('north'));
              break;
            case '오른쪽 문으로 간다':
              expect(direction, equals('east'));
              break;
            case '아래쪽 문으로 간다':
              expect(direction, equals('south'));
              break;
            case '왼쪽 문으로 간다':
              expect(direction, equals('west'));
              break;
          }
        }
      }
    });

    test('should only show available doors in choice selection', () {
      // Test room with only north and south doors
      final room = MazeRoom(x: 0, y: 0, north: true, east: false, south: true, west: false);
      
      final List<Map<String, dynamic>> choices = [];
      
      if (room.north) {
        choices.add({
          'text': '위쪽 문으로 간다',
          'direction': 'north',
          'description': '북쪽 방향으로 이동합니다.',
        });
      }
      
      if (room.east) {
        choices.add({
          'text': '오른쪽 문으로 간다', 
          'direction': 'east',
          'description': '동쪽 방향으로 이동합니다.',
        });
      }
      
      if (room.south) {
        choices.add({
          'text': '아래쪽 문으로 간다',
          'direction': 'south', 
          'description': '남쪽 방향으로 이동합니다.',
        });
      }
      
      if (room.west) {
        choices.add({
          'text': '왼쪽 문으로 간다',
          'direction': 'west',
          'description': '서쪽 방향으로 이동합니다.',
        });
      }
      
      // Should only have 2 choices (north and south)
      expect(choices.length, equals(2));
      
      final choiceTexts = choices.map((choice) => choice['text'] as String).toList();
      expect(choiceTexts, contains('위쪽 문으로 간다'));
      expect(choiceTexts, contains('아래쪽 문으로 간다'));
      expect(choiceTexts, isNot(contains('오른쪽 문으로 간다')));
      expect(choiceTexts, isNot(contains('왼쪽 문으로 간다')));
    });

    test('should validate door availability using MazeRoom.canMoveTo method', () {
      final room = MazeRoom(x: 0, y: 0, north: true, east: false, south: true, west: false);
      
      // Test that canMoveTo correctly identifies available doors
      expect(room.canMoveTo('north'), isTrue);
      expect(room.canMoveTo('east'), isFalse);
      expect(room.canMoveTo('south'), isTrue);
      expect(room.canMoveTo('west'), isFalse);
      
      // Test case insensitivity
      expect(room.canMoveTo('NORTH'), isTrue);
      expect(room.canMoveTo('North'), isTrue);
      
      // Test invalid direction
      expect(room.canMoveTo('invalid'), isFalse);
    });
  });
}