import 'dart:math';
import '../models/event_model.dart';
import '../models/maze_model.dart';
import '../models/room_event_data.dart';

/// Service responsible for distributing events across maze rooms using weighted selection
class EventDistributor {
  final Random _random;
  final Map<String, RoomEventData> _roomEventData = {};

  EventDistributor({Random? random}) : _random = random ?? Random();

  /// Getter for room event data
  Map<String, RoomEventData> get roomEventData =>
      Map.unmodifiable(_roomEventData);

  /// Selects events from a collection using weighted random selection
  ///
  /// [events] - Map of event ID to Event objects to select from
  /// [count] - Number of events to select
  ///
  /// Returns a list of selected event IDs
  ///
  /// Throws [ArgumentError] if count is negative or greater than available events
  List<String> selectEventsByWeight(Map<String, Event> events, int count) {
    if (count < 0) {
      throw ArgumentError('Count cannot be negative: $count');
    }

    if (count == 0) {
      return [];
    }

    if (events.isEmpty) {
      return [];
    }

    if (count > events.length) {
      throw ArgumentError(
        'Cannot select $count events from ${events.length} available events',
      );
    }

    // Validate and normalize weights
    final validatedEvents = <String, Event>{};
    for (final entry in events.entries) {
      final event = entry.value;
      final normalizedWeight = _validateWeight(event.weight);

      // Create a copy with normalized weight if needed
      if (normalizedWeight != event.weight) {
        validatedEvents[entry.key] = event.copyWith(weight: normalizedWeight);
      } else {
        validatedEvents[entry.key] = event;
      }
    }

    final selectedIds = <String>[];
    final remainingEvents = Map<String, Event>.from(validatedEvents);

    // Select events without replacement
    for (int i = 0; i < count; i++) {
      if (remainingEvents.isEmpty) break;

      final selectedId = _selectSingleEventByWeight(remainingEvents);
      selectedIds.add(selectedId);
      remainingEvents.remove(selectedId);
    }

    return selectedIds;
  }

  /// Validates and normalizes event weight values
  ///
  /// Returns a valid weight (defaults to 10 for invalid weights)
  int _validateWeight(int weight) {
    if (weight <= 0) {
      return 10; // Default weight for invalid values
    }
    return weight;
  }

  /// Selects a single event from the collection using weighted random selection
  ///
  /// [events] - Map of available events to select from
  ///
  /// Returns the ID of the selected event
  String _selectSingleEventByWeight(Map<String, Event> events) {
    if (events.isEmpty) {
      throw StateError('Cannot select from empty event collection');
    }

    if (events.length == 1) {
      return events.keys.first;
    }

    // Calculate total weight for current collection
    final totalWeight = events.values
        .map((event) => event.weight)
        .reduce((a, b) => a + b);

    // Generate random number between 1 and totalWeight (inclusive)
    final randomValue = _random.nextInt(totalWeight) + 1;

    // Find the event that corresponds to this random value
    int cumulativeWeight = 0;
    for (final entry in events.entries) {
      cumulativeWeight += entry.value.weight;
      if (randomValue <= cumulativeWeight) {
        return entry.key;
      }
    }

    // Fallback (should never reach here with valid input)
    return events.keys.first;
  }

  /// Assigns exactly 10 trap events to unique rooms in the maze
  ///
  /// [maze] - The maze data containing room information
  /// [trapEvents] - Map of available trap events to assign
  ///
  /// Throws [ArgumentError] if there are insufficient trap events or rooms
  /// Throws [StateError] if unable to find enough available rooms
  void assignTrapEvents(MazeData maze, Map<String, Event> trapEvents) {
    if (trapEvents.isEmpty) {
      throw ArgumentError('No trap events available for assignment');
    }

    if (trapEvents.length < 10) {
      throw ArgumentError(
        'Insufficient trap events: need 10, have ${trapEvents.length}',
      );
    }

    // Clear existing room event data and reinitialize
    _roomEventData.clear();
    _initializeRoomEventData(maze);

    // Get all available rooms (excluding start and exit rooms)
    final availableRooms = _getAvailableRoomsForTraps(maze);

    if (availableRooms.length < 10) {
      throw StateError(
        'Insufficient rooms for trap assignment: need 10, have ${availableRooms.length}',
      );
    }

    // Select 10 trap events using weighted selection
    final selectedTrapEventIds = selectEventsByWeight(trapEvents, 10);

    // Select 10 random rooms for trap placement
    final selectedRooms = _selectRandomRooms(availableRooms, 10);

    // Assign each trap event to a unique room
    for (int i = 0; i < selectedTrapEventIds.length; i++) {
      final eventId = selectedTrapEventIds[i];
      final room = selectedRooms[i];
      final roomId = _getRoomId(room);

      // Mark room as having a trap event (prevents other events)
      _roomEventData[roomId] = _roomEventData[roomId]!.addEvent(
        eventId,
        isTrap: true,
      );
    }
  }

  /// Assigns exactly 15 item events across available rooms in the maze
  ///
  /// [maze] - The maze data containing room information
  /// [itemEvents] - Map of available item events to assign
  ///
  /// Item events can be assigned to any room except trap rooms and start/exit rooms.
  /// Multiple item events can be assigned to the same room.
  ///
  /// Throws [ArgumentError] if there are insufficient item events
  /// Throws [StateError] if no rooms are available for item assignment
  void assignItemEvents(MazeData maze, Map<String, Event> itemEvents) {
    if (itemEvents.isEmpty) {
      throw ArgumentError('No item events available for assignment');
    }

    if (itemEvents.length < 15) {
      throw ArgumentError(
        'Insufficient item events: need 15, have ${itemEvents.length}',
      );
    }

    // Initialize room event data if not already done
    if (_roomEventData.isEmpty) {
      _initializeRoomEventData(maze);
    }

    // Get all rooms available for item events (excludes start, exit, and trap rooms)
    final availableRooms = _getAvailableRoomsForItems(maze);

    if (availableRooms.isEmpty) {
      throw StateError('No rooms available for item assignment');
    }

    // Select 15 item events using weighted selection
    final selectedItemEventIds = selectEventsByWeight(itemEvents, 15);

    // Distribute item events randomly across available rooms
    // Multiple events can go to the same room
    for (final eventId in selectedItemEventIds) {
      final randomRoom = availableRooms[_random.nextInt(availableRooms.length)];
      final roomId = _getRoomId(randomRoom);

      // Add item event to the room (not a trap event)
      _roomEventData[roomId] = _roomEventData[roomId]!.addEvent(
        eventId,
        isTrap: false,
      );
    }
  }

  /// Gets all rooms available for item event assignment
  ///
  /// Excludes:
  /// - Start and exit rooms
  /// - Rooms that already have trap events
  List<MazeRoom> _getAvailableRoomsForItems(MazeData maze) {
    final availableRooms = <MazeRoom>[];

    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final room = maze.getRoomAt(x, y);
        if (room != null && !room.isStart && !room.isExit) {
          final roomId = _getRoomId(room);
          final roomData = _roomEventData[roomId];

          // Only include rooms that don't have trap events
          if (roomData == null || !roomData.hasTrapEvent) {
            availableRooms.add(room);
          }
        }
      }
    }

    return availableRooms;
  }

  /// Assigns character and monster events to available rooms in the maze
  ///
  /// [maze] - The maze data containing room information
  /// [allEvents] - Map of combined character and monster events to assign
  ///
  /// Each available room (excluding start, exit, and trap rooms) receives
  /// between 1 and 20 events randomly selected from the combined pool.
  ///
  /// Throws [ArgumentError] if no events are available for assignment
  /// Throws [StateError] if no rooms are available for assignment
  void assignCharacterMonsterEvents(
    MazeData maze,
    Map<String, Event> allEvents,
  ) {
    if (allEvents.isEmpty) {
      throw ArgumentError(
        'No character or monster events available for assignment',
      );
    }

    // Initialize room event data if not already done
    if (_roomEventData.isEmpty) {
      _initializeRoomEventData(maze);
    }

    // Get all rooms available for character/monster events
    final availableRooms = _getAvailableRoomsForCharacterMonster(maze);

    if (availableRooms.isEmpty) {
      throw StateError('No rooms available for character/monster assignment');
    }

    // Assign events to each available room
    for (final room in availableRooms) {
      final roomId = _getRoomId(room);

      // Randomly determine number of events for this room (1 to 20)
      final eventCount = _random.nextInt(20) + 1;

      // Select events for this room using weighted selection
      // Allow the same event to be selected multiple times if needed
      final selectedEvents = _selectEventsWithReplacement(
        allEvents,
        eventCount,
      );

      // Add all selected events to the room
      for (final eventId in selectedEvents) {
        _roomEventData[roomId] = _roomEventData[roomId]!.addEvent(
          eventId,
          isTrap: false,
        );
      }
    }
  }

  /// Gets all rooms available for character/monster event assignment
  ///
  /// Excludes:
  /// - Start and exit rooms
  /// - Rooms that already have trap events
  List<MazeRoom> _getAvailableRoomsForCharacterMonster(MazeData maze) {
    final availableRooms = <MazeRoom>[];

    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final room = maze.getRoomAt(x, y);
        if (room != null && !room.isStart && !room.isExit) {
          final roomId = _getRoomId(room);
          final roomData = _roomEventData[roomId];

          // Only include rooms that don't have trap events
          if (roomData == null || !roomData.hasTrapEvent) {
            availableRooms.add(room);
          }
        }
      }
    }

    return availableRooms;
  }

  /// Selects events with replacement using weighted selection
  ///
  /// [events] - Map of available events to select from
  /// [count] - Number of events to select
  ///
  /// Returns a list of selected event IDs (may contain duplicates)
  List<String> _selectEventsWithReplacement(
    Map<String, Event> events,
    int count,
  ) {
    if (events.isEmpty || count <= 0) {
      return [];
    }

    final selectedIds = <String>[];

    for (int i = 0; i < count; i++) {
      final selectedId = _selectSingleEventByWeight(events);
      selectedIds.add(selectedId);
    }

    return selectedIds;
  }

  /// Initializes room event data for all rooms in the maze
  void _initializeRoomEventData(MazeData maze) {
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final room = maze.getRoomAt(x, y);
        if (room != null) {
          final roomId = _getRoomId(room);
          if (!_roomEventData.containsKey(roomId)) {
            _roomEventData[roomId] = RoomEventData.empty(roomId);
          }
        }
      }
    }
  }

  /// Gets all rooms available for trap assignment (excludes start and exit rooms)
  List<MazeRoom> _getAvailableRoomsForTraps(MazeData maze) {
    final availableRooms = <MazeRoom>[];

    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        final room = maze.getRoomAt(x, y);
        if (room != null && !room.isStart && !room.isExit) {
          availableRooms.add(room);
        }
      }
    }

    return availableRooms;
  }

  /// Selects random rooms from the available rooms list
  List<MazeRoom> _selectRandomRooms(List<MazeRoom> availableRooms, int count) {
    if (count > availableRooms.length) {
      throw ArgumentError(
        'Cannot select $count rooms from ${availableRooms.length} available rooms',
      );
    }

    final roomsCopy = List<MazeRoom>.from(availableRooms);
    final selectedRooms = <MazeRoom>[];

    for (int i = 0; i < count; i++) {
      final randomIndex = _random.nextInt(roomsCopy.length);
      selectedRooms.add(roomsCopy.removeAt(randomIndex));
    }

    return selectedRooms;
  }

  /// Generates a unique room ID from room coordinates
  String _getRoomId(MazeRoom room) {
    return '${room.x},${room.y}';
  }

  /// Gets the room event data for a specific room
  RoomEventData? getRoomEventData(String roomId) {
    return _roomEventData[roomId];
  }

  /// Gets all room event data
  Map<String, RoomEventData> get allRoomEventData =>
      Map.unmodifiable(_roomEventData);
}
