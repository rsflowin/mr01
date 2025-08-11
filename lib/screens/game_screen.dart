import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/maze_model.dart';
import '../models/event_model.dart';
import '../models/room_event_data.dart';
import '../models/game_state.dart';
import '../models/item_model.dart';
import '../services/event_processor.dart';
import '../services/event_assignment_manager.dart';
import '../services/game_manager.dart';
import '../services/turn_manager.dart';
import '../services/inventory_manager.dart';
import '../services/logger_service.dart';
import '../services/error_handler_service.dart';
import '../widgets/event_interaction.dart';
import '../widgets/event_display.dart';
import '../widgets/choice_buttons.dart';
import '../widgets/turn_transition_widget.dart';
import 'ending_screen.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import '../services/audio_service.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
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

  // Turn management

  bool _isTurnTransitionActive = false;

  // Event processing
  EventProcessor? _eventProcessor;
  Event? _currentEvent;
  RoomEventData? _currentRoomEventData;
  bool _isProcessingEvent = false;
  Map<String, dynamic>? _storedEventDisplay;

  // Services
  final GameManager _gameManager = GameManager();
  final TurnManager _turnManager = TurnManager();
  final InventoryManager _inventoryManager = InventoryManager();
  final LoggerService _logger = LoggerService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  @override
  void initState() {
    super.initState();

    _textController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _textController, curve: Curves.easeInOut),
    );

    _pageController = PageController(initialPage: 2); // Start at main screen

    // Turn manager already initialized in the services section

    _initializeGame();
  }

  Future<void> _initializeGame() async {
    // Initialize game state first
    await _initializeGameState();

    // Setup navigation choices for current room
    _updateNavigationChoices();
  }

  Future<void> _initializeGameState() async {
    // Ensure item database is available for inventory UI
    try {
      await _inventoryManager.loadItemDatabase();
    } catch (_) {}
    _logger.info('GameScreen', '=== GAME SCREEN INITIALIZATION ===');
    _logger.info(
      'GameScreen',
      'GameManager initialized: ${_gameManager.isInitialized}',
    );
    _logger.info(
      'GameScreen',
      'GameManager initializing: ${_gameManager.isInitializing}',
    );

    // Wait for GameManager to be ready if not already initialized
    while (!_gameManager.isInitialized) {
      _logger.info('GameScreen', 'Waiting for GameManager to initialize...');
      await Future.delayed(const Duration(milliseconds: 100));
    }

    _logger.info('GameScreen', 'GameManager ready! Getting data...');

    // Get game state and maze from GameManager
    gameState = _gameManager.gameState;
    mazeData = _gameManager.currentMaze;

    _logger.info(
      'GameScreen',
      'GameState: ${gameState != null ? "loaded" : "null"}',
    );
    _logger.info(
      'GameScreen',
      'MazeData: ${mazeData != null ? "loaded" : "null"}',
    );

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

      _logger.info('GameScreen', '=== MAZE DATA LOADED ===');
      _logger.info('GameScreen', 'Maze name: ${mazeData!.name}');
      _logger.info(
        'GameScreen',
        'Start room coordinates: (${mazeData!.startRoom.x}, ${mazeData!.startRoom.y})',
      );
      _logger.info(
        'GameScreen',
        'Exit room coordinates: (${mazeData!.exitRoom.x}, ${mazeData!.exitRoom.y})',
      );
      _logger.info(
        'GameScreen',
        'Player position set to: ($playerX, $playerY)',
      );
      _logger.info(
        'GameScreen',
        'Starting room marked as visited: ${visitedRooms.contains('$playerX,$playerY')}',
      );

      // Initialize event processor
      _initializeEventProcessor();
      _logger.info('GameScreen', 'Victory condition reset: $hasReachedExit');
      _logger.info(
        'GameScreen',
        'Start room isStart: ${mazeData!.startRoom.isStart}',
      );
      _logger.info(
        'GameScreen',
        'Exit room isExit: ${mazeData!.exitRoom.isExit}',
      );
      _logger.info('GameScreen', '========================');
    } else {
      _logger.error('GameScreen', 'MazeData is null!');
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

  /// Initializes the event processor with the event database from GameManager
  void _initializeEventProcessor() {
    try {
      final eventManager = _gameManager.eventAssignmentManager;
      if (eventManager != null && eventManager.isInitialized) {
        _eventProcessor = EventProcessor(eventDatabase: eventManager.allEvents);
        _logger.info(
          'GameScreen',
          'Event processor initialized with ${eventManager.allEvents.length} events',
        );
      } else {
        _logger.warning(
          'GameScreen',
          'Event assignment manager not initialized, event processor not created',
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'GameScreen',
        'Failed to initialize event processor: $e',
        null,
        stackTrace,
      );
    }
  }

  /// Processes room entry and triggers events if available
  void _processRoomEntry() {
    try {
      print('INFO: Processing room entry at ($playerX, $playerY)');
      
      // Reset event processing state first
      setState(() {
        _isProcessingEvent = false;
        _currentEvent = null;
        gameState!.currentEvent = null;
      });
      
      // Always show room description and navigation choices first
      // Events will be triggered after user selects a door and moves
      _updateNavigationChoices();
    } catch (e, stackTrace) {
      print('ERROR: Exception in _processRoomEntry: $e');
      print('Stack trace: $stackTrace');

      // Fallback to navigation choices on error
      _updateNavigationChoices();
    }
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
        print(
          'ERROR: Invalid player position ($playerX, $playerY) in _updateNavigationChoices',
        );
        _recoverFromInvalidPosition();
        return;
      }

      final currentRoom = mazeData!.getRoomAt(playerX, playerY);
      if (currentRoom == null) {
        print('ERROR: Current room is null at position ($playerX, $playerY)');
        _recoverFromInvalidPosition();
        return;
      }

      print(
        'INFO: Updating navigation choices for room at ($playerX, $playerY)',
      );

      // Check for victory condition
      if (currentRoom.isExit && !hasReachedExit) {
        print('INFO: Player reached exit room - triggering victory');
        hasReachedExit = true;
        _showVictoryScreen();
        return;
      }

      // If already reached exit, don't show navigation choices
      if (hasReachedExit) {
        print(
          'INFO: Player has already reached exit - no navigation choices shown',
        );
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
        print(
          'WARNING: No navigation choices available - player may be in dead end',
        );
        _handleDeadEnd(currentRoom);
        return;
      }

      setState(() {
        if (gameState != null) {
          gameState!.currentEvent = {
            'name': '현재 위치: (${playerX}, ${playerY})',
            'description': _getRoomDescription(currentRoom),
            'image': '',  // No image for door selection screen
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

      // Check if this is an event choice or navigation choice
      if (_isProcessingEvent && _currentEvent != null) {
        _handleEventChoice(choice);
        return;
      }

      // Handle navigation choice
      _handleNavigationChoice(choice);
    } catch (e, stackTrace) {
      print('ERROR: Exception in _onChoiceSelected: $e');
      print('Stack trace: $stackTrace');
      _handleChoiceError('Failed to process choice selection');
    }
  }

  /// Handles event choice selection
  void _handleEventChoice(Map<String, dynamic> choice) {
    try {
      if (_eventProcessor == null ||
          _currentEvent == null ||
          gameState == null) {
        print('ERROR: Event choice called without proper initialization');
        _handleChoiceError('Event processing not available');
        return;
      }

      // Get choice index from the choice data
      final choiceIndex = choice['index'] as int?;
      if (choiceIndex == null) {
        print('ERROR: No choice index provided for event choice');
        _handleChoiceError('Invalid event choice');
        return;
      }

      print(
        'INFO: Processing event choice $choiceIndex for event ${_currentEvent!.name}',
      );

      // Process the choice selection
      final choiceResult = _eventProcessor!.processChoiceSelectionEnhanced(
        _currentEvent!,
        choiceIndex,
        gameState!,
        _currentRoomEventData!,
      );

      // Apply results to game state
      gameState = choiceResult['gameState'] as GameState;
      _currentRoomEventData = choiceResult['roomEventData'] as RoomEventData;

      // Update room event data in the manager
      final eventManager = _gameManager.eventAssignmentManager;
      if (eventManager != null && _currentRoomEventData != null) {
        eventManager.updateRoomEventDataByCoordinates(
          playerX,
          playerY,
          _currentRoomEventData!,
        );
      }

      // Show choice result
      final description = choiceResult['description'] as String;
      final success = choiceResult['success'] as bool;
      final effectsApplied = choiceResult['effectsApplied'] as Map<String, dynamic>;

      setState(() {
        gameState!.currentEvent = {
          'name': success ? '성공!' : '결과',
          'description': '$description\n\n미로의 다른 이들이 움직이고 있습니다...',
          'image': 'result.png',
          'choices': [
            {
              'text': '계속하기',
              'direction': 'continue',
              'description': '게임을 계속 진행합니다.',
            },
          ],
          'effectsApplied': effectsApplied, // Store effects for visual display
        };
        _isProcessingEvent = false;
        _currentEvent = null;
      });

      // Restart text animation for result display
      _textController.forward();
    } catch (e, stackTrace) {
      print('ERROR: Exception in _handleEventChoice: $e');
      print('Stack trace: $stackTrace');
      _handleChoiceError('Failed to process event choice');
    }
  }

  /// Handles navigation choice selection
  void _handleNavigationChoice(Map<String, dynamic> choice) {
    try {
      // Extract direction from choice data structure with validation
      final direction = choice['direction'] as String?;
      final choiceText = choice['text'] as String?;
      final description = choice['description'] as String?;

      // Handle continue action (after event result)
      if (direction == 'continue') {
        print('INFO: Continue action selected, updating navigation choices');
        // No popup needed - go directly to navigation choices
        _updateNavigationChoices();
        return;
      }

      // Handle rest action (in empty rooms)
      if (direction == 'rest') {
        print('INFO: Rest action selected, showing rest result');
        // Show rest result immediately
        setState(() {
          gameState!.currentEvent = {
            'name': '휴식 완료',
            'description': '잠시 휴식을 취했습니다. 기분이 조금 나아졌습니다.\n\n미로의 다른 이들이 움직이고 있습니다...',
            'image': 'result.png',
            'choices': [
              {
                'text': '계속하기',
                'direction': 'continue',
                'description': '게임을 계속 진행합니다.',
              },
            ],
          };
          _isProcessingEvent = false;
        });
        _textController.forward();
        
        // No popup needed - turn transition text is included in the description
        return;
      }

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
      print(
        'INFO: Choice selected - Text: "$choiceText", Direction: "$direction"',
      );
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
        print(
          'ERROR: Cannot process choice - invalid player position ($playerX, $playerY)',
        );
        _recoverFromInvalidPosition();
        return;
      }

      final currentRoom = mazeData!.getRoomAt(playerX, playerY);
      if (currentRoom == null) {
        print(
          'ERROR: Cannot process choice - current room is null at ($playerX, $playerY)',
        );
        _recoverFromInvalidPosition();
        return;
      }

      // Validate that movement is possible before attempting
      if (!currentRoom.canMoveTo(direction)) {
        print(
          'WARNING: Attempted to move in direction "$direction" but no door available',
        );
        _handleChoiceError('Movement not possible in that direction');
        return;
      }

      // Validate destination exists
      final destinationRoom = mazeData!.getAdjacentRoom(
        playerX,
        playerY,
        direction,
      );
      if (destinationRoom == null) {
        print(
          'ERROR: Destination room is null for direction "$direction" from ($playerX, $playerY)',
        );
        _handleChoiceError('Cannot reach destination');
        return;
      }

      print('INFO: All validations passed - triggering movement');

      // Trigger movement for directional choice
      _movePlayer(direction);
    } catch (e, stackTrace) {
      print('ERROR: Exception in _handleNavigationChoice: $e');
      print('Stack trace: $stackTrace');
      _handleChoiceError('Failed to process navigation choice');
    }
  }

  String _getRoomDescription(MazeRoom room) {
    try {
      // Generate contextual room descriptions based on room type and state
      String baseDescription = _getBaseRoomDescription(room);

      // Add door availability descriptions based on locale
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
      return _isKoreanLocale()
          ? '방 설명을 생성하는 중 오류가 발생했습니다.'
          : 'An error occurred while generating the room description.';
    }
  }

  bool _isKoreanLocale() {
    final current = LocaleService.instance.localeNotifier.value;
    final code = current?.languageCode;
    if (code == 'ko') return true;
    if (code == 'en') return false;
    final platformCode = Localizations.localeOf(context).languageCode;
    return platformCode == 'ko';
  }

  String _dirLabel(String key) {
    final isKo = _isKoreanLocale();
    switch (key) {
      case 'north':
        return isKo ? '북쪽(위쪽)' : 'North (Up)';
      case 'east':
        return isKo ? '동쪽(오른쪽)' : 'East (Right)';
      case 'south':
        return isKo ? '남쪽(아래쪽)' : 'South (Down)';
      case 'west':
        return isKo ? '서쪽(왼쪽)' : 'West (Left)';
      default:
        return key;
    }
  }

  String _getBaseRoomDescription(MazeRoom room) {
    try {
      // Special descriptions for different room types
      if (room.isStart) {
        return _isKoreanLocale()
            ? '여기가 미로의 시작점입니다. 어둡고 차가운 돌벽으로 둘러싸인 이 방에서 당신의 모험이 시작됩니다. 출구를 찾아 미로를 탈출해야 합니다.'
            : 'This is the starting point of the maze. Surrounded by cold, dark stone walls, your journey begins here. Find the exit and escape the labyrinth.';
      } else if (room.isExit) {
        return _isKoreanLocale()
            ? '축하합니다! 미로의 출구를 찾았습니다! 밝은 빛이 앞에서 당신을 기다리고 있습니다. 긴 여정이 드디어 끝났습니다.'
            : 'Congratulations! You have found the exit of the maze! A bright light awaits you ahead. Your long journey is finally over.';
      } else {
        // Simple generic room description (should eventually come from JSON data)
        return _isKoreanLocale()
            ? '미로의 방입니다. 어느 방향으로 이동할지 선택하세요.'
            : 'You are in a room of the maze. Choose which direction to move.';
      }
    } catch (e, stackTrace) {
      print('ERROR: Exception in _getBaseRoomDescription: $e');
      print('Stack trace: $stackTrace');
      return _isKoreanLocale()
          ? '방 설명을 생성하는 중 오류가 발생했습니다.'
          : 'An error occurred while generating the base room description.';
    }
  }

  String _getDoorAvailabilityDescription(MazeRoom room) {
    try {
      final List<String> availableDirections = [];
      final List<String> blockedDirections = [];

      // Check each direction and categorize
      if (room.north) {
        availableDirections.add(_dirLabel('north'));
      } else {
        blockedDirections.add(_dirLabel('north'));
      }

      if (room.east) {
        availableDirections.add(_dirLabel('east'));
      } else {
        blockedDirections.add(_dirLabel('east'));
      }

      if (room.south) {
        availableDirections.add(_dirLabel('south'));
      } else {
        blockedDirections.add(_dirLabel('south'));
      }

      if (room.west) {
        availableDirections.add(_dirLabel('west'));
      } else {
        blockedDirections.add(_dirLabel('west'));
      }

      String description = '';
      final isKo = _isKoreanLocale();

      // Describe available doors
      if (availableDirections.isNotEmpty) {
        if (isKo) {
          if (availableDirections.length == 1) {
            description += '${availableDirections[0]} 방향으로 나갈 수 있는 문이 있습니다.';
          } else if (availableDirections.length == 2) {
            description += '${availableDirections.join('과 ')} 방향으로 나갈 수 있는 문이 있습니다.';
          } else {
            final lastDirection = availableDirections.removeLast();
            description += '${availableDirections.join(', ')}, 그리고 $lastDirection 방향으로 나갈 수 있는 문이 있습니다.';
          }
        } else {
          if (availableDirections.length == 1) {
            description += 'There is a door leading to ${availableDirections[0]}.';
          } else if (availableDirections.length == 2) {
            description += 'There are doors leading to ${availableDirections.join(' and ')}.';
          } else {
            final lastDirection = availableDirections.removeLast();
            description += 'There are doors leading to ${availableDirections.join(', ')}, and $lastDirection.';
          }
        }
      } else {
        description += isKo
            ? '이용할 수 있는 문이 없습니다. 막다른 길인 것 같습니다.'
            : 'There are no usable doors. It seems to be a dead end.';
      }

      // Add information about blocked directions for context
      if (blockedDirections.isNotEmpty && availableDirections.isNotEmpty) {
        if (isKo) {
          if (blockedDirections.length == 1) {
            description += ' ${blockedDirections[0]} 방향은 벽으로 막혀있습니다.';
          } else if (blockedDirections.length == 2) {
            description += ' ${blockedDirections.join('과 ')} 방향은 벽으로 막혀있습니다.';
          } else {
            final lastBlocked = blockedDirections.removeLast();
            description += ' ${blockedDirections.join(', ')}, 그리고 $lastBlocked 방향은 벽으로 막혀있습니다.';
          }
        } else {
          if (blockedDirections.length == 1) {
            description += ' ${blockedDirections[0]} is blocked by a wall.';
          } else if (blockedDirections.length == 2) {
            description += ' ${blockedDirections.join(' and ')} are blocked by walls.';
          } else {
            final lastBlocked = blockedDirections.removeLast();
            description += ' ${blockedDirections.join(', ')}, and $lastBlocked are blocked by walls.';
          }
        }
      }

      return description;
    } catch (e, stackTrace) {
      print('ERROR: Exception in _getDoorAvailabilityDescription: $e');
      print('Stack trace: $stackTrace');
      return _isKoreanLocale()
          ? '문 정보를 생성하는 중 오류가 발생했습니다.'
          : 'An error occurred while generating door information.';
    }
  }

  String _getRoomCountDescription() {
    try {
      final totalRooms = 64; // 8x8 maze
      final visitedCount = visitedRooms.length;

      // Validate visitedCount is reasonable
      if (visitedCount < 0 || visitedCount > totalRooms) {
        print('WARNING: Invalid visited room count: $visitedCount');
        return _isKoreanLocale() ? '탐험 진행도: 정보 오류' : 'Exploration: data error';
      }

      final explorationPercentage = totalRooms > 0
          ? ((visitedCount / totalRooms) * 100).round()
          : 0;

      final isKo = _isKoreanLocale();
      return isKo
          ? '탐험 진행도: $visitedCount/$totalRooms 방 ($explorationPercentage%)'
          : 'Exploration: $visitedCount/$totalRooms rooms ($explorationPercentage%)';
    } catch (e, stackTrace) {
      print('ERROR: Exception in _getRoomCountDescription: $e');
      print('Stack trace: $stackTrace');
      return _isKoreanLocale()
          ? '탐험 진행도를 계산하는 중 오류가 발생했습니다.'
          : 'An error occurred while calculating exploration progress.';
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
        print(
          'ERROR: Cannot move player - invalid current position ($playerX, $playerY)',
        );
        _recoverFromInvalidPosition();
        return;
      }

      // Get current room and validate movement
      final currentRoom = mazeData!.getRoomAt(playerX, playerY);
      if (currentRoom == null) {
        print(
          'ERROR: Cannot move player - current room is null at ($playerX, $playerY)',
        );
        _recoverFromInvalidPosition();
        return;
      }

      if (!currentRoom.canMoveTo(direction)) {
        print(
          'WARNING: Cannot move $direction from ($playerX, $playerY) - no door available',
        );
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

      print(
        'INFO: Moving player from ($playerX, $playerY) to ($newX, $newY) via $direction',
      );

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

      print(
        'INFO: Player now at ($playerX, $playerY), visited rooms: ${visitedRooms.length}',
      );

      // Validate the move was successful
      if (playerX != newX || playerY != newY) {
        print(
          'ERROR: Player position update failed - expected ($newX, $newY), got ($playerX, $playerY)',
        );
        // Attempt to recover by restoring previous position
        setState(() {
          playerX = previousX;
          playerY = previousY;
        });
        _handleNavigationError('Movement failed - position restored');
        return;
      }

      // Load room event for the new position but don't display it yet
      _loadRoomEvent();
      
      // Show the event for this room immediately after moving
      _displayLoadedEvent();
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

  void _loadRoomEvent() {
    try {
      print('INFO: Loading room event at ($playerX, $playerY)');

      // Check if event processing is available
      if (_eventProcessor == null) {
        _logger.warning(
          'GameScreen',
          'Event processor not initialized, skipping event loading',
        );
        return;
      }

      final eventManager = _gameManager.eventAssignmentManager;
      if (eventManager == null) {
        print(
          'WARNING: Event assignment manager not available, skipping event loading',
        );
        return;
      }

      // Get room event data for current position
      _currentRoomEventData = eventManager.getRoomEventDataByCoordinates(
        playerX,
        playerY,
      );

      if (_currentRoomEventData == null ||
          !_currentRoomEventData!.hasAvailableEvents) {
        print(
          'INFO: No events available in current room, creating empty room placeholder',
        );
        // Create empty room placeholder event
        _storedEventDisplay = {
          'name': '빈 방',
          'description': '이곳은 빈 방입니다. 아무 일도 일어나지 않았습니다.',
          'image': 'empty_room.png',
          'choices': [
            {
              'text': '잠시 휴식을 취한다',
              'direction': 'rest',
              'description': '잠시 쉬며 체력을 회복합니다.',
            },
          ],
        };
        return;
      }

      // Process room entry and select an event
      final roomEntryResult = _eventProcessor!.processRoomEntryEnhanced(
        _currentRoomEventData!,
        gameState!,
      );

      _currentEvent = roomEntryResult['event'] as Event?;
      _currentRoomEventData =
          roomEntryResult['roomEventData'] as RoomEventData?;

      if (_currentEvent != null) {
        print('INFO: Event loaded: ${_currentEvent!.name}');

        // Store the event but don't display it yet
        // It will be shown after user selects a door
        final eventDisplay = roomEntryResult['eventDisplay'] as Map<String, dynamic>?;
        
        // Store event data for later display, but don't show it yet
        _storedEventDisplay = eventDisplay;
      } else {
        print('INFO: No event selected for current room');
        _storedEventDisplay = null;
      }
    } catch (e, stackTrace) {
      print('ERROR: Exception in _loadRoomEvent: $e');
      print('Stack trace: $stackTrace');
    }
  }

  void _displayLoadedEvent() {
    try {
      if (_storedEventDisplay != null) {
        print('INFO: Displaying loaded event');
        
        // Display the previously loaded event
        setState(() {
          _isProcessingEvent = true;
          gameState!.currentEvent = _storedEventDisplay;
        });
        
        // Start the text animation
        _textController.forward();
      } else {
        print('INFO: No stored event to display, showing room navigation');
        // Show room description and navigation choices if no event
        _processRoomEntry();
      }
    } catch (e, stackTrace) {
      print('ERROR: Exception in _displayLoadedEvent: $e');
      print('Stack trace: $stackTrace');
      // Fallback to room entry on error
      _processRoomEntry();
    }
  }

  // Error handling for navigation issues
  void _handleNavigationError(String message) {
    print('NAVIGATION ERROR: $message');

    try {
      setState(() {
        if (gameState != null) {
          gameState!.currentEvent = {
            'name': '오류 발생',
            'description':
                '네비게이션 중 문제가 발생했습니다: $message\n\n게임을 다시 시작하거나 이전 위치로 돌아가세요.',
            'image': 'error.png',
            'choices': [
              {
                'text': '현재 위치에서 계속하기',
                'direction': 'stay',
                'description': '현재 위치에서 게임을 계속합니다.',
              },
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
            'description':
                '이곳은 막다른 길입니다. 더 이상 갈 곳이 없습니다.\n\n이전에 방문한 방으로 돌아가거나 다른 경로를 찾아보세요.',
            'image': 'dead_end.png',
            'choices': [
              {
                'text': '이전 위치로 돌아가기',
                'direction': 'back',
                'description': '이전에 방문한 방으로 돌아갑니다.',
              },
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

  /// Triggers turn transition with the "Others in the maze are moving" message
  ///
  /// [onTransitionComplete] - Callback to execute after transition completes
  void _triggerTurnTransition(VoidCallback onTransitionComplete) async {
    try {
      print('INFO: Starting turn transition');

      // Start turn transition
      setState(() {
        _isTurnTransitionActive = true;
      });

      // Use TurnManager to handle the transition
      await _turnManager.processTurnCycle(
        onTransitionStart: () {
          print('INFO: Turn transition started');
        },
        onTransitionComplete: () {
          print('INFO: Turn transition completed');
          if (mounted) {
            setState(() {
              _isTurnTransitionActive = false;
            });

            // Execute the completion callback
            onTransitionComplete();
          }
        },
        onReturnToMovement: () {
          print('INFO: Returned to movement phase');
        },
      );
    } catch (e, stackTrace) {
      print('ERROR: Exception in _triggerTurnTransition: $e');
      print('Stack trace: $stackTrace');

      // Ensure transition state is reset on error
      if (mounted) {
        setState(() {
          _isTurnTransitionActive = false;
        });

        // Still execute the completion callback
        onTransitionComplete();
      }
    }
  }

  // Recovery mechanism for invalid player positions
  void _recoverFromInvalidPosition() {
    print(
      'INFO: Attempting to recover from invalid player position ($playerX, $playerY)',
    );

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
        print(
          'INFO: Attempting recovery to start room at ($recoveryX, $recoveryY)',
        );
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

        print(
          'INFO: Successfully recovered player position to ($playerX, $playerY)',
        );
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
    final stats = gameState?.stats;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.backgroundSecondary,
        border: Border(
          bottom: BorderSide(color: AppTheme.borderSecondary, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modernBar(label: 'HP', value: stats?.hp ?? 100, color: AppTheme.hpColor),
                const SizedBox(height: 8),
                _modernBar(label: 'SAN', value: stats?.san ?? 100, color: AppTheme.sanColor),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _modernBar(label: 'FIT', value: stats?.fit ?? 70, color: AppTheme.fitnessColor),
                const SizedBox(height: 8),
                _modernBar(label: 'HUNGER', value: stats?.hunger ?? 80, color: AppTheme.hungerColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _modernBar({required String label, required int value, required Color color}) {
    return Row(
      children: [
        SizedBox(
          width: 52,
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.backgroundTertiary,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppTheme.borderSecondary, width: 0.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              tween: Tween(
                begin: 0.0,
                end: (value.clamp(0, 100) as int) / 100,
              ),
              builder: (context, widthFactor, _) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: widthFactor.clamp(0.0, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.9),
                            color.withOpacity(0.6),
                          ],
                        ),
                      ),
                      height: double.infinity,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${value.clamp(0, 100)}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppTheme.textTertiary,
              ),
        ),
      ],
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
            style: const TextStyle(color: Color(0xFF888888), fontSize: 9),
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
        print(
          'WARNING: _buildRoomVisualization called with invalid position ($playerX, $playerY)',
        );
        return _buildErrorVisualization('Invalid player position');
      }

      final currentRoom = mazeData!.getRoomAt(playerX, playerY);
      if (currentRoom == null) {
        print(
          'WARNING: _buildRoomVisualization - current room is null at ($playerX, $playerY)',
        );
        return _buildErrorVisualization('Room data unavailable');
      }

      return AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
        height:
            240, // Increased from 200 to 240 to accommodate larger room structure
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
            CustomPaint(painter: EventImagePainter(), size: Size.infinite),
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
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
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
                          // Coordinate label removed
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
                      width:
                          180 +
                          (math.sin(value * math.pi * 2) *
                              6), // Adjusted for larger size
                      height:
                          180 +
                          (math.sin(value * math.pi * 2) *
                              6), // Adjusted for larger size
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF00AA00).withOpacity(
                            0.3 + (math.sin(value * math.pi * 2) * 0.2),
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
        borderRadius: BorderRadius.circular(
          12,
        ), // Slightly larger border radius
        border: Border.all(
          color: const Color(
            0xFF8B0000,
          ).withOpacity(0.4), // Slightly more visible border
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
            // Minimap grid (title removed)
            Expanded(
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(
                      6,
                    ), // Slightly larger border radius
                    border: Border.all(
                      color: const Color(
                        0xFF444444,
                      ), // Added subtle border to grid
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
                style: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 12),
                child: Text(errorMessage, textAlign: TextAlign.center),
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
            child: _buildChoiceButton(choice, index),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildChoiceButton(Map<String, dynamic> choice, int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () => _onChoiceSelected({...choice, 'index': index}),
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
    final localeService = LocaleService.instance;
    final currentLocale = localeService.localeNotifier.value;
    final isKo = (currentLocale?.languageCode ?? Localizations.localeOf(context).languageCode) == 'ko';
    final title = isKo ? '설정' : 'Settings';
    final languageLabel = isKo ? '언어' : 'Language';
    final bgmLabel = isKo ? '배경 음악 (BGM)' : 'Background Music (BGM)';
    final bgmDesc = isKo ? '배경 음악을 켜거나 끄세요' : 'Turn background music on or off';

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with back button
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFD4D4D4),
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              _buildPillButton(
                label: isKo ? '인벤토리' : 'Inventory',
                icon: Icons.arrow_forward,
                onTap: () {
                  _pageController.animateToPage(
                    1,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Settings content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.borderSecondary,
                  width: 1,
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Language selection (System default implied through app-level logic)
                  Text(
                    isKo ? '언어' : 'Language',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment<String>(value: 'en', label: Text('English')),
                      ButtonSegment<String>(value: 'ko', label: Text('한국어')),
                    ],
                    selected: {
                      (currentLocale?.languageCode ?? Localizations.localeOf(context).languageCode),
                    },
                    onSelectionChanged: (values) {
                      final value = values.first;
                      localeService.setLocale(Locale(value));
                      setState(() {});
                    },
                  ),

                  const SizedBox(height: 24),

                  // BGM toggle
                  Text(
                    languageLabel == '언어' ? '오디오' : 'Audio',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(bgmLabel),
                    subtitle: Text(bgmDesc, style: Theme.of(context).textTheme.bodySmall),
                    trailing: ValueListenableBuilder<bool>(
                      valueListenable: AudioService.instance.bgmEnabled,
                      builder: (context, enabled, _) {
                        return Switch(
                          value: enabled,
                          onChanged: (v) => AudioService.instance.setBgmEnabled(v),
                        );
                      },
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
    final items = gameState?.inventory.items ?? const [];
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with nav buttons
          Row(
            children: [
              _buildPillButton(
                label: 'Settings',
                icon: Icons.arrow_back,
                onTap: () => _pageController.animateToPage(
                  0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
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
              _buildPillButton(
                label: 'Play',
                icon: Icons.arrow_forward,
                onTap: () => _pageController.animateToPage(
                  2,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Items list
          Expanded(
            child: items.isEmpty
                ? _buildEmptyInventoryListPlaceholder()
                : ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final invItem = items[index];
                      final itemDef = _inventoryManager.getItem(invItem.id);
                      return _buildInventoryItemCard(invItem, itemDef);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInventoryListPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFF666666)),
          SizedBox(height: 10),
          Text(
            'No items yet',
            style: TextStyle(color: Color(0xFFAAAAAA)),
          ),
        ],
      ),
    );
  }

  Widget _buildPillButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
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
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, color: const Color(0xFFE0E0E0), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryItemCard(InventoryItem invItem, Item? itemDef) {
    final hasDef = itemDef != null;
    final isActive = hasDef ? (itemDef!.itemType.toUpperCase() == 'ACTIVE') : true;
    final canUse = hasDef && itemDef!.effects.hasEffects && isActive && invItem.quantity > 0;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF333333), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF444444), width: 1),
                  ),
                  child: const Icon(Icons.inventory, color: Color(0xFFBBBBBB), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              invItem.name,
                              style: const TextStyle(
                                color: Color(0xFFE0E0E0),
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B0000).withOpacity(0.25),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFF8B0000).withOpacity(0.4), width: 1),
                            ),
                            child: Text(
                              'x${invItem.quantity}',
                              style: const TextStyle(color: Color(0xFFE0E0E0), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hasDef ? itemDef!.description : (invItem.description ?? ''),
                        style: const TextStyle(color: Color(0xFFB0B0B0), fontSize: 12, height: 1.3),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasDef && itemDef!.effects.hasEffects) _buildEffectsChips(itemDef!.effects),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canUse ? () => _useInventoryItem(invItem.id) : null,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Use'),
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(36)),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: () => _confirmDiscard(invItem),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  label: const Text('Discard'),
                  style: OutlinedButton.styleFrom(minimumSize: const Size(100, 36)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEffectsChips(ItemEffects effects) {
    final chips = <Widget>[];
    if (effects.statChanges != null) {
      effects.statChanges!.forEach((stat, change) {
        final isPositive = change > 0;
        chips.add(_effectChip(
          text: '${stat.toUpperCase()} ${isPositive ? '+' : ''}$change',
          color: isPositive ? const Color(0xFF32CD32) : const Color(0xFFFF6B6B),
          icon: isPositive ? Icons.trending_up : Icons.trending_down,
        ));
      });
    }
    if (effects.applyStatus != null && effects.applyStatus!.isNotEmpty) {
      for (final s in effects.applyStatus!) {
        chips.add(_effectChip(text: s.toUpperCase(), color: const Color(0xFF4169E1), icon: Icons.auto_awesome));
      }
    }
    if (effects.removeStatus != null && effects.removeStatus!.isNotEmpty) {
      for (final s in effects.removeStatus!) {
        chips.add(_effectChip(text: 'REMOVE ${s.toUpperCase()}', color: const Color(0xFFAAAAAA), icon: Icons.cleaning_services));
      }
    }
    return Wrap(spacing: 6, runSpacing: 6, children: chips);
  }

  Widget _effectChip({required String text, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  void _useInventoryItem(String itemId) {
    if (gameState == null) return;
    final result = _inventoryManager.useItem(itemId, gameState!);
    if (result['success'] == true) {
      setState(() {
        gameState = result['gameState'] as GameState;
      });
      final desc = (result['description'] as String?) ?? 'Item used';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(desc), duration: const Duration(seconds: 2)),
        );
      }
    } else {
      final msg = (result['description'] as String?) ?? 'Cannot use item';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: const Color(0xFF8B0000)),
        );
      }
    }
  }

  void _confirmDiscard(InventoryItem invItem) async {
    if (!mounted) return;
    final choice = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          title: const Text('Discard item', style: TextStyle(color: Color(0xFFE0E0E0))),
          content: Text(
            'Discard ${invItem.name}?',
            style: const TextStyle(color: Color(0xFFB0B0B0)),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, 'cancel'), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, 'one'), child: const Text('Discard 1')),
            if (invItem.quantity > 1)
              TextButton(
                onPressed: () => Navigator.pop(context, 'all'),
                child: Text('Discard all (${invItem.quantity})'),
              ),
          ],
        );
      },
    );
    if (choice == 'one' || choice == 'all') {
      final qty = choice == 'all' ? invItem.quantity : 1;
      setState(() {
        gameState!.inventory.removeItem(invItem.id, quantity: qty);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Discarded ${choice == 'all' ? 'all of ' : ''}${invItem.name}'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
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
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
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
              child: mazeData != null
                  ? _buildMazeGrid()
                  : const Center(
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
                color: isVisited
                    ? const Color(0xFF666666)
                    : const Color(0xFF444444),
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
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

          // Minimap - show always to provide context
          _buildMiniMap(),

          // Room visualization - only show during navigation choices (doors)
          if (_shouldShowRoomStructure())
            _buildRoomVisualization(),

          const SizedBox(height: 16),

          // Event image (only show when there's an event with an image)
          if (gameState?.currentEvent?['image'] != null &&
              gameState!.currentEvent!['image'].isNotEmpty &&
              gameState!.currentEvent!['image'] != 'result.png' &&
              gameState!.currentEvent!['image'] != '')
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: 200,
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  _getImagePath(gameState!.currentEvent!['image']),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF2A2A2A),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.image_not_supported,
                          color: Color(0xFF8B0000),
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

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
                key: ValueKey(
                  gameState?.currentEvent?['description'] ?? 'default',
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    _buildEventText(
                      gameState?.currentEvent?['description'] ??
                          'Something happens...',
                    ),
                    // Show visual stat changes if available
                    if (gameState?.currentEvent?['effectsApplied'] != null)
                      _buildEffectsVisualDisplay(
                        gameState!.currentEvent!['effectsApplied'] as Map<String, dynamic>
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

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFF8B0000)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Stack(
        children: [
          SafeArea(
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
                  transitionBuilder:
                      (Widget child, Animation<double> animation) {
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
                  child:
                      (currentPageIndex == 2 &&
                          gameState?.currentEvent?['choices'] != null)
                      ? _buildChoiceButtons(gameState!.currentEvent!['choices'])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),

          // Turn transition overlay
          TurnTransitionWidget(
            message: _turnManager.getTurnTransitionMessage(),
            isVisible: _isTurnTransitionActive,
            duration: const Duration(milliseconds: 1500),
            onAnimationComplete: () {
              // Animation completion is handled in _triggerTurnTransition
            },
          ),
        ],
      ),
    );
  }

  /// Builds visual display for stat changes and status effects
  Widget _buildEffectsVisualDisplay(Map<String, dynamic> effectsApplied) {
    final statChanges = effectsApplied['statChanges'] as Map<String, dynamic>? ?? {};
    final statusEffectsApplied = effectsApplied['statusEffectsApplied'] as List<dynamic>? ?? [];
    final itemsGained = effectsApplied['itemsGained'] as List<dynamic>? ?? [];
    final itemsLost = effectsApplied['itemsLost'] as List<dynamic>? ?? [];

    // Don't show if no effects
    if (statChanges.isEmpty && statusEffectsApplied.isEmpty && 
        itemsGained.isEmpty && itemsLost.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1A1A1A).withOpacity(0.8),
            const Color(0xFF2A2A2A).withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF8B0000).withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(
                Icons.trending_up,
                color: const Color(0xFF8B0000),
                size: 18,
              ),
              const SizedBox(width: 8),
              const Text(
                '변화',
                style: TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Stat Changes
          if (statChanges.isNotEmpty) ...[
            _buildStatChangesDisplay(statChanges),
            if (statusEffectsApplied.isNotEmpty || itemsGained.isNotEmpty || itemsLost.isNotEmpty)
              const SizedBox(height: 12),
          ],
          
          // Status Effects
          if (statusEffectsApplied.isNotEmpty) ...[
            _buildStatusEffectsDisplay(statusEffectsApplied),
            if (itemsGained.isNotEmpty || itemsLost.isNotEmpty)
              const SizedBox(height: 12),
          ],
          
          // Items
          if (itemsGained.isNotEmpty || itemsLost.isNotEmpty) ...[
            _buildItemChangesDisplay(itemsGained, itemsLost),
          ],
        ],
      ),
    );
  }

  /// Builds display for stat changes
  Widget _buildStatChangesDisplay(Map<String, dynamic> statChanges) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...statChanges.entries.map((entry) {
          final statName = entry.key;
          final changes = entry.value as Map<String, int>;
          final actualChange = changes['actual'] ?? 0;
          
          if (actualChange == 0) return const SizedBox.shrink();
          
          final isPositive = actualChange > 0;
          final color = _getStatColor(statName, isPositive);
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                // Stat icon
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Icon(
                    _getStatIcon(statName),
                    size: 14,
                    color: color,
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Stat name
                Expanded(
                  child: Text(
                    _getStatDisplayName(statName),
                    style: const TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                
                // Change amount (larger and more prominent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.4),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}$actualChange',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).where((widget) => widget is! SizedBox),
      ],
    );
  }

  /// Builds display for status effects
  Widget _buildStatusEffectsDisplay(List<dynamic> statusEffects) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '상태 효과',
          style: TextStyle(
            color: Color(0xFFB0B0B0),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: statusEffects.map((effect) {
            final effectName = effect.toString();
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF4169E1).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFF4169E1).withOpacity(0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.auto_awesome,
                    size: 10,
                    color: const Color(0xFF4169E1),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    effectName,
                    style: const TextStyle(
                      color: Color(0xFF4169E1),
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// Builds display for item changes
  Widget _buildItemChangesDisplay(List<dynamic> itemsGained, List<dynamic> itemsLost) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '아이템',
          style: TextStyle(
            color: Color(0xFFB0B0B0),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            ...itemsGained.map((item) => _buildItemChip(item.toString(), true)),
            ...itemsLost.map((item) => _buildItemChip(item.toString(), false)),
          ],
        ),
      ],
    );
  }

  /// Builds individual item chip
  Widget _buildItemChip(String itemName, bool isGained) {
    final color = isGained ? const Color(0xFF32CD32) : const Color(0xFFFF6B6B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isGained ? Icons.add_circle_outline : Icons.remove_circle_outline,
            size: 10,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            itemName,
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Gets color for stat changes
  Color _getStatColor(String statName, bool isPositive) {
    switch (statName.toUpperCase()) {
      case 'HP':
        return isPositive ? const Color(0xFF32CD32) : const Color(0xFF8B0000);
      case 'SAN':
        return isPositive ? const Color(0xFF4169E1) : const Color(0xFF8A2BE2);
      case 'FITNESS':
      case 'FIT':
        return isPositive ? const Color(0xFFFFD700) : const Color(0xFFFF8C00);
      case 'HUNGER':
        return isPositive ? const Color(0xFF32CD32) : const Color(0xFFFF8C00);
      default:
        return isPositive ? const Color(0xFF32CD32) : const Color(0xFFFF6B6B);
    }
  }

  /// Gets icon for stat
  IconData _getStatIcon(String statName) {
    switch (statName.toUpperCase()) {
      case 'HP':
        return Icons.favorite;
      case 'SAN':
        return Icons.psychology;
      case 'FITNESS':
      case 'FIT':
        return Icons.fitness_center;
      case 'HUNGER':
        return Icons.restaurant;
      default:
        return Icons.trending_up;
    }
  }

  /// Gets display name for stat
  String _getStatDisplayName(String statName) {
    switch (statName.toUpperCase()) {
      case 'HP':
        return 'HP';
      case 'SAN':
        return 'SAN';
      case 'FITNESS':
      case 'FIT':
        return 'FITNESS';
      case 'HUNGER':
        return 'HUNGER';
      default:
        return statName;
    }
  }

  /// Determines if room structure should be visible
  /// Shows only during navigation choices (not during events or results)
  bool _shouldShowRoomStructure() {
    // Don't show if we're processing an event
    if (_isProcessingEvent) return false;
    
    // Don't show if there's no current event data
    if (gameState?.currentEvent == null) return true;
    
    // Check if current choices are navigation choices (doors)
    final choices = gameState?.currentEvent?['choices'] as List<dynamic>? ?? [];
    if (choices.isEmpty) return true;
    
    // Show room structure only if we have navigation choices (north/south/east/west)
    final hasNavigationChoices = choices.any((choice) {
      final direction = choice['direction']?.toString() ?? '';
      return ['north', 'south', 'east', 'west'].contains(direction);
    });
    
    // Don't show during 'continue' screens (event results) or other non-navigation states
    final hasContinueChoice = choices.any((choice) {
      final direction = choice['direction']?.toString() ?? '';
      return direction == 'continue';
    });
    
    return hasNavigationChoices && !hasContinueChoice;
  }

  /// Gets the correct asset path for an image based on its filename
  /// Automatically routes images to appropriate subfolders
  String _getImagePath(String? imageName) {
    if (imageName == null || imageName.isEmpty) {
      return 'assets/images/rooms/general/empty_room.png';
    }

    // Handle special UI images
    if (imageName == 'result.png' || imageName == 'empty_room.png') {
      return 'assets/images/rooms/general/$imageName';
    }

    // Determine subfolder based on filename patterns
    String subfolder = 'rooms/general'; // default

    // Character events
    if (imageName.contains('character') || 
        imageName.contains('person') || 
        imageName.contains('student') || 
        imageName.contains('worker') || 
        imageName.contains('guard')) {
      subfolder = 'events/characters';
    }
    // Monster events
    else if (imageName.contains('monster') || 
             imageName.contains('creature') || 
             imageName.contains('shadow') || 
             imageName.contains('ghost') || 
             imageName.contains('entity')) {
      subfolder = 'events/monsters';
    }
    // Trap events
    else if (imageName.contains('trap') || 
             imageName.contains('pit') || 
             imageName.contains('dart') || 
             imageName.contains('hazard') || 
             imageName.contains('wire')) {
      subfolder = 'events/traps';
    }
    // Item events
    else if (imageName.contains('item') || 
             imageName.contains('kit') || 
             imageName.contains('rope') || 
             imageName.contains('flashlight') || 
             imageName.contains('bandage') || 
             imageName.contains('drink') ||
             imageName.contains('discovery')) {
      subfolder = 'events/items';
    }

    return 'assets/images/$subfolder/$imageName';
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
      ..color =
          const Color(0xFF555555) // Slightly brighter for visited rooms
      ..style = PaintingStyle.fill;

    final unvisitedPaint = Paint()
      ..color =
          const Color(0xFF333333) // Slightly brighter for unvisited rooms
      ..style = PaintingStyle.fill;

    final playerPaint = Paint()
      ..color =
          const Color(0xFF00CC00) // Brighter green for player
      ..style = PaintingStyle.fill;

    final startPaint = Paint()
      ..color =
          const Color(0xFF0088FF) // Brighter blue for start
      ..style = PaintingStyle.fill;

    final exitPaint = Paint()
      ..color =
          const Color(0xFFCC0000) // Brighter red for exit
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color =
          const Color(0xFF777777) // Slightly brighter border
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
          ..color =
              const Color(0xFFAAAAAA) // Brighter door color
          ..style = PaintingStyle.fill;

        final doorSize = math.max(
          3.0,
          cellWidth * 0.15,
        ); // Larger doors, scale with cell size
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
            ..color =
                const Color(0xFFFFFFFF) // White icon on green background
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
        final seed =
            ((x / gridSize).floor() * 13 + (y / gridSize).floor() * 17) % 100;

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
        final seed =
            ((x / gridSize).floor() * 31 + (y / gridSize).floor() * 23) % 100;

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
      canvas.drawLine(const Offset(0, 0), Offset(size.width * 0.3, 0), paint);
      canvas.drawLine(
        Offset(size.width * 0.7, 0),
        Offset(size.width, 0),
        paint,
      );
    } else {
      // Solid top border
      canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), paint);
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
      canvas.drawLine(Offset(0, size.height * 0.3), const Offset(0, 0), paint);
    } else {
      // Solid left border
      canvas.drawLine(Offset(0, size.height), const Offset(0, 0), paint);
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
    canvas.drawLine(
      const Offset(0, cornerSize),
      const Offset(0, 0),
      cornerPaint,
    );
    canvas.drawLine(
      const Offset(0, 0),
      const Offset(cornerSize, 0),
      cornerPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(size.width - cornerSize, 0),
      Offset(size.width, 0),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, 0),
      Offset(size.width, cornerSize),
      cornerPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(size.width, size.height - cornerSize),
      Offset(size.width, size.height),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(size.width, size.height),
      Offset(size.width - cornerSize, size.height),
      cornerPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(cornerSize, size.height),
      Offset(0, size.height),
      cornerPaint,
    );
    canvas.drawLine(
      Offset(0, size.height),
      Offset(0, size.height - cornerSize),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    if (oldDelegate is! CurrentRoomPainter) return true;
    return oldDelegate.room != room;
  }
}
