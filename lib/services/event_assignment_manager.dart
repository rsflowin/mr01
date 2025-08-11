import 'dart:math';
import '../models/event_model.dart';
import '../models/maze_model.dart';
import '../models/room_event_data.dart';
import 'event_loader.dart';
import 'event_distributor.dart';
import 'logger_service.dart';
import 'error_handler_service.dart';

/// Manager responsible for coordinating event assignment across the entire maze
/// Handles the complete event assignment lifecycle from loading to distribution
class EventAssignmentManager {
  final EventLoader _eventLoader;
  final EventDistributor _eventDistributor;

  // Services
  final LoggerService _logger = LoggerService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();

  // Event databases
  Map<String, Event> _allEvents = {};
  Map<String, Event> _trapEvents = {};
  Map<String, Event> _itemEvents = {};
  Map<String, Event> _characterEvents = {};
  Map<String, Event> _monsterEvents = {};

  // Room event data
  Map<String, RoomEventData> _roomEventData = {};

  EventAssignmentManager({
    EventLoader? eventLoader,
    EventDistributor? eventDistributor,
    Random? random,
  }) : _eventLoader = eventLoader ?? EventLoader(),
       _eventDistributor = eventDistributor ?? EventDistributor(random: random);

  /// Getters for event data
  Map<String, Event> get allEvents => Map.unmodifiable(_allEvents);
  Map<String, RoomEventData> get roomEventData =>
      Map.unmodifiable(_roomEventData);

  /// Loads all event data from JSON files
  ///
  /// This method loads trap, item, character, and monster events from their
  /// respective JSON files and validates the data structure.
  ///
  /// Returns true if all events loaded successfully, false otherwise
  Future<bool> loadAllEvents() async {
    try {
      _logger.info('EventAssignmentManager', '=== LOADING ALL EVENT DATA ===');

      // Load all event types in parallel for better performance
      final results = await Future.wait([
        _eventLoader.loadTrapEvents(),
        _eventLoader.loadItemEvents(),
        _eventLoader.loadCharacterEvents(),
        _eventLoader.loadMonsterEvents(),
      ]);

      _trapEvents = results[0];
      _itemEvents = results[1];
      _characterEvents = results[2];
      _monsterEvents = results[3];

      // Combine all events into master database
      _allEvents = {
        ..._trapEvents,
        ..._itemEvents,
        ..._characterEvents,
        ..._monsterEvents,
      };

      _logger.info('EventAssignmentManager', 'Event loading complete', {
        'trapEvents': _trapEvents.length,
        'itemEvents': _itemEvents.length,
        'characterEvents': _characterEvents.length,
        'monsterEvents': _monsterEvents.length,
        'totalEvents': _allEvents.length,
      });

      // Validate minimum event requirements
      final hasMinimumEvents = _validateMinimumEventRequirements();

      if (!hasMinimumEvents) {
        _logger.warning(
          'EventAssignmentManager',
          'Insufficient events loaded for proper assignment',
        );
        await _errorHandler.handleError(
          'EventLoadingError',
          'EventAssignmentManager',
          'Insufficient events loaded',
          StateError('Insufficient events for assignment'),
          null,
          {
            'trapEvents': _trapEvents.length,
            'itemEvents': _itemEvents.length,
            'characterEvents': _characterEvents.length,
            'monsterEvents': _monsterEvents.length,
          },
        );
        return false;
      }

      _logger.info('EventAssignmentManager', '=== EVENT LOADING SUCCESS ===');
      return true;
    } catch (e, stackTrace) {
      _logger.error('EventAssignmentManager', '=== EVENT LOADING ERROR ===', {
        'error': e.toString(),
      }, stackTrace);

      await _errorHandler.handleError(
        'EventLoadingError',
        'EventAssignmentManager',
        'Event loading failed',
        e,
        stackTrace,
        {'operation': 'loadAllEvents'},
      );

      return false;
    }
  }

  /// Validates that we have enough events for proper assignment
  bool _validateMinimumEventRequirements() {
    const minTrapEvents = 10;
    const minItemEvents = 15;
    const minCharacterMonsterEvents = 50; // For populating many rooms

    if (_trapEvents.length < minTrapEvents) {
      _logger.error(
        'EventAssignmentManager',
        'Need at least $minTrapEvents trap events, have ${_trapEvents.length}',
      );
      return false;
    }

    if (_itemEvents.length < minItemEvents) {
      _logger.error(
        'EventAssignmentManager',
        'Need at least $minItemEvents item events, have ${_itemEvents.length}',
      );
      return false;
    }

    final combinedCharacterMonster =
        _characterEvents.length + _monsterEvents.length;
    if (combinedCharacterMonster < minCharacterMonsterEvents) {
      _logger.error(
        'EventAssignmentManager',
        'Need at least $minCharacterMonsterEvents character/monster events, have $combinedCharacterMonster',
      );
      return false;
    }

    return true;
  }

  /// Assigns all events to maze rooms according to the design specifications
  ///
  /// This method follows the three-phase assignment strategy:
  /// 1. Assign 10 trap events to exclusive rooms
  /// 2. Assign 15 item events across available rooms
  /// 3. Populate remaining rooms with character/monster events
  ///
  /// [maze] - The maze to assign events to
  ///
  /// Returns true if assignment completed successfully
  Future<bool> assignEventsToMaze(MazeData maze) async {
    try {
      _logger.info(
        'EventAssignmentManager',
        '=== STARTING EVENT ASSIGNMENT ===',
      );

      // Clear any previous assignments
      _roomEventData.clear();

      // Phase 1: Assign trap events to exclusive rooms
      _logger.info(
        'EventAssignmentManager',
        'Phase 1: Assigning trap events...',
      );
      _eventDistributor.assignTrapEvents(maze, _trapEvents);

      // Phase 2: Assign item events across available rooms
      _logger.info(
        'EventAssignmentManager',
        'Phase 2: Assigning item events...',
      );
      _eventDistributor.assignItemEvents(maze, _itemEvents);

      // Phase 3: Assign character and monster events to remaining rooms
      _logger.info(
        'EventAssignmentManager',
        'Phase 3: Assigning character and monster events...',
      );
      final characterMonsterEvents = {..._characterEvents, ..._monsterEvents};
      _eventDistributor.assignCharacterMonsterEvents(
        maze,
        characterMonsterEvents,
      );

      // Get the room event data from the distributor
      _roomEventData = Map.from(_eventDistributor.roomEventData);

      // Validate assignment results
      final assignmentValid = _validateEventAssignment(maze);

      if (assignmentValid) {
        _logger.info(
          'EventAssignmentManager',
          '=== EVENT ASSIGNMENT SUCCESS ===',
        );
        _printAssignmentSummary();
        return true;
      } else {
        _logger.error(
          'EventAssignmentManager',
          '=== EVENT ASSIGNMENT VALIDATION FAILED ===',
        );
        await _errorHandler.handleError(
          'EventAssignmentError',
          'EventAssignmentManager',
          'Event assignment validation failed',
          StateError('Event assignment validation failed'),
          null,
          {'mazeSize': maze.grid.length * maze.grid[0].length},
        );
        return false;
      }
    } catch (e, stackTrace) {
      _logger.error(
        'EventAssignmentManager',
        '=== EVENT ASSIGNMENT ERROR ===',
        {'error': e.toString()},
        stackTrace,
      );

      await _errorHandler.handleError(
        'EventAssignmentError',
        'EventAssignmentManager',
        'Event assignment failed',
        e,
        stackTrace,
        {'operation': 'assignEventsToMaze'},
      );

      return false;
    }
  }

  /// Validates that event assignment meets the requirements
  bool _validateEventAssignment(MazeData maze) {
    int trapRooms = 0;
    int roomsWithEvents = 0;

    for (final roomData in _roomEventData.values) {
      if (roomData.hasTrapEvent) {
        trapRooms++;
      }

      roomsWithEvents += roomData.hasAvailableEvents ? 1 : 0;
    }

    // Validate trap assignment
    if (trapRooms != 10) {
      _logger.error(
        'EventAssignmentManager',
        'Expected 10 trap rooms, found $trapRooms',
      );
      return false;
    }

    // Validate that we have events distributed
    if (roomsWithEvents < 20) {
      _logger.warning(
        'EventAssignmentManager',
        'Only $roomsWithEvents rooms have events, expected more distribution',
      );
    }

    return true;
  }

  /// Prints a summary of the event assignment for debugging
  void _printAssignmentSummary() {
    int trapRooms = 0;
    int emptyRooms = 0;
    int roomsWithEvents = 0;
    int totalEventsAssigned = 0;

    for (final roomData in _roomEventData.values) {
      if (roomData.hasTrapEvent) {
        trapRooms++;
      }

      if (roomData.hasAvailableEvents) {
        roomsWithEvents++;
        totalEventsAssigned += roomData.eventCount;
      } else {
        emptyRooms++;
      }
    }

    _logger.info('EventAssignmentManager', 'Event Assignment Summary', {
      'trapRooms': trapRooms,
      'roomsWithEvents': roomsWithEvents,
      'emptyRooms': emptyRooms,
      'totalEventsAssigned': totalEventsAssigned,
      'totalRoomsProcessed': _roomEventData.length,
    });
  }

  /// Gets room event data for a specific room
  ///
  /// [roomId] - The room identifier (format: "x,y")
  ///
  /// Returns the room's event data, or empty data if room not found
  RoomEventData getRoomEventData(String roomId) {
    final roomData = _roomEventData[roomId];
    _logger.debug('EventAssignmentManager', 'Getting room data for: $roomId', {
      'hasData': roomData != null,
      'hasEvents': roomData?.hasAvailableEvents ?? false,
      'eventCount': roomData?.eventCount ?? 0,
      'totalRoomsWithData': _roomEventData.length,
    });
    return roomData ?? RoomEventData.empty(roomId);
  }

  /// Updates room event data after an event is consumed
  ///
  /// [roomId] - The room identifier
  /// [updatedRoomData] - The updated room event data
  void updateRoomEventData(String roomId, RoomEventData updatedRoomData) {
    _roomEventData[roomId] = updatedRoomData;
  }

  /// Gets an event by its ID from the master database
  ///
  /// [eventId] - The event identifier
  ///
  /// Returns the event if found, null otherwise
  Event? getEvent(String eventId) {
    return _allEvents[eventId];
  }

  /// Checks if events have been loaded and assigned
  bool get isInitialized => _allEvents.isNotEmpty && _roomEventData.isNotEmpty;

  /// Resets all event assignments (for new game)
  void reset() {
    _allEvents.clear();
    _trapEvents.clear();
    _itemEvents.clear();
    _characterEvents.clear();
    _monsterEvents.clear();
    _roomEventData.clear();
    print('Event assignment manager reset');
  }

  /// Saves event assignment data for persistence
  ///
  /// Returns a map containing all event assignment data for saving
  Map<String, dynamic> saveEventAssignments() {
    return {
      'roomEventData': _roomEventData.map(
        (roomId, roomData) => MapEntry(roomId, {
          'roomId': roomData.roomId,
          'availableEventIds': roomData.availableEventIds,
          'consumedEventIds': roomData.consumedEventIds,
          'hasTrapEvent': roomData.hasTrapEvent,
          'eventCount': roomData.eventCount,
        }),
      ),
      'assignmentTimestamp': DateTime.now().toIso8601String(),
      'eventsLoadedCount': _allEvents.length,
    };
  }

  /// Loads event assignment data from saved data
  ///
  /// [savedData] - The saved event assignment data
  /// [maze] - The maze to validate assignments against
  ///
  /// Returns true if loading was successful
  Future<bool> loadEventAssignments(
    Map<String, dynamic> savedData,
    MazeData maze,
  ) async {
    try {
      print('=== LOADING EVENT ASSIGNMENTS ===');

      // First ensure events are loaded
      if (_allEvents.isEmpty) {
        final eventsLoaded = await loadAllEvents();
        if (!eventsLoaded) {
          print('ERROR: Failed to load events for assignment loading');
          return false;
        }
      }

      // Load room event data
      final roomEventDataMap =
          savedData['roomEventData'] as Map<String, dynamic>? ?? {};

      _roomEventData.clear();

      for (final entry in roomEventDataMap.entries) {
        final roomId = entry.key;
        final roomDataMap = entry.value as Map<String, dynamic>;

        _roomEventData[roomId] = RoomEventData(
          roomId: roomDataMap['roomId'] ?? roomId,
          availableEventIds: List<String>.from(
            roomDataMap['availableEventIds'] ?? [],
          ),
          consumedEventIds: List<String>.from(
            roomDataMap['consumedEventIds'] ?? [],
          ),
          hasTrapEvent: roomDataMap['hasTrapEvent'] ?? false,
          eventCount: roomDataMap['eventCount']?.toInt() ?? 0,
        );
      }

      // Validate loaded assignments
      final assignmentValid = _validateEventAssignment(maze);

      if (assignmentValid) {
        print('=== EVENT ASSIGNMENT LOADING SUCCESS ===');
        _printAssignmentSummary();
        return true;
      } else {
        print('WARNING: Loaded assignments failed validation, regenerating...');
        return await assignEventsToMaze(maze);
      }
    } catch (e, stackTrace) {
      print('=== EVENT ASSIGNMENT LOADING ERROR ===');
      print('Error loading assignments: $e');
      print('Stack trace: $stackTrace');

      // Fallback to regenerating assignments
      return await assignEventsToMaze(maze);
    }
  }

  /// Creates a room identifier from coordinates
  static String createRoomId(int x, int y) {
    return '$x,$y';
  }

  /// Parses coordinates from a room identifier
  static Map<String, int> parseRoomId(String roomId) {
    final parts = roomId.split(',');
    if (parts.length != 2) {
      throw ArgumentError('Invalid room ID format: $roomId');
    }

    return {'x': int.parse(parts[0]), 'y': int.parse(parts[1])};
  }

  /// Gets room event data by coordinates
  RoomEventData getRoomEventDataByCoordinates(int x, int y) {
    final roomId = createRoomId(x, y);
    _logger.debug('EventAssignmentManager', 'Getting room data by coordinates', {
      'x': x,
      'y': y,
      'roomId': roomId,
      'availableRoomIds': _roomEventData.keys.take(10).toList(), // Show first 10 room IDs
      'totalRooms': _roomEventData.length,
    });
    return getRoomEventData(roomId);
  }

  /// Updates room event data by coordinates
  void updateRoomEventDataByCoordinates(
    int x,
    int y,
    RoomEventData updatedRoomData,
  ) {
    final roomId = createRoomId(x, y);
    updateRoomEventData(roomId, updatedRoomData);
  }
}
