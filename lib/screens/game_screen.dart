import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/game_state.dart';
import '../models/maze_model.dart';
import '../services/game_manager.dart';
import 'ending_screen.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  late AnimationController _textController;
  late Animation<double> _fadeAnimation;
  late PageController _pageController;
  
  // Game state management
  GameState? gameState;
  MazeData? mazeData;
  bool isLoading = true;
  int currentPageIndex = 2; // Start at main screen (now at index 2)
  int playerX = 0; // Player position
  int playerY = 0;
  Set<String> visitedRooms = {}; // Track visited rooms ("x,y" format)
  bool hasReachedExit = false;
  
  @override
  void initState() {
    super.initState();
    
    _textController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textController,
      curve: Curves.easeInOut,
    ));
    
    _pageController = PageController(initialPage: 2); // Start at main screen
    
    _initializeGame();
  }
  
  Future<void> _initializeGame() async {
    // Initialize game state first
    await _initializeGameState();
    
    // Setup navigation choices for current room
    _updateNavigationChoices();
  }

  Future<void> _initializeGameState() async {
    print('=== GAME SCREEN INITIALIZATION ===');
    print('GameManager initialized: ${GameManager().isInitialized}');
    print('GameManager initializing: ${GameManager().isInitializing}');
    
    // Wait for GameManager to be ready if not already initialized
    while (!GameManager().isInitialized) {
      print('Waiting for GameManager to initialize...');
      await Future.delayed(const Duration(milliseconds: 100));
    }
    
    print('GameManager ready! Getting data...');
    
    // Get game state and maze from GameManager
    gameState = GameManager().gameState;
    mazeData = GameManager().currentMaze;
    
    print('GameState: ${gameState != null ? "loaded" : "null"}');
    print('MazeData: ${mazeData != null ? "loaded" : "null"}');
    
    // Set player starting position
    if (mazeData != null) {
      // Initialize player position at maze starting room
      playerX = mazeData!.startRoom.x;
      playerY = mazeData!.startRoom.y;
      
      // Clear any previous visited rooms and mark starting room as visited
      visitedRooms.clear();
      visitedRooms.add('$playerX,$playerY');
      
      // Reset victory condition
      hasReachedExit = false;
      
      print('=== MAZE DATA LOADED ===');
      print('Maze name: ${mazeData!.name}');
      print('Start room coordinates: (${mazeData!.startRoom.x}, ${mazeData!.startRoom.y})');
      print('Exit room coordinates: (${mazeData!.exitRoom.x}, ${mazeData!.exitRoom.y})');
      print('Player position set to: ($playerX, $playerY)');
      print('Starting room marked as visited: ${visitedRooms.contains('$playerX,$playerY')}');
      print('Victory condition reset: $hasReachedExit');
      print('Start room isStart: ${mazeData!.startRoom.isStart}');
      print('Exit room isExit: ${mazeData!.exitRoom.isExit}');
      print('========================');
    } else {
      print('ERROR: MazeData is null!'); // Debug
    }
    
    setState(() {
      isLoading = false;
    });
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _pageController.dispose();
    super.dispose();
  }
  
  void _updateNavigationChoices() {
    try {
      // Comprehensive null checks and validation
      if (mazeData == null) {
        print('ERROR: _updateNavigationChoices called with null mazeData');
        _handleNavigationError('Maze data is not available');
        return;
      }
      
      // Validate player position is within bounds
      if (!_isValidPosition(playerX, playerY)) {
        print('ERROR: Invalid player position ($playerX, $playerY) in _updateNavigationChoices');
        _recoverFromInvalidPosition();
        return;
      }
      
      final currentRoom = mazeData!.getRoomAt(playerX, playerY);
      if (currentRoom == null) {
        print('ERROR: Current room is null at position ($playerX, $playerY)');
        _recoverFromInvalidPosition();
        return;
      }
      
      print('INFO: Updating navigation choices for room at ($playerX, $playerY)');
      
      // Check for victory condition
      if (currentRoom.isExit && !hasReachedExit) {
        print('INFO: Player reached exit room - triggering victory');
        hasReachedExit = true;
        _showVictoryScreen();
        return;
      }
      
      // If already reached exit, don't show navigation choices
      if (hasReachedExit) {
        print('INFO: Player has already reached exit - no navigation choices shown');
        return;
      }
      
      // Create navigation choices based on available doors
      final List<Map<String, dynamic>> choices = [];
      
      if (currentRoom.north) {
        choices.add({
          'text': '위쪽 문으로 간다',
          'direction': 'north',
          'description': '북쪽 방향으로 이동합니다.',
        });
      }
      
      if (currentRoom.east) {
        choices.add({
          'text': '오른쪽 문으로 간다', 
          'direction': 'east',
          'description': '동쪽 방향으로 이동합니다.',
        });
      }
      
      if (currentRoom.south) {
        choices.add({
          'text': '아래쪽 문으로 간다',
          'direction': 'south', 
          'description': '남쪽 방향으로 이동합니다.',
        });
      }
      
      if (currentRoom.west) {
        choices.add({
          'text': '왼쪽 문으로 간다',
          'direction': 'west',
          'description': '서쪽 방향으로 이동합니다.',
        });
      }
      
      print('INFO: Generated ${choices.length} navigation choices');
      
      // Validate we have at least one choice or handle dead end
      if (choices.isEmpty) {
        print('WARNING: No navigation choices available - player may be in dead end');
        _handleDeadEnd(currentRoom);
        return;
      }
      
      setState(() {
        if (gameState != null) {
          gameState!.currentEvent = {
            'name': '현재 위치: (${playerX}, ${playerY})',
            'description': _getRoomDescription(currentRoom),
            'image': 'room_interior.png',
            'choices': choices,
          };
        } else {
          print('WARNING: gameState is null when updating navigation choices');
        }
      });
      
      _textController.forward();
      
    } catch (e, stackTrace) {
      print('ERROR: Exception in _updateNavigationChoices: $e');
      print('Stack trace: $stackTrace');
      _handleNavigationError('Failed to update navigation options');
    }
  }
  
  void _onChoiceSelected(Map<String, dynamic> choice) {
    try {
      print('INFO: Choice selection initiated');
      
      // Validate choice parameter
      if (choice.isEmpty) {
        print('ERROR: Empty choice provided to _onChoiceSelected');
        _handleChoiceError('Invalid choice selection');
        return;
      }
      
      // Provide immediate visual feedback by showing selection state
      setState(() {
        // Reset text animation to provide visual feedback
        _textController.reset();
      });
      
      // Extract direction from choice data structure with validation
      final direction = choice['direction'] as String?;
      final choiceText = choice['text'] as String?;
      final description = choice['description'] as String?;
      
      // Validate that we have a direction-based choice
      if (direction == null || direction.isEmpty) {
        print('ERROR: Choice selected without valid direction: $choice');
        _handleChoiceError('Invalid navigation choice');
        return;
      }
      
      // Validate that the direction is one of the expected values
      final validDirections = ['north', 'east', 'south', 'west'];
      if (!validDirections.contains(direction.toLowerCase())) {
        print('ERROR: Invalid direction selected: $direction');
        _handleChoiceError('Invalid movement direction');
        return;
      }
      
      // Log choice selection for debugging
      print('INFO: Choice selected - Text: "$choiceText", Direction: "$direction"');
      if (description != null) {
        print('INFO: Choice description: "$description"');
      }
      
      // Comprehensive validation before movement
      if (mazeData == null) {
        print('ERROR: Cannot process choice - mazeData is null');
        _handleChoiceError('Game data unavailable');
        return;
      }
      
      if (!_isValidPosition(playerX, playerY)) {
        print('ERROR: Cannot process choice - invalid player position ($playerX, $playerY)');
        _recoverFromInvalidPosition();
        return;
      }
      
      final currentRoom = mazeData!.getRoomAt(playerX, playerY);
      if (currentRoom == null) {
        print('ERROR: Cannot process choice - current room is null at ($playerX, $playerY)');
        _recoverFromInvalidPosition();
        return;
      }
      
      // Validate that movement is possible before attempting
      if (!currentRoom.canMoveTo(direction)) {
        print('WARNING: Attempted to move in direction "$direction" but no door available');
        _handleChoiceError('Movement not possible in that direction');
        return;
      }
      
      // Validate destination exists
      final destinationRoom = mazeData!.getAdjacentRoom(playerX, playerY, direction);
      if (destinationRoom == null) {
        print('ERROR: Destination room is null for direction "$direction" from ($playerX, $playerY)');
        _handleChoiceError('Cannot reach destination');
        return;
      }
      
      print('INFO: All validations passed - triggering movement');
      
      // Trigger movement for directional choice
      _movePlayer(direction);
      
      // Provide immediate visual feedback by restarting text animation
      // This will be called after _movePlayer updates the room description
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _textController.forward();
        }
      });
      
    } catch (e, stackTrace) {
      print('ERROR: Exception in _onChoiceSelected: $e');
      print('Stack trace: $stackTrace');
      _handleChoiceError('Failed to process choice selection');
    }
  }
  
  String _getRoomDescription(MazeRoom room) {
    try {
      // Validate room parameter
      if (room == null) {
        print('ERROR: _getRoomDescription called with null room');
        return '방 정보를 불러올 수 없습니다.';
      }
      
      // Generate contextual room descriptions based on room type and state
      String baseDescription = _getBaseRoomDescription(room);
      
      // Add door availability descriptions in Korean
      String doorDescription = _getDoorAvailabilityDescription(room);
      
      // Combine base description with door information
      String fullDescription = baseDescription;
      if (doorDescription.isNotEmpty) {
        fullDescription += '\n\n$doorDescription';
      }
      
      // Add room count information
      String roomCountInfo = _getRoomCountDescription();
      if (roomCountInfo.isNotEmpty) {
        fullDescription += '\n\n$roomCountInfo';
      }
      
      return fullDescription;
    } catch (e, stackTrace) {
      print('ERROR: Exception in _getRoomDescription: $e');
      print('Stack trace: $stackTrace');
      return '방 설명을 생성하는 중 오류가 발생했습니다.';
    }
  }
  
  String _getBaseRoomDescription(MazeRoom room) {
    try {
      // Validate room parameter
      if (room == null) {
        print('ERROR: _getBaseRoomDescription called with null room');
        return '방 정보를 불러올 수 없습니다.';
      }
      
      // Special descriptions for different room types
      if (room.isStart) {
        return '여기가 미로의 시작점입니다. 어둡고 차가운 돌벽으로 둘러싸인 이 방에서 당신의 모험이 시작됩니다. 출구를 찾아 미로를 탈출해야 합니다.';
      } else if (room.isExit) {
        return '축하합니다! 미로의 출구를 찾았습니다! 밝은 빛이 앞에서 당신을 기다리고 있습니다. 긴 여정이 드디어 끝났습니다.';
      } else {
        // Room descriptions with variety - no distinction between visited and new rooms
        final List<String> roomDescriptions = [
          '당신은 미로의 방에 들어섰습니다. 차가운 돌벽이 사방을 둘러싸고 있고, 희미한 빛이 어디선가 스며들어 옵니다.',
          '어둠 속에서 방이 모습을 드러냅니다. 오래된 돌벽에는 시간의 흔적이 새겨져 있고, 발걸음 소리가 메아리칩니다.',
          '미로의 또 다른 방입니다. 축축한 공기와 함께 신비로운 분위기가 감돕니다. 어느 방향으로 가야 할지 신중히 선택해야 합니다.',
          '고대의 돌로 만들어진 이 방은 수많은 모험가들의 발자취를 간직하고 있는 듯합니다. 조심스럽게 주변을 살펴봅니다.',
        ];
        
        // Use room coordinates to consistently select the same description for the same room
        final descriptionIndex = (room.x + room.y * 8) % roomDescriptions.length;
        return roomDescriptions[descriptionIndex];
      }
    } catch (e, stackTrace) {
      print('ERROR: Exception in _getBaseRoomDescription: $e');
      print('Stack trace: $stackTrace');
      return '방 설명을 생성하는 중 오류가 발생했습니다.';
    }
  }
  
  String _getDoorAvailabilityDescription(MazeRoom room) {
    try {
      // Validate room parameter
      if (room == null) {
        print('ERROR: _getDoorAvailabilityDescription called with null room');
        return '문 정보를 불러올 수 없습니다.';
      }
      
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
    } catch (e, stackTrace) {
      print('ERROR: Exception in _getDoorAvailabilityDescription: $e');
      print('Stack trace: $stackTrace');
      return '문 정보를 생성하는 중 오류가 발생했습니다.';
    }
  }
  
  String _getRoomCountDescription() {
    try {
      // Validate visitedRooms set
      if (visitedRooms == null) {
        print('ERROR: visitedRooms is null in _getRoomCountDescription');
        return '탐험 진행도를 불러올 수 없습니다.';
      }
      
      final totalRooms = 64; // 8x8 maze
      final visitedCount = visitedRooms.length;
      
      // Validate visitedCount is reasonable
      if (visitedCount < 0 || visitedCount > totalRooms) {
        print('WARNING: Invalid visited room count: $visitedCount');
        return '탐험 진행도: 정보 오류';
      }
      
      final explorationPercentage = totalRooms > 0 ? ((visitedCount / totalRooms) * 100).round() : 0;
      
      return '탐험 진행도: $visitedCount/$totalRooms 방 ($explorationPercentage%)';
    } catch (e, stackTrace) {
      print('ERROR: Exception in _getRoomCountDescription: $e');
      print('Stack trace: $stackTrace');
      return '탐험 진행도를 계산하는 중 오류가 발생했습니다.';
    }
  }
  
  void _movePlayer(String direction) {
    try {
      print('INFO: _movePlayer called with direction: $direction');
      
      // Validate maze data exists
      if (mazeData == null) {
        print('ERROR: Cannot move player - maze data is null');
        _handleNavigationError('Game data unavailable for movement');
        return;
      }
      
      // Validate direction parameter
      if (direction.isEmpty) {
        print('ERROR: Cannot move player - direction is empty');
        _handleNavigationError('Invalid movement direction');
        return;
      }
      
      final validDirections = ['north', 'east', 'south', 'west'];
      if (!validDirections.contains(direction.toLowerCase())) {
        print('ERROR: Invalid direction: $direction');
        _handleNavigationError('Invalid movement direction');
        return;
      }
      
      // Validate current player position
      if (!_isValidPosition(playerX, playerY)) {
        print('ERROR: Cannot move player - invalid current position ($playerX, $playerY)');
        _recoverFromInvalidPosition();
        return;
      }
      
      // Get current room and validate movement
      final currentRoom = mazeData!.getRoomAt(playerX, playerY);
      if (currentRoom == null) {
        print('ERROR: Cannot move player - current room is null at ($playerX, $playerY)');
        _recoverFromInvalidPosition();
        return;
      }
      
      if (!currentRoom.canMoveTo(direction)) {
        print('WARNING: Cannot move $direction from ($playerX, $playerY) - no door available');
        _handleNavigationError('No door available in that direction');
        return;
      }
      
      // Calculate new position based on direction
      int newX = playerX;
      int newY = playerY;
      
      switch (direction.toLowerCase()) {
        case 'north':
          newY = playerY - 1;
          break;
        case 'east':
          newX = playerX + 1;
          break;
        case 'south':
          newY = playerY + 1;
          break;
        case 'west':
          newX = playerX - 1;
          break;
        default:
          print('ERROR: Invalid direction in switch: $direction');
          _handleNavigationError('Invalid movement direction');
          return;
      }
      
      // Validate new position is within maze bounds (8x8 grid)
      if (!_isValidPosition(newX, newY)) {
        print('ERROR: Movement would go outside maze bounds: ($newX, $newY)');
        _handleNavigationError('Cannot move outside maze boundaries');
        return;
      }
      
      // Verify destination room exists
      final newRoom = mazeData!.getRoomAt(newX, newY);
      if (newRoom == null) {
        print('ERROR: Destination room is null at ($newX, $newY)');
        _handleNavigationError('Destination room is not accessible');
        return;
      }
      
      print('INFO: Moving player from ($playerX, $playerY) to ($newX, $newY) via $direction');
      
      // Store previous position for potential recovery
      final previousX = playerX;
      final previousY = playerY;
      
      // Update player position and mark room as visited
      setState(() {
        playerX = newX;
        playerY = newY;
        visitedRooms.add('$newX,$newY');
        
        // Check for victory condition
        if (newRoom.isExit) {
          hasReachedExit = true;
          print('INFO: Player reached exit room - victory condition set');
        }
      });
      
      print('INFO: Player now at ($playerX, $playerY), visited rooms: ${visitedRooms.length}');
      
      // Validate the move was successful
      if (playerX != newX || playerY != newY) {
        print('ERROR: Player position update failed - expected ($newX, $newY), got ($playerX, $playerY)');
        // Attempt to recover by restoring previous position
        setState(() {
          playerX = previousX;
          playerY = previousY;
        });
        _handleNavigationError('Movement failed - position restored');
        return;
      }
      
      // Update navigation choices for new room
      _updateNavigationChoices();
      
    } catch (e, stackTrace) {
      print('ERROR: Exception in _movePlayer: $e');
      print('Stack trace: $stackTrace');
      _handleNavigationError('Movement failed due to unexpected error');
    }
  }
  
  void _showVictoryScreen() {
    try {
      print('INFO: Showing victory screen');
      // Navigate to ending screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => EndingScreen(
            visitedRoomsCount: visitedRooms.length,
            totalRooms: 64,
          ),
        ),
      );
    } catch (e, stackTrace) {
      print('ERROR: Failed to show victory screen: $e');
      print('Stack trace: $stackTrace');
      _handleNavigationError('Failed to display victory screen');
    }
  }
  
  // Helper method to validate position coordinates
  bool _isValidPosition(int x, int y) {
    return x >= 0 && x < 8 && y >= 0 && y < 8;
  }
  
  // Error handling for navigation issues
  void _handleNavigationError(String message) {
    print('NAVIGATION ERROR: $message');
    
    try {
      setState(() {
        if (gameState != null) {
          gameState!.currentEvent = {
            'name': '오류 발생',
            'description': '네비게이션 중 문제가 발생했습니다: $message\n\n게임을 다시 시작하거나 이전 위치로 돌아가세요.',
            'image': 'error.png',
            'choices': [
              {
                'text': '현재 위치에서 계속하기',
                'direction': 'stay',
                'description': '현재 위치에서 게임을 계속합니다.',
              }
            ],
          };
        }
      });
      
      _textController.forward();
    } catch (e) {
      print('ERROR: Failed to display navigation error: $e');
      // Last resort - try to reinitialize the game
      _initializeGame();
    }
  }
  
  // Error handling for choice selection issues
  void _handleChoiceError(String message) {
    print('CHOICE ERROR: $message');
    
    try {
      // Restart animation for visual feedback
      _textController.forward();
      
      // Optionally show error message to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('선택 오류: $message'),
            backgroundColor: const Color(0xFF8B0000),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('ERROR: Failed to handle choice error: $e');
    }
  }
  
  // Handle dead end situations
  void _handleDeadEnd(MazeRoom room) {
    print('INFO: Player in dead end at (${room.x}, ${room.y})');
    
    try {
      setState(() {
        if (gameState != null) {
          gameState!.currentEvent = {
            'name': '막다른 길',
            'description': '이곳은 막다른 길입니다. 더 이상 갈 곳이 없습니다.\n\n이전에 방문한 방으로 돌아가거나 다른 경로를 찾아보세요.',
            'image': 'dead_end.png',
            'choices': [
              {
                'text': '이전 위치로 돌아가기',
                'direction': 'back',
                'description': '이전에 방문한 방으로 돌아갑니다.',
              }
            ],
          };
        }
      });
      
      _textController.forward();
    } catch (e) {
      print('ERROR: Failed to handle dead end: $e');
      _handleNavigationError('Failed to handle dead end situation');
    }
  }
  
  // Recovery mechanism for invalid player positions
  void _recoverFromInvalidPosition() {
    print('INFO: Attempting to recover from invalid player position ($playerX, $playerY)');
    
    try {
      // Try to find a valid position to recover to
      MazeRoom? recoveryRoom;
      int recoveryX = 0;
      int recoveryY = 0;
      
      // First, try to use the start room
      if (mazeData != null) {
        recoveryRoom = mazeData!.startRoom;
        recoveryX = recoveryRoom.x;
        recoveryY = recoveryRoom.y;
        print('INFO: Attempting recovery to start room at ($recoveryX, $recoveryY)');
      }
      
      // If start room is not available, find any valid room
      if (recoveryRoom == null && mazeData != null) {
        for (int y = 0; y < 8; y++) {
          for (int x = 0; x < 8; x++) {
            final testRoom = mazeData!.getRoomAt(x, y);
            if (testRoom != null) {
              recoveryRoom = testRoom;
              recoveryX = x;
              recoveryY = y;
              print('INFO: Found recovery room at ($recoveryX, $recoveryY)');
              break;
            }
          }
          if (recoveryRoom != null) break;
        }
      }
      
      // Apply recovery if we found a valid room
      if (recoveryRoom != null) {
        setState(() {
          playerX = recoveryX;
          playerY = recoveryY;
          visitedRooms.add('$recoveryX,$recoveryY');
          hasReachedExit = false; // Reset victory condition during recovery
        });
        
        print('INFO: Successfully recovered player position to ($playerX, $playerY)');
        _updateNavigationChoices();
      } else {
        print('ERROR: Could not find any valid room for recovery');
        _handleNavigationError('Unable to recover player position');
      }
      
    } catch (e, stackTrace) {
      print('ERROR: Exception during position recovery: $e');
      print('Stack trace: $stackTrace');
      
      // Last resort - reinitialize the entire game
      print('INFO: Attempting full game reinitialization as last resort');
      _initializeGame();
    }
  }
  
  Widget _buildStatusBar() {
    return Container(
      height: 100,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border.all(
          color: const Color(0xFF8B0000).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Main stats row
          Row(
            children: gameState != null ? [
              _buildStatBar('HP', gameState!.stats.hp, const Color(0xFF8B0000)),
              const SizedBox(width: 12),
              _buildStatBar('SAN', gameState!.stats.san, const Color(0xFF4169E1)),
              const SizedBox(width: 12),
              _buildStatBar('FIT', gameState!.stats.fit, const Color(0xFF32CD32)),
              const SizedBox(width: 12),
              _buildStatBar('HUNGER', gameState!.stats.hunger, const Color(0xFFFF8C00)),
            ] : [
              _buildStatBar('HP', 100, const Color(0xFF8B0000)),
              const SizedBox(width: 12),
              _buildStatBar('SAN', 100, const Color(0xFF4169E1)),
              const SizedBox(width: 12),
              _buildStatBar('FIT', 70, const Color(0xFF32CD32)),
              const SizedBox(width: 12),
              _buildStatBar('HUNGER', 80, const Color(0xFFFF8C00)),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Status effects row - no "Status:" label
          if (gameState != null && gameState!.statusEffects.isNotEmpty)
            Expanded(
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: gameState!.statusEffects.map((status) => 
                  _buildStatusEffect(status)
                ).toList(),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatBar(String label, int value, Color color) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFD4D4D4),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: const Color(0xFF333333),
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: value / 100,
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatusEffect(StatusEffect status) {
    final isBuff = status.isBuff;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isBuff 
          ? const Color(0xFF32CD32).withOpacity(0.2)
          : const Color(0xFF8B0000).withOpacity(0.2),
        border: Border.all(
          color: isBuff 
            ? const Color(0xFF32CD32).withOpacity(0.5)
            : const Color(0xFF8B0000).withOpacity(0.5),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isBuff ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: isBuff ? const Color(0xFF32CD32) : const Color(0xFF8B0000),
          ),
          const SizedBox(width: 2),
          Text(
            status.name,
            style: TextStyle(
              color: isBuff ? const Color(0xFF32CD32) : const Color(0xFF8B0000),
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            '(${status.remainingDuration})',
            style: const TextStyle(
              color: Color(0xFF888888),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRoomVisualization() {
    try {
      // Comprehensive null checks and validation
      if (mazeData == null) {
        print('WARNING: _buildRoomVisualization called with null mazeData');
        return _buildErrorVisualization('Maze data unavailable');
      }
      
      if (!_isValidPosition(playerX, playerY)) {
        print('WARNING: _buildRoomVisualization called with invalid position ($playerX, $playerY)');
        return _buildErrorVisualization('Invalid player position');
      }
      
      final currentRoom = mazeData!.getRoomAt(playerX, playerY);
      if (currentRoom == null) {
        print('WARNING: _buildRoomVisualization - current room is null at ($playerX, $playerY)');
        return _buildErrorVisualization('Room data unavailable');
      }
      
      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        height: 240, // Increased from 200 to 240 to accommodate larger room structure
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: const Color(0xFF8B0000).withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Background pattern
            CustomPaint(
              painter: EventImagePainter(),
              size: Size.infinite,
            ),
            // Room visualization with smooth transitions - increased size
            Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                width: 180, // Increased from 120 to 180
                height: 180, // Increased from 120 to 180
                child: CustomPaint(
                  painter: CurrentRoomPainter(room: currentRoom),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      transitionBuilder: (Widget child, Animation<double> animation) {
                        return ScaleTransition(
                          scale: animation,
                          child: FadeTransition(
                            opacity: animation,
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        key: ValueKey('room_${playerX}_${playerY}'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          TweenAnimationBuilder<double>(
                            duration: const Duration(milliseconds: 400),
                            tween: Tween(begin: 0.8, end: 1.0),
                            builder: (context, scale, child) {
                              return Transform.scale(
                                scale: scale,
                                child: Icon(
                                  currentRoom.isStart
                                      ? Icons.home
                                      : currentRoom.isExit
                                          ? Icons.flag
                                          : Icons.person,
                                  size: 40, // Increased from 32 to 40
                                  color: currentRoom.isStart
                                      ? const Color(0xFF0066CC)
                                      : currentRoom.isExit
                                          ? const Color(0xFF8B0000)
                                          : const Color(0xFF00AA00),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 6), // Increased spacing
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 200),
                            style: const TextStyle(
                              color: Color(0xFFD4D4D4),
                              fontSize: 14, // Increased from 12 to 14
                              fontWeight: FontWeight.bold,
                            ),
                            child: Text('($playerX, $playerY)'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Subtle pulse animation for current room - adjusted for larger size
            if (!hasReachedExit)
              Center(
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 2000),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Container(
                      width: 180 + (math.sin(value * math.pi * 2) * 6), // Adjusted for larger size
                      height: 180 + (math.sin(value * math.pi * 2) * 6), // Adjusted for larger size
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF00AA00).withOpacity(
                            0.3 + (math.sin(value * math.pi * 2) * 0.2)
                          ),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                  onEnd: () {
                    // Restart the animation
                    if (mounted && !hasReachedExit) {
                      setState(() {});
                    }
                  },
                ),
              ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      print('ERROR: Exception in _buildRoomVisualization: $e');
      print('Stack trace: $stackTrace');
      return _buildErrorVisualization('Visualization error');
    }
  }
  
  // Build minimap for navigation choices
  Widget _buildMiniMap() {
    if (mazeData == null) return const SizedBox.shrink();
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: 180, // Increased from 120 to 180 (50% larger)
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16), // Increased margin
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12), // Slightly larger border radius
        border: Border.all(
          color: const Color(0xFF8B0000).withOpacity(0.4), // Slightly more visible border
          width: 1.5, // Thicker border
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3), // Stronger shadow
            blurRadius: 6, // Increased blur
            offset: const Offset(0, 3), // Larger offset
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12), // Increased padding
        child: Column(
          children: [
            // Minimap title
            Text(
              'Mini Map',
              style: const TextStyle(
                color: Color(0xFFD4D4D4),
                fontSize: 14, // Increased from 12 to 14
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8), // Increased spacing
            // Minimap grid
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(6), // Slightly larger border radius
                    border: Border.all(
                      color: const Color(0xFF444444), // Added subtle border to grid
                      width: 1,
                    ),
                  ),
                  child: CustomPaint(
                    painter: MiniMapPainter(
                      mazeData: mazeData!,
                      playerX: playerX,
                      playerY: playerY,
                      visitedRooms: visitedRooms,
                    ),
                    size: Size.infinite,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper method to build error visualization
  Widget _buildErrorVisualization(String errorMessage) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF8B0000).withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B0000).withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(errorMessage),
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<double>(
                duration: const Duration(milliseconds: 500),
                tween: Tween(begin: 0.0, end: 1.0),
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: 0.8 + (value * 0.2),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Color.lerp(
                        const Color(0xFF8B0000).withOpacity(0.5),
                        const Color(0xFF8B0000),
                        value,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: const TextStyle(
                  color: Color(0xFF8B0000),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                child: const Text('Visualization Error'),
              ),
              const SizedBox(height: 8),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: const TextStyle(
                  color: Color(0xFFD4D4D4),
                  fontSize: 12,
                ),
                child: Text(
                  errorMessage,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildEventText(String text) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 16,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
  
  Widget _buildChoiceButtons(List<dynamic> choices) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF8B0000).withOpacity(0.3),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: choices.asMap().entries.map<Widget>((entry) {
          final index = entry.key;
          final choice = entry.value;
          return AnimatedContainer(
            duration: Duration(milliseconds: 200 + (index * 50)),
            curve: Curves.easeOutBack,
            child: _buildChoiceButton(choice),
          );
        }).toList(),
      ),
    );
  }
  
  Widget _buildChoiceButton(Map<String, dynamic> choice) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _onChoiceSelected(choice),
          splashColor: const Color(0xFF8B0000).withOpacity(0.3),
          highlightColor: const Color(0xFF8B0000).withOpacity(0.1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF8B0000).withOpacity(0.6),
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF2A2A2A).withOpacity(0.8),
                  const Color(0xFF1A1A1A).withOpacity(0.9),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B0000).withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 150),
              style: const TextStyle(
                color: Color(0xFFD4D4D4),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              child: Text(
                choice['text'] ?? 'Unknown choice',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSettingsView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            children: [
              const Text(
                'Settings',
                style: TextStyle(
                  color: Color(0xFFD4D4D4),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    _pageController.animateToPage(
                      1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFE0E0E0).withOpacity(0.15),
                          const Color(0xFFB0B0B0).withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Inventory',
                          style: TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          color: const Color(0xFFE0E0E0),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Settings content placeholder
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF8B0000).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Stack(
                children: [
                  // Background pattern
                  CustomPaint(
                    painter: SettingsBackgroundPainter(),
                    size: Size.infinite,
                  ),
                  
                  // Center placeholder
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.settings_outlined,
                          size: 60,
                          color: Color(0xFF8B0000),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Settings',
                          style: TextStyle(
                            color: Color(0xFFD4D4D4),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Game configuration will appear here',
                          style: TextStyle(
                            color: Color(0xFF888888),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInventoryView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with navigation buttons
          Row(
            children: [
              // Settings button (left)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    _pageController.animateToPage(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFE0E0E0).withOpacity(0.15),
                          const Color(0xFFB0B0B0).withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFE0E0E0),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Settings',
                          style: TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Spacer(),
              const Text(
                'Inventory',
                style: TextStyle(
                  color: Color(0xFFD4D4D4),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              // Play button (right)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    _pageController.animateToPage(
                      2,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFE0E0E0).withOpacity(0.15),
                          const Color(0xFFB0B0B0).withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Play',
                          style: TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward,
                          color: const Color(0xFFE0E0E0),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Item slots
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 1,
                childAspectRatio: 4,
                mainAxisSpacing: 8,
              ),
              itemCount: 5, // 5 inventory slots
              itemBuilder: (context, index) {
                return _buildInventorySlot(index);
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInventorySlot(int index) {
    final hasItem = gameState != null && index < gameState!.inventory.items.length;
    final item = hasItem ? gameState!.inventory.items[index] : null;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        border: Border.all(
          color: hasItem 
            ? const Color(0xFF8B0000).withOpacity(0.6)
            : const Color(0xFF444444),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Item icon placeholder
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: const Color(0xFF444444),
                width: 1,
              ),
            ),
            child: Icon(
              hasItem ? Icons.inventory : Icons.add,
              size: 20,
              color: hasItem 
                ? const Color(0xFF8B0000)
                : const Color(0xFF444444),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Item info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  hasItem ? item!.name : 'Empty Slot',
                  style: TextStyle(
                    color: hasItem 
                      ? const Color(0xFFD4D4D4)
                      : const Color(0xFF666666),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (hasItem && item!.description != null)
                  Text(
                    item!.description!,
                    style: const TextStyle(
                      color: Color(0xFF888888),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          
          // Quantity
          if (hasItem && item!.quantity > 1)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF8B0000).withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'x${item!.quantity}',
                style: const TextStyle(
                  color: Color(0xFFD4D4D4),
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildMazeMapView() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header with back button
          Row(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    _pageController.animateToPage(
                      2,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFE0E0E0).withOpacity(0.15),
                          const Color(0xFFB0B0B0).withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: const Color(0xFFE0E0E0).withOpacity(0.3),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_back,
                          color: const Color(0xFFE0E0E0),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        const Text(
                          'Play',
                          style: TextStyle(
                            color: Color(0xFFE0E0E0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Maze Map',
                style: TextStyle(
                  color: Color(0xFFD4D4D4),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Map grid placeholder
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2A2A2A),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF8B0000).withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: mazeData != null ? 
                _buildMazeGrid() : 
                const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.map_outlined,
                        size: 60,
                        color: Color(0xFF8B0000),
                      ),
                      SizedBox(height: 16),
                      Text(
                        '미로 데이터 없음',
                        style: TextStyle(
                          color: Color(0xFFD4D4D4),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMazeGrid() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 8,
          crossAxisSpacing: 1,
          mainAxisSpacing: 1,
        ),
        itemCount: 64, // 8x8 grid
        itemBuilder: (context, index) {
          final x = index % 8;
          final y = index ~/ 8;
          final room = mazeData!.getRoomAt(x, y);
          
          if (room == null) return const SizedBox.shrink();
          
          final isCurrentPlayerPosition = (x == playerX && y == playerY);
          final isStartRoom = room.isStart;
          final isExitRoom = room.isExit;
          final isVisited = visitedRooms.contains('$x,$y');
          
          return Container(
            decoration: BoxDecoration(
              color: isCurrentPlayerPosition
                  ? const Color(0xFF00AA00).withOpacity(0.8) // Player position
                  : isStartRoom
                      ? const Color(0xFF0066CC).withOpacity(0.6) // Start
                      : isExitRoom
                          ? const Color(0xFF8B0000).withOpacity(0.6) // Exit
                          : isVisited
                              ? const Color(0xFF4A4A4A).withOpacity(0.8) // Visited
                              : const Color(0xFF2A2A2A), // Unvisited
              border: Border.all(
                color: isVisited ? const Color(0xFF666666) : const Color(0xFF444444),
                width: 0.5,
              ),
            ),
            child: CustomPaint(
              painter: MazeRoomPainter(room: room),
              child: isCurrentPlayerPosition
                  ? const Center(
                      child: Icon(
                        Icons.person_pin_circle,
                        color: Colors.white,
                        size: 12,
                      ),
                    )
                  : isStartRoom
                      ? const Center(
                          child: Text(
                            'S',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : isExitRoom
                          ? const Center(
                              child: Text(
                                'E',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildMainContentView() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Navigation tabs at top with smooth transitions
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: Row(
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFE0E0E0).withOpacity(0.15),
                            const Color(0xFFB0B0B0).withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0).withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            color: const Color(0xFFE0E0E0),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Inventory',
                            style: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      _pageController.animateToPage(
                        3,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            const Color(0xFFE0E0E0).withOpacity(0.15),
                            const Color(0xFFB0B0B0).withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE0E0E0).withOpacity(0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.map_outlined,
                            color: const Color(0xFFE0E0E0),
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Map',
                            style: TextStyle(
                              color: Color(0xFFE0E0E0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Minimap - only show when there are navigation choices
          if (gameState?.currentEvent?['choices'] != null && 
              (gameState!.currentEvent!['choices'] as List).isNotEmpty)
            _buildMiniMap(),
          
          // Room visualization - positioned in center with smooth transitions
          _buildRoomVisualization(),
          
          const SizedBox(height: 16),
          
          // Event text (scrollable if needed) with smooth transitions
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.1),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: SingleChildScrollView(
                key: ValueKey(gameState?.currentEvent?['description'] ?? 'default'),
                physics: const BouncingScrollPhysics(),
                child: _buildEventText(
                  gameState?.currentEvent?['description'] ?? 'Something happens...'
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFF8B0000),
          ),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar at top (always visible)
            _buildStatusBar(),
            
            // Main swipeable content area
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const AlwaysScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() {
                    currentPageIndex = index;
                  });
                },
                children: [
                  // Page 0: Settings (swipe left from inventory)
                  _buildSettingsView(),
                  
                  // Page 1: Inventory (swipe right from main)
                  _buildInventoryView(),
                  
                  // Page 2: Main content (default)
                  _buildMainContentView(),
                  
                  // Page 3: Maze map (swipe left from main)
                  _buildMazeMapView(),
                ],
              ),
            ),
            
            // Choice buttons at bottom (only show on main screen) with smooth transitions
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(
                    opacity: animation,
                    child: child,
                  ),
                );
              },
              child: (currentPageIndex == 2 && gameState?.currentEvent?['choices'] != null)
                  ? _buildChoiceButtons(gameState!.currentEvent!['choices'])
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for minimap
class MiniMapPainter extends CustomPainter {
  final MazeData mazeData;
  final int playerX;
  final int playerY;
  final Set<String> visitedRooms;

  MiniMapPainter({
    required this.mazeData,
    required this.playerX,
    required this.playerY,
    required this.visitedRooms,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellWidth = size.width / 8;
    final cellHeight = size.height / 8;
    
    // Paint for different room types - enhanced colors for larger minimap
    final visitedPaint = Paint()
      ..color = const Color(0xFF555555) // Slightly brighter for visited rooms
      ..style = PaintingStyle.fill;
      
    final unvisitedPaint = Paint()
      ..color = const Color(0xFF333333) // Slightly brighter for unvisited rooms
      ..style = PaintingStyle.fill;
      
    final playerPaint = Paint()
      ..color = const Color(0xFF00CC00) // Brighter green for player
      ..style = PaintingStyle.fill;
      
    final startPaint = Paint()
      ..color = const Color(0xFF0088FF) // Brighter blue for start
      ..style = PaintingStyle.fill;
      
    final exitPaint = Paint()
      ..color = const Color(0xFFCC0000) // Brighter red for exit
      ..style = PaintingStyle.fill;
      
    final borderPaint = Paint()
      ..color = const Color(0xFF777777) // Slightly brighter border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0; // Thicker border for better visibility
    
    // Draw each room
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final room = mazeData.getRoomAt(x, y);
        if (room == null) continue;
        
        final rect = Rect.fromLTWH(
          x * cellWidth,
          y * cellHeight,
          cellWidth,
          cellHeight,
        );
        
        // Determine room color
        Paint roomPaint;
        if (x == playerX && y == playerY) {
          roomPaint = playerPaint;
        } else if (room.isStart) {
          roomPaint = startPaint;
        } else if (room.isExit) {
          roomPaint = exitPaint;
        } else if (visitedRooms.contains('$x,$y')) {
          roomPaint = visitedPaint;
        } else {
          roomPaint = unvisitedPaint;
        }
        
        // Draw room
        canvas.drawRect(rect, roomPaint);
        canvas.drawRect(rect, borderPaint);
        
        // Draw doors as larger, more visible openings
        final doorPaint = Paint()
          ..color = const Color(0xFFAAAAAA) // Brighter door color
          ..style = PaintingStyle.fill;
          
        final doorSize = math.max(3.0, cellWidth * 0.15); // Larger doors, scale with cell size
        final doorThickness = math.max(2.0, cellWidth * 0.08); // Door thickness
        
        if (room.north && y > 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * cellWidth + cellWidth / 2 - doorSize / 2,
              y * cellHeight - doorThickness / 2,
              doorSize,
              doorThickness,
            ),
            doorPaint,
          );
        }
        
        if (room.east && x < 7) {
          canvas.drawRect(
            Rect.fromLTWH(
              (x + 1) * cellWidth - doorThickness / 2,
              y * cellHeight + cellHeight / 2 - doorSize / 2,
              doorThickness,
              doorSize,
            ),
            doorPaint,
          );
        }
        
        if (room.south && y < 7) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * cellWidth + cellWidth / 2 - doorSize / 2,
              (y + 1) * cellHeight - doorThickness / 2,
              doorSize,
              doorThickness,
            ),
            doorPaint,
          );
        }
        
        if (room.west && x > 0) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * cellWidth - doorThickness / 2,
              y * cellHeight + cellHeight / 2 - doorSize / 2,
              doorThickness,
              doorSize,
            ),
            doorPaint,
          );
        }
        
        // Add player indicator icon for current position
        if (x == playerX && y == playerY) {
          final playerIconPaint = Paint()
            ..color = const Color(0xFFFFFFFF) // White icon on green background
            ..style = PaintingStyle.fill;
          
          final iconSize = math.min(cellWidth, cellHeight) * 0.4;
          final centerX = x * cellWidth + cellWidth / 2;
          final centerY = y * cellHeight + cellHeight / 2;
          
          // Draw a simple circle for player
          canvas.drawCircle(
            Offset(centerX, centerY),
            iconSize / 2,
            playerIconPaint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! MiniMapPainter) return true;
    return oldDelegate.playerX != playerX ||
           oldDelegate.playerY != playerY ||
           oldDelegate.visitedRooms != visitedRooms;
  }
}

// Custom painter for event image background
class EventImagePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B0000).withOpacity(0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const gridSize = 30.0;
    
    // Draw subtle atmospheric pattern
    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        final seed = ((x / gridSize).floor() * 13 + (y / gridSize).floor() * 17) % 100;
        
        if (seed % 8 == 0) {
          // Draw subtle lines
          canvas.drawLine(
            Offset(x, y),
            Offset(x + gridSize * 0.5, y + gridSize * 0.5),
            paint,
          );
        }
        if (seed % 12 == 0) {
          // Draw subtle dots
          canvas.drawCircle(
            Offset(x + gridSize * 0.5, y + gridSize * 0.5),
            2,
            paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for maze map grid
class MazeMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B0000).withOpacity(0.2)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final cellWidth = size.width / 8;
    final cellHeight = size.height / 8;
    
    // Draw 8x8 grid
    for (int x = 0; x <= 8; x++) {
      canvas.drawLine(
        Offset(x * cellWidth, 0),
        Offset(x * cellWidth, size.height),
        paint,
      );
    }
    
    for (int y = 0; y <= 8; y++) {
      canvas.drawLine(
        Offset(0, y * cellHeight),
        Offset(size.width, y * cellHeight),
        paint,
      );
    }
    
    // Draw start and exit positions as placeholders
    final startPaint = Paint()
      ..color = const Color(0xFF32CD32).withOpacity(0.6)
      ..style = PaintingStyle.fill;
      
    final exitPaint = Paint()
      ..color = const Color(0xFF8B0000).withOpacity(0.6)
      ..style = PaintingStyle.fill;
    
    // Start position (0,7) - bottom left
    canvas.drawCircle(
      Offset(cellWidth * 0.5, size.height - cellHeight * 0.5),
      cellWidth * 0.3,
      startPaint,
    );
    
    // Exit position (7,0) - top right  
    canvas.drawCircle(
      Offset(size.width - cellWidth * 0.5, cellHeight * 0.5),
      cellWidth * 0.3,
      exitPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for settings background
class SettingsBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B0000).withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const gridSize = 40.0;
    
    // Draw subtle gear pattern
    for (double x = 0; x < size.width; x += gridSize) {
      for (double y = 0; y < size.height; y += gridSize) {
        final seed = ((x / gridSize).floor() * 31 + (y / gridSize).floor() * 23) % 100;
        
        if (seed % 15 == 0) {
          // Draw gear-like shapes
          final center = Offset(x + gridSize * 0.5, y + gridSize * 0.5);
          final radius = gridSize * 0.15;
          
          // Draw outer circle
          canvas.drawCircle(center, radius, paint);
          
          // Draw inner circle
          canvas.drawCircle(center, radius * 0.5, paint);
          
          // Draw gear teeth
          for (int i = 0; i < 8; i++) {
            final angle = (i * 45) * 3.14159 / 180;
            final start = Offset(
              center.dx + radius * 0.8 * math.cos(angle),
              center.dy + radius * 0.8 * math.sin(angle),
            );
            final end = Offset(
              center.dx + radius * 1.2 * math.cos(angle),
              center.dy + radius * 1.2 * math.sin(angle),
            );
            canvas.drawLine(start, end, paint);
          }
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for individual maze room with doors
class MazeRoomPainter extends CustomPainter {
  final MazeRoom room;

  MazeRoomPainter({required this.room});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF666666)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw doors/openings
    if (room.north) {
      // Opening to north - leave gap in top border
      canvas.drawLine(
        const Offset(0, 0),
        Offset(size.width * 0.3, 0),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.7, 0),
        Offset(size.width, 0),
        paint,
      );
    } else {
      // Solid top border
      canvas.drawLine(
        const Offset(0, 0),
        Offset(size.width, 0),
        paint,
      );
    }

    if (room.east) {
      // Opening to east - leave gap in right border
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, size.height * 0.3),
        paint,
      );
      canvas.drawLine(
        Offset(size.width, size.height * 0.7),
        Offset(size.width, size.height),
        paint,
      );
    } else {
      // Solid right border
      canvas.drawLine(
        Offset(size.width, 0),
        Offset(size.width, size.height),
        paint,
      );
    }

    if (room.south) {
      // Opening to south - leave gap in bottom border
      canvas.drawLine(
        Offset(size.width, size.height),
        Offset(size.width * 0.7, size.height),
        paint,
      );
      canvas.drawLine(
        Offset(size.width * 0.3, size.height),
        Offset(0, size.height),
        paint,
      );
    } else {
      // Solid bottom border
      canvas.drawLine(
        Offset(size.width, size.height),
        Offset(0, size.height),
        paint,
      );
    }

    if (room.west) {
      // Opening to west - leave gap in left border
      canvas.drawLine(
        Offset(0, size.height),
        Offset(0, size.height * 0.7),
        paint,
      );
      canvas.drawLine(
        Offset(0, size.height * 0.3),
        const Offset(0, 0),
        paint,
      );
    } else {
      // Solid left border
      canvas.drawLine(
        Offset(0, size.height),
        const Offset(0, 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! MazeRoomPainter) return true;
    return oldDelegate.room != room;
  }
}

// Custom painter for current room visualization (larger)
class CurrentRoomPainter extends CustomPainter {
  final MazeRoom room;

  CurrentRoomPainter({required this.room});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8B0000)
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    final doorPaint = Paint()
      ..color = const Color(0xFF00AA00)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Draw room outline
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawRect(rect, paint);

    // Draw doors as colored segments
    if (room.north) {
      // North door
      canvas.drawLine(
        Offset(size.width * 0.3, 0),
        Offset(size.width * 0.7, 0),
        doorPaint,
      );
    }

    if (room.east) {
      // East door
      canvas.drawLine(
        Offset(size.width, size.height * 0.3),
        Offset(size.width, size.height * 0.7),
        doorPaint,
      );
    }

    if (room.south) {
      // South door
      canvas.drawLine(
        Offset(size.width * 0.7, size.height),
        Offset(size.width * 0.3, size.height),
        doorPaint,
      );
    }

    if (room.west) {
      // West door
      canvas.drawLine(
        Offset(0, size.height * 0.7),
        Offset(0, size.height * 0.3),
        doorPaint,
      );
    }
    
    // Add corner decorations
    final cornerPaint = Paint()
      ..color = const Color(0xFF666666)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // Draw corner brackets
    const cornerSize = 15.0;
    
    // Top-left corner
    canvas.drawLine(const Offset(0, cornerSize), const Offset(0, 0), cornerPaint);
    canvas.drawLine(const Offset(0, 0), const Offset(cornerSize, 0), cornerPaint);
    
    // Top-right corner
    canvas.drawLine(Offset(size.width - cornerSize, 0), Offset(size.width, 0), cornerPaint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), cornerPaint);
    
    // Bottom-right corner
    canvas.drawLine(Offset(size.width, size.height - cornerSize), Offset(size.width, size.height), cornerPaint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerSize, size.height), cornerPaint);
    
    // Bottom-left corner
    canvas.drawLine(Offset(cornerSize, size.height), Offset(0, size.height), cornerPaint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerSize), cornerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! CurrentRoomPainter) return true;
    return oldDelegate.room != room;
  }
}

