/// Model for tracking event assignments and state for individual maze rooms
class RoomEventData {
  final String roomId;
  final List<String> availableEventIds;
  final List<String> consumedEventIds;
  final bool hasTrapEvent;
  final int eventCount;

  RoomEventData({
    required this.roomId,
    required this.availableEventIds,
    required this.consumedEventIds,
    required this.hasTrapEvent,
    required this.eventCount,
  });

  /// Creates a copy of this RoomEventData with updated values
  RoomEventData copyWith({
    String? roomId,
    List<String>? availableEventIds,
    List<String>? consumedEventIds,
    bool? hasTrapEvent,
    int? eventCount,
  }) {
    return RoomEventData(
      roomId: roomId ?? this.roomId,
      availableEventIds: availableEventIds ?? List.from(this.availableEventIds),
      consumedEventIds: consumedEventIds ?? List.from(this.consumedEventIds),
      hasTrapEvent: hasTrapEvent ?? this.hasTrapEvent,
      eventCount: eventCount ?? this.eventCount,
    );
  }

  /// Creates an empty room event data for a given room
  factory RoomEventData.empty(String roomId) {
    return RoomEventData(
      roomId: roomId,
      availableEventIds: [],
      consumedEventIds: [],
      hasTrapEvent: false,
      eventCount: 0,
    );
  }

  /// Adds an event to this room's available events
  RoomEventData addEvent(String eventId, {bool isTrap = false}) {
    final newAvailableEvents = List<String>.from(availableEventIds);
    if (!newAvailableEvents.contains(eventId)) {
      newAvailableEvents.add(eventId);
    }

    return copyWith(
      availableEventIds: newAvailableEvents,
      hasTrapEvent: hasTrapEvent || isTrap,
      eventCount: newAvailableEvents.length,
    );
  }

  /// Removes an event from available events (marks as consumed)
  RoomEventData consumeEvent(String eventId) {
    final newAvailableEvents = List<String>.from(availableEventIds);
    final newConsumedEvents = List<String>.from(consumedEventIds);

    if (newAvailableEvents.contains(eventId)) {
      newAvailableEvents.remove(eventId);
      if (!newConsumedEvents.contains(eventId)) {
        newConsumedEvents.add(eventId);
      }
    }

    return copyWith(
      availableEventIds: newAvailableEvents,
      consumedEventIds: newConsumedEvents,
      eventCount: newAvailableEvents.length,
    );
  }

  /// Checks if this room has any available events
  bool get hasAvailableEvents => availableEventIds.isNotEmpty;

  /// Checks if this room is available for non-trap events
  bool get isAvailableForEvents => !hasTrapEvent;

  /// Gets the total number of events that have been assigned to this room
  int get totalEventsAssigned =>
      availableEventIds.length + consumedEventIds.length;

  /// Checks if a specific event is available in this room
  bool hasEvent(String eventId) => availableEventIds.contains(eventId);

  /// Checks if a specific event has been consumed in this room
  bool hasConsumedEvent(String eventId) => consumedEventIds.contains(eventId);

  /// Gets a copy of available event IDs (immutable)
  List<String> get availableEvents => List.unmodifiable(availableEventIds);

  /// Gets a copy of consumed event IDs (immutable)
  List<String> get consumedEvents => List.unmodifiable(consumedEventIds);

  /// Checks if the room is empty (no events available or consumed)
  bool get isEmpty => totalEventsAssigned == 0;

  /// Restores a consumed event back to available (for persistent events)
  RoomEventData restoreEvent(String eventId) {
    final newAvailableEvents = List<String>.from(availableEventIds);
    final newConsumedEvents = List<String>.from(consumedEventIds);

    if (newConsumedEvents.contains(eventId) &&
        !newAvailableEvents.contains(eventId)) {
      newConsumedEvents.remove(eventId);
      newAvailableEvents.add(eventId);
    }

    return copyWith(
      availableEventIds: newAvailableEvents,
      consumedEventIds: newConsumedEvents,
      eventCount: newAvailableEvents.length,
    );
  }

  /// Removes an event completely from the room (both available and consumed)
  RoomEventData removeEventCompletely(String eventId) {
    final newAvailableEvents = List<String>.from(availableEventIds);
    final newConsumedEvents = List<String>.from(consumedEventIds);

    newAvailableEvents.remove(eventId);
    newConsumedEvents.remove(eventId);

    return copyWith(
      availableEventIds: newAvailableEvents,
      consumedEventIds: newConsumedEvents,
      eventCount: newAvailableEvents.length,
    );
  }

  @override
  String toString() {
    return 'RoomEventData(roomId: $roomId, available: ${availableEventIds.length}, consumed: ${consumedEventIds.length}, hasTrap: $hasTrapEvent)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is RoomEventData &&
        other.roomId == roomId &&
        other.availableEventIds.length == availableEventIds.length &&
        other.consumedEventIds.length == consumedEventIds.length &&
        other.hasTrapEvent == hasTrapEvent &&
        other.eventCount == eventCount;
  }

  @override
  int get hashCode {
    return roomId.hashCode ^
        availableEventIds.length.hashCode ^
        consumedEventIds.length.hashCode ^
        hasTrapEvent.hashCode ^
        eventCount.hashCode;
  }
}
