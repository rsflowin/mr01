import 'package:flutter_test/flutter_test.dart';
import 'package:mr01/models/maze_model.dart';

// Mock implementation for testing room descriptions
class MockGameScreen {
  Set<String> visitedRooms = {};
  
  String getRoomDescription(MazeRoom room) {
    // Generate contextual room descriptions based on room type and state
    String baseDescription = getBaseRoomDescription(room);
    
    // Add door availability descriptions in Korean
    String doorDescription = getDoorAvailabilityDescription(room);
    
    // Combine base description with door information
    String fullDescription = baseDescription;
    if (doorDescription.isNotEmpty) {
      fullDescription += '\n\n$doorDescription';
    }
    
    // Add room count information
    String roomCountInfo = getRoomCountDescription();
    if (roomCountInfo.isNotEmpty) {
      fullDescription += '\n\n$roomCountInfo';
    }
    
    return fullDescription;
  }
  
  String getBaseRoomDescription(MazeRoom room) {
    // Special descriptions for different room types
    if (room.isStart) {
      return '여기가 미로의 시작점입니다. 어둡고 차가운 돌벽으로 둘러싸인 이 방에서 당신의 모험이 시작됩니다. 출구를 찾아 미로를 탈출해야 합니다.';
    } else if (room.isExit) {
      return '축하합니다! 미로의 출구를 찾았습니다! 밝은 빛이 앞에서 당신을 기다리고 있습니다. 긴 여정이 드디어 끝났습니다.';
    } else if (visitedRooms.contains('${room.x},${room.y}')) {
      return '이미 방문한 적이 있는 방입니다. 익숙한 돌벽과 바닥의 모습이 기억을 되살려줍니다. 다른 길을 찾아보는 것이 좋겠습니다.';
    } else {
      // New room descriptions with variety
      final List<String> newRoomDescriptions = [
        '당신은 미로의 새로운 방에 들어섰습니다. 차가운 돌벽이 사방을 둘러싸고 있고, 희미한 빛이 어디선가 스며들어 옵니다.',
        '어둠 속에서 새로운 방이 모습을 드러냅니다. 오래된 돌벽에는 시간의 흔적이 새겨져 있고, 발걸음 소리가 메아리칩니다.',
        '미로의 또 다른 방입니다. 축축한 공기와 함께 신비로운 분위기가 감돕니다. 어느 방향으로 가야 할지 신중히 선택해야 합니다.',
        '새로운 공간이 펼쳐집니다. 고대의 돌로 만들어진 이 방은 수많은 모험가들의 발자취를 간직하고 있는 듯합니다.',
      ];
      
      // Use room coordinates to consistently select the same description for the same room
      final descriptionIndex = (room.x + room.y * 8) % newRoomDescriptions.length;
      return newRoomDescriptions[descriptionIndex];
    }
  }
  
  String getDoorAvailabilityDescription(MazeRoom room) {
    final List<String> availableDirections = [];
    final List<String> blockedDirections = [];
    
    // Check each direction and categorize
    if (room.north) {
      availableDirections.add('북쪽(위쪽)');
    } else {
      blockedDirections.add('북쪽(위쪽)');
    }
    
    if (room.east) {
      availableDirections.add('동쪽(오른쪽)');
    } else {
      blockedDirections.add('동쪽(오른쪽)');
    }
    
    if (room.south) {
      availableDirections.add('남쪽(아래쪽)');
    } else {
      blockedDirections.add('남쪽(아래쪽)');
    }
    
    if (room.west) {
      availableDirections.add('서쪽(왼쪽)');
    } else {
      blockedDirections.add('서쪽(왼쪽)');
    }
    
    String description = '';
    
    // Describe available doors
    if (availableDirections.isNotEmpty) {
      if (availableDirections.length == 1) {
        description += '${availableDirections[0]} 방향으로 나갈 수 있는 문이 있습니다.';
      } else if (availableDirections.length == 2) {
        description += '${availableDirections.join('과 ')} 방향으로 나갈 수 있는 문이 있습니다.';
      } else {
        final lastDirection = availableDirections.removeLast();
        description += '${availableDirections.join(', ')}, 그리고 $lastDirection 방향으로 나갈 수 있는 문이 있습니다.';
      }
    } else {
      description += '이용할 수 있는 문이 없습니다. 막다른 길인 것 같습니다.';
    }
    
    // Add information about blocked directions for context
    if (blockedDirections.isNotEmpty && availableDirections.isNotEmpty) {
      if (blockedDirections.length == 1) {
        description += ' ${blockedDirections[0]} 방향은 벽으로 막혀있습니다.';
      } else if (blockedDirections.length == 2) {
        description += ' ${blockedDirections.join('과 ')} 방향은 벽으로 막혀있습니다.';
      } else {
        final lastBlocked = blockedDirections.removeLast();
        description += ' ${blockedDirections.join(', ')}, 그리고 $lastBlocked 방향은 벽으로 막혀있습니다.';
      }
    }
    
    return description;
  }
  
  String getRoomCountDescription() {
    final totalRooms = 64; // 8x8 maze
    final visitedCount = visitedRooms.length;
    final explorationPercentage = ((visitedCount / totalRooms) * 100).round();
    
    return '탐험 진행도: $visitedCount/$totalRooms 방 ($explorationPercentage%)';
  }
}

void main() {
  group('Room Description Generation Tests', () {
    late MockGameScreen gameScreen;
    
    setUp(() {
      gameScreen = MockGameScreen();
    });
    
    test('should generate special description for start room', () {
      final startRoom = MazeRoom(
        x: 0, y: 0,
        north: true, east: false, south: false, west: false,
        isStart: true, isExit: false,
      );
      
      final description = gameScreen.getRoomDescription(startRoom);
      
      expect(description, contains('여기가 미로의 시작점입니다'));
      expect(description, contains('북쪽(위쪽) 방향으로 나갈 수 있는 문이 있습니다'));
      expect(description, contains('탐험 진행도: 0/64 방'));
    });
    
    test('should generate special description for exit room', () {
      final exitRoom = MazeRoom(
        x: 7, y: 7,
        north: false, east: false, south: true, west: false,
        isStart: false, isExit: true,
      );
      
      final description = gameScreen.getRoomDescription(exitRoom);
      
      expect(description, contains('축하합니다! 미로의 출구를 찾았습니다'));
      expect(description, contains('남쪽(아래쪽) 방향으로 나갈 수 있는 문이 있습니다'));
    });
    
    test('should generate special description for visited room', () {
      final visitedRoom = MazeRoom(
        x: 2, y: 3,
        north: true, east: true, south: false, west: false,
        isStart: false, isExit: false,
      );
      
      // Mark room as visited
      gameScreen.visitedRooms.add('2,3');
      
      final description = gameScreen.getRoomDescription(visitedRoom);
      
      expect(description, contains('이미 방문한 적이 있는 방입니다'));
      expect(description, contains('북쪽(위쪽)과 동쪽(오른쪽) 방향으로 나갈 수 있는 문이 있습니다'));
    });
    
    test('should generate Korean door availability descriptions', () {
      final roomWithMultipleDoors = MazeRoom(
        x: 3, y: 3,
        north: true, east: true, south: true, west: false,
        isStart: false, isExit: false,
      );
      
      final description = gameScreen.getRoomDescription(roomWithMultipleDoors);
      
      expect(description, contains('북쪽(위쪽), 동쪽(오른쪽), 그리고 남쪽(아래쪽) 방향으로 나갈 수 있는 문이 있습니다'));
      expect(description, contains('서쪽(왼쪽) 방향은 벽으로 막혀있습니다'));
    });
    
    test('should handle room with no doors', () {
      final deadEndRoom = MazeRoom(
        x: 4, y: 4,
        north: false, east: false, south: false, west: false,
        isStart: false, isExit: false,
      );
      
      final description = gameScreen.getRoomDescription(deadEndRoom);
      
      expect(description, contains('이용할 수 있는 문이 없습니다. 막다른 길인 것 같습니다'));
    });
    
    test('should include room count information', () {
      gameScreen.visitedRooms.addAll(['0,0', '1,0', '2,0']); // 3 visited rooms
      
      final room = MazeRoom(
        x: 1, y: 1,
        north: true, east: false, south: false, west: false,
        isStart: false, isExit: false,
      );
      
      final description = gameScreen.getRoomDescription(room);
      
      expect(description, contains('탐험 진행도: 3/64 방 (5%)'));
    });
    
    test('should provide consistent descriptions for same room coordinates', () {
      final room1 = MazeRoom(
        x: 1, y: 2,
        north: true, east: false, south: false, west: false,
        isStart: false, isExit: false,
      );
      
      final room2 = MazeRoom(
        x: 1, y: 2,
        north: false, east: true, south: false, west: false,
        isStart: false, isExit: false,
      );
      
      final description1 = gameScreen.getBaseRoomDescription(room1);
      final description2 = gameScreen.getBaseRoomDescription(room2);
      
      // Base descriptions should be the same for same coordinates
      expect(description1, equals(description2));
    });
  });
}