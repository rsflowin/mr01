import 'package:flutter/material.dart';
import '../models/event_model.dart';
import '../services/event_processor.dart';
import '../widgets/event_display.dart';
import '../widgets/choice_buttons.dart';
import '../widgets/event_interaction.dart';

/// Demo screen showcasing the event display and choice presentation system
///
/// This screen demonstrates all the event display widgets and their capabilities
class EventDemoScreen extends StatefulWidget {
  const EventDemoScreen({super.key});

  @override
  State<EventDemoScreen> createState() => _EventDemoScreenState();
}

class _EventDemoScreenState extends State<EventDemoScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late List<Event> _demoEvents;
  late EventProcessor _eventProcessor;
  late Map<String, dynamic> _playerState;

  int _currentEventIndex = 0;
  String _lastChoiceResult = '';

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _initializeDemoData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _initializeDemoData() {
    _demoEvents = _createDemoEvents();
    _eventProcessor = EventProcessor(eventDatabase: _createEventDatabase());
    _playerState = _createDemoPlayerState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Event Display System Demo',
          style: TextStyle(color: Color(0xFFE0E0E0)),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFE0E0E0)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Color(0xFF8B0000)),
            onPressed: _showInfoDialog,
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        children: [
          // Page 1: EventDisplay showcase
          _buildEventDisplayDemo(),

          // Page 2: ChoiceButtons showcase
          _buildChoiceButtonsDemo(),

          // Page 3: Complete EventInteraction showcase
          _buildEventInteractionDemo(),

          // Page 4: Processed event display showcase
          _buildProcessedEventDemo(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigation(),
      floatingActionButton: _buildFloatingActionButtons(),
    );
  }

  Widget _buildEventDisplayDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demo header
          _buildDemoHeader(
            'EventDisplay Widget',
            'Showcases event name, description, and image display with category-specific styling.',
          ),

          const SizedBox(height: 20),

          // Different styles showcase
          _buildStyleShowcase(),

          const SizedBox(height: 20),

          // Category examples
          _buildCategoryExamples(),
        ],
      ),
    );
  }

  Widget _buildChoiceButtonsDemo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Demo header
          _buildDemoHeader(
            'ChoiceButtons Widget',
            'Displays interactive choice options with requirement validation and visual feedback.',
          ),

          const SizedBox(height: 20),

          // Choice states demonstration
          _buildChoiceStatesDemo(),

          const SizedBox(height: 20),

          // Result display
          if (_lastChoiceResult.isNotEmpty) _buildResultDisplay(),
        ],
      ),
    );
  }

  Widget _buildEventInteractionDemo() {
    return Column(
      children: [
        // Demo header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1A1A1A),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Complete Event Interaction',
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Full event experience with EventProcessor integration.',
                style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
              ),
            ],
          ),
        ),

        // Complete event interaction
        Expanded(
          child: EventInteraction(
            eventProcessor: _eventProcessor,
            event: _demoEvents[_currentEventIndex],
            playerState: _playerState,
            onChoiceProcessed: _handleChoiceProcessed,
            enableAnimations: true,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessedEventDemo() {
    final eventData = _eventProcessor.displayEvent(
      _demoEvents[_currentEventIndex],
    );

    return Column(
      children: [
        // Demo header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF1A1A1A),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Processed Event Display',
                style: const TextStyle(
                  color: Color(0xFFE0E0E0),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Displays events that have been processed by EventProcessor.displayEvent().',
                style: const TextStyle(color: Color(0xFF999999), fontSize: 14),
              ),
            ],
          ),
        ),

        // Processed event display
        Expanded(
          child: ProcessedEventDisplay(
            eventData: eventData,
            onChoiceSelected: (index) {
              setState(() {
                _lastChoiceResult =
                    'Selected choice $index: "${eventData['choices'][index]['text']}"';
              });
              _showSnackBar(_lastChoiceResult);
            },
            isChoiceAvailable: (choice) {
              // Demo some choices as unavailable
              return choice['text'].toString().toLowerCase().contains('magic')
                  ? false
                  : true;
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStyleShowcase() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Style Variations',
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        // Default style
        EventDisplay(
          event: _demoEvents[0],
          style: EventDisplayStyle.defaultStyle(),
        ),

        const SizedBox(height: 16),

        // Compact style
        EventDisplay(event: _demoEvents[1], style: EventDisplayStyle.compact()),

        const SizedBox(height: 16),

        // Minimal style
        EventDisplay(event: _demoEvents[2], style: EventDisplayStyle.minimal()),
      ],
    );
  }

  Widget _buildCategoryExamples() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Examples',
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        // Show events by category
        ..._demoEvents
            .take(4)
            .map(
              (event) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                child: EventDisplay(
                  event: event,
                  style: EventDisplayStyle.minimal(),
                ),
              ),
            ),
      ],
    );
  }

  Widget _buildChoiceStatesDemo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choice States Demo',
          style: const TextStyle(
            color: Color(0xFFE0E0E0),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 16),

        // Demo choice buttons with different states
        ChoiceButtons(
          choices: _demoEvents[0].choices,
          onChoiceSelected: (index, choice) {
            setState(() {
              _lastChoiceResult = 'Selected: "${choice.text}"';
            });
            _showSnackBar(_lastChoiceResult);
          },
          isChoiceAvailable: (choice) {
            // Demo: make some choices unavailable based on content
            return !choice.text.toLowerCase().contains('magic');
          },
          style: ChoiceButtonsStyle.defaultStyle().copyWith(
            showHeader: true,
            showChoiceCount: true,
          ),
          showChoiceIndices: true,
        ),
      ],
    );
  }

  Widget _buildResultDisplay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF8B0000).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last Choice Result:',
            style: const TextStyle(
              color: Color(0xFF8B0000),
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _lastChoiceResult,
            style: const TextStyle(color: Color(0xFFD4D4D4), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoHeader(String title, String description) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFF8B0000).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFFE0E0E0),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 14,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        border: Border(
          top: BorderSide(
            color: const Color(0xFF8B0000).withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavButton('EventDisplay', 0),
              _buildNavButton('ChoiceButtons', 1),
              _buildNavButton('Interaction', 2),
              _buildNavButton('Processed', 3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(String label, int pageIndex) {
    return TextButton(
      onPressed: () {
        _pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF8B0000),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFloatingActionButtons() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Previous event
        FloatingActionButton(
          heroTag: 'prev',
          mini: true,
          backgroundColor: const Color(0xFF8B0000),
          child: const Icon(Icons.skip_previous, color: Colors.white),
          onPressed: _previousEvent,
        ),

        const SizedBox(height: 8),

        // Next event
        FloatingActionButton(
          heroTag: 'next',
          mini: true,
          backgroundColor: const Color(0xFF8B0000),
          child: const Icon(Icons.skip_next, color: Colors.white),
          onPressed: _nextEvent,
        ),
      ],
    );
  }

  void _previousEvent() {
    setState(() {
      _currentEventIndex = (_currentEventIndex - 1) % _demoEvents.length;
      if (_currentEventIndex < 0) _currentEventIndex = _demoEvents.length - 1;
    });
  }

  void _nextEvent() {
    setState(() {
      _currentEventIndex = (_currentEventIndex + 1) % _demoEvents.length;
    });
  }

  void _handleChoiceProcessed(Map<String, dynamic> result) {
    setState(() {
      _lastChoiceResult =
          'Processed choice: ${result['choiceText']}\n'
          'Success: ${result['success']}\n'
          'Description: ${result['description']}';
    });

    _showSnackBar('Choice processed successfully!');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF8B0000),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text(
          'Event Display System Demo',
          style: TextStyle(color: Color(0xFFE0E0E0)),
        ),
        content: const Text(
          'This demo showcases the event display and choice presentation system components:\n\n'
          '• EventDisplay: Shows event name, description, and image\n'
          '• ChoiceButtons: Interactive choice selection with validation\n'
          '• EventInteraction: Complete event experience\n'
          '• ProcessedEventDisplay: For pre-processed event data\n\n'
          'Use the navigation buttons to explore different demos, and the floating buttons to cycle through events.',
          style: TextStyle(color: Color(0xFFD4D4D4)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: Color(0xFF8B0000)),
            ),
          ),
        ],
      ),
    );
  }

  // Demo data creation methods
  List<Event> _createDemoEvents() {
    return [
      Event(
        id: 'demo_trap',
        name: 'Hidden Pit Trap',
        description:
            'As you step forward, the floor gives way beneath your feet! A deep pit opens up, filled with sharp spikes at the bottom. Your quick reflexes might save you.',
        image: 'pit_trap.png',
        category: 'trap',
        weight: 10,
        persistence: 'persistent',
        choices: [
          Choice(
            text: 'Try to jump to safety',
            successEffects: ChoiceEffects(
              description:
                  'You leap with surprising agility and land safely on the other side.',
              statChanges: {'SAN': 5, 'FITNESS': -5},
            ),
            failureEffects: ChoiceEffects(
              description:
                  'You fall into the pit, but manage to grab the edge and climb out.',
              statChanges: {'HP': -15, 'SAN': -10},
            ),
            successConditions: {
              'stats': {
                'FITNESS': {'operator': '>', 'value': 60},
              },
            },
          ),
          Choice(
            text: 'Carefully find another path',
            successEffects: ChoiceEffects(
              description:
                  'You find a way around the trap, feeling clever and cautious.',
              statChanges: {'SAN': 10, 'HUNGER': -5},
            ),
          ),
          Choice(
            text: 'Use magic to levitate across',
            requirements: {
              'items': ['magic_scroll'],
            },
            successEffects: ChoiceEffects(
              description:
                  'You float gracefully across the pit using arcane powers.',
              statChanges: {'SAN': 15},
              itemsLost: ['magic_scroll'],
            ),
          ),
        ],
      ),

      Event(
        id: 'demo_item',
        name: 'Mysterious Chest',
        description:
            'You discover an ornate chest sitting in the corner of the room. Its metal surface is covered in intricate engravings, and it seems to glow with an inner light.',
        image: 'treasure_chest.png',
        category: 'item',
        weight: 15,
        persistence: 'oneTime',
        choices: [
          Choice(
            text: 'Open the chest carefully',
            successEffects: ChoiceEffects(
              description:
                  'The chest opens with a satisfying click, revealing valuable treasures inside.',
              statChanges: {'SAN': 10},
              itemsGained: ['golden_sword', 'health_potion'],
            ),
            failureEffects: ChoiceEffects(
              description:
                  'The chest is trapped! A small explosion singes your hands.',
              statChanges: {'HP': -10, 'SAN': -5},
            ),
            successConditions: {'probability': 0.7},
          ),
          Choice(
            text: 'Examine for traps first',
            requirements: {
              'stats': {
                'FITNESS': {'operator': '>=', 'value': 40},
              },
            },
            successEffects: ChoiceEffects(
              description:
                  'Your careful examination reveals and disarms a trap. The chest opens safely.',
              statChanges: {'SAN': 15},
              itemsGained: ['golden_sword', 'health_potion', 'trap_kit'],
            ),
          ),
          Choice(
            text: 'Leave it alone',
            successEffects: ChoiceEffects(
              description:
                  'You decide discretion is the better part of valor and move on.',
              statChanges: {'SAN': 5},
            ),
          ),
        ],
      ),

      Event(
        id: 'demo_character',
        name: 'Wise Oracle',
        description:
            'An elderly figure in flowing robes sits cross-legged before a crystal ball. Her eyes are clouded with age, but they seem to see far more than they should.',
        image: 'oracle.png',
        category: 'character',
        weight: 12,
        persistence: 'oneTime',
        choices: [
          Choice(
            text: 'Ask about your destiny',
            successEffects: ChoiceEffects(
              description:
                  'The oracle speaks of trials ahead and hidden strengths within you.',
              statChanges: {'SAN': 20, 'HUNGER': -10},
              applyStatus: ['blessed'],
            ),
          ),
          Choice(
            text: 'Request directions out of the maze',
            successEffects: ChoiceEffects(
              description:
                  'She points in a direction and whispers cryptic directions.',
              statChanges: {'SAN': 10},
            ),
          ),
          Choice(
            text: 'Offer her food',
            requirements: {
              'items': ['bread'],
            },
            successEffects: ChoiceEffects(
              description:
                  'The oracle smiles gratefully and gives you a magical blessing.',
              statChanges: {'SAN': 25, 'HP': 15},
              itemsLost: ['bread'],
              itemsGained: ['oracle_blessing'],
            ),
          ),
        ],
      ),

      Event(
        id: 'demo_monster',
        name: 'Shadow Beast',
        description:
            'A creature of living darkness emerges from the shadows, its eyes glowing like red embers. It moves with predatory grace, sizing you up as potential prey.',
        image: 'shadow_beast.png',
        category: 'monster',
        weight: 8,
        persistence: 'oneTime',
        choices: [
          Choice(
            text: 'Fight with weapon',
            requirements: {
              'items': ['sword'],
            },
            successEffects: ChoiceEffects(
              description:
                  'Your blade cuts through the darkness, dispersing the creature.',
              statChanges: {'SAN': 15, 'FITNESS': -10},
              itemsGained: ['shadow_essence'],
            ),
            failureEffects: ChoiceEffects(
              description:
                  'The beast claws you before you manage to drive it away.',
              statChanges: {'HP': -20, 'SAN': -10, 'FITNESS': -5},
            ),
            successConditions: {
              'stats': {
                'FITNESS': {'operator': '>', 'value': 50},
              },
            },
          ),
          Choice(
            text: 'Try to flee',
            successEffects: ChoiceEffects(
              description:
                  'You manage to outrun the creature and escape to safety.',
              statChanges: {'SAN': 5, 'FITNESS': -15},
            ),
            failureEffects: ChoiceEffects(
              description:
                  'The beast catches you as you run, landing a vicious blow.',
              statChanges: {'HP': -25, 'SAN': -15},
            ),
            successConditions: {'probability': 0.6},
          ),
          Choice(
            text: 'Use light source to ward it off',
            requirements: {
              'items': ['torch'],
            },
            successEffects: ChoiceEffects(
              description:
                  'The bright light causes the shadow creature to retreat into the darkness.',
              statChanges: {'SAN': 10},
            ),
          ),
        ],
      ),

      Event(
        id: 'demo_rest',
        name: 'Peaceful Garden',
        description:
            'You find yourself in a small, enclosed garden. Soft moss covers the ground, and gentle light filters through an opening above. This seems like a perfect place to rest.',
        image: 'garden.png',
        category: 'rest',
        weight: 20,
        persistence: 'persistent',
        choices: [
          Choice(
            text: 'Take a short rest',
            successEffects: ChoiceEffects(
              description:
                  'You feel refreshed and ready to continue your journey.',
              statChanges: {'HP': 10, 'SAN': 15, 'HUNGER': -5},
            ),
          ),
          Choice(
            text: 'Meditate for inner peace',
            successEffects: ChoiceEffects(
              description:
                  'Deep meditation brings clarity and spiritual renewal.',
              statChanges: {'SAN': 25, 'HUNGER': -10},
              applyStatus: ['inner_peace'],
            ),
          ),
          Choice(
            text: 'Search for useful plants',
            successEffects: ChoiceEffects(
              description:
                  'You find some medicinal herbs growing in the garden.',
              statChanges: {'SAN': 5},
              itemsGained: ['healing_herbs'],
            ),
            failureEffects: ChoiceEffects(
              description:
                  'You find nothing useful, but the search was relaxing.',
              statChanges: {'SAN': 2},
            ),
            successConditions: {'probability': 0.5},
          ),
        ],
      ),
    ];
  }

  Map<String, Event> _createEventDatabase() {
    final events = _createDemoEvents();
    return {for (final event in events) event.id: event};
  }

  Map<String, dynamic> _createDemoPlayerState() {
    return {
      'stats': {'HP': 75, 'SAN': 60, 'FITNESS': 65, 'HUNGER': 70},
      'inventory': ['sword', 'torch', 'bread'],
      'statusEffects': [],
    };
  }
}
