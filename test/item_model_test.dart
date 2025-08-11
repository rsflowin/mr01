import 'package:test/test.dart';
import '../lib/models/item_model.dart';

void main() {
  group('ItemEffects', () {
    test('should create with all properties', () {
      final effects = ItemEffects(
        statChanges: {'HP': 25, 'SAN': -5},
        removeStatus: ['bleeding', 'poison'],
        applyStatus: ['blessing'],
      );

      expect(effects.statChanges, equals({'HP': 25, 'SAN': -5}));
      expect(effects.removeStatus, equals(['bleeding', 'poison']));
      expect(effects.applyStatus, equals(['blessing']));
      expect(effects.hasEffects, isTrue);
    });

    test('should create with null properties', () {
      final effects = ItemEffects();

      expect(effects.statChanges, isNull);
      expect(effects.removeStatus, isNull);
      expect(effects.applyStatus, isNull);
      expect(effects.hasEffects, isFalse);
    });

    test('should deserialize from Map correctly', () {
      final map = {
        'statChanges': {'HP': 30, 'HUNGER': 10},
        'removeStatus': ['fatigue'],
        'applyStatus': ['energized', 'focused'],
      };

      final effects = ItemEffects.fromMap(map);

      expect(effects.statChanges, equals({'HP': 30, 'HUNGER': 10}));
      expect(effects.removeStatus, equals(['fatigue']));
      expect(effects.applyStatus, equals(['energized', 'focused']));
    });

    test('should serialize to Map correctly', () {
      final effects = ItemEffects(
        statChanges: {'SAN': 15},
        removeStatus: ['dizziness'],
      );

      final map = effects.toMap();

      expect(map['statChanges'], equals({'SAN': 15}));
      expect(map['removeStatus'], equals(['dizziness']));
      expect(map.containsKey('applyStatus'), isFalse);
    });

    test('should handle copyWith correctly', () {
      final original = ItemEffects(
        statChanges: {'HP': 10},
        removeStatus: ['bleeding'],
      );

      final copy = original.copyWith(
        statChanges: {'SAN': 20},
        applyStatus: ['blessing'],
      );

      expect(copy.statChanges, equals({'SAN': 20}));
      expect(copy.removeStatus, equals(['bleeding'])); // Preserved
      expect(copy.applyStatus, equals(['blessing'])); // New
    });

    test('should implement equality correctly', () {
      final effects1 = ItemEffects(
        statChanges: {'HP': 25},
        removeStatus: ['poison'],
      );

      final effects2 = ItemEffects(
        statChanges: {'HP': 25},
        removeStatus: ['poison'],
      );

      final effects3 = ItemEffects(
        statChanges: {'HP': 30},
        removeStatus: ['poison'],
      );

      expect(effects1, equals(effects2));
      expect(effects1, isNot(equals(effects3)));
      expect(effects1.hashCode, equals(effects2.hashCode));
    });
  });

  group('Item', () {
    test('should create with all properties', () {
      final effects = ItemEffects(statChanges: {'HP': 25});
      final item = Item(
        id: 'health_potion',
        name: 'Health Potion',
        description: 'Restores health',
        image: 'health_potion.png',
        itemType: 'ACTIVE',
        consumeOnUse: true,
        effects: effects,
      );

      expect(item.id, equals('health_potion'));
      expect(item.name, equals('Health Potion'));
      expect(item.description, equals('Restores health'));
      expect(item.image, equals('health_potion.png'));
      expect(item.itemType, equals('ACTIVE'));
      expect(item.consumeOnUse, isTrue);
      expect(item.effects, equals(effects));
      expect(item.isValid(), isTrue);
    });

    test('should validate required properties', () {
      final validItem = Item(
        id: 'test_item',
        name: 'Test Item',
        description: 'Test description',
        image: 'test.png',
        itemType: 'ACTIVE',
        consumeOnUse: true,
        effects: ItemEffects(),
      );

      final invalidItem = Item(
        id: '', // Empty ID
        name: 'Test Item',
        description: 'Test description',
        image: 'test.png',
        itemType: 'ACTIVE',
        consumeOnUse: true,
        effects: ItemEffects(),
      );

      expect(validItem.isValid(), isTrue);
      expect(invalidItem.isValid(), isFalse);
    });

    test('should deserialize from Map correctly', () {
      final map = {
        'id': 'first_aid_kit',
        'name': '구급상자',
        'description': '응급 처치 키트',
        'image': 'first_aid_kit.png',
        'itemType': 'ACTIVE',
        'consumeOnUse': true,
        'effects': {
          'statChanges': {'HP': 40, 'SAN': 5},
          'removeStatus': ['bleeding'],
        },
      };

      final item = Item.fromMap(map);

      expect(item.id, equals('first_aid_kit'));
      expect(item.name, equals('구급상자'));
      expect(item.description, equals('응급 처치 키트'));
      expect(item.itemType, equals('ACTIVE'));
      expect(item.consumeOnUse, isTrue);
      expect(item.effects.statChanges, equals({'HP': 40, 'SAN': 5}));
      expect(item.effects.removeStatus, equals(['bleeding']));
    });

    test('should use default values for missing properties', () {
      final map = {'id': 'test_item', 'name': 'Test Item'};

      final item = Item.fromMap(map);

      expect(item.id, equals('test_item'));
      expect(item.name, equals('Test Item'));
      expect(item.description, equals(''));
      expect(item.image, equals(''));
      expect(item.itemType, equals('ACTIVE'));
      expect(item.consumeOnUse, isTrue);
    });

    test('should serialize to Map correctly', () {
      final effects = ItemEffects(
        statChanges: {'SAN': 10},
        removeStatus: ['fatigue'],
      );

      final item = Item(
        id: 'painkillers',
        name: 'Painkillers',
        description: 'Relieves pain',
        image: 'painkillers.png',
        itemType: 'ACTIVE',
        consumeOnUse: true,
        effects: effects,
      );

      final map = item.toMap();

      expect(map['id'], equals('painkillers'));
      expect(map['name'], equals('Painkillers'));
      expect(map['description'], equals('Relieves pain'));
      expect(map['itemType'], equals('ACTIVE'));
      expect(map['consumeOnUse'], isTrue);
      expect(map['effects'], isA<Map<String, dynamic>>());
    });

    test('should handle JSON serialization', () {
      final effects = ItemEffects(statChanges: {'HP': 20});
      final item = Item(
        id: 'test_item',
        name: 'Test Item',
        description: 'Test description',
        image: 'test.png',
        itemType: 'ACTIVE',
        consumeOnUse: false,
        effects: effects,
      );

      final json = item.toJson();
      final reconstructed = Item.fromJson(json);

      expect(reconstructed.id, equals(item.id));
      expect(reconstructed.name, equals(item.name));
      expect(reconstructed.consumeOnUse, equals(item.consumeOnUse));
      expect(
        reconstructed.effects.statChanges,
        equals(item.effects.statChanges),
      );
    });

    test('should implement copyWith correctly', () {
      final original = Item(
        id: 'original_item',
        name: 'Original Item',
        description: 'Original description',
        image: 'original.png',
        itemType: 'ACTIVE',
        consumeOnUse: true,
        effects: ItemEffects(statChanges: {'HP': 10}),
      );

      final modified = original.copyWith(
        name: 'Modified Item',
        consumeOnUse: false,
      );

      expect(modified.id, equals('original_item')); // Preserved
      expect(modified.name, equals('Modified Item')); // Changed
      expect(modified.description, equals('Original description')); // Preserved
      expect(modified.consumeOnUse, isFalse); // Changed
    });

    test('should implement equality correctly', () {
      final effects = ItemEffects(statChanges: {'HP': 25});

      final item1 = Item(
        id: 'test_item',
        name: 'Test Item',
        description: 'Test description',
        image: 'test.png',
        itemType: 'ACTIVE',
        consumeOnUse: true,
        effects: effects,
      );

      final item2 = Item(
        id: 'test_item',
        name: 'Test Item',
        description: 'Test description',
        image: 'test.png',
        itemType: 'ACTIVE',
        consumeOnUse: true,
        effects: effects,
      );

      final item3 = Item(
        id: 'different_item',
        name: 'Test Item',
        description: 'Test description',
        image: 'test.png',
        itemType: 'ACTIVE',
        consumeOnUse: true,
        effects: effects,
      );

      expect(item1, equals(item2));
      expect(item1, isNot(equals(item3)));
      expect(item1.hashCode, equals(item2.hashCode));
    });

    test('should have meaningful toString', () {
      final item = Item(
        id: 'test_item',
        name: 'Test Item',
        description: 'Test description',
        image: 'test.png',
        itemType: 'ACTIVE',
        consumeOnUse: true,
        effects: ItemEffects(),
      );

      final string = item.toString();
      expect(string, contains('test_item'));
      expect(string, contains('Test Item'));
      expect(string, contains('true')); // consumeOnUse
    });
  });

  group('Real-world Item Examples', () {
    test('should handle first aid kit from game data', () {
      final map = {
        "id": "first_aid_kit",
        "name": "구급상자",
        "description": "응급 처치에 필요한 모든 것이 들어있는 키트. 심각한 부상을 치료할 수 있다.",
        "image": "first_aid_kit.png",
        "itemType": "ACTIVE",
        "consumeOnUse": true,
        "effects": {
          "statChanges": {"HP": 40, "SAN": 5},
          "removeStatus": ["bleeding", "sprain"],
          "applyStatus": null,
        },
      };

      final item = Item.fromMap(map);

      expect(item.isValid(), isTrue);
      expect(item.effects.hasEffects, isTrue);
      expect(item.effects.statChanges?['HP'], equals(40));
      expect(item.effects.removeStatus, equals(['bleeding', 'sprain']));
      expect(item.effects.applyStatus, isNull);
    });

    test('should handle non-consumable multitool from game data', () {
      final map = {
        "id": "multitool",
        "name": "멀티툴",
        "description": "다양한 도구가 하나로 합쳐진 만능 도구.",
        "image": "multitool.png",
        "itemType": "PASSIVE",
        "consumeOnUse": false,
        "effects": {
          "statChanges": {"SAN": 5},
          "removeStatus": null,
          "applyStatus": null,
        },
      };

      final item = Item.fromMap(map);

      expect(item.isValid(), isTrue);
      expect(item.consumeOnUse, isFalse);
      expect(item.effects.hasEffects, isTrue);
      expect(item.effects.statChanges?['SAN'], equals(5));
    });
  });
}
