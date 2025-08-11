import 'dart:convert';

/// Represents the effects that occur when a choice is selected
class ChoiceEffects {
  final String description;
  final Map<String, int>? statChanges;
  final List<String>? itemsGained;
  final List<String>? itemsLost;
  final List<String>? applyStatus;

  ChoiceEffects({
    required this.description,
    this.statChanges,
    this.itemsGained,
    this.itemsLost,
    this.applyStatus,
  });

  /// Validates that the ChoiceEffects has required properties
  bool isValid() {
    return description.isNotEmpty;
  }

  /// Creates ChoiceEffects from a Map (JSON deserialization)
  factory ChoiceEffects.fromMap(Map<String, dynamic> map) {
    // Ensure required fields exist
    if (!map.containsKey('description')) {
      throw FormatException(
        'ChoiceEffects missing required field: description',
      );
    }

    return ChoiceEffects(
      description: map['description'] ?? '',
      statChanges: map['statChanges'] != null
          ? Map<String, int>.from(map['statChanges'])
          : null,
      itemsGained: map['itemsGained'] != null
          ? List<String>.from(map['itemsGained'])
          : null,
      itemsLost: map['itemsLost'] != null
          ? List<String>.from(map['itemsLost'])
          : null,
      applyStatus: map['applyStatus'] != null
          ? List<String>.from(map['applyStatus'])
          : null,
    );
  }

  /// Converts ChoiceEffects to a Map (JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      if (statChanges != null) 'statChanges': statChanges,
      if (itemsGained != null) 'itemsGained': itemsGained,
      if (itemsLost != null) 'itemsLost': itemsLost,
      if (applyStatus != null) 'applyStatus': applyStatus,
    };
  }

  ChoiceEffects copyWith({
    String? description,
    Map<String, int>? statChanges,
    List<String>? itemsGained,
    List<String>? itemsLost,
    List<String>? applyStatus,
  }) {
    return ChoiceEffects(
      description: description ?? this.description,
      statChanges: statChanges ?? this.statChanges,
      itemsGained: itemsGained ?? this.itemsGained,
      itemsLost: itemsLost ?? this.itemsLost,
      applyStatus: applyStatus ?? this.applyStatus,
    );
  }

  @override
  String toString() {
    return 'ChoiceEffects(description: $description, statChanges: $statChanges, itemsGained: $itemsGained, itemsLost: $itemsLost, applyStatus: $applyStatus)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ChoiceEffects &&
        other.description == description &&
        _mapEquals(other.statChanges, statChanges) &&
        _listEquals(other.itemsGained, itemsGained) &&
        _listEquals(other.itemsLost, itemsLost) &&
        _listEquals(other.applyStatus, applyStatus);
  }

  @override
  int get hashCode {
    return Object.hash(
      description,
      _mapHashCode(statChanges),
      _listHashCode(itemsGained),
      _listHashCode(itemsLost),
      _listHashCode(applyStatus),
    );
  }

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

/// Represents a choice that a player can make during an event
class Choice {
  final String text;
  final Map<String, dynamic>? requirements;
  final Map<String, dynamic>? successConditions;
  final ChoiceEffects successEffects;
  final ChoiceEffects? failureEffects;

  Choice({
    required this.text,
    this.requirements,
    this.successConditions,
    required this.successEffects,
    this.failureEffects,
  });

  /// Validates that the Choice has required properties
  bool isValid() {
    return text.isNotEmpty && successEffects.isValid();
  }

  /// Creates Choice from a Map (JSON deserialization)
  factory Choice.fromMap(Map<String, dynamic> map) {
    // Ensure required fields exist
    if (!map.containsKey('text') || !map.containsKey('successEffects')) {
      throw FormatException(
        'Choice missing required fields: text or successEffects',
      );
    }

    return Choice(
      text: map['text'] ?? '',
      requirements: map['requirements'],
      successConditions: map['successConditions'],
      successEffects: ChoiceEffects.fromMap(map['successEffects'] ?? {}),
      failureEffects: map['failureEffects'] != null
          ? ChoiceEffects.fromMap(map['failureEffects'])
          : null,
    );
  }

  /// Converts Choice to a Map (JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'text': text,
      if (requirements != null) 'requirements': requirements,
      if (successConditions != null) 'successConditions': successConditions,
      'successEffects': successEffects.toMap(),
      if (failureEffects != null) 'failureEffects': failureEffects!.toMap(),
    };
  }

  Choice copyWith({
    String? text,
    Map<String, dynamic>? requirements,
    Map<String, dynamic>? successConditions,
    ChoiceEffects? successEffects,
    ChoiceEffects? failureEffects,
  }) {
    return Choice(
      text: text ?? this.text,
      requirements: requirements ?? this.requirements,
      successConditions: successConditions ?? this.successConditions,
      successEffects: successEffects ?? this.successEffects,
      failureEffects: failureEffects ?? this.failureEffects,
    );
  }

  @override
  String toString() {
    return 'Choice(text: $text, requirements: $requirements, successConditions: $successConditions, successEffects: $successEffects, failureEffects: $failureEffects)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Choice &&
        other.text == text &&
        _mapEquals(other.requirements, requirements) &&
        _mapEquals(other.successConditions, successConditions) &&
        other.successEffects == successEffects &&
        other.failureEffects == failureEffects;
  }

  @override
  int get hashCode {
    return Object.hash(
      text,
      _mapHashCode(requirements),
      _mapHashCode(successConditions),
      successEffects,
      failureEffects,
    );
  }

  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
    }
    return true;
  }

  bool _deepEquals(dynamic a, dynamic b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a is Map && b is Map) {
      if (a.length != b.length) return false;
      for (final key in a.keys) {
        if (!b.containsKey(key) || !_deepEquals(a[key], b[key])) return false;
      }
      return true;
    }
    if (a is List && b is List) {
      if (a.length != b.length) return false;
      for (int i = 0; i < a.length; i++) {
        if (!_deepEquals(a[i], b[i])) return false;
      }
      return true;
    }
    return a == b;
  }

  int _mapHashCode(Map<String, dynamic>? map) {
    if (map == null) return 0;
    int hash = 0;
    for (final entry in map.entries) {
      hash ^= Object.hash(entry.key, _deepHashCode(entry.value));
    }
    return hash;
  }

  int _deepHashCode(dynamic value) {
    if (value == null) return 0;
    if (value is Map) {
      int hash = 0;
      for (final entry in value.entries) {
        hash ^= Object.hash(entry.key, _deepHashCode(entry.value));
      }
      return hash;
    }
    if (value is List) {
      return Object.hashAll(value.map(_deepHashCode));
    }
    return value.hashCode;
  }
}

/// Represents an event that can occur in the maze
class Event {
  final String id;
  final String name;
  final String description;
  final String image;
  final String category;
  final int weight;
  final String persistence;
  final List<Choice> choices;

  Event({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.category,
    required this.weight,
    required this.persistence,
    required this.choices,
  });

  /// Validates that the Event has all required properties and data integrity
  bool isValid() {
    // Check required string properties
    if (id.isEmpty || name.isEmpty || description.isEmpty) {
      return false;
    }

    // Check weight is positive
    if (weight <= 0) {
      return false;
    }

    // Check persistence is valid
    if (persistence != 'oneTime' && persistence != 'persistent') {
      return false;
    }

    // Check category is not empty
    if (category.isEmpty) {
      return false;
    }

    // Check choices exist and are valid
    if (choices.isEmpty) {
      return false;
    }

    for (final choice in choices) {
      if (!choice.isValid()) {
        return false;
      }
    }

    return true;
  }

  /// Creates Event from a Map (JSON deserialization)
  factory Event.fromMap(Map<String, dynamic> map) {
    // Ensure required fields exist
    if (!map.containsKey('id') ||
        !map.containsKey('name') ||
        !map.containsKey('description') ||
        !map.containsKey('choices')) {
      throw FormatException(
        'Event missing required fields: id, name, description, or choices',
      );
    }

    final choicesData = map['choices'] as List<dynamic>? ?? [];
    final choices = choicesData
        .map((choiceData) => Choice.fromMap(choiceData as Map<String, dynamic>))
        .toList();

    return Event(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      image: map['image'] ?? '',
      category: map['category'] ?? '',
      weight: map['weight']?.toInt() ?? 10, // Default weight of 10
      persistence: map['persistence'] ?? 'oneTime',
      choices: choices,
    );
  }

  /// Converts Event to a Map (JSON serialization)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'category': category,
      'weight': weight,
      'persistence': persistence,
      'choices': choices.map((choice) => choice.toMap()).toList(),
    };
  }

  /// Creates Event from JSON string
  factory Event.fromJson(String source) {
    return Event.fromMap(json.decode(source) as Map<String, dynamic>);
  }

  /// Converts Event to JSON string
  String toJson() => json.encode(toMap());

  Event copyWith({
    String? id,
    String? name,
    String? description,
    String? image,
    String? category,
    int? weight,
    String? persistence,
    List<Choice>? choices,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      category: category ?? this.category,
      weight: weight ?? this.weight,
      persistence: persistence ?? this.persistence,
      choices: choices ?? this.choices,
    );
  }

  @override
  String toString() {
    return 'Event(id: $id, name: $name, description: $description, image: $image, category: $category, weight: $weight, persistence: $persistence, choices: $choices)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Event &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.image == image &&
        other.category == category &&
        other.weight == weight &&
        other.persistence == persistence &&
        _listEquals(other.choices, choices);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      description,
      image,
      category,
      weight,
      persistence,
      Object.hashAll(choices),
    );
  }

  bool _listEquals(List<Choice> a, List<Choice> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
