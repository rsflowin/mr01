import 'dart:convert';

// Player stats model
class PlayerStats {
  int hp;
  int san;
  int fit;
  int hunger;

  PlayerStats({
    required this.hp,
    required this.san,
    required this.fit,
    required this.hunger,
  });

  PlayerStats.initial()
      : hp = 100,
        san = 100,
        fit = 70,
        hunger = 80;

  void updateStat(String statName, int change) {
    switch (statName.toUpperCase()) {
      case 'HP':
        hp = (hp + change).clamp(0, 100);
        break;
      case 'SAN':
        san = (san + change).clamp(0, 100);
        break;
      case 'FIT':
      case 'FITNESS':
        fit = (fit + change).clamp(0, 100);
        break;
      case 'HUNGER':
        hunger = (hunger + change).clamp(0, 100);
        break;
    }
  }

  void updateStats(Map<String, int> changes) {
    changes.forEach((statName, change) {
      updateStat(statName, change);
    });
  }

  Map<String, int> toMap() {
    return {
      'hp': hp,
      'san': san,
      'fit': fit,
      'hunger': hunger,
    };
  }

  factory PlayerStats.fromMap(Map<String, dynamic> map) {
    return PlayerStats(
      hp: map['hp']?.toInt() ?? 100,
      san: map['san']?.toInt() ?? 100,
      fit: map['fit']?.toInt() ?? 70,
      hunger: map['hunger']?.toInt() ?? 80,
    );
  }

  PlayerStats copyWith({
    int? hp,
    int? san,
    int? fit,
    int? hunger,
  }) {
    return PlayerStats(
      hp: hp ?? this.hp,
      san: san ?? this.san,
      fit: fit ?? this.fit,
      hunger: hunger ?? this.hunger,
    );
  }

  bool get isAlive => hp > 0;
  bool get isSane => san > 0;
  bool get isStarving => hunger <= 0;
}

// Status effect model
class StatusEffect {
  final String id;
  final String name;
  final String type; // BUFF or DEBUFF
  int remainingDuration;
  final String? icon;

  StatusEffect({
    required this.id,
    required this.name,
    required this.type,
    required this.remainingDuration,
    this.icon,
  });

  bool get isBuff => type == 'BUFF';
  bool get isDebuff => type == 'DEBUFF';
  bool get isExpired => remainingDuration <= 0;

  void decrementDuration() {
    if (remainingDuration > 0) {
      remainingDuration--;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'remainingDuration': remainingDuration,
      'icon': icon,
    };
  }

  factory StatusEffect.fromMap(Map<String, dynamic> map) {
    return StatusEffect(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      type: map['type'] ?? 'DEBUFF',
      remainingDuration: map['remainingDuration']?.toInt() ?? 1,
      icon: map['icon'],
    );
  }
}

// Inventory item model
class InventoryItem {
  final String id;
  final String name;
  int quantity;
  final String? description;
  final String? icon;

  InventoryItem({
    required this.id,
    required this.name,
    this.quantity = 1,
    this.description,
    this.icon,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'description': description,
      'icon': icon,
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map) {
    return InventoryItem(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      quantity: map['quantity']?.toInt() ?? 1,
      description: map['description'],
      icon: map['icon'],
    );
  }
}

// Player inventory model
class PlayerInventory {
  final List<InventoryItem> items;
  final int maxSlots;

  PlayerInventory({
    List<InventoryItem>? items,
    this.maxSlots = 5,
  }) : items = items ?? [];

  bool get isFull => items.length >= maxSlots;
  int get availableSlots => maxSlots - items.length;

  bool addItem(InventoryItem item) {
    if (isFull) return false;
    
    // Check if item already exists and can stack
    final existingIndex = items.indexWhere((i) => i.id == item.id);
    if (existingIndex != -1) {
      items[existingIndex].quantity += item.quantity;
    } else {
      items.add(item);
    }
    
    return true;
  }

  bool removeItem(String itemId, {int quantity = 1}) {
    final itemIndex = items.indexWhere((item) => item.id == itemId);
    if (itemIndex == -1) return false;

    final item = items[itemIndex];
    if (item.quantity <= quantity) {
      items.removeAt(itemIndex);
    } else {
      item.quantity -= quantity;
    }
    
    return true;
  }

  bool hasItem(String itemId) {
    return items.any((item) => item.id == itemId);
  }

  InventoryItem? getItem(String itemId) {
    try {
      return items.firstWhere((item) => item.id == itemId);
    } catch (e) {
      return null;
    }
  }

  List<Map<String, dynamic>> toMapList() {
    return items.map((item) => item.toMap()).toList();
  }

  factory PlayerInventory.fromMapList(List<dynamic> mapList, {int maxSlots = 5}) {
    final items = mapList
        .map((map) => InventoryItem.fromMap(map as Map<String, dynamic>))
        .toList();
    return PlayerInventory(items: items, maxSlots: maxSlots);
  }
}

// Main game state model
class GameState {
  PlayerStats stats;
  List<StatusEffect> statusEffects;
  PlayerInventory inventory;
  String? currentEventId;
  Map<String, dynamic>? currentEvent;
  int turnCount;
  DateTime startTime;

  GameState({
    PlayerStats? stats,
    List<StatusEffect>? statusEffects,
    PlayerInventory? inventory,
    this.currentEventId,
    this.currentEvent,
    this.turnCount = 0,
    DateTime? startTime,
  })  : stats = stats ?? PlayerStats.initial(),
        statusEffects = statusEffects ?? [],
        inventory = inventory ?? PlayerInventory(),
        startTime = startTime ?? DateTime.now();

  // Apply stat changes from event effects
  void applyStatChanges(Map<String, int> changes) {
    stats.updateStats(changes);
    turnCount++;
  }

  // Add status effect
  void addStatusEffect(StatusEffect effect) {
    // Remove existing effect with same ID
    statusEffects.removeWhere((e) => e.id == effect.id);
    statusEffects.add(effect);
  }

  // Remove status effect
  void removeStatusEffect(String effectId) {
    statusEffects.removeWhere((e) => e.id == effectId);
  }

  // Process turn - decrement status effect durations and apply effects
  void processTurn() {
    // Decrement durations and remove expired effects
    statusEffects.forEach((effect) => effect.decrementDuration());
    statusEffects.removeWhere((effect) => effect.isExpired);
    
    turnCount++;
  }

  // Get active status effects by type
  List<StatusEffect> get activeBuffs =>
      statusEffects.where((e) => e.isBuff).toList();

  List<StatusEffect> get activeDebuffs =>
      statusEffects.where((e) => e.isDebuff).toList();

  // Check game over conditions
  bool get isGameOver => !stats.isAlive || !stats.isSane;
  
  String? get gameOverReason {
    if (!stats.isAlive) return 'death';
    if (!stats.isSane) return 'insanity';
    return null;
  }

  // Serialize to Map for saving
  Map<String, dynamic> toMap() {
    return {
      'stats': stats.toMap(),
      'statusEffects': statusEffects.map((e) => e.toMap()).toList(),
      'inventory': inventory.toMapList(),
      'currentEventId': currentEventId,
      'currentEvent': currentEvent,
      'turnCount': turnCount,
      'startTime': startTime.toIso8601String(),
    };
  }

  // Deserialize from Map for loading
  factory GameState.fromMap(Map<String, dynamic> map) {
    return GameState(
      stats: PlayerStats.fromMap(map['stats'] ?? {}),
      statusEffects: (map['statusEffects'] as List<dynamic>?)
              ?.map((e) => StatusEffect.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      inventory: PlayerInventory.fromMapList(map['inventory'] ?? []),
      currentEventId: map['currentEventId'],
      currentEvent: map['currentEvent'],
      turnCount: map['turnCount']?.toInt() ?? 0,
      startTime: DateTime.tryParse(map['startTime'] ?? '') ?? DateTime.now(),
    );
  }

  // Serialize to JSON string
  String toJson() => json.encode(toMap());

  // Deserialize from JSON string
  factory GameState.fromJson(String source) =>
      GameState.fromMap(json.decode(source));

  GameState copyWith({
    PlayerStats? stats,
    List<StatusEffect>? statusEffects,
    PlayerInventory? inventory,
    String? currentEventId,
    Map<String, dynamic>? currentEvent,
    int? turnCount,
    DateTime? startTime,
  }) {
    return GameState(
      stats: stats ?? this.stats,
      statusEffects: statusEffects ?? this.statusEffects,
      inventory: inventory ?? this.inventory,
      currentEventId: currentEventId ?? this.currentEventId,
      currentEvent: currentEvent ?? this.currentEvent,
      turnCount: turnCount ?? this.turnCount,
      startTime: startTime ?? this.startTime,
    );
  }
}