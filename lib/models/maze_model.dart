import 'dart:convert';

// Individual maze room model
class MazeRoom {
  final int x;
  final int y;
  final bool north;
  final bool east;
  final bool south;
  final bool west;
  final bool isStart;
  final bool isExit;

  MazeRoom({
    required this.x,
    required this.y,
    required this.north,
    required this.east,
    required this.south,
    required this.west,
    this.isStart = false,
    this.isExit = false,
  });

  bool canMoveTo(String direction) {
    switch (direction.toLowerCase()) {
      case 'north':
        return north;
      case 'east':
        return east;
      case 'south':
        return south;
      case 'west':
        return west;
      default:
        return false;
    }
  }

  factory MazeRoom.fromMap(Map<String, dynamic> map) {
    final doors = map['doors'] as Map<String, dynamic>? ?? {};
    
    return MazeRoom(
      x: map['x']?.toInt() ?? 0,
      y: map['y']?.toInt() ?? 0,
      north: doors['north'] ?? false,
      east: doors['east'] ?? false,
      south: doors['south'] ?? false,
      west: doors['west'] ?? false,
      isStart: map['isStart'] ?? false,
      isExit: map['isExit'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'x': x,
      'y': y,
      'north': north,
      'east': east,
      'south': south,
      'west': west,
      'isStart': isStart,
      'isExit': isExit,
    };
  }
}

// Complete maze model
class MazeData {
  final int id;
  final String name;
  final String difficulty;
  final List<List<MazeRoom>> grid; // 8x8 grid
  final MazeRoom startRoom;
  final MazeRoom exitRoom;

  MazeData({
    required this.id,
    required this.name,
    required this.difficulty,
    required this.grid,
    required this.startRoom,
    required this.exitRoom,
  });

  // Get room at specific coordinates
  MazeRoom? getRoomAt(int x, int y) {
    if (x < 0 || x >= 8 || y < 0 || y >= 8) return null;
    return grid[y][x];
  }

  // Get adjacent room in specific direction
  MazeRoom? getAdjacentRoom(int x, int y, String direction) {
    final currentRoom = getRoomAt(x, y);
    if (currentRoom == null || !currentRoom.canMoveTo(direction)) {
      return null;
    }

    switch (direction.toLowerCase()) {
      case 'north':
        return getRoomAt(x, y - 1);
      case 'east':
        return getRoomAt(x + 1, y);
      case 'south':
        return getRoomAt(x, y + 1);
      case 'west':
        return getRoomAt(x - 1, y);
      default:
        return null;
    }
  }

  factory MazeData.fromMap(Map<String, dynamic> map) {
    final roomsData = map['rooms'] as List<dynamic>;
    
    // Get start and exit positions from the JSON
    final startPosition = map['startPosition'] as List<dynamic>?;
    final exitPosition = map['exitPosition'] as List<dynamic>?;
    
    final startX = startPosition?[0]?.toInt() ?? 0;
    final startY = startPosition?[1]?.toInt() ?? 7;
    final exitX = exitPosition?[0]?.toInt() ?? 7;
    final exitY = exitPosition?[1]?.toInt() ?? 0;
    
    // Create 8x8 grid
    List<List<MazeRoom>> grid = List.generate(
      8, 
      (y) => List.generate(8, (x) => MazeRoom(x: x, y: y, north: false, east: false, south: false, west: false))
    );
    
    MazeRoom? startRoom;
    MazeRoom? exitRoom;
    
    // Populate grid with room data
    for (final roomData in roomsData) {
      final roomMap = roomData as Map<String, dynamic>;
      final doors = roomMap['doors'] as Map<String, dynamic>;
      
      final room = MazeRoom(
        x: roomMap['x']?.toInt() ?? 0,
        y: roomMap['y']?.toInt() ?? 0,
        north: doors['north'] ?? false,
        east: doors['east'] ?? false,
        south: doors['south'] ?? false,
        west: doors['west'] ?? false,
        isStart: roomMap['isStart'] ?? false,
        isExit: roomMap['isExit'] ?? false,
      );
      
      grid[room.y][room.x] = room;
      
      // Set start and exit rooms based on positions from JSON
      if (room.x == startX && room.y == startY) {
        startRoom = room;
      }
      if (room.x == exitX && room.y == exitY) {
        exitRoom = room;
      }
    }

    return MazeData(
      id: map['id']?.hashCode ?? 1,
      name: map['name'] ?? 'Unnamed Maze',
      difficulty: 'Normal', // Not in JSON, set default
      grid: grid,
      startRoom: startRoom ?? grid[startY][startX],
      exitRoom: exitRoom ?? grid[exitY][exitX],
    );
  }

  Map<String, dynamic> toMap() {
    final List<Map<String, dynamic>> roomsData = [];
    
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        roomsData.add(grid[y][x].toMap());
      }
    }

    return {
      'id': id,
      'name': name,
      'difficulty': difficulty,
      'rooms': roomsData,
    };
  }

  String toJson() => json.encode(toMap());

  factory MazeData.fromJson(String source) =>
      MazeData.fromMap(json.decode(source) as Map<String, dynamic>);
}