import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/maze_model.dart';
import '../models/game_state.dart';

class GameManager {
  static final GameManager _instance = GameManager._internal();
  factory GameManager() => _instance;
  GameManager._internal();

  MazeData? _currentMaze;
  GameState? _gameState;
  bool _isInitialized = false;
  bool _isInitializing = false;

  // Getters
  MazeData? get currentMaze => _currentMaze;
  GameState? get gameState => _gameState;
  bool get isInitialized => _isInitialized;
  bool get isInitializing => _isInitializing;

  // Initialize game during intro
  Future<void> initializeGame() async {
    if (_isInitialized || _isInitializing) return;
    
    _isInitializing = true;
    
    try {
      // Step 1: Load random maze
      await _loadRandomMaze();
      
      // Step 2: Initialize game state with default stats
      _initializeGameState();
      
      _isInitialized = true;
      print('Game initialized successfully with maze: ${_currentMaze?.name}');
    } catch (e) {
      print('Error initializing game: $e');
    } finally {
      _isInitializing = false;
    }
  }

  // Load a random maze from the data files
  Future<void> _loadRandomMaze() async {
    try {
      // Get random maze number (1-8)  
      final random = Random();
      final mazeNumber = random.nextInt(8) + 1;
      
      print('=== ATTEMPTING TO LOAD MAZE ===');
      print('Trying to load: data/maze/maze_$mazeNumber.json');
      
      // Load maze data
      final String jsonString = await rootBundle.loadString('data/maze/maze_$mazeNumber.json');
      print('JSON loaded successfully, length: ${jsonString.length}');
      
      final Map<String, dynamic> mazeData = json.decode(jsonString);
      print('JSON parsed successfully');
      print('Start position from JSON: ${mazeData['startPosition']}');
      print('Exit position from JSON: ${mazeData['exitPosition']}');
      
      _currentMaze = MazeData.fromMap(mazeData);
      
      print('=== MAZE LOADING SUCCESS ===');
      print('Loaded maze: ${_currentMaze?.name}');
      print('Start room: (${_currentMaze?.startRoom.x}, ${_currentMaze?.startRoom.y})');
      print('Exit room: (${_currentMaze?.exitRoom.x}, ${_currentMaze?.exitRoom.y})');
      print('Maze grid size: ${_currentMaze?.grid.length}x${_currentMaze?.grid[0].length}');
      print('=============================');
    } catch (e, stackTrace) {
      print('=== MAZE LOADING ERROR ===');
      print('Error loading maze: $e');
      print('Stack trace: $stackTrace');
      print('Using fallback maze instead');
      print('==========================');
      // Fallback to a basic maze if loading fails
      _createFallbackMaze();
    }
  }

  // Initialize game state with default stats
  void _initializeGameState() {
    _gameState = GameState(
      stats: PlayerStats.initial(), // HP: 100, SAN: 100, FIT: 70, HUNGER: 80
      statusEffects: [],
      inventory: PlayerInventory(),
      turnCount: 0,
      startTime: DateTime.now(),
    );
  }

  // Create a basic fallback maze if loading fails
  void _createFallbackMaze() {
    // Create a simple 8x8 maze with basic connections
    List<List<MazeRoom>> grid = List.generate(8, (y) => 
      List.generate(8, (x) => MazeRoom(
        x: x, 
        y: y,
        north: y > 0,
        east: x < 7,
        south: y < 7,
        west: x > 0,
        isStart: x == 0 && y == 7, // Bottom-left
        isExit: x == 7 && y == 0,  // Top-right
      ))
    );

    _currentMaze = MazeData(
      id: 0,
      name: 'Basic Maze',
      difficulty: 'Easy',
      grid: grid,
      startRoom: grid[7][0], // Bottom-left in grid coordinates
      exitRoom: grid[0][7],  // Top-right in grid coordinates
    );
  }

  // Get player's current position (starts at maze start)
  MazeRoom get currentPlayerPosition {
    return _currentMaze?.startRoom ?? 
           MazeRoom(x: 0, y: 0, north: false, east: true, south: true, west: false, isStart: true);
  }

  // Check if player can move in a direction
  bool canMoveInDirection(int currentX, int currentY, String direction) {
    final room = _currentMaze?.getRoomAt(currentX, currentY);
    return room?.canMoveTo(direction) ?? false;
  }

  // Process player movement
  MazeRoom? movePlayer(int currentX, int currentY, String direction) {
    if (!canMoveInDirection(currentX, currentY, direction)) {
      return null;
    }
    
    return _currentMaze?.getAdjacentRoom(currentX, currentY, direction);
  }

  // Reset game state for new game
  void resetGame() {
    _currentMaze = null;
    _gameState = null;
    _isInitialized = false;
    _isInitializing = false;
  }

  // Apply event effects to game state
  void applyEventEffects(Map<String, int> statChanges, List<StatusEffect>? statusEffects) {
    if (_gameState == null) return;

    // Apply stat changes
    _gameState!.applyStatChanges(statChanges);

    // Add status effects
    if (statusEffects != null) {
      for (final effect in statusEffects) {
        _gameState!.addStatusEffect(effect);
      }
    }

    // Process turn effects
    _gameState!.processTurn();
  }

  // Check for game over conditions
  bool get isGameOver => _gameState?.isGameOver ?? false;
  String? get gameOverReason => _gameState?.gameOverReason;

  // Save game state
  Map<String, dynamic> saveGame() {
    return {
      'gameState': _gameState?.toMap(),
      'currentMaze': _currentMaze?.toMap(),
      'isInitialized': _isInitialized,
    };
  }

  // Load game state
  void loadGame(Map<String, dynamic> saveData) {
    try {
      if (saveData['gameState'] != null) {
        _gameState = GameState.fromMap(saveData['gameState']);
      }
      
      if (saveData['currentMaze'] != null) {
        _currentMaze = MazeData.fromMap(saveData['currentMaze']);
      }
      
      _isInitialized = saveData['isInitialized'] ?? false;
    } catch (e) {
      print('Error loading game: $e');
    }
  }
}