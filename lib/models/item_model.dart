import 'dart:convert';

/// Represents the effects an item can have when used
class ItemEffects {
  final Map<String, int>? statChanges;
  final List<String>? removeStatus;
  final List<String>? applyStatus;

  ItemEffects({this.statChanges, this.removeStatus, this.applyStatus});

  /// Creates ItemEffects from a Map (JSON deserialization)
  factory ItemEffects.fromMap(Map<String, dynamic> map) {
    return ItemEffects(
      statChanges: map['statChanges'] != null
          ? Map<String, int>.from(map['statChanges'])
          : null,
      removeStatus: map['removeStatus'] != null
          ? List<String>.from(map['removeStatus'])
          : null,
      applyStatus: map['applyStatus'] != null
          ? List<String>.from(map['applyStatus'])
          : null,
    );
  }

  /// Converts ItemEffects to a Map (JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      if (statChanges != null) 'statChanges': statChanges,
      if (removeStatus != null) 'removeStatus': removeStatus,
      if (applyStatus != null) 'applyStatus': applyStatus,
    };
  }

  /// Validates that the ItemEffects has at least one effect
  bool get hasEffects =>
      statChanges != null || removeStatus != null || applyStatus != null;

  ItemEffects copyWith({
    Map<String, int>? statChanges,
    List<String>? removeStatus,
    List<String>? applyStatus,
  }) {
    return ItemEffects(
      statChanges: statChanges ?? this.statChanges,
      removeStatus: removeStatus ?? this.removeStatus,
      applyStatus: applyStatus ?? this.applyStatus,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemEffects &&
        _mapEquals(statChanges, other.statChanges) &&
        _listEquals(removeStatus, other.removeStatus) &&
        _listEquals(applyStatus, other.applyStatus);
  }

  @override
  int get hashCode => Object.hash(
    _mapHashCode(statChanges),
    _listHashCode(removeStatus),
    _listHashCode(applyStatus),
  );

  bool _mapEquals(Map<String, int>? a, Map<String, int>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int _mapHashCode(Map<String, int>? map) {
    if (map == null) return 0;
    int hash = 0;
    for (final entry in map.entries) {
      hash ^= Object.hash(entry.key, entry.value);
    }
    return hash;
  }

  int _listHashCode(List<String>? list) {
    if (list == null) return 0;
    return Object.hashAll(list);
  }
}

/// Represents a usable item in the game
class Item {
  final String id;
  final String name;
  final String description;
  final String image;
  final String itemType;
  final bool consumeOnUse;
  final ItemEffects effects;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.itemType,
    required this.consumeOnUse,
    required this.effects,
  });

  /// Validates that the Item has all required properties
  bool isValid() {
    return id.isNotEmpty &&
        name.isNotEmpty &&
        description.isNotEmpty &&
        itemType.isNotEmpty;
  }

  /// Creates Item from a Map (JSON deserialization)
  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      itemType: map['itemType'] ?? 'ACTIVE',
      consumeOnUse: map['consumeOnUse'] ?? true,
      effects: ItemEffects.fromMap(map['effects'] ?? {}),
    );
  }

  /// Converts Item to a Map (JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'itemType': itemType,
      'consumeOnUse': consumeOnUse,
      'effects': effects.toMap(),
    };
  }

  /// Creates Item from JSON string
  factory Item.fromJson(String source) => Item.fromMap(json.decode(source));

  /// Converts Item to JSON string
  String toJson() => json.encode(toMap());

  Item copyWith({
    String? id,
    String? name,
    String? description,
    String? image,
    String? itemType,
    bool? consumeOnUse,
    ItemEffects? effects,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      itemType: itemType ?? this.itemType,
      consumeOnUse: consumeOnUse ?? this.consumeOnUse,
      effects: effects ?? this.effects,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.image == image &&
        other.itemType == itemType &&
        other.consumeOnUse == consumeOnUse &&
        other.effects == effects;
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    description,
    image,
    itemType,
    consumeOnUse,
    effects,
  );

  @override
  String toString() =>
      'Item(id: $id, name: $name, consumeOnUse: $consumeOnUse)';
}
