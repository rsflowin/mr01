import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/event_model.dart';
import 'logger_service.dart';
import 'error_handler_service.dart';
import 'performance_optimizer.dart';

/// Service responsible for loading and validating event data from JSON files
/// Includes caching and memory management for optimal performance
/// Enhanced with performance optimizer integration and monitoring
class EventLoader {
  static const String _eventsPath = 'data/events';

  // Services
  final LoggerService _logger = LoggerService();
  final ErrorHandlerService _errorHandler = ErrorHandlerService();
  final PerformanceOptimizer _performanceOptimizer = PerformanceOptimizer();

  // Caching and memory management
  final Map<String, Map<String, Event>> _eventCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, int> _cacheAccessCounts = {};
  static const Duration _cacheExpiryDuration = Duration(minutes: 30);
  static const int _maxCacheSize = 1000;
  static const int _maxCacheAccessCount = 100;

  // Memory management
  final List<String> _recentlyAccessedEvents = [];
  static const int _maxRecentlyAccessedSize = 200;

  // Performance monitoring
  final Map<String, List<Duration>> _loadingTimings = {};
  final Map<String, int> _loadingCounts = {};

  /// Loads trap events from event_traps.json
  /// Returns a map of event ID to Event objects
  /// Handles missing files and malformed JSON with comprehensive error handling
  /// Uses caching to avoid repeated file loading
  /// Enhanced with performance optimization
  Future<Map<String, Event>> loadTrapEvents() async {
    return await _loadEventsFromFileWithCache(
      '$_eventsPath/event_traps.json',
      'trap',
    );
  }

  /// Loads item events from event_items.json
  /// Returns a map of event ID to Event objects
  /// Handles missing files and malformed JSON with comprehensive error handling
  /// Uses caching to avoid repeated file loading
  /// Enhanced with performance optimization
  Future<Map<String, Event>> loadItemEvents() async {
    return await _loadEventsFromFileWithCache(
      '$_eventsPath/event_items.json',
      'item',
    );
  }

  /// Loads character events from all event_character_*.json files
  /// Returns a map of event ID to Event objects combining all character files
  /// Handles missing files and malformed JSON with comprehensive error handling
  /// Uses caching to avoid repeated file loading
  /// Enhanced with performance optimization and parallel loading
  Future<Map<String, Event>> loadCharacterEvents() async {
    _performanceOptimizer.startOperationMeasurement('loadCharacterEvents');

    try {
      final Map<String, Event> allCharacterEvents = {};
      final List<Future<Map<String, Event>>> loadFutures = [];

      // Load all character event files in parallel for better performance
      for (int i = 1; i <= 18; i++) {
        loadFutures.add(
          _loadEventsFromFileWithCache(
            '$_eventsPath/event_character_$i.json',
            'character',
          ),
        );
      }

      // Wait for all files to load
      final results = await Future.wait(loadFutures);

      // Combine results
      for (final characterEvents in results) {
        allCharacterEvents.addAll(characterEvents);
      }

      // Preload frequent character events for better performance
      await _performanceOptimizer.preloadFrequentEvents(allCharacterEvents);

      return allCharacterEvents;
    } finally {
      _performanceOptimizer.endOperationMeasurement('loadCharacterEvents');
    }
  }

  /// Loads monster events from event_monsters.json
  /// Returns a map of event ID to Event objects
  /// Handles missing files and malformed JSON with comprehensive error handling
  /// Uses caching to avoid repeated file loading
  /// Enhanced with performance optimization
  Future<Map<String, Event>> loadMonsterEvents() async {
    return await _loadEventsFromFileWithCache(
      '$_eventsPath/event_monsters.json',
      'monster',
    );
  }

  /// Private method to load events from a specific JSON file with caching
  /// Provides comprehensive error handling, validation, and performance optimization
  /// Enhanced with performance monitoring and optimizer integration
  Future<Map<String, Event>> _loadEventsFromFileWithCache(
    String filePath,
    String expectedCategory,
  ) async {
    final operationName = 'loadEvents_${filePath.split('/').last}';
    _performanceOptimizer.startOperationMeasurement(operationName);

    try {
      // Check cache first
      if (_isCacheValid(filePath)) {
        _logger.info('EventLoader', 'Using cached events for: $filePath');
        _updateCacheAccess(filePath);
        _recordLoadingTime(operationName, Duration.zero);
        return _eventCache[filePath]!;
      }

      // Load from file if not cached or cache expired
      final events = await _loadEventsFromFile(filePath, expectedCategory);

      // Cache the results
      _cacheEvents(filePath, events);

      // Add events to performance optimizer cache
      _addEventsToPerformanceCache(events);

      return events;
    } finally {
      _performanceOptimizer.endOperationMeasurement(operationName);
    }
  }

  /// Adds events to performance optimizer cache for better performance
  void _addEventsToPerformanceCache(Map<String, Event> events) {
    for (final entry in events.entries) {
      _performanceOptimizer.cacheEvent(entry.key, entry.value);
    }

    _logger.debug(
      'EventLoader',
      'Added ${events.length} events to performance cache',
    );
  }

  /// Records loading time for performance monitoring
  void _recordLoadingTime(String operationName, Duration duration) {
    _loadingTimings.putIfAbsent(operationName, () => []).add(duration);
    _loadingCounts[operationName] = (_loadingCounts[operationName] ?? 0) + 1;
  }

  /// Private method to load events from a specific JSON file
  /// Provides comprehensive error handling and validation
  /// Enhanced with performance monitoring
  Future<Map<String, Event>> _loadEventsFromFile(
    String filePath,
    String expectedCategory,
  ) async {
    final startTime = DateTime.now();

    try {
      _logger.info('EventLoader', 'Loading events from: $filePath');

      // Load JSON string using rootBundle (Flutter web compatible)
      String jsonString;
      try {
        jsonString = await rootBundle.loadString(filePath);
        _logger.info(
          'EventLoader',
          'Successfully loaded JSON string from: $filePath, length: ${jsonString.length}',
        );
      } catch (e) {
        _logger.warning(
          'EventLoader',
          'Event file not found: $filePath, error: $e',
        );
        return _createFallbackEvents(expectedCategory);
      }

      final jsonData = json.decode(jsonString) as Map<String, dynamic>;
      _logger.info('EventLoader', 'Successfully parsed JSON from: $filePath');

      // Validate JSON structure
      if (!jsonData.containsKey('events')) {
        _logger.error('EventLoader', 'Invalid JSON structure in: $filePath');
        return _createFallbackEvents(expectedCategory);
      }

      // Parse events - handle both array and map structures
      final eventsData = jsonData['events'];
      final events = <String, Event>{};

      if (eventsData is List<dynamic>) {
        // Handle array structure: {"events": [{...}, {...}]}
        for (final eventData in eventsData) {
          try {
            _logger.debug('EventLoader', 'Parsing event from array');
            final event = Event.fromMap(eventData as Map<String, dynamic>);

            // Validate event category
            if (event.category != expectedCategory) {
              _logger.warning(
                'EventLoader',
                'Event category mismatch: expected $expectedCategory, got ${event.category}',
              );
            }

            events[event.id] = event;
          } catch (e, stackTrace) {
            _logger.error(
              'EventLoader',
              'Failed to parse event from: $filePath',
              {'eventData': eventData},
              stackTrace,
            );
          }
        }
      } else if (eventsData is Map<String, dynamic>) {
        // Handle map structure: {"events": {"id1": {...}, "id2": {...}}}
        for (final entry in eventsData.entries) {
          try {
            final eventData = entry.value as Map<String, dynamic>;
            _logger.debug('EventLoader', 'Parsing event: ${entry.key}');
            final event = Event.fromMap(eventData);

            // Validate event category
            if (event.category != expectedCategory) {
              _logger.warning(
                'EventLoader',
                'Event category mismatch: expected $expectedCategory, got ${event.category}',
              );
            }

            events[event.id] = event;
          } catch (e, stackTrace) {
            _logger.error(
              'EventLoader',
              'Failed to parse event from: $filePath',
              {'eventData': entry.value},
              stackTrace,
            );
          }
        }
      } else {
        _logger.error(
          'EventLoader',
          'Invalid events data type in: $filePath, type: ${eventsData.runtimeType}',
        );
        return _createFallbackEvents(expectedCategory);
      }

      final duration = DateTime.now().difference(startTime);
      _recordLoadingTime('parseEvents_${filePath.split('/').last}', duration);

      _logger.info(
        'EventLoader',
        'Successfully loaded ${events.length} events from: $filePath in ${duration.inMilliseconds}ms',
      );

      return events;
    } catch (e, stackTrace) {
      final duration = DateTime.now().difference(startTime);
      _recordLoadingTime('error_${filePath.split('/').last}', duration);

      _logger.error(
        'EventLoader',
        'Failed to load events from: $filePath',
        {},
        stackTrace,
      );

      // Return fallback events on error
      return _createFallbackEvents(expectedCategory);
    }
  }

  /// Creates fallback events when file loading fails
  /// Ensures the system can continue functioning even with missing event data
  Map<String, Event> _createFallbackEvents(String category) {
    _logger.info(
      'EventLoader',
      'Creating fallback events for category: $category',
    );

    final fallbackEvents = <String, Event>{};

    switch (category) {
      case 'trap':
        fallbackEvents['fallback_trap_1'] = Event(
          id: 'fallback_trap_1',
          name: 'Basic Trap',
          description: 'A simple trap that causes minor damage.',
          image: '',
          category: 'trap',
          weight: 50,
          persistence: 'oneTime',
          choices: [
            Choice(
              text: 'Try to avoid it',
              successEffects: ChoiceEffects(
                description: 'You successfully avoid the trap.',
                statChanges: {'FITNESS': 0, 'SAN': 0},
                itemsGained: [],
                itemsLost: [],
                applyStatus: [],
              ),
              requirements: {},
            ),
          ],
        );
        break;

      case 'item':
        fallbackEvents['fallback_item_1'] = Event(
          id: 'fallback_item_1',
          name: 'Basic Item',
          description: 'A simple item that provides minor benefits.',
          image: '',
          category: 'item',
          weight: 50,
          persistence: 'oneTime',
          choices: [
            Choice(
              text: 'Take the item',
              successEffects: ChoiceEffects(
                description: 'You pick up the item.',
                statChanges: {'FITNESS': 0, 'SAN': 0},
                itemsGained: ['basic_item'],
                itemsLost: [],
                applyStatus: [],
              ),
              requirements: {},
            ),
          ],
        );
        break;

      case 'character':
        fallbackEvents['fallback_character_1'] = Event(
          id: 'fallback_character_1',
          name: 'Basic Character',
          description: 'A simple character interaction.',
          image: '',
          category: 'character',
          weight: 50,
          persistence: 'oneTime',
          choices: [
            Choice(
              text: 'Interact with the character',
              successEffects: ChoiceEffects(
                description: 'You have a pleasant interaction.',
                statChanges: {'FITNESS': 0, 'SAN': 5},
                itemsGained: [],
                itemsLost: [],
                applyStatus: [],
              ),
              requirements: {},
            ),
          ],
        );
        break;

      case 'monster':
        fallbackEvents['fallback_monster_1'] = Event(
          id: 'fallback_monster_1',
          name: 'Basic Monster',
          description: 'A simple monster encounter.',
          image: '',
          category: 'monster',
          weight: 50,
          persistence: 'oneTime',
          choices: [
            Choice(
              text: 'Fight the monster',
              successEffects: ChoiceEffects(
                description: 'You defeat the monster.',
                statChanges: {'FITNESS': -5, 'SAN': 0},
                itemsGained: [],
                itemsLost: [],
                applyStatus: [],
              ),
              requirements: {},
            ),
          ],
        );
        break;
    }

    _logger.info(
      'EventLoader',
      'Created ${fallbackEvents.length} fallback events for category: $category',
    );

    return fallbackEvents;
  }

  /// Checks if cached events are still valid
  bool _isCacheValid(String filePath) {
    if (!_eventCache.containsKey(filePath)) return false;

    final timestamp = _cacheTimestamps[filePath];
    if (timestamp == null) return false;

    final age = DateTime.now().difference(timestamp);
    return age < _cacheExpiryDuration;
  }

  /// Updates cache access tracking
  void _updateCacheAccess(String filePath) {
    _cacheAccessCounts[filePath] = (_cacheAccessCounts[filePath] ?? 0) + 1;

    // Update recently accessed list
    _recentlyAccessedEvents.remove(filePath);
    _recentlyAccessedEvents.add(filePath);

    // Trim recently accessed list
    if (_recentlyAccessedEvents.length > _maxRecentlyAccessedSize) {
      _recentlyAccessedEvents.removeRange(
        0,
        _recentlyAccessedEvents.length - _maxRecentlyAccessedSize,
      );
    }
  }

  /// Caches events with memory management
  void _cacheEvents(String filePath, Map<String, Event> events) {
    // Check cache size before adding
    if (_eventCache.length >= _maxCacheSize) {
      _evictOldestCache();
    }

    _eventCache[filePath] = Map<String, Event>.from(events);
    _cacheTimestamps[filePath] = DateTime.now();
    _cacheAccessCounts[filePath] = 1;

    _logger.debug(
      'EventLoader',
      'Cached ${events.length} events from: $filePath',
    );
  }

  /// Evicts oldest cache entries when cache is full
  void _evictOldestCache() {
    if (_eventCache.isEmpty) return;

    // Find oldest cache entry
    String? oldestPath;
    DateTime? oldestTime;

    for (final entry in _cacheTimestamps.entries) {
      if (oldestTime == null || entry.value.isBefore(oldestTime)) {
        oldestTime = entry.value;
        oldestPath = entry.key;
      }
    }

    if (oldestPath != null) {
      _eventCache.remove(oldestPath);
      _cacheTimestamps.remove(oldestPath);
      _cacheAccessCounts.remove(oldestPath);
      _recentlyAccessedEvents.remove(oldestPath);

      _logger.debug('EventLoader', 'Evicted oldest cache entry: $oldestPath');
    }
  }

  /// Gets performance statistics for event loading operations
  Map<String, dynamic> getLoadingPerformanceStats() {
    final stats = <String, dynamic>{};

    for (final operationName in _loadingTimings.keys) {
      final timings = _loadingTimings[operationName]!;
      if (timings.isEmpty) continue;

      final sortedTimings = List<Duration>.from(timings)..sort();
      final count = timings.length;

      stats[operationName] = {
        'totalCount': count,
        'averageDuration':
            timings.fold(Duration.zero, (sum, d) => sum + d) ~/ count,
        'minDuration': sortedTimings.first,
        'maxDuration': sortedTimings.last,
        'medianDuration': sortedTimings[count ~/ 2],
      };
    }

    // Add cache statistics
    stats['cache'] = {
      'totalCachedFiles': _eventCache.length,
      'recentlyAccessedCount': _recentlyAccessedEvents.length,
      'totalCacheAccesses': _cacheAccessCounts.values.fold(
        0,
        (sum, count) => sum + count,
      ),
    };

    return stats;
  }

  /// Clears all cached events and resets performance metrics
  void clearCache() {
    _eventCache.clear();
    _cacheTimestamps.clear();
    _cacheAccessCounts.clear();
    _recentlyAccessedEvents.clear();
    _loadingTimings.clear();
    _loadingCounts.clear();

    _logger.info('EventLoader', 'All event cache and performance data cleared');
  }

  /// Gets events by category with optimized caching
  List<Event> getEventsByCategory(String category) {
    return _performanceOptimizer.getEventsByCategory(category);
  }

  /// Preloads events for better performance
  Future<void> preloadEvents() async {
    _logger.info(
      'EventLoader',
      'Starting event preloading for better performance',
    );

    try {
      // Load all event types in parallel
      final futures = [
        loadTrapEvents(),
        loadItemEvents(),
        loadCharacterEvents(),
        loadMonsterEvents(),
      ];

      final results = await Future.wait(futures);

      // Combine all events for preloading
      final allEvents = <String, Event>{};
      for (final eventMap in results) {
        allEvents.addAll(eventMap);
      }

      // Preload frequent events
      await _performanceOptimizer.preloadFrequentEvents(allEvents);

      _logger.info(
        'EventLoader',
        'Event preloading completed: ${allEvents.length} events',
      );
    } catch (e, stackTrace) {
      _logger.error('EventLoader', 'Event preloading failed', {}, stackTrace);
    }
  }
}
