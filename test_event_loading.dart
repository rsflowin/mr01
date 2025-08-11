import 'dart:convert';
import 'package:flutter/services.dart';
import 'lib/models/event_model.dart';

void main() async {
  try {
    print('=== TESTING EVENT LOADING ===');

    // Test loading trap events
    print('Loading trap events...');
    final trapEventsJson = await rootBundle.loadString(
      'data/events/event_traps.json',
    );
    print('JSON loaded successfully, length: ${trapEventsJson.length}');

    final trapEventsData = json.decode(trapEventsJson) as Map<String, dynamic>;
    print('JSON parsed successfully');

    if (trapEventsData.containsKey('events')) {
      final events = trapEventsData['events'];
      print('Events data type: ${events.runtimeType}');

      if (events is Map<String, dynamic>) {
        print('Events is a Map with ${events.length} entries');

        // Try to parse the first event
        final firstEventKey = events.keys.first;
        final firstEventData = events[firstEventKey] as Map<String, dynamic>;
        print('First event key: $firstEventKey');
        print('First event data keys: ${firstEventData.keys.toList()}');

        try {
          final event = Event.fromMap(firstEventData);
          print('Event parsed successfully: ${event.name}');
          print('Event category: ${event.category}');
          print('Event choices: ${event.choices.length}');

          if (event.choices.isNotEmpty) {
            final firstChoice = event.choices.first;
            print('First choice text: ${firstChoice.text}');
            print(
              'First choice success effects: ${firstChoice.successEffects.description}',
            );
          }

          print('=== EVENT LOADING TEST SUCCESS ===');
        } catch (e, stackTrace) {
          print('=== EVENT PARSING ERROR ===');
          print('Error parsing event: $e');
          print('Stack trace: $stackTrace');
        }
      } else {
        print('Events is not a Map, it is: ${events.runtimeType}');
      }
    } else {
      print('JSON does not contain "events" key');
    }
  } catch (e, stackTrace) {
    print('=== EVENT LOADING TEST ERROR ===');
    print('Error: $e');
    print('Stack trace: $stackTrace');
  }
}
