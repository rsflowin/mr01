import 'dart:async';
import 'dart:collection';
import 'dart:isolate';
import 'dart:math';
import '../models/event_model.dart';
import '../models/room_event_data.dart';
import 'logger_service.dart';

/// Service responsible for performance optimization and memory management
/// Implements advanced caching, memory cleanup, and performance monitoring
/// Enhanced with event-specific optimizations and large pool management
class PerformanceOptimizer {
  final LoggerService _logger = LoggerService();

  // Advanced caching system
  final Map<String, Event> _eventCache = {};
  final Map<String, DateTime> _cacheTimestamps = {};
  final Map<String, int> _accessCounts = {};
  final LinkedHashMap<String, void> _lruCache = LinkedHashMap();

  // Event-specific caching
  final Map<String, List<String>> _categoryEventCache = {};
  final Map<String, Map<String, Event>> _roomEventCache = {};
  final Map<String, List<String>> _weightedEventCache = {};

  // Memory management
  final Map<String, int> _memoryUsage = {};
  final List<String> _recentlyAccessed = [];
  final Queue<String> _cleanupQueue = Queue();

  // Performance monitoring
  final Map<String, List<Duration>> _operationTimings = {};
  final Map<String, int> _operationCounts = {};
  final Map<String, DateTime> _lastOperationTime = {};

  // Event pool optimization
  final Map<String, List<String>> _optimizedEventPools = {};
  final Map<String, DateTime> _poolOptimizationTimestamps = {};
  static const Duration _poolOptimizationInterval = Duration(minutes: 10);

  // Configuration
  static const int _maxCacheSize = 2000;
  static const int _maxMemoryUsage = 100 * 1024 * 1024; // 100MB
  static const Duration _cacheExpiryDuration = Duration(minutes: 45);
  static const Duration _cleanupInterval = Duration(minutes: 5);
  static const int _maxRecentlyAccessedSize = 500;
  static const int _maxEventPoolSize = 10000;

  // Background cleanup timer
  Timer? _cleanupTimer;

  PerformanceOptimizer() {
    _startBackgroundCleanup();
  }

  /// Starts background cleanup timer for automatic memory management
  void _startBackgroundCleanup() {
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _performBackgroundCleanup();
    });

    _logger.info('PerformanceOptimizer', 'Background cleanup timer started');
  }

  /// Stops background cleanup timer
  void dispose() {
    _cleanupTimer?.cancel();
    _logger.info('PerformanceOptimizer', 'Performance optimizer disposed');
  }

  /// Caches an event with advanced memory management and category optimization
  void cacheEvent(String eventId, Event event) {
    // Check memory constraints before caching
    if (_shouldEvictForMemory(event)) {
      _evictLeastValuableEvents();
    }

    // Add to main cache
    _eventCache[eventId] = event;
    _cacheTimestamps[eventId] = DateTime.now();
    _accessCounts[eventId] = 1;
    _lruCache[eventId] = null;
    _recentlyAccessed.insert(0, eventId);

    // Add to category cache for faster filtering
    _categoryEventCache.putIfAbsent(event.category, () => []).add(eventId);

    // Add to weighted cache for performance optimization
    _addToWeightedCache(eventId, event);

    // Update memory usage tracking
    _updateMemoryUsage(eventId, event);

    // Trim recently accessed list
    if (_recentlyAccessed.length > _maxRecentlyAccessedSize) {
      _recentlyAccessed.removeRange(
        _maxRecentlyAccessedSize,
        _recentlyAccessed.length,
      );
    }

    _logger.debug(
      'PerformanceOptimizer',
      'Cached event: $eventId (${event.category})',
    );
  }

  /// Adds event to weighted cache for optimized selection
  void _addToWeightedCache(String eventId, Event event) {
    final weightKey = _getWeightKey(event.weight);
    _weightedEventCache.putIfAbsent(weightKey, () => []).add(eventId);
  }

  /// Gets weight key for categorization
  String _getWeightKey(int weight) {
    if (weight <= 10) return 'low';
    if (weight <= 50) return 'medium';
    if (weight <= 100) return 'high';
    return 'very_high';
  }

  /// Caches room-specific event data for faster access
  void cacheRoomEvents(String roomId, Map<String, Event> events) {
    if (events.length > _maxEventPoolSize) {
      _logger.warning(
        'PerformanceOptimizer',
        'Room $roomId has very large event pool (${events.length}), applying optimization',
      );
      _optimizeRoomEventPool(roomId, events);
    } else {
      _roomEventCache[roomId] = Map<String, Event>.from(events);
    }
  }

  /// Optimizes large room event pools for better performance
  void _optimizeRoomEventPool(String roomId, Map<String, Event> events) {
    final now = DateTime.now();
    final lastOptimization = _poolOptimizationTimestamps[roomId];

    if (lastOptimization != null &&
        now.difference(lastOptimization) < _poolOptimizationInterval) {
      return; // Skip if recently optimized
    }

    // Create optimized event pool with weighted sampling
    final optimizedPool = <String>[];
    final eventList = events.entries.toList();

    // Sort by weight for efficient selection
    eventList.sort((a, b) => b.value.weight.compareTo(a.value.weight));

    // Take top weighted events and random sample from rest
    final topCount = (events.length * 0.3).round();
    for (int i = 0; i < topCount && i < eventList.length; i++) {
      optimizedPool.add(eventList[i].key);
    }

    // Random sample from remaining events
    final random = Random();
    final remainingEvents = eventList.skip(topCount).toList();
    final sampleCount = (remainingEvents.length * 0.2).round();

    for (int i = 0; i < sampleCount && i < remainingEvents.length; i++) {
      final randomIndex = random.nextInt(remainingEvents.length);
      optimizedPool.add(remainingEvents[randomIndex].key);
      remainingEvents.removeAt(randomIndex);
    }

    _optimizedEventPools[roomId] = optimizedPool;
    _poolOptimizationTimestamps[roomId] = now;

    _logger.info(
      'PerformanceOptimizer',
      'Optimized room $roomId event pool: ${events.length} -> ${optimizedPool.length} events',
    );
  }

  /// Retrieves an event from cache with access tracking
  Event? getCachedEvent(String eventId) {
    if (!_eventCache.containsKey(eventId)) return null;

    // Check if cache entry is still valid
    if (!_isCacheValid(eventId)) {
      _removeFromCache(eventId);
      return null;
    }

    // Update access tracking
    _updateAccessTracking(eventId);

    return _eventCache[eventId];
  }

  /// Gets events by category with optimized caching
  List<Event> getEventsByCategory(String category) {
    final eventIds = _categoryEventCache[category] ?? [];
    final events = <Event>[];

    for (final eventId in eventIds) {
      final event = _eventCache[eventId];
      if (event != null && _isCacheValid(eventId)) {
        events.add(event);
      }
    }

    return events;
  }

  /// Gets optimized event pool for a room
  List<String> getOptimizedRoomEventPool(String roomId) {
    return _optimizedEventPools[roomId] ?? [];
  }

  /// Checks if a cached event is still valid
  bool _isCacheValid(String eventId) {
    final timestamp = _cacheTimestamps[eventId];
    if (timestamp == null) return false;

    final age = DateTime.now().difference(timestamp);
    return age < _cacheExpiryDuration;
  }

  /// Updates access tracking for LRU eviction
  void _updateAccessTracking(String eventId) {
    _accessCounts[eventId] = (_accessCounts[eventId] ?? 0) + 1;

    // Update LRU cache
    _lruCache.remove(eventId);
    _lruCache[eventId] = null;

    // Update recently accessed list
    _recentlyAccessed.remove(eventId);
    _recentlyAccessed.insert(0, eventId);
  }

  /// Updates memory usage tracking for an event
  void _updateMemoryUsage(String eventId, Event event) {
    // Estimate memory usage based on event size
    final estimatedSize = _estimateEventMemorySize(event);
    _memoryUsage[eventId] = estimatedSize;
  }

  /// Estimates memory usage of an event object
  int _estimateEventMemorySize(Event event) {
    int size = 0;

    // Basic object overhead
    size += 64;

    // String fields
    size +=
        (event.id.length + event.name.length + event.description.length) * 2;
    size += event.image?.length ?? 0;
    size += event.category.length;

    // Choices
    size += event.choices.length * 32;
    for (final choice in event.choices) {
      size += choice.text.length * 2;
      size +=
          (choice.successEffects.description.length +
              (choice.failureEffects?.description.length ?? 0)) *
          2;
      size += (choice.requirements?.length ?? 0) * 16;
    }

    // Integer fields
    size += 16;

    return size;
  }

  /// Checks if memory eviction is needed
  bool _shouldEvictForMemory(Event event) {
    final currentMemoryUsage = _memoryUsage.values.fold(
      0,
      (sum, size) => sum + size,
    );
    final newEventSize = _estimateEventMemorySize(event);

    return (currentMemoryUsage + newEventSize) > _maxMemoryUsage;
  }

  /// Evicts least valuable events based on access patterns and memory usage
  void _evictLeastValuableEvents() {
    if (_eventCache.length < _maxCacheSize) return;

    // Calculate value scores for each cached event
    final eventScores = <String, double>{};
    final now = DateTime.now();

    for (final entry in _eventCache.entries) {
      final eventId = entry.key;
      final timestamp = _cacheTimestamps[eventId] ?? now;
      final accessCount = _accessCounts[eventId] ?? 0;
      final memorySize = _memoryUsage[eventId] ?? 0;

      // Calculate score based on recency, access frequency, and memory efficiency
      final age = now.difference(timestamp).inMinutes;
      final recencyScore = 1.0 / (1.0 + age);
      final accessScore = accessCount / 100.0;
      final memoryEfficiency = 1.0 / (1.0 + memorySize / 1024.0);

      final score =
          (recencyScore * 0.4) + (accessScore * 0.4) + (memoryEfficiency * 0.2);
      eventScores[eventId] = score;
    }

    // Sort by score and evict lowest scoring events
    final sortedEvents = eventScores.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    final evictCount = (_eventCache.length - _maxCacheSize + 200).clamp(
      0,
      _eventCache.length,
    );

    for (int i = 0; i < evictCount; i++) {
      final eventId = sortedEvents[i].key;
      _removeFromCache(eventId);
    }

    _logger.info(
      'PerformanceOptimizer',
      'Evicted $evictCount events for memory management',
    );
  }

  /// Removes an event from all cache structures
  void _removeFromCache(String eventId) {
    final event = _eventCache[eventId];
    if (event != null) {
      // Remove from category cache
      _categoryEventCache[event.category]?.remove(eventId);

      // Remove from weighted cache
      final weightKey = _getWeightKey(event.weight);
      _weightedEventCache[weightKey]?.remove(eventId);
    }

    _eventCache.remove(eventId);
    _cacheTimestamps.remove(eventId);
    _accessCounts.remove(eventId);
    _lruCache.remove(eventId);
    _recentlyAccessed.remove(eventId);
    _memoryUsage.remove(eventId);
  }

  /// Performs background cleanup operations
  void _performBackgroundCleanup() {
    try {
      final beforeSize = _eventCache.length;
      final beforeMemory = _memoryUsage.values.fold(
        0,
        (sum, size) => sum + size,
      );

      // Remove expired cache entries
      final cutoffTime = DateTime.now().subtract(_cacheExpiryDuration);
      final expiredKeys = <String>[];

      for (final entry in _cacheTimestamps.entries) {
        if (entry.value.isBefore(cutoffTime)) {
          expiredKeys.add(entry.key);
        }
      }

      for (final key in expiredKeys) {
        _removeFromCache(key);
      }

      // Clean up rarely accessed events
      final rarelyAccessedKeys = <String>[];
      for (final entry in _accessCounts.entries) {
        if (entry.value < 3) {
          rarelyAccessedKeys.add(entry.key);
        }
      }

      // Only remove some rarely accessed events to avoid over-aggressive cleanup
      final removeCount = (rarelyAccessedKeys.length * 0.3).round();
      for (int i = 0; i < removeCount && i < rarelyAccessedKeys.length; i++) {
        _removeFromCache(rarelyAccessedKeys[i]);
      }

      // Clean up old room event caches
      _cleanupOldRoomEventCaches();

      final afterSize = _eventCache.length;
      final afterMemory = _memoryUsage.values.fold(
        0,
        (sum, size) => sum + size,
      );

      if (beforeSize != afterSize || beforeMemory != afterMemory) {
        _logger.info(
          'PerformanceOptimizer',
          'Background cleanup completed: removed ${beforeSize - afterSize} events, '
              'freed ${(beforeMemory - afterMemory) / 1024}KB memory',
        );
      }
    } catch (e, stackTrace) {
      _logger.error(
        'PerformanceOptimizer',
        'Background cleanup failed',
        {},
        stackTrace,
      );
    }
  }

  /// Cleans up old room event caches
  void _cleanupOldRoomEventCaches() {
    final cutoffTime = DateTime.now().subtract(Duration(minutes: 30));
    final oldRoomIds = <String>[];

    for (final entry in _poolOptimizationTimestamps.entries) {
      if (entry.value.isBefore(cutoffTime)) {
        oldRoomIds.add(entry.key);
      }
    }

    for (final roomId in oldRoomIds) {
      _roomEventCache.remove(roomId);
      _optimizedEventPools.remove(roomId);
      _poolOptimizationTimestamps.remove(roomId);
    }

    if (oldRoomIds.isNotEmpty) {
      _logger.debug(
        'PerformanceOptimizer',
        'Cleaned up ${oldRoomIds.length} old room event caches',
      );
    }
  }

  /// Starts performance measurement for an operation
  void startOperationMeasurement(String operationName) {
    _lastOperationTime[operationName] = DateTime.now();
  }

  /// Ends performance measurement and records timing
  void endOperationMeasurement(String operationName) {
    final startTime = _lastOperationTime[operationName];
    if (startTime == null) return;

    final duration = DateTime.now().difference(startTime);

    _operationTimings.putIfAbsent(operationName, () => []).add(duration);
    _operationCounts[operationName] =
        (_operationCounts[operationName] ?? 0) + 1;

    _lastOperationTime.remove(operationName);
  }

  /// Gets performance statistics for an operation
  Map<String, dynamic>? getOperationStats(String operationName) {
    final timings = _operationTimings[operationName];
    if (timings == null || timings.isEmpty) return null;

    final sortedTimings = List<Duration>.from(timings)..sort();
    final count = timings.length;

    return {
      'operationName': operationName,
      'totalCount': count,
      'averageDuration':
          timings.fold(Duration.zero, (sum, d) => sum + d) ~/ count,
      'minDuration': sortedTimings.first,
      'maxDuration': sortedTimings.last,
      'medianDuration': sortedTimings[count ~/ 2],
      'p95Duration': sortedTimings[(count * 0.95).round()],
      'p99Duration': sortedTimings[(count * 0.99).round()],
    };
  }

  /// Gets comprehensive performance statistics
  Map<String, dynamic> getAllPerformanceStats() {
    final stats = <String, dynamic>{};

    for (final operationName in _operationTimings.keys) {
      final stat = getOperationStats(operationName);
      if (stat != null) {
        stats[operationName] = stat;
      }
    }

    // Add cache statistics
    stats['cache'] = {
      'totalCachedEvents': _eventCache.length,
      'totalMemoryUsage': _memoryUsage.values.fold(
        0,
        (sum, size) => sum + size,
      ),
      'recentlyAccessedCount': _recentlyAccessed.length,
      'lruCacheSize': _lruCache.length,
      'categoryCacheCounts': _categoryEventCache.map(
        (key, value) => MapEntry(key, value.length),
      ),
      'roomEventCacheCount': _roomEventCache.length,
      'optimizedPoolCount': _optimizedEventPools.length,
    };

    return stats;
  }

  /// Optimizes event selection algorithm for large event pools
  List<String> optimizedEventSelection(
    Map<String, Event> events,
    int count,
    Random random,
  ) {
    startOperationMeasurement('optimizedEventSelection');

    try {
      if (count <= 0 || events.isEmpty) return [];
      if (count >= events.length) return events.keys.toList();

      // Use reservoir sampling for large event pools
      if (events.length > 1000) {
        return _reservoirSampling(events.keys.toList(), count, random);
      }

      // Use standard weighted selection for smaller pools
      return _weightedSelection(events, count, random);
    } finally {
      endOperationMeasurement('optimizedEventSelection');
    }
  }

  /// Implements reservoir sampling for large event pools
  List<String> _reservoirSampling(
    List<String> eventIds,
    int count,
    Random random,
  ) {
    final result = <String>[];

    // Fill reservoir with first k elements
    for (int i = 0; i < count; i++) {
      result.add(eventIds[i]);
    }

    // Replace elements with decreasing probability
    for (int i = count; i < eventIds.length; i++) {
      final j = random.nextInt(i + 1);
      if (j < count) {
        result[j] = eventIds[i];
      }
    }

    return result;
  }

  /// Implements weighted selection for smaller event pools
  List<String> _weightedSelection(
    Map<String, Event> events,
    int count,
    Random random,
  ) {
    final selectedIds = <String>[];
    final remainingEvents = Map<String, Event>.from(events);

    for (int i = 0; i < count && remainingEvents.isNotEmpty; i++) {
      final totalWeight = remainingEvents.values
          .map((e) => e.weight)
          .reduce((a, b) => a + b);

      int randomWeight = random.nextInt(totalWeight);
      String? selectedId;

      for (final entry in remainingEvents.entries) {
        randomWeight -= entry.value.weight;
        if (randomWeight < 0) {
          selectedId = entry.key;
          break;
        }
      }

      if (selectedId != null) {
        selectedIds.add(selectedId);
        remainingEvents.remove(selectedId);
      }
    }

    return selectedIds;
  }

  /// Preloads frequently accessed events for better performance
  Future<void> preloadFrequentEvents(Map<String, Event> allEvents) async {
    startOperationMeasurement('preloadFrequentEvents');

    try {
      // Identify frequently accessed events based on weight and category
      final frequentEvents = <String, Event>{};

      for (final entry in allEvents.entries) {
        final event = entry.value;

        // Prioritize high-weight events and common categories
        if (event.weight > 50 ||
            event.category == 'trap' ||
            event.category == 'item') {
          frequentEvents[entry.key] = event;
        }
      }

      // Cache frequent events
      for (final entry in frequentEvents.entries) {
        cacheEvent(entry.key, entry.value);
      }

      _logger.info(
        'PerformanceOptimizer',
        'Preloaded ${frequentEvents.length} frequent events',
      );
    } finally {
      endOperationMeasurement('preloadFrequentEvents');
    }
  }

  /// Performs manual memory cleanup
  void cleanupMemory() {
    _performBackgroundCleanup();
  }

  /// Clears all cached data and resets performance metrics
  void clearAll() {
    _eventCache.clear();
    _cacheTimestamps.clear();
    _accessCounts.clear();
    _lruCache.clear();
    _recentlyAccessed.clear();
    _memoryUsage.clear();
    _operationTimings.clear();
    _operationCounts.clear();
    _lastOperationTime.clear();
    _categoryEventCache.clear();
    _roomEventCache.clear();
    _weightedEventCache.clear();
    _optimizedEventPools.clear();
    _poolOptimizationTimestamps.clear();

    _logger.info('PerformanceOptimizer', 'All data cleared and metrics reset');
  }
}
